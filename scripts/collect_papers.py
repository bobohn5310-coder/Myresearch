#!/usr/bin/env python3
"""Nature, Science 에 새로 실린 연구 논문을 공식 RSS 에서 모아 data/papers.json 으로 저장한다.

웹사이트(index.html)가 이 파일을 바로 읽어 홈 화면에 보여준다. Supabase 설정은 필요 없다.

저작권을 지키기 위해 논문 본문이나 그림은 저장하지 않는다.
제목, 저널 이름, 게재일, RSS 가 공개하는 짧은 소개 문장(최대 200자), 원문 링크만 남긴다.

RSS 에 담긴 논문이 적으면 제목·날짜·링크를 Crossref(논문 DOI 공식 등록 기관) 공개 API 에서 보충한다.

사용법
  python scripts/collect_papers.py --out data/papers.json
"""
from __future__ import annotations

import argparse
import datetime as dt
import email.utils
import hashlib
import html
import json
import re
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

UA = "MyResearchCalendar-PaperCollector/1.0 (+https://bobohn5310-coder.github.io/Myresearch/)"
KST = dt.timezone(dt.timedelta(hours=9))
NOW = dt.datetime.now(KST)
KEEP_DAYS = 45          # 이보다 오래된 논문은 남기지 않는다
MAX_PER_JOURNAL = 30
SUMMARY_LEN = 200

NATURE_RSS = [
    "https://www.nature.com/nature.rss",                    # 최신 게재(뉴스·칼럼 포함)
]
NATURE_ISSN = "0028-0836"

# 정정·철회 공지나 목차 안내는 논문이 아니므로 뺀다
SKIP_TITLES = re.compile(r"^(author correction|publisher correction|correction|erratum|retraction|"
                         r"editorial expression of concern|addendum|in other journals|in science journals|"
                         r"this week in science|editors'? choice)\b", re.I)
SCIENCE_RSS = [
    "https://www.science.org/action/showFeed?type=etoc&feed=rss&jc=science",   # 최신호 목차
    "https://www.science.org/action/showFeed?type=axatoc&feed=rss&jc=science",  # 온라인 선공개
]
SCIENCE_ISSN = "0036-8075"

# Science 목차에는 뉴스·사설·서평도 섞여 있다. 섹션 정보가 있으면 연구 논문만 남긴다.
SCIENCE_RESEARCH_SECTIONS = ("research article", "report", "review", "research")
SCIENCE_SKIP_SECTIONS = ("news", "editorial", "letter", "book", "perspective", "policy forum",
                         "in brief", "feature", "working life", "erratum", "correction", "this week",
                         "in other journals", "insights", "expression of concern", "retraction")

