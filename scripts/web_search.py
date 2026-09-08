#!/usr/bin/env python3
import sys
import json
import urllib.request
import urllib.parse
import re

def search(query, max_results=5):
    url = "https://html.duckduckgo.com/html/"
    data = urllib.parse.urlencode({"q": query}).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "User-Agent": "Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0"
        }
    )
    results = []
    try:
        html = urllib.request.urlopen(req, timeout=10).read().decode("utf-8", errors="ignore")
        titles = re.findall(r'<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="([^"]+)"[^>]*>(.*?)</a>', html, re.DOTALL)
        snippets = re.findall(r'<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</a>', html, re.DOTALL)
        for i in range(min(len(titles), len(snippets), max_results)):
            href, title_html = titles[i]
            snip_html = snippets[i]
            clean_title = re.sub(r'<[^>]+>', '', title_html).strip()
            clean_snippet = re.sub(r'<[^>]+>', '', snip_html).strip()
            actual_url = href
            if "uddg=" in href:
                actual_url = urllib.parse.unquote(href.split("uddg=")[1].split("&")[0])
            results.append({
                "title": clean_title,
                "snippet": clean_snippet,
                "url": actual_url
            })
    except Exception as e:
        sys.stderr.write(f"Web search error: {e}\n")
    return results

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("[]")
        sys.exit(0)
    q = sys.argv[1]
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    res = search(q, limit)
    print(json.dumps(res, ensure_ascii=False))
