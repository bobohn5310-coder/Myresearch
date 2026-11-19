#!/usr/bin/env python3
"""읽는 페이지(소개·문의·연구 가이드·학회 일정표)를 정적 HTML 로 만든다.

홈(index.html)은 자바스크립트로 그려지는 한 장짜리 앱이라, 검색엔진과 애드센스 심사 로봇이
읽을 수 있는 글이 거의 없다. 이 스크립트는 같은 내용을 자바스크립트 없이도 읽히는 페이지로 만든다.

  content/pages/*.html   : 소개·문의 같은 고정 페이지 (맨 위 --- 사이에 제목·설명)
  content/guide/*.html   : 연구 가이드 글. 목록 페이지 guide/index.html 은 자동으로 만든다
  data/conferences.json  : 학회 일정표 conferences.html (매일 학회 수집 뒤 다시 만든다)

사용법
  python scripts/build_pages.py            # 전부 다시 만들고 sitemap.xml 도 갱신
외부 라이브러리 없이 파이썬 표준 라이브러리만 쓴다.
"""
from __future__ import annotations

import datetime as dt
import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SITE = "https://myresearchcal.com"
KST = dt.timezone(dt.timedelta(hours=9))
TODAY = dt.datetime.now(KST).date()

NAV = [
    ("home", "", "홈"),
    ("conferences", "conferences.html", "학회 일정표"),
    ("guide", "guide/", "연구 가이드"),
    ("about", "about.html", "소개"),
    ("contact", "contact.html", "문의"),
]
FIELD_LABEL = {"cs": "AI·컴퓨터", "eng": "공학·반도체·재료", "bio": "생명·의학", "energy": "에너지·이차전지", "quantum": "양자·통신"}
FIELD_ORDER = ["cs", "eng", "bio", "energy", "quantum"]
ADSENSE = '<script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=ca-pub-8855158825430155" crossorigin="anonymous"></script>'
REDIRECT = ("<script>(function(){var h=location.hostname;if(/\\.github\\.io$|\\.netlify\\.app$/.test(h)){var p=location.pathname"
            ".replace(/^\\/myresearch(?=\\/|$)/i,'')||'/';location.replace('https://myresearchcal.com'+p+location.search+location.hash);}})();</script>")

esc = html.escape


def read_source(path):
    """--- 로 감싼 머리말(key: value)과 본문을 나눠 읽는다."""
    text = open(path, encoding="utf-8").read()
    m = re.match(r"---\n(.*?)\n---\n", text, re.S)
    if not m:
        sys.exit(f"{path}: 맨 위에 --- 머리말이 없어요")
    meta = {}
    for line in m.group(1).splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            meta[k.strip()] = v.strip()
    meta["body"] = text[m.end():].strip()
    return meta


