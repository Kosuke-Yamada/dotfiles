"""Search script for related work survey using the arXiv API.

Uses the arXiv API to collect paper metadata and output results in JSON format to stdout.
arXiv API is free, stable, and does not require an API key.

Usage:
  python3 search_papers.py "query string" [--year 2020-2025] [--limit 50] [--field NLP]
"""

import argparse
import json
import re
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

# Auto-check and install dependencies
try:
    import requests
except ImportError:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "requests"])
    import requests

# arXiv API endpoint
ARXIV_API_URL = "https://export.arxiv.org/api/query"

# arXiv category mappings per research field
ARXIV_CATEGORIES = {
    "NLP": ["cs.CL", "cs.IR"],
    "ML": ["cs.LG", "stat.ML"],
    "AI": ["cs.AI"],
    "IR": ["cs.IR", "cs.DB"],
    "HCI": ["cs.HC"],
    "CV": ["cs.CV"],
    "DB": ["cs.DB"],
    "all": ["cs.CL", "cs.LG", "cs.AI", "cs.IR", "cs.CV", "cs.HC", "cs.DB", "stat.ML"],
}

# arXiv recommends >= 3 seconds between requests for non-API-key access
REQUEST_INTERVAL = 3.0


def _parse_arxiv_entry(entry, ns, year_start=None, year_end=None):
    """Parse an arXiv entry XML element into a paper dict.

    Returns None if the paper falls outside the requested year range.
    """
    # Publication date
    published_el = entry.find("atom:published", ns)
    if published_el is not None:
        pub_date = published_el.text[:10]  # YYYY-MM-DD
        year = int(pub_date[:4])
    else:
        pub_date = ""
        year = 0

    if year_start and year < year_start:
        return None
    if year_end and year > year_end:
        return None

    # arXiv ID and URL
    id_el = entry.find("atom:id", ns)
    arxiv_url = id_el.text.strip() if id_el is not None else ""
    arxiv_id = arxiv_url.split("/abs/")[-1] if "/abs/" in arxiv_url else ""

    # Title (collapse whitespace)
    title_el = entry.find("atom:title", ns)
    title = " ".join(title_el.text.split()) if title_el is not None else ""

    # Abstract
    summary_el = entry.find("atom:summary", ns)
    abstract = " ".join(summary_el.text.split()) if summary_el is not None else ""

    # Authors
    authors = []
    for author_el in entry.findall("atom:author", ns):
        name_el = author_el.find("atom:name", ns)
        if name_el is not None:
            authors.append({"name": name_el.text.strip(), "author_id": ""})

    # arXiv categories
    categories = [
        cat_el.get("term", "")
        for cat_el in entry.findall("atom:category", ns)
        if cat_el.get("term", "")
    ]

    return {
        "paper_id": f"arxiv:{arxiv_id}",
        "title": title,
        "authors": authors,
        "year": year,
        "venue": "arXiv",
        "venue_tier": "arxiv",
        "abstract": abstract,
        "citation_count": 0,  # arXiv API does not provide citation counts
        "reference_count": 0,
        "priority_score": 0,   # computed after collection
        "publication_date": pub_date,
        "external_ids": {
            "DOI": "",
            "ArXiv": arxiv_id,
            "ACL": "",
        },
        "url": arxiv_url,
        "open_access_pdf": f"https://arxiv.org/pdf/{arxiv_id}",
        "publication_types": ["Preprint"],
        "fields_of_study": categories,
    }


def _compute_priority_score(paper, current_year=2026):
    """Compute a recency-based priority score.

    arXiv API does not provide citation counts, so score is recency-only.
    """
    year = paper.get("year") or current_year - 5
    years_ago = max(current_year - year, 0)

    if years_ago <= 1:
        return 30
    elif years_ago <= 2:
        return 15
    elif years_ago <= 3:
        return 8
    else:
        return max(0, 5 - years_ago)