# 분야 분류: 영어 제목·요약에서 단어를 찾는다. 먼저 맞는 규칙이 이긴다. (field, 한글 태그, 단어들)
FIELD_RULES = [
    ("space", "우주", ("galaxy", "galaxies", "black hole", "cosmic", "universe", "supernova", "telescope",
                      "exoplanet", "asteroid", "solar system", "lunar", "mars", "martian", "meteorite",
                      "redshift", "big bang", "radio burst", "stellar", "planet")),
    ("quantum", "양자/물리", ("quantum", "qubit", "superconduct", "photon", "topological", "entangle",
                            "magnet", "altermagn", "magnon", "laser", "optic", "particle", "neutrino",
                            "boson", "spin ", "spins ", "moiré", "moire", "kondo", "chern", "ferroelectric",
                            "antiferroelectric", "electron", "phonon", "graphene")),
    ("cs", "AI/컴퓨터", ("machine learning", "deep learning", "neural network", "artificial intelligence",
                        "language model", " ai ", "algorithm", "robot", "comput")),
    ("energy", "에너지", ("battery", "batteries", "solar", "perovskite", "photovoltaic", "hydrogen",
                         "fuel cell", "electrolyte", "lithium", "fusion", "energy")),
    ("bio", "생명/의학", ("cell", "gene ", "genes ", "genetic", "genom", "protein", "cancer", "tumour", "tumor", "immun", "virus",
                         "bacteri", "neuron", "brain", "mouse", "mice", "patient", "disease", "clinical",
                         "dna", "rna", "enzyme", "microb", "evolution", "species", "plant", "drug",
                         "vaccine", "infection", "metabol", "tissue", "mitochond", "antibod", "bird",
                         "avian", "avifauna", "animal", "milk", "infant", "birth", "cerebell", "ribosom",
                         "fish", "insect", "drosophila", "courtship", "behavio", "biopolymer", "bird", "organ", "embryo", "zygote", "human", "neural", "song")),
    ("earth", "지구/환경", ("climate", "ocean", "warming", "carbon dioxide", "carbon cycle", "co2 ", "earthquake", "glacier", "ice sheet",
                          "atmospher", "drought", "forest", "biodiversity", "emission", "volcan",
                          "subduction", "rift", "crust", "mantle", "glacial", "erosion", "freshwater",
                          "sediment", "earth")),
    ("eng", "소재/화학", ("material", "catalys", "polymer", "crystal", "semiconductor", "transistor",
                         "chemi", "molecul", "nano", "alloy", "synthes", "radical", "depolymer",
                         "silicone", "chlorin", "telomeriz", "amine", "diene", "stereo", "mxene",
                         "bond", "metal", "oxide", "hafnia", "reaction")),
]


def clean(text, limit=300):
    """외부 텍스트를 화면에 그대로 넣어도 안전하도록 태그와 꺾쇠를 없앤다."""
    if text is None:
        return ""
    s = html.unescape(html.unescape(str(text)))
    s = re.sub(r"<[^>]*>", " ", s)
    s = s.replace("<", "").replace(">", "").replace('"', "'")
    s = re.sub(r"\s+", " ", s).strip()
    if len(s) > limit:
        cut = s[:limit]
        # 단어 중간에서 자르지 않는다
        if " " in cut[limit - 30:]:
            cut = cut[:cut.rfind(" ")]
        s = cut.rstrip(" ,;:") + "…"
    return s


def safe_url(url):
    url = re.sub(r"[\"'<>\s`]", "", (url or "").strip())
    return url if re.match(r"^https?://", url, re.I) else ""


def http_get(url, timeout=30, accept="application/rss+xml, application/xml, text/xml, */*"):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": accept})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def parse_date(text):
    if not text:
        return None
    s = text.strip()
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})", s)
    if m:
        try:
            return dt.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
        except ValueError:
            return None
    try:
        return email.utils.parsedate_to_datetime(s).date()
    except (TypeError, ValueError, IndexError):
        return None


def local(tag):
    return tag.rsplit("}", 1)[-1]


def children(el):
    """item 아래 요소를 {이름: [값들]} 로 모은다. (네임스페이스는 무시)"""
    out = {}
    for c in el:
        name = local(c.tag)
        val = c.get("href") if name == "link" and c.get("href") else (c.text or "")
        out.setdefault(name, []).append(val.strip())
    return out


def first(d, *names):
    for n in names:
        for v in d.get(n, []):
            if v:
                return v
    return ""


CHANNEL_INFO = {}
# 저널별 '이번 호' 정보. 표지 그림은 학술지가 공개한 주소만 적어 두고(링크), 파일을 복사하지 않는다.
ISSUE = {
    "Nature": {"url": "https://www.nature.com/nature/current-issue"},
    "Science": {"url": "https://www.science.org/toc/science/current"},
}   # 피드 주소 -> 채널 정보 (표지 그림 주소 등)