def page(out_path, *, title, description, body, nav, updated=None, crumb=None, article=False):
    """공통 머리·메뉴·바닥을 씌워 out_path(사이트 루트 기준)에 쓴다."""
    depth = out_path.count("/")
    up = "../" * depth
    url = SITE + "/" + (out_path[:-10] if out_path.endswith("index.html") else out_path)
    nav_html = "".join(
        f'<a href="{up}{href}"{" class=\"on\"" if key == nav else ""}>{label}</a>' for key, href, label in NAV if key != "home"
    )
    crumb_html = ""
    if crumb:
        crumb_html = '<div class="crumb">' + " › ".join(
            f'<a href="{up}{h}">{esc(t)}</a>' if h is not None else esc(t) for t, h in crumb) + "</div>"
    meta_line = f'<div class="meta">마이리서치캘린더 · {updated} 업데이트</div>' if updated else ""
    ld = ""
    if article:
        ld = '<script type="application/ld+json">' + json.dumps({
            "@context": "https://schema.org", "@type": "Article", "headline": title, "description": description,
            "dateModified": updated, "inLanguage": "ko", "mainEntityOfPage": url,
            "publisher": {"@type": "Organization", "name": "마이리서치캘린더", "url": SITE + "/"},
        }, ensure_ascii=False) + "</script>\n"
    doc = f"""<!DOCTYPE html>
<html lang="ko">
<head>
<meta charset="UTF-8">
{REDIRECT}
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>{esc(title)} | 마이리서치캘린더</title>
<meta name="description" content="{esc(description)}">
<meta name="robots" content="index,follow">
<link rel="canonical" href="{url}">
<meta property="og:type" content="{'article' if article else 'website'}">
<meta property="og:site_name" content="마이리서치캘린더">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(description)}">
<meta property="og:url" content="{url}">
<meta property="og:image" content="{SITE}/assets/og-image.png">
<link rel="icon" type="image/png" sizes="32x32" href="{up}assets/favicon-32.png">
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="{up}assets/page.css">
{ld}<!-- 구글 애드센스 (광고) -->
{ADSENSE}
</head>
<body>
<header class="top"><div class="top-in"><a class="brand" href="{up or './'}">📅 마이리서치캘린더</a><nav>{nav_html}</nav></div></header>
<main><div class="card">
{crumb_html}<h1>{esc(title)}</h1>
{meta_line}{body}
</div></main>
<footer><a href="{up or './'}">홈</a> · <a href="{up}conferences.html">학회 일정표</a> · <a href="{up}guide/">연구 가이드</a> · <a href="{up}about.html">소개</a> · <a href="{up}contact.html">문의</a> · <a href="{up}terms.html">이용약관</a> · <a href="{up}privacy.html">개인정보처리방침</a><br>© {TODAY.year} My Research Calendar</footer>
</body>
</html>
"""
    full = os.path.join(ROOT, out_path)
    os.makedirs(os.path.dirname(full), exist_ok=True)
    with open(full, "w", encoding="utf-8") as f:
        f.write(doc)
    return out_path


# ───────── 고정 페이지 ─────────
def build_static_pages():
    out = []
    d = os.path.join(ROOT, "content", "pages")
    for name in sorted(os.listdir(d)):
        if not name.endswith(".html"):
            continue
        m = read_source(os.path.join(d, name))
        out.append((page(name, title=m["title"], description=m["description"], body=m["body"], nav=m.get("nav", "")), m.get("updated")))
    return out


# ───────── 연구 가이드 ─────────
def build_guides():
    d = os.path.join(ROOT, "content", "guide")
    guides = []
    for name in sorted(os.listdir(d)):
        if name.endswith(".html"):
            m = read_source(os.path.join(d, name))
            m["slug"] = name[:-5]
            guides.append(m)
    guides.sort(key=lambda g: int(g.get("order", 99)))
    out = []
    for g in guides:
        others = [o for o in guides if o is not g][:4]
        related = '<div class="related"><h2>함께 읽으면 좋은 글</h2><div class="cards">' + "".join(
            f'<a href="{o["slug"]}.html"><div class="t">{esc(o["title"])}</div><div class="d">{esc(o["description"])}</div></a>' for o in others
        ) + '</div><p><a class="cta" href="../conferences.html">다가오는 학회 마감 보기 →</a></p></div>'
        out.append((page(f"guide/{g['slug']}.html", title=g["title"], description=g["description"], body=g["body"] + related,
                         nav="guide", updated=g.get("updated"), crumb=[("홈", ""), ("연구 가이드", "guide/"), (g["title"], None)],
                         article=True), g.get("updated")))
    cards = '<div class="cards">' + "".join(
        f'<a href="{g["slug"]}.html"><div class="t">{esc(g["title"])}</div><div class="d">{esc(g["description"])}</div></a>' for g in guides
    ) + "</div>"
    body = ('<div class="lead">학회 마감을 놓치지 않는 법부터 첫 해외 학회 준비, 연구실 고르기까지. '
            '대학원 생활에서 자주 묻는 질문을 마이리서치캘린더가 정리했어요. 글은 계속 늘려 갈게요.</div>' + cards +
            '<p class="muted">다뤘으면 하는 주제가 있으면 <a href="../contact.html">문의</a>로 알려 주세요.</p>')
    newest = max((g.get("updated", "") for g in guides), default=None)
    out.append((page("guide/index.html", title="대학원생 연구 가이드", nav="guide", updated=newest, body=body,
                     description="학회 초록 마감 시간 계산, 학회 등급 읽는 법, 첫 해외 학회 준비, 연구실 고르는 법 등 대학원생을 위한 실전 가이드 모음."),
                newest))
    return out


