#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import random
import re
import shutil
import socket
import string
import subprocess
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

try:
    from rich.console import Console
    from rich.live import Live
    from rich.panel import Panel
    from rich.progress import BarColumn, Progress, SpinnerColumn, TextColumn, TimeElapsedColumn
    from rich.table import Table
except Exception:
    Console = Live = Panel = Progress = SpinnerColumn = TextColumn = BarColumn = TimeElapsedColumn = Table = None

try:
    import dns.resolver
except Exception:
    dns = None


AUTHOR = "EnCrYpTeD05"
VERSION = "8.1.0"
UA = f"subrecon/{VERSION}"

HOST_RE = re.compile(
    r"^(?=.{1,253}$)(?!-)(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$"
)

HOST_EXTRACT_RE = re.compile(
    r"(?:\*\.)?([a-zA-Z0-9](?:[a-zA-Z0-9_-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9_-]{0,61}[a-zA-Z0-9])?)+)"
)


@dataclass
class Counters:
    sources_total: int = 0
    sources_processed: int = 0
    raw_collected: int = 0
    normalized: int = 0
    unique_subdomains: int = 0
    duplicates_removed: int = 0
    checked: int = 0
    exported_subdomains: int = 0
    false_positives: int = 0
    started: float = field(default_factory=time.time)


class UI:
    def __init__(self) -> None:
        self.console = Console() if Console else None
        self.progress = None
        self.live = None
        self.collect_task = None
        self.filter_task = None

    def start(self, counters: Counters) -> None:
        banner = r"""
   _____       ____           ______          
  / ___/__  __/ __ )_______  / ____/___  ____ 
  \__ \/ / / / __  / ___/ _ \/ /   / __ \/ __ \
 ___/ / /_/ / /_/ / /  /  __/ /___/ /_/ / / / /
/____/\__,_/_____/_/   \___/\____/\____/_/ /_/ 
"""
        if self.console and Progress:
            self.console.print(f"[bold cyan]{banner}[/bold cyan]")
            self.console.print(f"[bold red]Created by {AUTHOR}[/bold red]\n")

            self.progress = Progress(
                SpinnerColumn(),
                TextColumn("[bold cyan]{task.description}"),
                BarColumn(bar_width=42),
                TextColumn("[progress.percentage]{task.percentage:>3.0f}%"),
                TimeElapsedColumn(),
            )
            self.collect_task = self.progress.add_task("Collecting from all sources", total=max(counters.sources_total, 1))
            self.filter_task = self.progress.add_task("Filtering clear false positives", total=1)

            self.live = Live(self.render(counters), console=self.console, refresh_per_second=8)
            self.live.__enter__()
        else:
            print(f"\033[96m{banner}\033[0m")
            print(f"\033[91mCreated by {AUTHOR}\033[0m\n")

    def render(self, counters: Counters):
        if not Table or not Panel:
            return None

        table = Table.grid(expand=True)
        table.add_column(justify="left")
        table.add_column(justify="right")
        table.add_row("[bold]Sources Processed[/bold]", f"{counters.sources_processed}/{counters.sources_total}")
        table.add_row("[bold]Raw Collected[/bold]", str(counters.raw_collected))
        table.add_row("[bold]Normalized[/bold]", str(counters.normalized))
        table.add_row("[bold]Unique Subdomains[/bold]", str(counters.unique_subdomains))
        table.add_row("[bold]Exported Subdomains[/bold]", str(counters.exported_subdomains))
        table.add_row("[bold]Duplicates Removed[/bold]", str(counters.duplicates_removed))
        table.add_row("[bold]False Positives[/bold]", str(counters.false_positives))
        table.add_row("[bold]Elapsed Time[/bold]", f"{time.time() - counters.started:.1f}s")

        outer = Table.grid(expand=True)
        outer.add_row(self.progress)
        outer.add_row(Panel(table, title="Live Counters", border_style="cyan"))
        return outer

    def update(self, counters: Counters, filter_total: int | None = None) -> None:
        if self.progress and self.collect_task is not None:
            self.progress.update(self.collect_task, completed=counters.sources_processed)

        if self.progress and self.filter_task is not None:
            if filter_total is not None:
                self.progress.update(self.filter_task, total=max(filter_total, 1))
            self.progress.update(self.filter_task, completed=counters.checked)

        if self.live:
            self.live.update(self.render(counters))

    def stop(self) -> None:
        if self.live:
            self.live.__exit__(None, None, None)
            self.live = None

    def warn(self, message: str) -> None:
        if self.console:
            self.console.print(f"[yellow]{message}[/yellow]")
        else:
            print(f"\033[93m{message}\033[0m")