def parse_feed(raw, url=""):
    root = ET.fromstring(raw)
    # 채널(피드 전체) 정보: 표지로 쓸 그림 주소가 들어 있는 경우가 있다
    info = {}
    for ch in root.iter():
        if local(ch.tag) in ("channel", "feed"):
            for c in ch:
                n = local(c.tag)
                if n in ("item", "entry"):
                    continue
                if n == "image":
                    for g in c:
                        if local(g.tag) == "url" and g.text:
                            info["image"] = g.text.strip()
                elif c.text and c.text.strip():
                    info.setdefault(n, c.text.strip())
            break
    for e in root.iter():
        if local(e.tag) == "image" and e.get("{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about"):
            info.setdefault("image", e.get("{http://www.w3.org/1999/02/22-rdf-syntax-ns#}about"))
    CHANNEL_INFO[url] = info
    print(f"  채널 정보 {url}: {json.dumps(info, ensure_ascii=False)[:400]}", file=sys.stderr)
    return [children(e) for e in root.iter() if local(e.tag) in ("item", "entry")]


def head_ok(url):
    try:
        req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=20) as r:
            return r.status == 200 and (r.headers.get("Content-Type") or "").startswith("image/")
    except Exception as e:
        print(f"[표지] {url} 확인 실패: {e}", file=sys.stderr)
        return False


def nature_issue():
    """Nature 최신호의 권·호를 Crossref 에서 알아내고, Springer Nature 그림 서버의 표지 주소를 찾는다.
    (nature.com 은 자동 접속을 막는다) 그림 파일은 저장하지 않고 주소만 남긴다."""
    info = ISSUE["Nature"]
    today = NOW.date().isoformat()
    url = (f"https://api.crossref.org/journals/{NATURE_ISSN}/works?" + urllib.parse.urlencode({
        "filter": f"type:journal-article,until-print-pub-date:{today},"
                  f"from-print-pub-date:{(NOW - dt.timedelta(days=21)).date().isoformat()}",
        "sort": "published-print", "order": "desc", "rows": 40,
        "select": "volume,issue,published-print",
    }))
    best = None
    try:
        for w in json.loads(http_get(url, timeout=60, accept="application/json"))["message"]["items"]:
            v, n = w.get("volume"), w.get("issue")
            parts = (w.get("published-print") or {}).get("date-parts", [[None]])[0]
            if v and n and str(v).isdigit() and str(n).isdigit() and parts and len(parts) == 3:
                key = (int(v), int(n))
                if not best or key > best[0]:
                    best = (key, dt.date(*parts).isoformat())
    except Exception as e:
        print(f"[Nature 이번 호] Crossref 실패: {e}", file=sys.stderr)
    if not best:
        return
    (v, n), d = best
    info.update(volume=str(v), issue=str(n), date=d,
                url=f"https://www.nature.com/nature/volumes/{v}/issues/{n}")
    for size in ("w440", "full"):
        c = f"https://media.springernature.com/{size}/springer-static/cover-hires/journal/41586/{v}/{n}"
        if head_ok(c):
            info["cover"] = c
            break
    print(f"[Nature 이번 호] {json.dumps(info, ensure_ascii=False)}", file=sys.stderr)


def classify(text):
    # 단어 앞부분 일치로 찾는다 (예: 'fusion' 이 'diffusion' 에 걸리지 않게).
    # 끝에 공백이 있는 단어('ai ')는 낱말 전체가 같아야 한다.
    t = " " + re.sub(r"[^0-9a-zà-ÿ]+", " ", text.lower()) + " "
    for field, tag, words in FIELD_RULES:
        if any(" " + w.lstrip() in t for w in words):
            return field, tag
    return "etc", "기초과학"


