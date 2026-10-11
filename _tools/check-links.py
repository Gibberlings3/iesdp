#!/usr/bin/env python3
"""Crawl generated local links; optionally fail only on regressions vs a build."""

import argparse
import json
import posixpath
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit


class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.anchors = set()
        self.links = []
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        for key in ("id", "name"):
            if attrs.get(key):
                self.anchors.add(attrs[key])
        for key in ("href", "src", "poster"):
            if attrs.get(key):
                self.links.append(attrs[key])


def crawl(root):
    if not (root / "index.htm").is_file():
        raise ValueError(f"Missing generated homepage in {root}")
    pages = {
        file.relative_to(root).as_posix(): Page(file.read_text(encoding="utf-8", errors="replace"))
        for file in root.rglob("*")
        if file.suffix.lower() in (".htm", ".html")
    }
    issues = set()
    checked = 0
    for source, page in pages.items():
        for href in page.links:
            url = urlsplit(urljoin("https://local.invalid/iesdp/" + source, href))
            if url.scheme not in ("http", "https") or url.netloc not in ("local.invalid", "gibberlings3.github.io"):
                continue
            checked += 1
            path = posixpath.normpath(unquote(url.path))
            if path == "/iesdp":
                path += "/"
            if not path.startswith("/iesdp/"):
                issues.add((source, href, "outside baseurl"))
                continue
            relative = path.removeprefix("/iesdp/")
            target = root / relative
            if target.is_dir():
                target = next((target / name for name in ("index.html", "index.htm") if (target / name).is_file()), target / "index.htm")
                relative = target.relative_to(root).as_posix()
            if not target.is_file():
                issues.add((source, href, "missing file"))
            elif url.fragment and relative in pages and unquote(url.fragment) not in pages[relative].anchors:
                issues.add((source, href, "missing anchor"))
    return {"html_pages": len(pages), "local_references": checked}, issues


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("site", type=Path)
    parser.add_argument("--baseline", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    summary, issues = crawl(args.site)
    baseline_summary, old = crawl(args.baseline) if args.baseline else ({}, set())
    new = issues - old
    report = {
        "current": summary,
        "baseline": baseline_summary,
        "existing_issue_count": len(issues & old),
        "resolved_issue_count": len(old - issues),
        "new_issues": sorted(new),
        "current_issues": sorted(issues),
    }
    if args.output:
        args.output.write_text(json.dumps(report, indent=2) + "\n")
    print(f"Checked {summary['html_pages']} HTML pages and {summary['local_references']} local references")
    print(f"{len(new)} new issues; {len(issues & old)} existing issues; {len(old - issues)} resolved")
    for source, href, kind in sorted(new)[:10]:
        print(f"  {source}: {kind}: {href}")
    return 1 if new else 0


if __name__ == "__main__":
    raise SystemExit(main())