def search_arxiv(query, year_start=None, year_end=None, categories=None, limit=100):
    """Search papers on arXiv using the public Atom/API endpoint.

    Args:
        query: Search query string (English).
        year_start: Inclusive start year filter (None = no limit).
        year_end: Inclusive end year filter (None = no limit).
        categories: List of arXiv category strings, e.g. ["cs.CL", "cs.LG"].
        limit: Maximum number of papers to return.

    Returns:
        Tuple of (papers, warnings, errors).
    """
    papers = []
    warnings = []
    errors = []

    # Build full query with optional category filter
    if categories:
        cat_filter = " OR ".join(f"cat:{cat}" for cat in categories)
        full_query = f"all:{query} AND ({cat_filter})"
    else:
        full_query = f"all:{query}"

    # Fetch in batches; fetch up to 3x limit to account for year filtering
    fetch_target = min(limit * 3, 500)
    batch_size = min(100, fetch_target)
    start = 0

    while len(papers) < fetch_target:
        params = {
            "search_query": full_query,
            "start": start,
            "max_results": batch_size,
            "sortBy": "relevance",
            "sortOrder": "descending",
        }

        time.sleep(REQUEST_INTERVAL)

        try:
            resp = requests.get(ARXIV_API_URL, params=params, timeout=30)
            resp.raise_for_status()
        except requests.exceptions.RequestException as e:
            errors.append(f"arXiv API error: {e}")
            break

        ns = {
            "atom": "http://www.w3.org/2005/Atom",
            "opensearch": "http://a9.com/-/spec/opensearch/1.1/",
        }
        root = ET.fromstring(resp.content)
        entries = root.findall("atom:entry", ns)

        if not entries:
            if not papers:
                warnings.append("No results from arXiv. Try a different query or broader categories.")
            break

        for entry in entries:
            paper = _parse_arxiv_entry(entry, ns, year_start, year_end)
            if paper:
                papers.append(paper)

        # Check total available results
        total_el = root.find("opensearch:totalResults", ns)
        total_available = int(total_el.text) if total_el is not None else 0

        start += batch_size
        if start >= total_available or start >= fetch_target:
            break

    # Compute priority scores and trim
    for paper in papers:
        paper["priority_score"] = _compute_priority_score(paper)

    papers.sort(key=lambda p: -p["priority_score"])
    papers = papers[:limit]

    if not papers:
        warnings.append("No papers collected. Consider widening year range or changing categories.")
    else:
        warnings.append(
            f"arXiv API note: citation counts are not available. "
            f"Priority score is recency-based only."
        )

    return papers, warnings, errors


def main():
    parser = argparse.ArgumentParser(
        description="Search related work on arXiv via the public API"
    )
    parser.add_argument("query", help="Search query (English)")
    parser.add_argument(
        "--year",
        default=None,
        help="Year range filter, e.g. 2020-2025 or 2024",
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=100,
        help="Maximum number of results (default: 100)",
    )
    parser.add_argument(
        "--field",
        default=None,
        choices=list(ARXIV_CATEGORIES.keys()),
        help="Research field shorthand: " + ", ".join(ARXIV_CATEGORIES.keys()),
    )
    parser.add_argument(
        "--categories",
        default=None,
        help="arXiv categories (comma-separated, e.g. cs.CL,cs.LG). Overrides --field.",
    )

    args = parser.parse_args()

    # Parse year range
    year_start = year_end = None
    if args.year:
        parts = args.year.split("-")
        try:
            if len(parts) == 2:
                year_start, year_end = int(parts[0]), int(parts[1])
            elif len(parts) == 1:
                year_start = year_end = int(parts[0])
        except ValueError:
            print(f"Invalid year format: {args.year}", file=sys.stderr)
            sys.exit(1)

    # Resolve categories
    categories = None
    if args.categories:
        categories = [c.strip() for c in args.categories.split(",") if c.strip()]
    elif args.field:
        categories = ARXIV_CATEGORIES.get(args.field)

    papers, warnings, errors = search_arxiv(
        query=args.query,
        year_start=year_start,
        year_end=year_end,
        categories=categories,
        limit=args.limit,
    )

    output = {
        "query_info": {
            "query": args.query,
            "year_range": args.year or "not specified",
            "categories": categories or "all",
            "returned": len(papers),
        },
        "papers": papers,
        "errors": errors,
        "warnings": warnings,
    }

    print(json.dumps(output, ensure_ascii=False, indent=2))

    if errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