def strip_citation(s):
    """RSS 요약 칸에 들어 있는 서지 정보(권·호·쪽, DOI)를 지우고 소개 문장만 남긴다."""
    s = clean(s, 2000)
    # Nature: "Nature, Published online: 03 November 2026; doi:10.1038/s41586-... 소개문"
    s = re.sub(r"^\s*Nature,\s*Published online:[^;]*;\s*doi:\s*\S+", "", s, flags=re.I)
    # Science: "Science, Volume 394, Issue 6823, Page 556-561, October 2026." / "Science, Ahead of Print."
    s = re.sub(r"^\s*Science,\s*(Ahead of Print\.?|Volume[^.]*\.)", "", s, flags=re.I)
    return s.strip()


def make_row(journal, title, link, summary, when, doi=""):
    title = clean(title, 250)
    link = safe_url(link)
    if not title or not link or not when or SKIP_TITLES.match(title):
        return None
    summary = clean(strip_citation(summary), SUMMARY_LEN)
    if summary and re.sub(r"\W", "", summary.lower()).startswith(re.sub(r"\W", "", title.lower())[:40]):
        summary = ""  # 요약이 제목 반복이면 버린다
    # 제목으로 먼저 분류하고, 모르겠으면 요약까지 본다
    field, tag = classify(title)
    if field == "etc" and summary:
        field, tag = classify(summary)
    key = (doi or link).lower()
    return {
        "journal": journal,
        "field": field,
        "tag": tag,
        "title": title,
        "summary": summary,
        "url": link,
        "doi": doi,
        "date": when.isoformat(),
        "external_id": "paper:" + hashlib.sha1(key.encode("utf-8")).hexdigest()[:20],
    }


def collect_nature():
    rows = []
    for url in NATURE_RSS:
        try:
            items = parse_feed(http_get(url), url)
        except Exception as e:
            print(f"[Nature RSS] 실패: {e}", file=sys.stderr)
            continue
        kept = 0
        for it in items:
            link = first(it, "link", "url", "identifier")
            # 연구 논문은 주소가 /articles/s41586- 로 시작한다. (d41586- 는 뉴스·칼럼)
            m = re.search(r"/articles/(s41586-[\w.-]+)", link)
            if not m:
                continue
            doi = "10.1038/" + m.group(1)
            row = make_row("Nature", first(it, "title"), "https://www.nature.com/articles/" + m.group(1),
                           first(it, "encoded", "description", "summary"),
                           parse_date(first(it, "date", "pubDate", "published", "updated")), doi)
            if row:
                rows.append(row)
                kept += 1
        print(f"[Nature RSS] {len(items)}건 중 연구 논문 {kept}건", file=sys.stderr)
        time.sleep(1)
    return rows


def crossref_recent(issn, journal, link_of, doi_ok):
    """RSS 로 충분히 모이지 않을 때 Crossref(논문 DOI 공식 등록 기관)에서 최근 논문 정보를 가져온다.
    제목·날짜·링크만 쓰고, 초록은 저장하지 않는다."""
    since = (NOW - dt.timedelta(days=KEEP_DAYS)).date().isoformat()
    url = (f"https://api.crossref.org/journals/{issn}/works?" + urllib.parse.urlencode({
        "filter": f"type:journal-article,from-online-pub-date:{since}",
        "sort": "published", "order": "desc", "rows": 150,
        "select": "DOI,title,published-online,published",
    }))
    try:
        data = json.loads(http_get(url, timeout=60, accept="application/json"))
    except Exception as e:
        print(f"[{journal} Crossref] 실패: {e}", file=sys.stderr)
        return []
    rows = []
    for w in data.get("message", {}).get("items", []):
        doi = (w.get("DOI") or "").lower()
        if not doi_ok(doi):
            continue
        parts = None
        for k in ("published-online", "published"):
            parts = (w.get(k) or {}).get("date-parts", [[None]])[0]
            if parts and len(parts) == 3:
                break
        if not parts or len(parts) != 3:
            continue
        row = make_row(journal, " ".join(w.get("title") or []), link_of(doi), "", dt.date(*parts), doi)
        if row:
            rows.append(row)
    print(f"[{journal} Crossref] 연구 논문 {len(rows)}건", file=sys.stderr)
    return rows