def internet_online(timeout: float = 5.0) -> bool:
    try:
        with socket.create_connection(("1.1.1.1", 53), timeout=timeout):
            return True
    except OSError:
        try:
            req = Request("https://example.com", headers={"User-Agent": UA})
            with urlopen(req, timeout=timeout):
                return True
        except Exception:
            return False


def wait_for_internet(ui: UI) -> None:
    if internet_online():
        return
    ui.warn("Internet unavailable. Waiting to start...")
    while not internet_online():
        time.sleep(5)


def fetch(url: str, timeout: float) -> str:
    req = Request(url, headers={"User-Agent": UA})
    with urlopen(req, timeout=timeout) as response:
        return response.read().decode("utf-8", errors="replace")


def valid_hostname(hostname: str) -> bool:
    hostname = hostname.strip().lower().removesuffix(".")
    if not HOST_RE.match(hostname):
        return False
    return all(0 < len(label) <= 63 for label in hostname.split("."))


def extract_hosts(text: str) -> Iterable[str]:
    for match in HOST_EXTRACT_RE.findall(text):
        yield match


def normalize(raw: str, domain: str) -> tuple[str | None, str | None]:
    original = raw.strip()
    if not original:
        return None, "empty"

    value = original.lower().strip()

    if "://" in value:
        parsed = urlparse(value)
        value = parsed.hostname or value

    matches = list(extract_hosts(value))
    if matches:
        value = matches[0]

    value = value.strip().lower()
    value = value.removeprefix("*.").removesuffix(".")
    value = value.split("/", 1)[0].split(":", 1)[0]

    root = domain.lower().removesuffix(".")

    if value == root:
        return None, f"{original} | root-domain"

    if not value.endswith("." + root):
        return None, f"{original} | out-of-scope"

    if not valid_hostname(value):
        return None, f"{original} | invalid-syntax"

    return value, None


class Collector:
    name = "collector"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        return []


class CrtShCollector(Collector):
    name = "crt.sh"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        data = json.loads(fetch(f"https://crt.sh/?q=%25.{quote(domain)}&output=json", timeout))
        for row in data:
            for name in str(row.get("name_value", "")).splitlines():
                yield name


class HackerTargetCollector(Collector):
    name = "hackertarget"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        text = fetch(f"https://api.hackertarget.com/hostsearch/?q={quote(domain)}", timeout)
        for line in text.splitlines():
            yield line.split(",", 1)[0] if "," in line else line


class AlienVaultCollector(Collector):
    name = "alienvault-otx"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        url = f"https://otx.alienvault.com/api/v1/indicators/domain/{quote(domain)}/passive_dns"
        data = json.loads(fetch(url, timeout))
        for item in data.get("passive_dns", []):
            if item.get("hostname"):
                yield str(item["hostname"])


class UrlscanCollector(Collector):
    name = "urlscan"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        url = f"https://urlscan.io/api/v1/search/?q=domain:{quote(domain)}&size=10000"
        data = json.loads(fetch(url, timeout))
        for item in data.get("results", []):
            page = item.get("page", {})
            if page.get("domain"):
                yield str(page["domain"])
            if page.get("url"):
                yield str(page["url"])


class RapidDnsCollector(Collector):
    name = "rapiddns"

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        yield from extract_hosts(fetch(f"https://rapiddns.io/subdomain/{quote(domain)}?full=1", timeout))


