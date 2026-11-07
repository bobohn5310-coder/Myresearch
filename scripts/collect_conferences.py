#!/usr/bin/env python3
"""국내외 학회 정보를 공개 소스에서 모아 Supabase academic_info 테이블에 넣는다.

소스
  1. ccfddl/ccf-deadlines (GitHub 공개 YAML) : 컴퓨터·AI 분야 국제 학회의 일정·장소·투고 마감
  2. WikiCFP RSS (분야별 카테고리)          : 생명/의학, 공학, 에너지, 양자 등 다른 분야의 CFP

사용법
  python scripts/collect_conferences.py --dry-run --out conferences.json   # DB에 쓰지 않고 결과만 저장
  SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... python scripts/collect_conferences.py

동작
  - 끝난 지 오래되지 않은(종료일이 오늘 이후) 학회만 모은다.
  - external_id 가 같은 행은 갱신(upsert)하고, 새 행은 추가한다.
  - 자동 수집한 행(source 가 있는 행) 중 종료 후 30일이 지난 행은 지운다.
    관리자가 직접 등록한 행(source 가 비어 있음)은 건드리지 않는다.
"""
from __future__ import annotations

import argparse
import collections
import datetime as dt
import glob
import html
import json
import os
import re
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

import yaml

UA = "MyResearchCalendar-ConferenceCollector/1.0 (+https://myresearchcal.com/)"
TODAY = dt.date.today()

# ccfddl 분류(sub) → 우리 서비스 분야(field) 와 태그
CCF_SUB_TAGS = {
    "AI": "인공지능", "CG": "그래픽스·멀티미디어", "CT": "이론", "DB": "데이터베이스·데이터마이닝",
    "DS": "컴퓨터구조·시스템", "HI": "HCI", "MX": "융합", "NW": "네트워크", "SC": "보안", "SE": "소프트웨어공학",
}

# WikiCFP 카테고리 → (field, 한국어 태그)
WIKICFP_CATEGORIES = [
    ("semiconductor", "eng", "반도체"),
    ("vlsi", "eng", "반도체"),
    ("battery", "energy", "이차전지"),
    ("energy storage", "energy", "이차전지"),
    ("display", "eng", "디스플레이"),
    ("robotics", "eng", "로봇"),
    ("medicine", "bio", "의학"),
    ("medical imaging", "bio", "의학"),
    ("healthcare", "bio", "의학"),
    ("bioinformatics", "bio", "생물정보학"),
    ("biology", "bio", "생명과학"),
    ("engineering", "eng", "공학"),
    ("materials science", "eng", "재료"),
    ("materials", "eng", "재료"),
    ("polymer", "eng", "고분자"),
    ("chemistry", "eng", "화학"),
    ("organic chemistry", "eng", "유기화학"),
    ("chemical engineering", "eng", "화학공학"),
    ("graphene", "eng", "그래핀"),
    ("nanotechnology", "eng", "나노"),
    ("nanomaterials", "eng", "나노"),
    ("metamaterials", "eng", "메타물질"),
    ("photonics", "eng", "광학"),
    ("automation", "eng", "로봇"),
    ("electrical engineering", "eng", "전기전자"),
    ("mechanical engineering", "eng", "기계"),
    ("energy", "energy", "에너지"),
    ("renewable energy", "energy", "신재생에너지"),
    ("quantum computing", "quantum", "양자컴퓨팅"),
    ("communications", "quantum", "통신"),
]

KOREA_WORDS = ("korea", "seoul", "busan", "daejeon", "incheon", "jeju", "daegu", "gwangju",
               "suwon", "pohang", "ulsan", "gyeongju", "songdo", "한국", "서울", "부산", "대전", "제주")

MONTHS = {m.lower(): i for i, m in enumerate(
    ["January", "February", "March", "April", "May", "June", "July",
     "August", "September", "October", "November", "December"], 1)}
MONTHS.update({k[:3]: v for k, v in list(MONTHS.items())})
MONTHS["sept"] = 9