def science_is_research(it):
    sec = " ".join(it.get("type", []) + it.get("section", []) + it.get("category", [])).lower()
    if not sec:
        return True  # 섹션 정보가 없으면 일단 남긴다
    if any(s in sec for s in SCIENCE_SKIP_SECTIONS):
        return False
    return any(s in sec for s in SCIENCE_RESEARCH_SECTIONS)


def collect_science_rss():
    rows = []
    for url in SCIENCE_RSS:
        try:
            items = parse_feed(http_get(url), url)
        except Exception as e:
            print(f"[Science RSS] 실패: {e}", file=sys.stderr)
            continue
        kept = 0
        for it in items:
            link = first(it, "link", "identifier")
            m = re.search(r"(10\.1126/science\.[\w.]+)", link + " " + first(it, "doi", "identifier"))
            if not m or not science_is_research(it):
                continue
            doi = m.group(1)
            if "type=etoc" in url:
                cm = re.search(r"Volume\s+(\d+),\s*Issue\s+(\d+)", first(it, "description", "encoded"))
                if cm:
                    ISSUE["Science"].update(volume=cm.group(1), issue=cm.group(2))
                    d = parse_date(first(it, "date", "pubDate"))
                    if d and d.isoformat() > ISSUE["Science"].get("date", ""):
                        ISSUE["Science"]["date"] = d.isoformat()
            row = make_row("Science", first(it, "title"), "https://www.science.org/doi/" + doi,
                           first(it, "description", "encoded", "summary"),
                           parse_date(first(it, "date", "pubDate", "published", "updated", "coverDate")), doi)
            if row:
                rows.append(row)
                kept += 1
        print(f"[Science RSS] {len(items)}건 중 연구 논문 {kept}건", file=sys.stderr)
        time.sleep(1)
    return rows


def page_image(url):
    """논문 페이지가 링크 미리보기용으로 공개한 대표 그림(og:image) 주소를 읽는다.
    그림 파일은 받거나 저장하지 않고 주소만 남긴다 (메신저 링크 미리보기와 같은 방식)."""
    try:
        page = http_get(url, accept="text/html").decode("utf-8", "replace")[:200000]
    except Exception as e:
        print(f"[대표 그림] {url} 실패: {e}", file=sys.stderr)
        return ""
    m = (re.search(r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]*content=["\']([^"\']+)', page)
         or re.search(r'<meta[^>]+content=["\']([^"\']+)["\'][^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\']', page))
    img = safe_url(html.unescape(m.group(1))) if m else ""
    if not getattr(page_image, "logged", False):
        page_image.logged = True
        t = re.search(r"<title>(.*?)</title>", page, re.S)
        print(f"[대표 그림 점검] {url} 길이 {len(page)} 제목 {t.group(1).strip()[:80] if t else '-'}", file=sys.stderr)
        for mm in re.findall(r"<meta[^>]+(?:og:image|twitter:image)[^>]*>", page)[:4]:
            print("   ", mm[:220], file=sys.stderr)
        print("    그림 후보:", re.findall(r"media\.springernature\.com/[^\s\"'<>]+", page)[:3], file=sys.stderr)
    # 학술지 로고 같은 기본 그림은 대표 그림이 아니므로 버린다
    if img and re.search(r"logo|default|placeholder|/static/images/", img, re.I):
        img = ""
    return img


