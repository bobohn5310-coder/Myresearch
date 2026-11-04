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

UA = "MyResearchCalendar-ConferenceCollector/1.0 (+https://bobohn5310-coder.github.io/Myresearch/)"
TODAY = dt.date.today()

# ccfddl 분류(sub) → 우리 서비스 분야(field) 와 태그
CCF_SUB_TAGS = {
    "AI": "인공지능", "CG": "그래픽스·멀티미디어", "CT": "이론", "DB": "데이터베이스·데이터마이닝",
    "DS": "컴퓨터구조·시스템", "HI": "HCI", "MX": "융합", "NW": "네트워크", "SC": "보안", "SE": "소프트웨어공학",
}

# WikiCFP 카테고리 → (field, 한국어 태그)
WIKICFP_CATEGORIES = [
    ("bioinformatics", "bio", "생물정보학"),
    ("biology", "bio", "생명과학"),
    ("medicine", "bio", "의학"),
    ("engineering", "eng", "공학"),
    ("materials science", "eng", "재료"),
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
                deadlines = sorted(d for d in (parse_one_date(t.get("deadline"))
                                               for t in (ed.get("timeline") or []) if isinstance(t, dict)) if d)
                next_dl = next((d for d in deadlines if d >= TODAY), None)
                tags = ["해외" if not is_korea(place) else "국내개최", CCF_SUB_TAGS.get(sub, "컴퓨터")]
                if rank.get("ccf") and rank["ccf"] != "N":
                    tags.append(f"CCF-{rank['ccf']}")
                if rank.get("core") and rank["core"] != "N":
                    tags.append(f"CORE-{rank['core']}")
                content = clean(conf.get("description"), 300)
                if next_dl:
                    content += f" · 투고 마감 {next_dl.isoformat()}"
                rows.append({
                    "type": "conf",
                    "field": "cs",
                    "title": clean(f"{conf.get('title', '')} {ed.get('year', '')}", 200),
                    "org": clean(conf.get("description"), 200),
                    "start_date": start.isoformat(),
                    "end_date": end.isoformat(),
                    "date": next_dl.isoformat() if next_dl else None,
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
def _field_after(label, text):
    m = re.search(label + r"\s*[:\t ]\s*(.+?)(?=(?:When|Where|Submission Deadline|Notification Due|Final Version Due|Link)\b|$)",
                  text, re.I | re.S)
    return m.group(1).strip() if m else ""


def parse_wikicfp_item(item, field, tag):
    title_raw = clean(item.findtext("title"), 300)
    desc = clean(item.findtext("description"), 2000)
    link = safe_url(item.findtext("link"))
    when = _field_after("When", desc)
    where = clean(_field_after("Where", desc), 120)
    deadline = parse_one_date(_field_after("Submission Deadline", desc))
    # WikiCFP 형식: "Jun 1, 2027 - Jun 3, 2027" (N/A 이면 일정 미정)
    parts = [p.strip() for p in when.split(" - ")] if when else []
    start = parse_one_date(parts[0]) if parts else None
    end = parse_one_date(parts[-1]) if parts else None
    if not start or not end or end < TODAY:
        return None
    acronym, _, fullname = title_raw.partition(" : ")
    m = re.search(r"eventid=(\d+)", link)
    ext = f"wikicfp:{m.group(1)}" if m else f"wikicfp:{acronym}:{start.isoformat()}"
    content = clean(fullname or title_raw, 300)
    if deadline and deadline >= TODAY:
        content += f" · 투고 마감 {deadline.isoformat()}"
    return {
        "type": "conf",
        "field": field,
        "title": clean(acronym or title_raw, 200),
        "org": clean(fullname or title_raw, 200),
        "start_date": start.isoformat(),
        "end_date": end.isoformat(),
        "date": deadline.isoformat() if deadline and deadline >= TODAY else None,
        "content": content,
        "url": link,
        "tags": ",".join(["국내개최" if is_korea(where) else "해외", tag]),
        "location": where,
        "source": "wikicfp",
        "external_id": ext,
    }


def collect_wikicfp(categories=WIKICFP_CATEGORIES, delay=3.0):
    rows = []
    for cat, field, tag in categories:
        url = "http://www.wikicfp.com/cfp/rss?cat=" + urllib.parse.quote(cat)
        try:
            root = ET.fromstring(http_get(url))
        except Exception as e:  # 네트워크·파싱 오류는 그 카테고리만 건너뛴다
            print(f"[wikicfp] {cat} 실패: {e}", file=sys.stderr)
            continue
        n = 0
        for item in root.iter("item"):
            row = parse_wikicfp_item(item, field, tag)
            if row:
                rows.append(row)
                n += 1
        print(f"[wikicfp] {cat}: {n}건")
        time.sleep(delay)  # WikiCFP 서버 부담을 줄이려 요청 간격을 둔다
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


def dedupe(rows):
    seen, out = set(), []
    for r in rows:
        key = r["external_id"]
        if key in seen or not r["title"]:
            continue
        seen.add(key)
        out.append(r)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="DB에 쓰지 않음")
    ap.add_argument("--out", help="수집 결과 JSON 저장 경로")
    ap.add_argument("--ccfddl-dir", help="이미 받아 둔 ccf-deadlines 저장소 경로")
    ap.add_argument("--skip-wikicfp", action="store_true")
    args = ap.parse_args()

    rows = collect_ccfddl(args.ccfddl_dir)
    if not args.skip_wikicfp:
        rows += collect_wikicfp()
    rows = dedupe(rows)
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