# ─────────────────────────── 공통 유틸 ───────────────────────────
def clean(text, limit=300):
    """외부 텍스트를 화면에 그대로 넣어도 안전하도록 태그와 꺾쇠를 없앤다."""
    if text is None:
        return ""
    s = html.unescape(str(text))
    s = re.sub(r"<[^>]*>", " ", s)
    s = s.replace("<", "").replace(">", "").replace('"', "'")
    s = re.sub(r"\s+", " ", s).strip()
    return s[:limit]


def safe_url(url):
    url = re.sub(r"[\"'<>\s`]", "", (url or "").strip())
    return url if re.match(r"^https?://", url, re.I) else ""


def is_korea(place):
    p = (place or "").lower()
    return any(w in p for w in KOREA_WORDS)


def month_num(name):
    return MONTHS.get(name.lower().rstrip("."))


def parse_date_range(text):
    """'February 4-7, 2021', 'Jun 30 - Jul 4, 2027', 'Nov 07-09, 2026', 'May 3, 2027' 같은 문자열을 해석."""
    if not text:
        return None, None
    s = re.sub(r"\([^)]*\)", "", str(text))  # 괄호 안 도시 설명 제거
    s = s.replace("–", "-").replace("—", "-")
    years = re.findall(r"(19|20)\d\d", s)
    year_m = re.search(r"((?:19|20)\d\d)\s*$", s.strip())
    if not years or not year_m:
        return None, None
    year = int(year_m.group(1))
    halves = [h.strip() for h in s.split("-") if h.strip()]
    if len(halves) == 2 and all(re.search(r"(?:19|20)\d\d", h) for h in halves):
        # 'December 28, 2026 - January 2, 2027' 처럼 양쪽에 연도가 있는 경우
        a, _ = parse_date_range(halves[0])
        b, _ = parse_date_range(halves[1])
        return (a, b) if a and b else (None, None)
    # Month D1 - Month D2, YYYY
    m = re.search(r"([A-Za-z]{3,9})\.?\s+(\d{1,2})\s*-\s*([A-Za-z]{3,9})\.?\s+(\d{1,2})", s)
    try:
        if m and month_num(m.group(1)) and month_num(m.group(3)):
            m1, d1, m2, d2 = month_num(m.group(1)), int(m.group(2)), month_num(m.group(3)), int(m.group(4))
            start = dt.date(year - (1 if m2 < m1 else 0), m1, d1)
            return start, dt.date(year, m2, d2)
        m = re.search(r"([A-Za-z]{3,9})\.?\s+(\d{1,2})\s*-\s*(\d{1,2})", s)
        if m and month_num(m.group(1)):
            mo = month_num(m.group(1))
            return dt.date(year, mo, int(m.group(2))), dt.date(year, mo, int(m.group(3)))
        m = re.search(r"([A-Za-z]{3,9})\.?\s+(\d{1,2})\b", s)
        if m and month_num(m.group(1)):
            d = dt.date(year, month_num(m.group(1)), int(m.group(2)))
            return d, d
    except ValueError:
        return None, None
    return None, None


def parse_one_date(text):
    """'2026-09-09 23:59:59' 또는 'Sep 9, 2026' → date"""
    if not text:
        return None
    s = str(text).strip()
    m = re.match(r"(\d{4})-(\d{1,2})-(\d{1,2})", s)
    if m:
        try:
            return dt.date(int(m.group(1)), int(m.group(2)), int(m.group(3)))
        except ValueError:
            return None
    start, _ = parse_date_range(s)
    return start