def nature_figure(doi):
    """Nature 논문 페이지는 자동 접속을 막지만, 미리보기 그림(첫 번째 그림)은 정해진 주소 규칙으로
    Springer Nature 그림 서버에 있다. 예) 10.1038/s41586-026-11200-4 →
    https://media.springernature.com/lw685/springer-static/image/art%3A10.1038%2Fs41586-026-11200-4/MediaObjects/41586_2026_11200_Fig1_HTML.png
    그 주소가 실제로 있는지만 확인하고(그림은 저장하지 않음) 주소를 남긴다."""
    m = re.match(r"10\.1038/s41586-0?(\d{2,4})-(\d+)-\w$", doi or "")
    if not m:
        return ""
    year = m.group(1) if len(m.group(1)) == 4 else "20" + m.group(1)[-2:]
    art = urllib.parse.quote(doi, safe="")
    for ext in ("png", "jpg"):
        url = (f"https://media.springernature.com/lw685/springer-static/image/art%3A{art}/MediaObjects/"
               f"41586_{year}_{m.group(2)}_Fig1_HTML.{ext}")
        try:
            req = urllib.request.Request(url, method="HEAD", headers={"User-Agent": UA})
            with urllib.request.urlopen(req, timeout=20) as r:
                if r.status == 200 and (r.headers.get("Content-Type") or "").startswith("image/"):
                    return url
        except Exception as e:
            if not getattr(nature_figure, "logged", False):
                nature_figure.logged = True
                print(f"[대표 그림] {url} 확인 실패: {e}", file=sys.stderr)
    return ""


def add_images(rows):
    found = 0
    for r in rows:
        r["image"] = nature_figure(r.get("doi")) or page_image(r["url"])
        found += bool(r["image"])
        time.sleep(0.5)
    print(f"[대표 그림] {len(rows)}편 중 {found}편", file=sys.stderr)
    if rows:
        print("  예:", rows[0]["url"], "->", rows[0]["image"], file=sys.stderr)


def finish(rows):
    cutoff = (NOW - dt.timedelta(days=KEEP_DAYS)).date().isoformat()
    future = (NOW + dt.timedelta(days=2)).date().isoformat()
    seen, out = set(), []
    for r in sorted(rows, key=lambda r: r["date"], reverse=True):
        if not (cutoff <= r["date"] <= future) or r["external_id"] in seen:
            continue
        seen.add(r["external_id"])
        out.append(r)
    return out[:MAX_PER_JOURNAL]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/papers.json")
    ap.add_argument("--min", type=int, default=3, help="이보다 적게 모이면 파일을 바꾸지 않고 실패")
    args = ap.parse_args()

    nature = collect_nature()
    if len(nature) < 12:
        # Nature RSS 는 최근 며칠 치만 담고 있어, 모자라면 Crossref 로 채운다 (s41586 = 연구 논문)
        nature += crossref_recent(NATURE_ISSN, "Nature", lambda d: "https://www.nature.com/articles/" + d.split("/", 1)[1],
                                  lambda d: d.startswith("10.1038/s41586-"))
    nature = finish(nature)
    add_images(nature)  # Science 는 자동 접속을 막아 Nature 만
    science = collect_science_rss()
    if len(science) < 5:
        science += crossref_recent(SCIENCE_ISSN, "Science", lambda d: "https://www.science.org/doi/" + d,
                                   lambda d: d.startswith("10.1126/science."))
    science = finish(science)

    # 이번 호 정보와 표지 그림 주소. Science 는 표지 그림 자동 수집을 막고 있어 권·호만 쓴다.
    # (표지 그림이 없으면 화면에서 직접 그린 표지를 쓴다)
    nature_issue()
    print("이번 호 정보", json.dumps(ISSUE, ensure_ascii=False), file=sys.stderr)

    rows = sorted(nature + science, key=lambda r: r["date"], reverse=True)
    print(f"총 {len(rows)}건 (Nature {len(nature)}, Science {len(science)})", file=sys.stderr)
    if len(rows) < args.min:
        print("모인 논문이 너무 적어 기존 파일을 그대로 둡니다.", file=sys.stderr)
        sys.exit(1)
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump({"updated": NOW.isoformat(timespec="minutes"), "issues": ISSUE, "papers": rows},
                  f, ensure_ascii=False, indent=1)
        f.write("\n")


if __name__ == "__main__":
    main()