# ───────── 학회 일정표 ─────────
def _d(s):
    try:
        return dt.date.fromisoformat((s or "")[:10])
    except ValueError:
        return None


def _fmt(d):
    return f"{d.year}.{d.month:02d}.{d.day:02d}" if d else "-"


def _dday(d):
    n = (d - TODAY).days
    return "오늘 마감" if n == 0 else f"D-{n}"


def _tags(c):
    keep = [t for t in (c.get("tags") or "").split(",") if t and (t.startswith(("CCF-", "CORE-")) or t in ("국내개최",))]
    return "".join(f'<span class="tag">{esc(t)}</span>' for t in keep)


def _name(c):
    title = esc(c.get("title") or "")
    url = c.get("url") or ""
    if url.startswith(("http://", "https://")):
        title = f'<a href="{esc(url)}" rel="nofollow noopener" target="_blank">{title}</a>'
    org = c.get("org") or ""
    sub = f'<br><span class="muted">{esc(org)}</span>' if org and org != c.get("title") else ""
    return title + sub


def build_conferences():
    rows = json.load(open(os.path.join(ROOT, "data", "conferences.json"), encoding="utf-8"))
    confs = []
    for c in rows:
        start, end = _d(c.get("start_date")), _d(c.get("end_date"))
        if not start or (end or start) < TODAY:
            continue
        dl = [x for x in (_d(c.get("abstract_deadline")), _d(c.get("date"))) if x and x >= TODAY]
        c["_start"], c["_end"], c["_next"] = start, end, min(dl) if dl else None
        c["_abs"], c["_paper"] = _d(c.get("abstract_deadline")), _d(c.get("date"))
        confs.append(c)

    soon = sorted([c for c in confs if c["_next"] and (c["_next"] - TODAY).days <= 120], key=lambda c: (c["_next"], c["title"]))
    by_field = {f: sorted([c for c in confs if c.get("field") == f], key=lambda c: (c["_start"], c["title"])) for f in FIELD_ORDER}

    def when(c):
        s = _fmt(c["_start"])
        return s if not c["_end"] or c["_end"] == c["_start"] else f"{s} ~ {_fmt(c['_end'])[5:]}"

    soon_rows = "".join(
        f"<tr><td style=\"white-space:nowrap\"><b>{_fmt(c['_next'])}</b><br><span class=\"muted\">{_dday(c['_next'])}</span></td>"
        f"<td>{_name(c)} {_tags(c)}</td><td>{esc(FIELD_LABEL.get(c.get('field'), ''))}</td><td>{when(c)}<br><span class=\"muted\">{esc(c.get('location') or '')}</span></td></tr>"
        for c in soon)
    parts = [
        '<div class="lead">국내외 학회의 <b>초록·논문 투고 마감</b>과 <b>개최 일정</b>을 분야별로 한 페이지에 모았어요. '
        f'매일 새벽 자동으로 갱신되며, 지금 목록은 <b>{TODAY.year}년 {TODAY.month}월 {TODAY.day}일</b> 기준 다가오는 학회 {len(confs)}개예요.</div>',
        '<div class="tip"><p><b>마감 날짜 읽는 법</b> — 해외 학회 마감은 대부분 현지 시간이나 AoE(지구 마지막 시간대) 기준이라, '
        '한국 시간으로는 하루 늦게 끝나는 경우가 많아요. 자세한 계산법은 '
        '<a href="guide/conference-deadline-timezone.html">학회 마감 시간, 한국 시간으로 언제일까?</a>에 정리했어요.</p>'
        '<p>마감과 일정은 학회 사정으로 바뀔 수 있으니, 제출 전에는 꼭 학회 공식 사이트(학회 이름 링크)에서 확인하세요.</p></div>',
        '<p>필요한 분야로 바로 가기: ' + " · ".join(f'<a href="#f-{f}">{FIELD_LABEL[f]} ({len(by_field[f])})</a>' for f in FIELD_ORDER) + "</p>",
        f'<h2 id="soon">✍️ 120일 안에 마감되는 학회 ({len(soon)})</h2>',
        "<p>초록 마감과 논문 투고 마감 중 더 빠른 날짜 순서예요. 학회 이름 옆 CCF·CORE 표시는 컴퓨터 분야 학회 등급이에요"
        ' (<a href="guide/conference-rankings.html">등급 읽는 법</a>).</p>',
        '<div class="tbl"><table><tr><th>다음 마감</th><th>학회</th><th>분야</th><th>개최</th></tr>' + soon_rows + "</table></div>",
    ]
    for f in FIELD_ORDER:
        lst = by_field[f]
        trs = "".join(
            f"<tr><td style=\"white-space:nowrap\">{when(c)}</td><td>{_name(c)} {_tags(c)}</td><td>{esc(c.get('location') or '-')}</td>"
            f"<td>{'초록 ' + _fmt(c['_abs']) + '<br>' if c['_abs'] else ''}{'투고 ' + _fmt(c['_paper']) if c['_paper'] else ('' if c['_abs'] else '-')}</td></tr>"
            for c in lst)
        parts.append(f'<h2 id="f-{f}">{FIELD_LABEL[f]} 학회 ({len(lst)})</h2>')
        parts.append('<div class="tbl"><table><tr><th>개최일</th><th>학회</th><th>장소</th><th>마감</th></tr>' + trs + "</table></div>")
    parts.append(
        '<h2>이 일정표는 어떻게 만들어지나요?</h2>'
        '<p>컴퓨터·AI 분야는 연구자들이 함께 관리하는 공개 마감 목록(ccf-deadlines), 그 밖의 분야는 WikiCFP 등 공개 학술행사 공지에서 매일 모으고, '
        '국내 학회와 빠진 학회는 운영자가 직접 확인해 넣어요. 끝난 학회는 자동으로 빠져요. '
        '빠진 학회나 틀린 날짜를 발견하면 <a href="contact.html">문의</a>나 홈의 “빠진 학회 알려 주기”로 알려 주세요.</p>'
        '<p><a class="cta" href="./">내 분야 학회만 모아 보고 D-day 알림 받기 →</a></p>')
    return [(page("conferences.html", title=f"{TODAY.year}~{TODAY.year + 1} 학회 일정·초록 마감 총정리", nav="conferences",
                  updated=TODAY.isoformat(), body="\n".join(parts),
                  description=f"AI·컴퓨터, 반도체·공학, 생명·의학, 에너지, 양자 분야 국내외 학회 {len(confs)}개의 초록·논문 마감과 개최 일정을 매일 갱신해 한 페이지에 정리했어요."),
             TODAY.isoformat())]


def write_sitemap(pages):
    urls = [("", TODAY.isoformat(), "daily")] + [
        (p[:-10] if p.endswith("index.html") else p, lm, "daily" if p == "conferences.html" else "monthly") for p, lm in pages
    ] + [("terms.html", None, "yearly"), ("privacy.html", None, "yearly")]
    body = "".join(
        f"  <url><loc>{SITE}/{u}</loc>{f'<lastmod>{lm}</lastmod>' if lm else ''}<changefreq>{cf}</changefreq></url>\n" for u, lm, cf in urls)
    with open(os.path.join(ROOT, "sitemap.xml"), "w", encoding="utf-8") as f:
        f.write('<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' + body + "</urlset>\n")


def main():
    pages = build_static_pages() + build_guides() + build_conferences()
    write_sitemap(pages)
    for p, _ in pages:
        print("만듦:", p)


if __name__ == "__main__":
    main()