def http_get(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


# ─────────────────────────── 소스 1: ccfddl ───────────────────────────
def collect_ccfddl(repo_dir=None):
    tmp = None
    if not repo_dir:
        tmp = tempfile.mkdtemp(prefix="ccfddl-")
        repo_dir = os.path.join(tmp, "ccf-deadlines")
        subprocess.run(["git", "clone", "-q", "--depth", "1",
                        "https://github.com/ccfddl/ccf-deadlines.git", repo_dir], check=True)
    rows = []
    for path in sorted(glob.glob(os.path.join(repo_dir, "conference", "*", "*.yml"))):
        try:
            docs = yaml.safe_load(open(path, encoding="utf-8")) or []
        except yaml.YAMLError as e:
            print(f"[ccfddl] YAML 오류 {path}: {e}", file=sys.stderr)
            continue
        for conf in docs:
            if not isinstance(conf, dict):
                continue
            sub = conf.get("sub", "")
            rank = conf.get("rank") or {}
            for ed in conf.get("confs") or []:
                start, end = parse_date_range(ed.get("date"))
                if not start or end < TODAY:
                    continue
                place = clean(ed.get("place"), 120)
                timeline = sorted(((parse_one_date(t.get("deadline")), parse_one_date(t.get("abstract_deadline")))
                                   for t in (ed.get("timeline") or []) if isinstance(t, dict)),
                                  key=lambda x: x[0] or dt.date.max)
                past = [(d, a) for d, a in timeline if d and d < TODAY]
                # 아직 남은 마감이 없으면 가장 최근에 지난 마감을 보여 준다 (화면에 '마감됨'으로 표시)
                next_dl, next_abs = next(((d, a) for d, a in timeline if d and d >= TODAY),
                                         past[-1] if past else (None, None))
                tags = ["해외" if not is_korea(place) else "국내개최", CCF_SUB_TAGS.get(sub, "컴퓨터")]
                if rank.get("ccf") and rank["ccf"] != "N":
                    tags.append(f"CCF-{rank['ccf']}")
                if rank.get("core") and rank["core"] != "N":
                    tags.append(f"CORE-{rank['core']}")
                content = clean(conf.get("description"), 300)
                if next_dl and next_dl >= TODAY:
                    content += f" · 투고 마감 {next_dl.isoformat()}"
                rows.append({
                    "type": "conf",
                    "field": "cs",
                    "title": clean(f"{conf.get('title', '')} {ed.get('year', '')}", 200),
                    "org": clean(conf.get("description"), 200),
                    "start_date": start.isoformat(),
                    "end_date": end.isoformat(),
                    "date": next_dl.isoformat() if next_dl else None,
                    "abstract_deadline": next_abs.isoformat() if next_abs else None,
                    "registration_deadline": None,
                    "content": content,
                    "url": safe_url(ed.get("link")),
                    "tags": ",".join(tags),
                    "location": place,
                    "source": "ccfddl",
                    "external_id": f"ccfddl:{ed.get('id') or (str(conf.get('dblp')) + str(ed.get('year')))}",
                })
    if tmp:
        subprocess.run(["rm", "-rf", tmp])
    print(f"[ccfddl] {len(rows)}건")
    return rows


# ─────────────────────────── 소스 2: WikiCFP RSS ───────────────────────────
WIKICFP_DESC_RE = re.compile(r"^(.*?)\s*\[([^\]]*)\]\s*\[([^\]]*)\]\s*$", re.S)


def parse_wikicfp_item(item, field, tag):
    """WikiCFP RSS 항목. description 형식: '정식 명칭 [장소] [Jun 1, 2027 - Jun 3, 2027]'"""
    title_raw = clean(item.findtext("title"), 300)
    desc = clean(item.findtext("description"), 1000)
    link = safe_url(item.findtext("link"))
    m = WIKICFP_DESC_RE.match(desc)
    if not m:
        return None
    fullname, where, when = m.group(1).strip(), m.group(2).strip(), m.group(3).strip()
    if where.upper() == "N/A":
        where = ""
    parts = [p.strip() for p in when.split(" - ")]
    start = parse_one_date(parts[0]) if parts else None
    end = parse_one_date(parts[-1]) if parts else None
    if not start or not end or end < TODAY:
        return None
    acronym = title_raw.partition(" : ")[0].strip()
    fullname = fullname or title_raw.partition(" : ")[2]
    m = re.search(r"eventid=(\d+)", link)
    ext = f"wikicfp:{m.group(1)}" if m else f"wikicfp:{acronym}:{start.isoformat()}"
    return {
        "type": "conf",
        "field": field,
        "title": clean(acronym or title_raw, 200),
        "org": clean(fullname, 200),
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
        "date": None,   # RSS에는 투고 마감이 없다
        "content": clean(fullname, 300),
        "url": link,
        "tags": ",".join(["국내개최" if is_korea(where) else "해외", tag]),
        "location": clean(where, 120),
        "source": "wikicfp",
        "external_id": ext,
    }


def collect_wikicfp(categories=WIKICFP_CATEGORIES, delay=3.0):
    rows = []
    fails = 0
    for cat, field, tag in categories:
        if fails >= 3 and not rows:
            # 처음부터 연달아 응답이 없으면 서버가 멈춘 것으로 보고 나머지는 건너뛴다
            print("[wikicfp] 서버가 응답하지 않아 오늘은 건너뜁니다", file=sys.stderr)
            break
        url = "http://www.wikicfp.com/cfp/rss?cat=" + urllib.parse.quote(cat)
        try:
            root = ET.fromstring(http_get(url, timeout=15))
        except Exception as e:  # 네트워크·파싱 오류는 그 카테고리만 건너뛴다
            print(f"[wikicfp] {cat} 실패: {e}", file=sys.stderr)
            fails += 1
            continue
        n = 0
        items = list(root.iter("item"))
        for item in items:
            row = parse_wikicfp_item(item, field, tag)
            if row:
                rows.append(row)
                n += 1
        print(f"[wikicfp] {cat}: {n}건 (피드 항목 {len(items)}개)")
        if items and not n:
            # 형식이 예상과 다를 때 원인을 찾을 수 있게 첫 항목을 남긴다
            print("[wikicfp] 첫 항목 예시:", repr(ET.tostring(items[0], encoding="unicode")[:800]))
        time.sleep(delay)  # WikiCFP 서버 부담을 줄이려 요청 간격을 둔다
    return rows


WIKICFP_LINK_RE = re.compile(r'Link:\s*(?:</[^>]+>\s*)*<a[^>]+href="([^"]+)"', re.I)


def previous_rows(path, source):
    """지난번 수집 결과에서 아직 끝나지 않은 학회만 다시 쓴다 (소스 서버가 잠깐 멈췄을 때 대비)."""
    if not path or not os.path.exists(path):
        return []
    try:
        old = json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError):
        return []
    today = TODAY.isoformat()
    return [r for r in old if r.get("source") == source and (r.get("end_date") or "") >= today]


