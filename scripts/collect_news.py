#!/usr/bin/env python3
"""국내 연구 소식을 공개 RSS 에서 모아 data/news.json 으로 저장한다.

Supabase 는 DB 안의 예약 작업(pg_cron)이 이 파일을 읽어 news 테이블에 반영한다.
(supabase/news_collector.sql 참고)

저작권을 지키기 위해 기사 본문은 저장하지 않는다.
제목, RSS 가 공개하는 짧은 요약(최대 160자), 출처 이름, 원문 링크만 남긴다.
최근 기사는 언론사가 공유용으로 공개한 대표 이미지(og:image) 주소도 함께 남긴다.
(이미지 파일은 내려받지 않고 주소만 저장한다)

사용법
  python scripts/collect_news.py --out data/news.json
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

UA = "MyResearchCalendar-NewsCollector/1.0 (+https://myresearchcal.com/)"
KST = dt.timezone(dt.timedelta(hours=9))
NOW = dt.datetime.now(KST)
KEEP_DAYS = 30          # 이보다 오래된 기사는 모으지 않는다 (DB 에서도 30일 뒤 지움)
MAX_ITEMS = 150         # 파일에 남길 최대 건수 (최신순)
SUMMARY_LEN = 160
IMAGE_LIMIT = 40        # 대표 이미지를 새로 찾아볼 최신 기사 수 (이미 찾은 기사는 지난 파일에서 이어받는다)
BROWSER_UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
              "(KHTML, like Gecko) Chrome/124.0 Safari/537.36")

# (이름, RSS 주소, 연구 관련 단어가 있어야만 남길지)
DIRECT_FEEDS = [
    # 대덕연구개발특구 중심의 과학기술 전문 매체. 출연연·대학 연구 소식이 많다.
    ("헬로디디", "https://www.hellodd.com/rss/allArticle.xml", True),
]
# 참고: 2026-11 확인 결과 정책브리핑(과기정통부), 사이언스타임즈, 동아사이언스, KAIST 뉴스 RSS 는
# 주소가 없어졌고, 전자신문·연합뉴스 분야 RSS 는 연구와 무관한 기사가 너무 많아 뺐다.

# 구글 뉴스 검색 RSS: 여러 언론사의 국내 연구 성과 기사를 모은다.
GOOGLE_QUERIES = [
    "교수 연구팀 개발",
    "연구팀 세계 최초",
    "연구팀 논문 게재",
    "한국연구재단 연구 성과",
    "인공지능 연구팀",
    "반도체 연구팀",
    "배터리 연구팀",
    "양자 연구팀",
    "신약 연구팀",
]

RESEARCH_WORDS = ("연구", "개발", "교수", "논문", "기술", "과학", "R&D", "실험", "발견", "규명", "출연연")

# 분야 분류: 먼저 맞는 규칙이 이긴다. (field, 태그, 단어들)
FIELD_RULES = [
    ("quantum", "양자", ("양자", "큐비트", "퀀텀")),
    ("quantum", "통신", ("6G", "5G", "통신", "위성")),
    ("cs", "AI", ("인공지능", "AI", "딥러닝", "머신러닝", "LLM", "생성형", "언어모델")),
    ("cs", "컴퓨터", ("소프트웨어", "알고리즘", "로봇", "자율주행", "메타버스", "데이터", "보안", "슈퍼컴")),
    ("energy", "이차전지", ("배터리", "이차전지", "전고체", "리튬", "전해질", "양극재", "음극재")),
    ("energy", "에너지", ("수소", "태양전지", "태양광", "에너지", "원전", "원자력", "핵융합", "SMR", "탄소중립", "연료전지")),
    ("bio", "의학", ("암", "치료", "신약", "질환", "환자", "의료", "의학", "치매", "백신", "병원", "임상", "수술", "간호")),
    ("bio", "생명과학", ("유전자", "단백질", "세포", "바이오", "생명", "뇌", "미생물", "DNA", "RNA", "줄기세포")),
    ("eng", "반도체", ("반도체", "칩", "메모리", "트랜지스터")),
    ("eng", "디스플레이", ("디스플레이", "OLED", "LED")),
    ("eng", "소재", ("소재", "나노", "촉매", "신소재", "그래핀", "고분자")),
    ("eng", "우주", ("우주", "누리호", "발사체", "항공")),
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
        s = s[:limit].rstrip() + "…"
    return s


def safe_url(url):
    url = re.sub(r"[\"'<>\s`]", "", (url or "").strip())
    return url if re.match(r"^https?://", url, re.I) else ""


def http_get(url, timeout=30):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/rss+xml, application/xml, text/xml, */*"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read()


def parse_date(text):
    if not text:
        return None
    s = text.strip()
    try:
        d = email.utils.parsedate_to_datetime(s)
        if d.tzinfo is None:
            d = d.replace(tzinfo=KST)
        return d.astimezone(KST)
    except (TypeError, ValueError, IndexError):
        pass
    m = re.match(r"(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2}))?", s)
    if m:
        y, mo, da = int(m.group(1)), int(m.group(2)), int(m.group(3))
        h, mi = int(m.group(4) or 0), int(m.group(5) or 0)
        try:
            return dt.datetime(y, mo, da, h, mi, tzinfo=KST)
        except ValueError:
            return None
    return None


def local(tag):
    return tag.rsplit("}", 1)[-1]


def child_text(el, *names):
    for c in el:
        if local(c.tag) in names:
            if local(c.tag) == "link" and c.get("href"):
                return c.get("href")
            if c.text and c.text.strip():
                return c.text
    return ""


def parse_feed(raw):
    """RSS 2.0 과 Atom 둘 다 읽어 (title, link, summary, date, source) 목록을 돌려준다."""
    root = ET.fromstring(raw)
    items = [e for e in root.iter() if local(e.tag) in ("item", "entry")]
    out = []
    for it in items:
        source = ""
        for c in it:
            if local(c.tag) == "source" and c.text:
                source = c.text
        out.append({
            "title": child_text(it, "title"),
            "link": child_text(it, "link", "guid"),
            "summary": child_text(it, "description", "summary", "content"),
            "date": parse_date(child_text(it, "pubDate", "published", "updated", "date")),
            "source": source,
        })
    return out


def classify(text):
    text = re.sub(r"과학기술정보통신부|정보통신|과기정통부", " ", text)
    for field, tag, words in FIELD_RULES:
        for w in words:
            if w.isascii():
                if re.search(r"(?<![A-Za-z])" + re.escape(w) + r"(?![A-Za-z])", text):
                    return field, tag
            elif w in text:
                return field, tag
    return "eng", "연구"


def title_key(title):
    """같은 기사가 여러 언론사에 실린 경우를 걸러내기 위한 비교용 제목."""
    t = re.sub(r"\[[^\]]*\]|\([^)]*\)", "", title)
    t = re.sub(r"[^0-9A-Za-z가-힣]", "", t)
    return t[:22]


def make_row(title, link, summary, when, org, source_id):
    title = clean(title, 200)
    link = safe_url(link)
    if not title or not link or not when:
        return None
    summary = clean(summary, SUMMARY_LEN)
    if summary and title_key(summary) == title_key(title):
        summary = ""  # 요약이 제목 반복이면 버림
    field, tag = classify(title + " " + summary)
    return {
        "org": clean(org, 60),
        "field": field,
        "tag": tag,
        "title": title,
        "content": summary,
        "url": link,
        "date": when.date().isoformat(),
        "source": source_id,
        "external_id": "news:" + hashlib.sha1(link.encode("utf-8")).hexdigest()[:20],
        "_ts": when.timestamp(),
    }


def collect_direct():
    rows = []
    for name, url, need_research in DIRECT_FEEDS:
        try:
            items = parse_feed(http_get(url))
        except Exception as e:  # 한 곳이 실패해도 나머지는 계속
            print(f"[{name}] 실패: {e}", file=sys.stderr)
            continue
        kept = 0
        for it in items:
            text = (it["title"] or "") + " " + clean(it["summary"], 400)
            if need_research and not any(w in text for w in RESEARCH_WORDS):
                continue
            row = make_row(it["title"], it["link"], it["summary"], it["date"], name, "rss")
            if row:
                rows.append(row)
                kept += 1
        print(f"[{name}] {len(items)}건 중 {kept}건", file=sys.stderr)
        time.sleep(1)
    return rows


def collect_google():
    rows = []
    for q in GOOGLE_QUERIES:
        url = "https://news.google.com/rss/search?" + urllib.parse.urlencode(
            {"q": q + " when:3d", "hl": "ko", "gl": "KR", "ceid": "KR:ko"})
        try:
            items = parse_feed(http_get(url))
        except Exception as e:
            print(f"[구글뉴스 '{q}'] 실패: {e}", file=sys.stderr)
            continue
        kept = 0
        for it in items:
            title = it["title"] or ""
            org = it["source"]
            # 구글 뉴스 제목 끝의 ' - 언론사' 떼기
            m = re.match(r"^(.*)\s+-\s+([^-]{1,30})$", title)
            if m:
                title, org = m.group(1), org or m.group(2)
            if "연구" not in title and "교수" not in title and "개발" not in title:
                continue
            # 구글 뉴스 요약은 링크 목록일 뿐이라 쓰지 않는다
            row = make_row(title, it["link"], "", it["date"], org or "구글 뉴스", "google_news")
            if row:
                rows.append(row)
                kept += 1
        print(f"[구글뉴스 '{q}'] {len(items)}건 중 {kept}건", file=sys.stderr)
        time.sleep(2)
    return rows


def dedupe(rows):
    cutoff = (NOW - dt.timedelta(days=KEEP_DAYS)).timestamp()
    future = (NOW + dt.timedelta(days=1)).timestamp()
    # 직접 RSS 를 구글 뉴스보다 먼저 두어, 같은 기사면 직접 RSS 쪽을 남긴다
    rows = sorted(rows, key=lambda r: (r["source"] != "rss", -r["_ts"]))
    seen_id, seen_title, out = set(), set(), []
    for r in rows:
        if not (cutoff <= r["_ts"] <= future):
            continue
        k = title_key(r["title"])
        if r["external_id"] in seen_id or (k and k in seen_title):
            continue
        seen_id.add(r["external_id"])
        seen_title.add(k)
        out.append(r)
    out.sort(key=lambda r: -r["_ts"])
    out = out[:MAX_ITEMS]
    for r in out:
        del r["_ts"]
    return out


# ── 대표 이미지 (og:image) ──────────────────────────────────────────
# 로고나 기본 이미지처럼 기사와 상관없는 그림은 쓰지 않는다
BAD_IMAGE_RE = re.compile(r"logo|default|noimage|no_image|no-image|blank|placeholder|favicon|"
                          r"share_img|og_img_default|sns_default|lh3\.googleusercontent|gstatic\.com", re.I)


def page_get(url, timeout=15, data=None, headers=None):
    h = {"User-Agent": BROWSER_UA, "Accept-Language": "ko-KR,ko;q=0.9"}
    h.update(headers or {})
    req = urllib.request.Request(url, data=data, headers=h)
    with urllib.request.urlopen(req, timeout=timeout) as r:
        raw = r.read(600_000)   # 머리말(head)만 있으면 되므로 앞부분만 읽는다
        final = r.geturl()
        charset = r.headers.get_content_charset() or ""
    m = re.search(rb'<meta[^>]+charset=["\']?([\w-]+)', raw[:4000], re.I)
    for enc in (charset, m.group(1).decode() if m else "", "utf-8", "euc-kr"):
        if not enc:
            continue
        try:
            return raw.decode(enc), final
        except (LookupError, UnicodeDecodeError):
            continue
    return raw.decode("utf-8", "replace"), final


def decode_google_link(url):
    """구글 뉴스 RSS 링크(news.google.com/rss/articles/...)를 실제 언론사 기사 주소로 바꾼다."""
    m = re.search(r"news\.google\.com/(?:rss/)?articles/([A-Za-z0-9_\-]+)", url)
    if not m:
        return url
    gid = m.group(1)
    sg = ts = None
    for u in (f"https://news.google.com/rss/articles/{gid}?hl=ko&gl=KR&ceid=KR:ko",
              f"https://news.google.com/articles/{gid}?hl=ko&gl=KR&ceid=KR:ko"):
        page, final = page_get(u)
        sg = re.search(r'data-n-a-sg="([^"]+)"', page)
        ts = re.search(r'data-n-a-ts="([^"]+)"', page)
        if sg and ts:
            break
        # 구글이 바로 원문으로 보내 주는 경우
        if "news.google.com" not in final and safe_url(final):
            return safe_url(final)
    if not (sg and ts):
        print(f"[이미지] 구글 링크 풀기 실패(서명 없음) {final[:80]} len={len(page)}", file=sys.stderr)
        return ""
    inner = json.dumps(["garturlreq",
                        [["X", "X", ["X", "X"], None, None, 1, 1, "KR:ko", None, 1, None, None, None, None, None, 0, 1],
                         "X", "X", 1, [1, 1, 1], 1, 1, None, 0, 0, None, 0],
                        gid, int(ts.group(1)), sg.group(1)], separators=(",", ":"))
    body = urllib.parse.urlencode({"f.req": json.dumps([[["Fbv4je", inner, None, "generic"]]], separators=(",", ":"))})
    text, _ = page_get("https://news.google.com/_/DotsSplashUi/data/batchexecute",
                       data=body.encode(),
                       headers={"Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
                                "Referer": "https://news.google.com/"})
    try:
        payload = json.loads(text.split("\n\n", 1)[1])
        real = json.loads(payload[0][2])[1]
    except (IndexError, ValueError, TypeError):
        print(f"[이미지] 구글 링크 풀기 실패(응답) {text[:120]!r}", file=sys.stderr)
        return ""
    return safe_url(real)


def find_og_image(article_url):
    page, final = page_get(article_url)
    head = page.split("</head>", 1)[0]
    for key in ("og:image", "og:image:url", "og:image:secure_url", "twitter:image", "twitter:image:src"):
        for tag in re.findall(r"<meta\b[^>]*>", head, re.I):
            prop = re.search(r'(?:property|name)\s*=\s*["\']([^"\']+)', tag, re.I)
            if not prop or prop.group(1).strip().lower() != key:
                continue
            c = re.search(r'content\s*=\s*["\']([^"\']+)', tag, re.I)
            if not c:
                continue
            img = html.unescape(c.group(1).strip())
            img = urllib.parse.urljoin(final, img)
            img = safe_url(img)
            if img and not BAD_IMAGE_RE.search(img):
                return bigger_image(img)[:500]
    return ""


def bigger_image(img):
    """국내 언론사 다수가 쓰는 기사 관리 시스템은 공유 이미지로 가로 150px 썸네일
    (/news/thumbnail/..._v150.jpg)을 준다. 같은 사진의 원본(/news/photo/...)이 있으면 그 주소를 쓴다."""
    m = re.match(r"^(https?://[^/]+/news/)thumbnail/(.+?)_v\d+(\.\w+)$", img)
    if not m:
        return img
    big = f"{m.group(1)}photo/{m.group(2)}{m.group(3)}"
    try:
        req = urllib.request.Request(big, method="HEAD", headers={"User-Agent": BROWSER_UA})
        with urllib.request.urlopen(req, timeout=10) as r:
            if r.status == 200 and r.headers.get_content_type().startswith("image/"):
                return big
    except Exception:
        pass
    return img


def load_previous_images(path):
    """지난번 파일에서 이미 찾아 둔 대표 이미지를 이어받아, 같은 기사를 매일 다시 열지 않는다."""
    try:
        with open(path, encoding="utf-8") as f:
            return {r["external_id"]: r.get("image_url", "") for r in json.load(f) if "image_url" in r}
    except (OSError, ValueError, KeyError, TypeError):
        return {}


def attach_images(rows, prev):
    tried = found = 0
    for r in rows:
        if r["external_id"] in prev:
            r["image_url"] = prev[r["external_id"]]
            continue
        if tried >= IMAGE_LIMIT:
            continue   # 이번에는 건너뛰고, image_url 키가 없으니 다음 수집 때 다시 찾아본다
        tried += 1
        try:
            link = r["url"]
            if "news.google.com" in link:
                link = decode_google_link(link)
                time.sleep(1)
            if not link:
                continue   # 원문 주소를 못 찾았으면 다음 수집 때 다시 시도
            img = find_og_image(link)
        except Exception as e:  # 한 기사가 실패해도 나머지는 계속 (다음 수집 때 다시 시도)
            print(f"[이미지] 실패 {r['url'][:80]}: {e}", file=sys.stderr)
            continue
        finally:
            time.sleep(0.5)
        r["image_url"] = img   # 기사에 이미지가 없으면 빈 값을 남겨 같은 기사를 다시 찾지 않는다
        found += bool(img)
    print(f"[이미지] {tried}건 새로 찾아 {found}건 찾음, "
          f"전체 {sum(1 for r in rows if r.get('image_url'))}/{len(rows)}건에 이미지", file=sys.stderr)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="data/news.json")
    ap.add_argument("--min", type=int, default=5, help="이보다 적게 모이면 파일을 바꾸지 않고 실패")
    args = ap.parse_args()

    rows = dedupe(collect_direct() + collect_google())
    print(f"총 {len(rows)}건", file=sys.stderr)
    if len(rows) < args.min:
        print("모인 소식이 너무 적어 기존 파일을 그대로 둡니다.", file=sys.stderr)
        sys.exit(1)
    attach_images(rows, load_previous_images(args.out))
    with open(args.out, "w", encoding="utf-8") as f:
        json.dump(rows, f, ensure_ascii=False, indent=1)
        f.write("\n")


if __name__ == "__main__":
    main()
