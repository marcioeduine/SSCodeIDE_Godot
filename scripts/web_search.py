#!/usr/bin/env python3
import urllib.request
import urllib.parse
import re
import html
import json
import sys

def search(query, max_results=5):
    if not query:
        return []

    results = []

    # 1. DuckDuckGo HTML POST
    try:
        data = urllib.parse.urlencode({'q': query}).encode('utf-8')
        req = urllib.request.Request(
            'https://html.duckduckgo.com/html/',
            data=data,
            headers={
                'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/119.0',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
                'Accept-Language': 'pt-PT,pt;q=0.9,en-US;q=0.8,en;q=0.7',
            }
        )
        with urllib.request.urlopen(req, timeout=6) as resp:
            content = resp.read().decode('utf-8', errors='ignore')
            matches = re.findall(r'<a class="result__snippet"[^>]*href="([^"]*)"[^>]*>(.*?)</a>', content, re.DOTALL)
            if not matches:
                # alternative fallback regex for DuckDuckGo
                matches = re.findall(r'<a[^>]+class="[^"]*result__snippet[^"]*"[^>]*href="([^"]*)"[^>]*>(.*?)</a>', content, re.DOTALL)
            for href, snip in matches[:max_results]:
                actual_url = href
                if 'uddg=' in href:
                    m = re.search(r'uddg=([^&]+)', href)
                    if m:
                        actual_url = urllib.parse.unquote(m.group(1))
                clean_text = html.unescape(re.sub(r'<[^>]+>', '', snip)).strip()
                if clean_text:
                    results.append({
                        'title': clean_text[:60] + ('...' if len(clean_text) > 60 else ''),
                        'snippet': clean_text,
                        'url': actual_url
                    })
    except Exception:
        pass

    # 2. Wikipedia API fallback
    if not results:
        try:
            url = 'https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=' + urllib.parse.quote(query) + '&format=json&utf8=1'
            req = urllib.request.Request(url, headers={'User-Agent': 'SSCodeIDE/1.0 (https://sersuperior.com)'})
            with urllib.request.urlopen(req, timeout=5) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                for item in data.get('query', {}).get('search', [])[:max_results]:
                    clean = html.unescape(re.sub(r'<[^>]+>', '', item.get('snippet', '')))
                    results.append({
                        'title': str(item.get('title', '')),
                        'snippet': clean,
                        'url': 'https://en.wikipedia.org/wiki/' + urllib.parse.quote(str(item.get('title', '')).replace(' ', '_'))
                    })
        except Exception:
            pass

    return results

if __name__ == '__main__':
    q = sys.argv[1] if len(sys.argv) > 1 else ''
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    res = search(q, limit)
    print(json.dumps(res))