WIKICFP_DEADLINE_FIELDS = {
    "abstract_deadline": r"Abstract (?:Registration )?Due|Abstract Deadline|Abstract Submission",
    "date": r"Submission Deadline|Paper Submission",
    "registration_deadline": r"Registration Due|Registration Deadline",
}
WIKICFP_KEEP = ("url", "date", "abstract_deadline", "registration_deadline")


def wikicfp_deadline(page, label_re):
    m = re.search(r"<th[^>]*>\s*(?:" + label_re + r")\s*</th>\s*<td[^>]*>(.*?)</td>", page, re.S | re.I)
    return parse_one_date(clean(m.group(1), 60)) if m else None


def resolve_official_links(rows, cache_path=None, delay=1.5, limit=400):
    """WikiCFP 상세 페이지에서 학회 공식 홈페이지 주소와 마감일(초록·논문·등록)을 읽는다.
    WikiCFP 링크는 쓰지 않는다. 지난번 결과(data/conferences.json)에서 이미 읽은 학회는 다시 받지 않는다."""
    cache = {}
    if cache_path and os.path.exists(cache_path):
        try:
            for r in json.load(open(cache_path, encoding="utf-8")):
                if r.get("source") == "wikicfp" and r.get("wikicfp_checked"):
                    cache[r.get("external_id")] = r
        except (OSError, ValueError):
            pass
    fetched = found = dl_found = fails = 0
    for r in rows:
        if r.get("source") != "wikicfp":
            continue
        cfp_url = r.get("url") or ""
        old = cache.get(r["external_id"])
        if old:
            for k in WIKICFP_KEEP:
                r[k] = old.get(k)
            r["wikicfp_checked"] = True
            continue
        if "wikicfp.com" in cfp_url:
            r["url"] = ""
        if "wikicfp.com" not in cfp_url or fetched >= limit or fails >= 3:
            continue
        fetched += 1
        try:
            page = http_get(cfp_url, timeout=15).decode("utf-8", "replace")
        except Exception as e:
            print(f"[wikicfp-link] {cfp_url} 실패: {e}", file=sys.stderr)
            fails += 1  # WikiCFP가 응답하지 않으면 몇 번 뒤에 그만둔다 (다음 날 다시 시도)
            time.sleep(delay)
            continue
        fails = 0
        r["wikicfp_checked"] = True
        m = WIKICFP_LINK_RE.search(page)
        u = safe_url(html.unescape(m.group(1))) if m else ""
        if u and "wikicfp.com" not in u:
            r["url"] = u
            found += 1
        any_dl = False
        for k, label in WIKICFP_DEADLINE_FIELDS.items():
            d = wikicfp_deadline(page, label)
            if d:
                r[k] = d.isoformat()
                any_dl = True
        dl_found += any_dl
        if fetched <= 2 and not (u and any_dl):
            i = page.find("Submission Deadline")
            print("[wikicfp-link] 예시:", repr(page[max(0, i - 600): i + 300] if i >= 0 else page[:600]))
        time.sleep(delay)
    print(f"[wikicfp-link] 캐시 {len(cache)}건, 새로 조회 {fetched}건, 공식 주소 {found}건, 마감일 {dl_found}건")
    return rows