class ExternalToolCollector(Collector):
    def __init__(self, name: str, variants: list[list[str]], timeout_floor: int) -> None:
        self.name = name
        self.variants = variants
        self.timeout_floor = timeout_floor

    def command(self) -> list[str] | None:
        for variant in self.variants:
            if shutil.which(variant[0]):
                return variant
        return None

    def collect(self, domain: str, timeout: float) -> Iterable[str]:
        variant = self.command()
        if not variant:
            return []

        cmd = [part.format(domain=domain) for part in variant]
        proc = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=max(int(timeout), self.timeout_floor),
            check=False,
        )

        for line in (proc.stdout + "\n" + proc.stderr).splitlines():
            yield from extract_hosts(line)


def internal_collectors() -> list[Collector]:
    return [
        CrtShCollector(),
        HackerTargetCollector(),
        AlienVaultCollector(),
        UrlscanCollector(),
        RapidDnsCollector(),
    ]


def external_collectors() -> list[Collector]:
    candidates = [
        ExternalToolCollector("subfinder", [["subfinder", "-silent", "-d", "{domain}"]], 900),
        ExternalToolCollector("amass", [["amass", "enum", "-passive", "-norecursive", "-noalts", "-d", "{domain}"]], 1200),
        ExternalToolCollector("assetfinder", [["assetfinder", "--subs-only", "{domain}"]], 600),
        ExternalToolCollector(
            "sublist3r",
            [
                ["sublist3r", "-d", "{domain}"],
                ["Sublist3r", "-d", "{domain}"],
                ["sublist3r.py", "-d", "{domain}"],
            ],
            900,
        ),
    ]
    return [collector for collector in candidates if collector.command()]


def run_collector(collector: Collector, domain: str, timeout: float) -> tuple[str, list[str]]:
    results: list[str] = []
    try:
        for value in collector.collect(domain, timeout):
            if value:
                results.append(str(value))
    except Exception:
        pass
    return collector.name, results


def resolve_records(hostname: str, timeout: float) -> tuple[bool, set[str]]:
    if dns is not None:
        resolver = dns.resolver.Resolver()
        resolver.lifetime = timeout
        resolver.timeout = timeout
        values: set[str] = set()

        for record_type in ("A", "AAAA", "CNAME"):
            try:
                answers = resolver.resolve(hostname, record_type)
                for answer in answers:
                    values.add(str(answer).rstrip("."))
            except Exception:
                continue

        return bool(values), values

    socket.setdefaulttimeout(timeout)
    try:
        values = {item[4][0] for item in socket.getaddrinfo(hostname, None)}
        return bool(values), values
    except OSError:
        return False, set()


def detect_wildcard_values(domain: str, timeout: float) -> set[str]:
    wildcard_sets: list[set[str]] = []

    for _ in range(5):
        random_host = "sr-" + "".join(random.choices(string.ascii_lowercase + string.digits, k=24))
        resolved, values = resolve_records(f"{random_host}.{domain}", timeout)
        if resolved and values:
            wildcard_sets.append(values)

    if len(wildcard_sets) < 3:
        return set()

    common = set.intersection(*wildcard_sets)
    if common:
        return common

    repeated: dict[str, int] = {}
    for values in wildcard_sets:
        for value in values:
            repeated[value] = repeated.get(value, 0) + 1

    return {value for value, count in repeated.items() if count >= 4}


def filter_one(hostname: str, wildcard_values: set[str], timeout: float) -> tuple[str, bool, str | None]:
    if not valid_hostname(hostname):
        return hostname, False, "invalid-syntax"

    resolved, values = resolve_records(hostname, timeout)

    # Important: DNS failure is NOT treated as false positive.
    # Passive sources often contain historical or temporarily unresolved subdomains.
    if not resolved:
        return hostname, True, None

    # Only strong wildcard evidence removes a hostname.
    if wildcard_values and values and values.issubset(wildcard_values):
        return hostname, False, "wildcard-dns"

    return hostname, True, None