# ─────────────────────────── 소스 3: 직접 확인한 주요 학회 목록 ───────────────────────────
CURATED_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "data", "conferences-curated.json")


def collect_curated(path=CURATED_PATH):
    """공식 페이지에서 날짜를 확인해 손으로 적어 둔 학회 (data/conferences-curated.json)."""
    try:
        items = json.load(open(path, encoding="utf-8"))
    except (OSError, ValueError) as e:
        print(f"[curated] 읽기 실패: {e}", file=sys.stderr)
        return []
    rows = []
    for it in items:
        start, end = parse_one_date(it.get("start_date")), parse_one_date(it.get("end_date"))
        if not start or not end or end < TODAY:
            continue
        rows.append({
            "type": "conf", "field": it.get("field", "all"),
            "title": clean(it["title"], 200), "org": clean(it.get("org"), 200),
            "start_date": start.isoformat(), "end_date": end.isoformat(),
            "date": it.get("deadline"), "abstract_deadline": it.get("abstract_deadline"),
            "registration_deadline": it.get("registration_deadline"),
            "content": clean(it.get("org"), 300),
            "url": safe_url(it.get("url")), "tags": clean(it.get("tags"), 200),
            "location": clean(it.get("location"), 120),
            "source": "curated", "external_id": f"curated:{it['id']}",
        })
    print(f"[curated] {len(rows)}건")
    return rows


# ─────────────────────────── 소스 4: 소재·디스플레이 전문 뉴스 사이트의 행사 목록 ───────────────────────────
# Metalgrass 계열 사이트들은 같은 형식의 /events 페이지를 갖고 있다.
METALGRASS_SITES = [
    ("https://www.graphene-info.com", "eng", ["그래핀", "나노", "재료"]),
    ("https://www.oled-info.com", "eng", ["디스플레이"]),
    ("https://www.microled-info.com", "eng", ["디스플레이"]),
    ("https://www.perovskite-info.com", "energy", ["재료", "신재생에너지"]),
]
DATE_RE = re.compile(r"(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+\d{1,2},?\s+(?:19|20)\d\d")


def parse_metalgrass(html_text, base, field, tags):
    rows = []
    blocks = re.split(r"<h2[^>]*>", html_text)[1:]
    for b in blocks:
        m = re.search(r'<a[^>]+href="([^"]+)"[^>]*>(.*?)</a>', b, re.S)
        if not m or "Event Duration" not in b and "Where" not in b:
            continue
        href, title = m.group(1), clean(m.group(2), 200)
        iso = re.findall(r'<time[^>]+datetime="(\d{4}-\d{2}-\d{2})', b)
        if not iso:
            continue
        try:
            start, end = dt.date.fromisoformat(iso[0]), dt.date.fromisoformat(iso[-1])
        except ValueError:
            continue
        if end < TODAY:
            continue
        where = re.search(r"Where:(.*?)</span>", b, re.S)
        where = re.sub(r"^Where\s*:?\s*", "", clean(where.group(1), 120).strip(" :")) if where else ""
        url = href if href.startswith("http") else base + href
        rows.append({
            "type": "conf", "field": field, "title": title, "org": title,
            "start_date": start.isoformat(), "end_date": end.isoformat(), "date": None,
            "content": title, "url": safe_url(url),
            "tags": ",".join(["국내개최" if is_korea(where) else "해외"] + tags),
            "location": where, "source": "metalgrass",
            "external_id": "metalgrass:" + re.sub(r"[^a-z0-9]+", "-", url.lower()).strip("-")[-120:],
        })
    return rows