def collect_merge_dedupe(
    domain: str,
    collectors: list[Collector],
    counters: Counters,
    ui: UI,
    timeout: float,
    workers: int,
) -> tuple[set[str], set[str]]:
    subdomains: set[str] = set()
    falsepositives: set[str] = set()
    lock = threading.RLock()

    counters.sources_total = len(collectors)
    ui.update(counters)

    with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        futures = [pool.submit(run_collector, collector, domain, timeout) for collector in collectors]

        for future in as_completed(futures):
            _, raw_values = future.result()

            with lock:
                for raw in raw_values:
                    counters.raw_collected += 1
                    normalized, fp_reason = normalize(raw, domain)

                    if fp_reason:
                        falsepositives.add(fp_reason)
                        counters.false_positives = len(falsepositives)
                        continue

                    if not normalized:
                        continue

                    counters.normalized += 1

                    if normalized in subdomains:
                        counters.duplicates_removed += 1
                    else:
                        subdomains.add(normalized)

                counters.sources_processed += 1
                counters.unique_subdomains = len(subdomains)
                counters.exported_subdomains = len(subdomains)
                ui.update(counters)

    return subdomains, falsepositives


def filter_all(
    subdomains: set[str],
    falsepositives: set[str],
    domain: str,
    counters: Counters,
    ui: UI,
    timeout: float,
    workers: int,
) -> set[str]:
    valid: set[str] = set()
    wildcard_values = detect_wildcard_values(domain, timeout)
    lock = threading.RLock()

    ui.update(counters, filter_total=len(subdomains))

    with ThreadPoolExecutor(max_workers=max(1, workers)) as pool:
        futures = [
            pool.submit(filter_one, hostname, wildcard_values, timeout)
            for hostname in sorted(subdomains)
        ]

        for future in as_completed(futures):
            hostname, ok, reason = future.result()

            with lock:
                counters.checked += 1

                if ok:
                    valid.add(hostname)
                else:
                    falsepositives.add(f"{hostname} | {reason}")

                counters.exported_subdomains = len(valid)
                counters.false_positives = len(falsepositives)
                ui.update(counters, filter_total=len(subdomains))

    return valid


def write_lines(path: Path, lines: Iterable[str]) -> None:
    data = sorted(set(line.strip() for line in lines if line and line.strip()))
    path.write_text("\n".join(data) + ("\n" if data else ""), encoding="utf-8")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="SuBreCon - fast subdomain merger and cleaner.")
    parser.add_argument("domain", help="Root domain, example: example.com")
    parser.add_argument("--timeout", type=float, default=8.0, help="DNS and source timeout")
    parser.add_argument("--collector-workers", type=int, default=9, help="Concurrent source workers")
    parser.add_argument("--filter-workers", type=int, default=120, help="Concurrent filter workers")
    parser.add_argument("--no-external-tools", action="store_true", help="Disable external tool collection")
    return parser


def main() -> int:
    args = build_parser().parse_args()
    domain = args.domain.strip().lower().removesuffix(".")

    collectors = internal_collectors()
    if not args.no_external_tools:
        collectors.extend(external_collectors())

    counters = Counters(sources_total=len(collectors))
    ui = UI()

    ui.start(counters)
    wait_for_internet(ui)

    final_subdomains: set[str] = set()
    falsepositives: set[str] = set()

    try:
        merged, falsepositives = collect_merge_dedupe(
            domain=domain,
            collectors=collectors,
            counters=counters,
            ui=ui,
            timeout=args.timeout,
            workers=args.collector_workers,
        )

        final_subdomains = filter_all(
            subdomains=merged,
            falsepositives=falsepositives,
            domain=domain,
            counters=counters,
            ui=ui,
            timeout=args.timeout,
            workers=args.filter_workers,
        )

        write_lines(Path("subdomains.txt"), final_subdomains)
        write_lines(Path("false_positive.txt"), falsepositives)

    finally:
        ui.stop()

    print()
    print(f"Domain: {domain}")
    print(f"Sources Processed: {counters.sources_processed}/{counters.sources_total}")
    print(f"Raw Collected: {counters.raw_collected}")
    print(f"Normalized: {counters.normalized}")
    print(f"Unique Subdomains: {counters.unique_subdomains}")
    print(f"Exported Subdomains: {len(final_subdomains)}")
    print(f"Duplicates Removed: {counters.duplicates_removed}")
    print(f"False Positives: {len(falsepositives)}")
    print("Output File: subdomains.txt")
    print("False Positive File: false_positive.txt")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