def collect_metalgrass(pages=3, delay=2.0):
    rows = []
    for base, field, tags in METALGRASS_SITES:
        n = 0
        for page in range(pages):
            url = f"{base}/events" + (f"?page={page}" if page else "")
            try:
                html_text = http_get(url).decode("utf-8", "replace")
            except Exception as e:
                print(f"[metalgrass] {url} 실패: {e}", file=sys.stderr)
                break
            found = parse_metalgrass(html_text, base, field, tags)
            if page == 0 and not found:
                i = html_text.find("Event Duration")
                print(f"[metalgrass] {base} 0건, 예시:", repr(html_text[max(0, i - 600): i + 400] if i >= 0 else html_text[:500]))
            rows += found
            n += len(found)
            time.sleep(delay)
        print(f"[metalgrass] {base}: {n}건")
    return rows


# ─────────────────────────── Supabase ───────────────────────────
def supabase_request(method, path, body=None, prefer=None):
    base = os.environ["SUPABASE_URL"].rstrip("/")
    key = os.environ["SUPABASE_SERVICE_ROLE_KEY"]
    headers = {"apikey": key, "Authorization": f"Bearer {key}", "Content-Type": "application/json",
               "User-Agent": UA}
    if prefer:
        headers["Prefer"] = prefer
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(base + "/rest/v1/" + path, data=data, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.status


def upload(rows):
    now = dt.datetime.now(dt.timezone.utc).isoformat()
    for r in rows:
        r["last_seen_at"] = now
    for i in range(0, len(rows), 200):
        chunk = rows[i:i + 200]
        supabase_request("POST", "academic_info?on_conflict=external_id", chunk,
                         prefer="resolution=merge-duplicates,return=minimal")
        print(f"[supabase] upsert {i + len(chunk)}/{len(rows)}")
    cutoff = (TODAY - dt.timedelta(days=30)).isoformat()
    supabase_request("DELETE", f"academic_info?source=not.is.null&end_date=lt.{cutoff}", prefer="return=minimal")
    print(f"[supabase] {cutoff} 이전에 끝난 자동 수집 학회 정리 완료")


# 학회 이름에 들어간 단어로 관심 분야 태그를 더 붙인다 (검색창에서 '반도체' 등으로 찾을 수 있게)
TOPIC_KEYWORDS = [
    ("반도체", r"semiconductor|vlsi|integrated circuit|circuits? and systems|chip|design automation|nanoelectronic|microelectronic|\bDAC\b|\bICCAD\b|\bDATE\b"),
    ("이차전지", r"batter|lithium|energy storage|electrochem|supercapacitor"),
    ("디스플레이", r"display|oled|\bled\b|optoelectronic|photonic"),
    ("로봇", r"robot|autonomous system|mechatronic"),
    ("의학", r"medic|health|clinical|biomedical|surgery|disease"),
    ("고분자", r"polymer|macromolecul|plastic|elastomer|rubber"),
    ("유기화학", r"organic chem|organic synthesis|synthetic chem|catalysis|organometallic"),
    ("화학", r"chemi"),
    ("그래핀", r"graphene|2d material|two-dimensional material|carbon nano"),
    ("메타물질", r"metamaterial|metasurface"),
    ("나노", r"\bnano"),
    ("재료", r"material"),
]


def add_topic_tags(row):
    text = f"{row['title']} {row['org']}"
    tags = [t for t in row["tags"].split(",") if t]
    for tag, pattern in TOPIC_KEYWORDS:
        if tag not in tags and re.search(pattern, text, re.I):
            tags.append(tag)
    row["tags"] = ",".join(tags)
    return row


# ─────────────────────────── 소스 5: 국립중앙도서관 연구정보서비스(RINK) 학회/행사 ───────────────────────────
# 국내외 학술행사 목록. 국내 학회 대부분이 여기에 올라온다. 이공계·의학 분야만 가져온다.
RINK_URL = "https://www.nl.go.kr/rink/contents/R11101000000.do"
RINK_ROW_RE = re.compile(r'<li class="board_tr board_td">(.*?)</li>', re.S)
HANGUL_RE = re.compile(r"[가-힣]")
RINK_NOT_CONF_RE = re.compile(r"(교육|강좌|강의|과정)\s*$|페스티벌|박람회|전시회")


def rink_field(code):
    """RINK 주제분야 코드(KDC) → 우리 분야. None 이면 가져오지 않는다."""
    try:
        c = int(code)
    except (TypeError, ValueError):
        return None
    if c <= 9 or c == 310:          # 컴퓨터·프로그래밍·데이터·통계
        return "cs"
    if 510 <= c <= 519 or 470 <= c <= 499:   # 의학, 생물학
        return "bio"
    if 400 <= c <= 469 or 500 <= c <= 589:   # 자연과학, 공학 (590번대 가정학은 뺀다)
        return "eng"
    return None


def parse_rink_rows(html_text):
    rows = []
    for b in RINK_ROW_RE.findall(html_text):
        rid = re.search(r"fn_goView\('(\d+)'\)", b)
        cat = re.search(r'class="title" title="(\d+)">([^<]*)', b)
        tit = re.search(r"fn_goView\('\d+'\)\">(.*?)</a>", b, re.S)
        loc = re.search(r'class="bd_location">(.*?)</div>', b, re.S)
        tm = re.search(r'class="bd_time">(.*?)</div>', b, re.S)
        if not (rid and tit and tm):
            continue
        dates = re.findall(r"\d{4}[-.]\d{2}[-.]\d{2}", tm.group(1))
        rows.append({
            "id": rid.group(1), "code": cat.group(1) if cat else "", "cat": clean(cat.group(2), 60) if cat else "",
            "title": clean(tit.group(1), 300), "location": clean(loc.group(1), 120) if loc else "",
            "start": dates[0].replace(".", "-") if dates else None,
            "end": dates[-1].replace(".", "-") if dates else None,
        })
    return rows


def collect_rink(cache_path=None, page_size=100, max_pages=10, delay=1.0):
    cache = {}
    if cache_path and os.path.exists(cache_path):
        try:
            for r in json.load(open(cache_path, encoding="utf-8")):
                if r.get("source") == "rink" and r.get("url"):
                    cache[r["external_id"]] = r["url"]
        except (OSError, ValueError):
            pass
    seen, out, skipped = set(), [], collections.Counter()
    for page in range(1, max_pages + 1):
        url = f"{RINK_URL}?page={page}&pageSize={page_size}&ordFld=regdtASC&ordBy=asc"
        try:
            html_text = http_get(url, timeout=30).decode("utf-8", "replace")
        except Exception as e:
            print(f"[rink] {page}쪽 실패: {e}", file=sys.stderr)
            break
        items = [x for x in parse_rink_rows(html_text) if x["id"] not in seen]
        if not items:
            break
        for x in items:
            seen.add(x["id"])
            field = rink_field(x["code"])
            korean = bool(HANGUL_RE.search(x["title"])) or is_korea(x["location"]) or bool(HANGUL_RE.search(x["location"]))
            if not field or not korean:
                skipped["분야 밖" if not field else "해외"] += 1
                continue
            start, end = parse_one_date(x["start"]), parse_one_date(x["end"])
            if not start or not end or end < TODAY:
                continue
            title, org = x["title"], ""
            m = re.match(r"^\[([^\]]+)\]\s*(.*)$", title)
            if m:
                org, title = m.group(1).strip(), m.group(2).strip() or title
            if RINK_NOT_CONF_RE.search(title):
                skipped["교육·강좌"] += 1
                continue
            # '2026 추계학술대회'처럼 학회 이름이 빠진 제목은 앞에 학회 이름을 붙인다
            if org and org not in title and not re.search(r"[A-Z]{2,}", title):
                title = f"{org} {title}"
            out.append({
                "type": "conf", "field": field, "title": clean(title, 200), "org": clean(org or x["cat"], 200),
                "start_date": start.isoformat(), "end_date": end.isoformat(), "date": None,
                "abstract_deadline": None, "registration_deadline": None,
                "content": clean(f"{org} · {x['cat']}" if org else x["cat"], 300),
                "url": "", "tags": ",".join(["국내개최" if (HANGUL_RE.search(x["location"]) or is_korea(x["location"])
                                  or (HANGUL_RE.search(x["title"]) and "online" in x["location"].lower())) else "해외",
                                 x["cat"].split(",")[0].strip()]),
                "location": x["location"], "source": "rink", "external_id": f"rink:{x['id']}",
                "_detail": f"{RINK_URL}?schM=view&recKey={x['id']}",
            })
        time.sleep(delay)
    # 상세 페이지의 '상세 URL'(학회 홈페이지)을 읽는다. 지난번에 읽은 것은 다시 받지 않는다.
    fetched = 0
    for r in out:
        detail = r.pop("_detail")
        if r["external_id"] in cache:
            r["url"] = cache[r["external_id"]]
            continue
        if fetched >= 200:
            continue
        fetched += 1
        try:
            page = http_get(detail, timeout=20).decode("utf-8", "replace")
            m = re.search(r"상세 URL.*?href=\"(https?://[^\"]+)\"", page, re.S)
            if m and "nl.go.kr" not in m.group(1):
                r["url"] = safe_url(html.unescape(m.group(1)))
        except Exception as e:
            print(f"[rink] 상세 {detail} 실패: {e}", file=sys.stderr)
        time.sleep(delay / 2)
    print(f"[rink] 국내 이공계·의학 {len(out)}건 (전체 {len(seen)}건, 제외 {dict(skipped)}, 상세 조회 {fetched}건)")
    return out


def dedupe(rows):
    """같은 ID, 또는 같은 이름과 시작일인 학회는 하나만 남긴다.
    WikiCFP는 한 학회의 세부 세션을 따로 올리기도 하고, ccfddl과 겹치기도 한다 (먼저 온 ccfddl을 남김)."""
    seen, out = set(), []
    for r in rows:
        if not r["title"]:
            continue
        keys = {r["external_id"], (re.sub(r"\s+", " ", r["title"]).strip().lower(), r["start_date"])}
        if keys & seen:
            continue
        seen |= keys
        out.append(r)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="DB에 쓰지 않음")
    ap.add_argument("--out", help="수집 결과 JSON 저장 경로")
    ap.add_argument("--ccfddl-dir", help="이미 받아 둔 ccf-deadlines 저장소 경로")
    ap.add_argument("--skip-wikicfp", action="store_true")
    args = ap.parse_args()

    rows = collect_ccfddl(args.ccfddl_dir) + collect_curated() + collect_rink(cache_path=args.out)
    if not args.skip_wikicfp:
        wiki = collect_wikicfp()
        if not wiki:
            wiki = previous_rows(args.out, "wikicfp")
            print(f"[wikicfp] 이번에는 받지 못해 지난 결과 {len(wiki)}건을 그대로 씁니다")
        rows += wiki
        rows += collect_metalgrass()
    rows = [add_topic_tags(r) for r in dedupe(rows)]
    if not args.skip_wikicfp:
        rows = resolve_official_links(rows, cache_path=args.out)
    print(f"총 {len(rows)}건 수집")

    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(rows, f, ensure_ascii=False, indent=1)
    if args.dry_run:
        return
    if not os.environ.get("SUPABASE_SERVICE_ROLE_KEY"):
        sys.exit("SUPABASE_SERVICE_ROLE_KEY 가 없습니다. GitHub 저장소 Secrets 에 등록해 주세요.")
    if not rows:
        sys.exit("수집 결과가 0건입니다. 소스 형식이 바뀌었는지 확인해 주세요.")
    upload(rows)


if __name__ == "__main__":
    main()
