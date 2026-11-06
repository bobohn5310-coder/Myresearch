// ─────────────────────────────────────────────────────────────
// 내 CV 관리 — 입학부터 졸업·취업 준비까지 연구 이력을 쌓아 두고 CV로 내보내기
// dashboard.html 의 _sb, _currentUser, esc, myPapers, myConfs, myProjects 를 함께 쓴다.
// 데이터: papers / conferences / projects (기존 표) + cv_items, cv_profile (supabase/cv_manager.sql)
// ─────────────────────────────────────────────────────────────

const CV_DEGREES = ['학사', '석사', '박사', '석박통합', '박사후연구원', '교환학생', '기타'];
const CV_PAPER_TYPES = [
  ['intl_journal', '국제 저널 (SCI(E)·SCOPUS 등)', 'International Journal Articles'],
  ['dom_journal', '국내 저널 (KCI 등)', 'Domestic Journal Articles'],
  ['intl_conf', '국제 학술대회 논문 (Proceedings)', 'International Conference Papers'],
  ['dom_conf', '국내 학술대회 논문', 'Domestic Conference Papers'],
  ['etc', '기타 (책·보고서·프리프린트)', 'Other Publications'],
];
const CV_PAPER_STATUS = { pub: ['게재', 'Published'], sub: ['심사중', 'Under review'], prep: ['준비중', 'In preparation'] };
const CV_CONF_STATUS = { oral: ['구두발표', 'Oral'], poster: ['포스터', 'Poster'], invited: ['초청강연', 'Invited talk'], attend: ['청중 참석', 'Attended'] };
const CV_PROJ_STATUS = { active: '진행중', done: '완료' };

// 각 칸: k = 표의 칸 이름. type: text(기본) / month / date / select / textarea
const CV_SECTIONS = [
  { key: 'education', table: 'cv_items', icon: '🎓', ko: '학력', en: 'Education', stage: 0,
    empty: '입학하는 날 바로 적어 두세요. 졸업 예정일은 비워 두면 "재학중"으로 나와요.',
    fields: [
      { k: 'role', label: '학위 과정', type: 'select', options: CV_DEGREES },
      { k: 'org', label: '학교', ph: '예: 성균관대학교', req: true },
      { k: 'title', label: '전공·학과', ph: '예: 화학공학과', req: true },
      { k: 'start_date', label: '입학', type: 'month', half: true },
      { k: 'end_date', label: '졸업 (예정)', type: 'month', half: true },
      { k: 'detail', label: '지도교수·학위논문', type: 'textarea', ph: '예: 지도교수 홍길동 / 학위논문: 플라즈마 공정의 ...' },
    ] },
  { key: 'experience', table: 'cv_items', icon: '🏢', ko: '연구·경력', en: 'Research Experience', stage: 1,
    empty: '연구실, 인턴, 방문연구, 회사 경력을 적어요.',
    fields: [
      { k: 'title', label: '역할·직위', ph: '예: 석사과정 연구원, 연구 인턴', req: true },
      { k: 'org', label: '기관·연구실', ph: '예: 성균관대 플라즈마 연구실' },
      { k: 'start_date', label: '시작', type: 'month', half: true },
      { k: 'end_date', label: '끝 (진행중이면 비움)', type: 'month', half: true },
      { k: 'detail', label: '주요 업무', type: 'textarea', ph: '예: 식각 공정 최적화, OES 데이터 분석' },
    ] },
  { key: 'paper', table: 'papers', icon: '📄', ko: '논문', en: 'Publications', stage: 1, own: 'myPapers',
    empty: '투고하는 순간 "심사중"으로 적어 두고, 게재되면 상태만 바꿔 주세요.',
    fields: [
      { k: 'title', label: '논문 제목', req: true },
      { k: 'authors', label: '저자 (순서대로)', ph: '예: Kim B., Lee C., Park D.' },
      { k: 'venue', label: '저널·학회명', ph: '예: Applied Surface Science' },
      { k: 'year', label: '연도', ph: '예: 2026', half: true },
      { k: 'author', label: '내 역할', type: 'select', half: true, options: ['제1저자', '제2저자', '공동저자', '교신저자', '제1저자·교신저자', '기타'] },
      { k: 'paper_type', label: '종류', type: 'select', half: true, options: CV_PAPER_TYPES.map(t => [t[0], t[1]]) },
      { k: 'status', label: '상태', type: 'select', half: true, options: [['pub', '게재'], ['sub', '심사중 (투고)'], ['prep', '준비중']] },
      { k: 'link', label: 'DOI·링크', ph: '예: 10.1016/j.apsusc.2026.000000' },
    ] },
  { key: 'conf', table: 'conferences', icon: '🎤', ko: '학회 발표', en: 'Presentations', stage: 1, own: 'myConfs',
    empty: '학회에 다녀오면 발표 제목과 함께 적어 두세요.',
    fields: [
      { k: 'title', label: '학회명', ph: '예: AVS 72nd International Symposium', req: true },
      { k: 'presentation_title', label: '발표 제목', ph: '청중 참석이면 비워도 돼요' },
      { k: 'status', label: '발표 형태', type: 'select', half: true, options: [['oral', '구두발표'], ['poster', '포스터'], ['invited', '초청강연'], ['attend', '청중 참석']] },
      { k: 'date', label: '날짜', type: 'date', half: true },
      { k: 'location', label: '장소', ph: '예: 미국 샌디에이고' },
    ] },
  { key: 'project', table: 'projects', icon: '🔬', ko: '연구과제', en: 'Research Projects', stage: 1, own: 'myProjects',
    empty: '참여한 국가과제·기업과제를 적어요. 수행 업무를 적어 두면 면접 때도 도움이 돼요.',
    fields: [
      { k: 'title', label: '과제명', req: true },
      { k: 'venue', label: '주관·지원기관', ph: '예: 한국연구재단' },
      { k: 'role', label: '역할', type: 'select', half: true, options: [['학생연구원', '학생연구원'], ['참여연구원', '참여연구원'], ['co-PI', '공동연구자'], ['PI', '책임연구자']] },
      { k: 'status', label: '상태', type: 'select', half: true, options: [['active', '진행중'], ['done', '완료']] },
      { k: 'start_date', label: '시작', type: 'month', half: true },
      { k: 'end_date', label: '끝', type: 'month', half: true },
      { k: 'task', label: '수행 업무', type: 'textarea', ph: '예: 플라즈마 공정 최적화, 데이터 분석, 보고서 작성' },
    ] },
  { key: 'patent', table: 'cv_items', icon: '💡', ko: '특허', en: 'Patents', stage: 2,
    empty: '출원했다면 출원번호와 함께 적어요.',
    fields: [
      { k: 'title', label: '발명의 명칭', req: true },
      { k: 'role', label: '상태', type: 'select', half: true, options: ['출원', '등록', 'PCT 출원'] },
      { k: 'start_date', label: '출원·등록일', type: 'month', half: true },
      { k: 'org', label: '출원·등록번호', ph: '예: 10-2026-0012345' },
      { k: 'detail', label: '발명자', ph: '예: 홍길동, 김보람' },
    ] },
  { key: 'award', table: 'cv_items', icon: '🏆', ko: '수상·장학', en: 'Honors & Awards', stage: 2,
    empty: '우수발표상, 장학금, 연구장려금 모두 CV에 들어가요.',
    fields: [
      { k: 'title', label: '상·장학금 이름', ph: '예: 우수 포스터 발표상', req: true },
      { k: 'org', label: '수여 기관', ph: '예: 한국진공학회' },
      { k: 'start_date', label: '받은 때', type: 'month' },
      { k: 'detail', label: '설명 (선택)', ph: '예: 상위 5%, 연 1,200만원' },
    ] },
  { key: 'teaching', table: 'cv_items', icon: '👩‍🏫', ko: '강의·조교', en: 'Teaching Experience', stage: 2,
    empty: '조교(TA)·멘토링 경험도 교수·연구직 지원 때 중요해요.',
    fields: [
      { k: 'title', label: '과목·프로그램', ph: '예: 일반화학실험', req: true },
      { k: 'role', label: '역할', type: 'select', half: true, options: ['조교 (TA)', '강사', '멘토', '기타'] },
      { k: 'org', label: '학교·기관', half: true },
      { k: 'start_date', label: '시작', type: 'month', half: true },
      { k: 'end_date', label: '끝', type: 'month', half: true },
      { k: 'detail', label: '설명 (선택)' },
    ] },
  { key: 'skill', table: 'cv_items', icon: '🛠️', ko: '어학·자격·기술', en: 'Skills & Certifications', stage: 3,
    empty: '어학 점수, 자격증, 다룰 줄 아는 장비·프로그램을 적어요.',
    fields: [
      { k: 'role', label: '분류', type: 'select', options: ['어학', '자격증', '프로그래밍·분석 도구', '실험 장비·기법', '기타'] },
      { k: 'title', label: '항목', ph: '예: TOEIC, Python, SEM', req: true },
      { k: 'detail', label: '점수·수준', ph: '예: 950점 / 능숙', half: true },
      { k: 'start_date', label: '취득일', type: 'month', half: true },
    ] },
  { key: 'activity', table: 'cv_items', icon: '🌱', ko: '학술·대외 활동', en: 'Professional Activities', stage: 3,
    empty: '학회 회원, 논문 심사, 봉사, 대외활동 등을 적어요.',
    fields: [
      { k: 'title', label: '활동명', ph: '예: 한국진공학회 학생회원', req: true },
      { k: 'org', label: '기관', half: true },
      { k: 'role', label: '역할', half: true },
      { k: 'start_date', label: '시작', type: 'month', half: true },
      { k: 'end_date', label: '끝', type: 'month', half: true },
      { k: 'detail', label: '설명 (선택)' },
    ] },
];

const CV_STAGES = [
  { icon: '🎓', ko: '입학', tip: '학력·연구실을 적어 두기' },
  { icon: '🔬', ko: '연구', tip: '논문·학회·과제를 그때그때' },
  { icon: '🏆', ko: '졸업', tip: '수상·특허·학위논문 정리' },
  { icon: '💼', ko: '취업 준비', tip: '어학·기술 채우고 CV 내보내기' },
];

let cvItems = [];
let cvProfile = null;
let cvReady = true;        // cv_manager.sql 이 실행되었는지
let cvLang = 'ko';
let cvEditing = null;      // { sec, id }

function cvSec(key) { return CV_SECTIONS.find(s => s.key === key); }

function cvRows(sec) {
  if (sec.own === 'myPapers') return myPapers;
  if (sec.own === 'myConfs') return myConfs;
  if (sec.own === 'myProjects') return myProjects;
  return cvItems.filter(i => i.section === sec.key);
}

// 최신이 위로: 날짜/연도 기준, 없으면 등록순
function cvSortKey(sec, r) {
  if (sec.key === 'paper') return String(r.year || '');
  if (sec.key === 'conf') return String(r.date || '');
  return String(r.end_date || (r.start_date ? '9999' : '') ) + String(r.start_date || '');
}
function cvSorted(sec) {
  return [...cvRows(sec)].sort((a, b) => {
    const ka = cvSortKey(sec, a), kb = cvSortKey(sec, b);
    if (ka !== kb) return ka < kb ? 1 : -1;
    return String(b.created_at || '').localeCompare(String(a.created_at || ''));
  });
}

function cvFmtDate(v) {
  if (!v) return '';
  const m = String(v).match(/^(\d{4})-(\d{2})/);
  return m ? `${m[1]}.${m[2]}` : String(v);
}
function cvRange(r, lang, ongoingWord) {
  const s = cvFmtDate(r.start_date), e = cvFmtDate(r.end_date);
  if (!s && !e) return '';
  if (s && !e) return `${s} – ${ongoingWord || (lang === 'en' ? 'Present' : '현재')}`;
  if (!s) return e;
  return s === e ? s : `${s} – ${e}`;
}

// ── 데이터 불러오기 ──
async function loadCV() {
  if (!_currentUser) return;
  const [itemsRes, profRes] = await Promise.all([
    _sb.from('cv_items').select('*').eq('user_id', _currentUser.id),
    _sb.from('cv_profile').select('*').eq('user_id', _currentUser.id).maybeSingle(),
  ]);
  cvReady = !itemsRes.error && !profRes.error;
  cvItems = itemsRes.data || [];
  cvProfile = profRes.data || null;
  renderCV();
}

// ── 화면 그리기 ──
function cvSummaryLine(sec, r) {
  const parts = [];
  if (sec.key === 'education') {
    return { main: [r.role, r.org].filter(Boolean).join(' · ') || r.title, sub: [r.title, cvRange(r, 'ko', '재학중')].filter(Boolean).join(' · '), detail: r.detail };
  }
  if (sec.key === 'paper') {
    const st = CV_PAPER_STATUS[r.status]?.[0];
    return { main: r.title, sub: [r.venue, r.year, r.author].filter(Boolean).join(' · '), badge: st, badgeCls: 'st-' + (r.status || 'prep'), detail: r.authors };
  }
  if (sec.key === 'conf') {
    return { main: r.presentation_title || r.title, sub: [r.presentation_title ? r.title : '', r.location, r.date].filter(Boolean).join(' · '), badge: CV_CONF_STATUS[r.status]?.[0], badgeCls: 'st-' + (r.status || 'attend') };
  }
  if (sec.key === 'project') {
    return { main: r.title, sub: [r.venue, r.role, cvRange(r, 'ko')].filter(Boolean).join(' · '), badge: CV_PROJ_STATUS[r.status], badgeCls: r.status === 'active' ? 'st-active' : 'st-done', detail: r.task };
  }
  if (sec.key === 'skill') {
    return { main: r.title, sub: [r.role, r.detail, cvFmtDate(r.start_date)].filter(Boolean).join(' · ') };
  }
  if (sec.key === 'patent') {
    return { main: r.title, sub: [r.role, r.org, cvFmtDate(r.start_date)].filter(Boolean).join(' · '), detail: r.detail ? '발명자: ' + r.detail : '' };
  }
  if (sec.key === 'award') {
    return { main: r.title, sub: [r.org, cvFmtDate(r.start_date)].filter(Boolean).join(' · '), detail: r.detail };
  }
  parts.push(r.org, r.role, cvRange(r, 'ko'));
  return { main: r.title, sub: parts.filter(Boolean).join(' · '), detail: r.detail };
}

function renderCV() {
  const page = document.getElementById('page-cv');
  if (!page) return;

  // 머리글
  const p = cvProfile || {};
  const head = document.getElementById('cv-head');
  const nm = p.name_ko || p.name_en;
  head.innerHTML = nm ? `
      <div class="cv-head-name">${esc(p.name_ko || '')}${p.name_en ? ` <span>${esc(p.name_en)}</span>` : ''}</div>
      <div class="cv-head-meta">${esc([p.affiliation, p.email, p.phone, p.website].filter(Boolean).join('  ·  '))}</div>
      ${p.interests ? `<div class="cv-head-int">연구 분야 · ${esc(p.interests)}</div>` : ''}`
    : `<div class="cv-head-name" style="color:var(--text-light);">이름과 연락처를 먼저 적어 주세요</div>
       <div class="cv-head-meta">CV 맨 위에 들어가는 정보예요. 커뮤니티에는 보이지 않아요.</div>`;

  // 단계·완성도
  const filled = CV_SECTIONS.filter(s => cvRows(s).length > 0).length + (nm ? 1 : 0);
  const total = CV_SECTIONS.length + 1;
  const pct = Math.round(filled / total * 100);
  document.getElementById('cv-progress-bar').style.width = pct + '%';
  document.getElementById('cv-progress-text').textContent = `${filled} / ${total} 항목 채움`;
  document.getElementById('cv-stages').innerHTML = CV_STAGES.map((st, i) => {
    const secs = CV_SECTIONS.filter(s => s.stage === i);
    const done = secs.filter(s => cvRows(s).length > 0).length;
    return `<div class="cv-stage ${done === secs.length ? 'done' : ''}">
      <div class="cv-stage-top"><span>${st.icon}</span><b>${st.ko}</b><em>${done}/${secs.length}</em></div>
      <div class="cv-stage-tip">${st.tip}</div></div>`;
  }).join('');

  document.getElementById('cv-setup-note').style.display = cvReady ? 'none' : 'block';

  // 섹션 카드
  document.getElementById('cv-grid').innerHTML = CV_SECTIONS.map(sec => {
    const rows = cvSorted(sec);
    const list = rows.length === 0
      ? `<div class="cv-empty">${esc(sec.empty)}</div>`
      : rows.map(r => {
          const s = cvSummaryLine(sec, r);
          return `<div class="cv-item">
            <div class="cv-item-body">
              <div class="cv-item-main">${esc(s.main)}</div>
              ${s.sub ? `<div class="cv-item-sub">${esc(s.sub)}</div>` : ''}
              ${s.detail ? `<div class="cv-item-detail">${esc(s.detail)}</div>` : ''}
            </div>
            ${s.badge ? `<span class="cv-badge ${s.badgeCls}">${esc(s.badge)}</span>` : ''}
            <div class="cv-item-act">
              <button title="수정" onclick="openCVForm('${sec.key}',${Number(r.id)})">✏️</button>
              <button title="삭제" onclick="deleteCVItem('${sec.key}',${Number(r.id)})">×</button>
            </div>
          </div>`;
        }).join('');
    return `<div class="cv-card" id="cv-card-${sec.key}">
      <div class="cv-card-head">
        <div class="cv-card-title"><span class="cv-card-icon">${sec.icon}</span>${sec.ko}<span class="cv-count">${rows.length}</span></div>
        <button class="cv-add" onclick="openCVForm('${sec.key}')">+ 추가</button>
      </div>
      <div class="cv-list">${list}</div>
    </div>`;
  }).join('');
}

// ── 추가·수정 창 ──
function cvFieldHTML(f, val) {
  const v = val == null ? '' : String(val);
  const id = 'cvf-' + f.k;
  let input;
  if (f.type === 'select') {
    input = `<select id="${id}" class="cv-input">` + f.options.map(o => {
      const [ov, ol] = Array.isArray(o) ? o : [o, o];
      return `<option value="${esc(ov)}" ${ov === v ? 'selected' : ''}>${esc(ol)}</option>`;
    }).join('') + `</select>`;
  } else if (f.type === 'textarea') {
    input = `<textarea id="${id}" class="cv-input" rows="3" placeholder="${esc(f.ph || '')}">${esc(v)}</textarea>`;
  } else {
    const t = f.type === 'month' ? 'month' : f.type === 'date' ? 'date' : 'text';
    input = `<input id="${id}" class="cv-input" type="${t}" value="${esc(v)}" placeholder="${esc(f.ph || '')}">`;
  }
  return `<div class="cv-field ${f.half ? 'half' : ''}"><label for="${id}">${esc(f.label)}${f.req ? ' <b>*</b>' : ''}</label>${input}</div>`;
}

function openCVForm(key, id) {
  if (!_currentUser) { alert('로그인이 필요합니다.'); return; }
  const sec = cvSec(key);
  if (sec.table === 'cv_items' && !cvReady) { alert('CV 저장 기능을 준비 중이에요. 잠시 후 다시 시도해 주세요.'); return; }
  const row = id ? cvRows(sec).find(r => Number(r.id) === Number(id)) : null;
  cvEditing = { key, id: row ? row.id : null };
  document.getElementById('cv-form-title').textContent = `${sec.icon} ${sec.ko} ${row ? '수정' : '추가'}`;
  document.getElementById('cv-form-body').innerHTML = sec.fields.map(f => cvFieldHTML(f, row ? row[f.k] : '')).join('');
  document.getElementById('cv-form-save').disabled = false;
  document.getElementById('cv-form-save').textContent = '저장';
  document.getElementById('cv-form-overlay').style.display = 'flex';
  setTimeout(() => document.querySelector('#cv-form-body input[type=text], #cv-form-body input')?.focus(), 50);
}
function closeCVForm() { document.getElementById('cv-form-overlay').style.display = 'none'; cvEditing = null; }

async function saveCVForm() {
  if (!cvEditing || !_currentUser) return;
  const sec = cvSec(cvEditing.key);
  const data = {};
  for (const f of sec.fields) {
    const el = document.getElementById('cvf-' + f.k);
    const v = (el?.value || '').trim();
    if (f.req && !v) { alert(`'${f.label}'을(를) 적어 주세요.`); el?.focus(); return; }
    data[f.k] = v || null;
  }
  const btn = document.getElementById('cv-form-save');
  btn.disabled = true; btn.textContent = '저장 중...';
  let res;
  if (cvEditing.id) {
    res = await _sb.from(sec.table).update(data).eq('id', cvEditing.id).eq('user_id', _currentUser.id);
  } else {
    const ins = { ...data, user_id: _currentUser.id };
    if (sec.table === 'cv_items') ins.section = sec.key;
    res = await _sb.from(sec.table).insert([ins]);
  }
  btn.disabled = false; btn.textContent = '저장';
  if (res.error) { alert('저장하지 못했어요: ' + res.error.message); return; }
  closeCVForm();
  await cvReload(sec);
}

async function deleteCVItem(key, id) {
  const sec = cvSec(key);
  if (!confirm('이 항목을 지울까요?')) return;
  const { error } = await _sb.from(sec.table).delete().eq('id', id).eq('user_id', _currentUser.id);
  if (error) { alert('지우지 못했어요: ' + error.message); return; }
  await cvReload(sec);
}

async function cvReload(sec) {
  if (sec.table === 'cv_items') await loadCV();
  else await loadMyData();   // 대시보드 카드와 CV를 함께 새로 그림
}

// ── 머리글(기본 정보) ──
async function openCVProfile() {
  if (!_currentUser) { alert('로그인이 필요합니다.'); return; }
  if (!cvReady) { alert('CV 저장 기능을 준비 중이에요. 잠시 후 다시 시도해 주세요.'); return; }
  const p = cvProfile || {};
  let fallbackAff = '';
  if (!cvProfile) {
    const { data } = await _sb.from('profiles').select('institution,major,keywords').eq('id', _currentUser.id).maybeSingle();
    if (data) {
      fallbackAff = [data.institution, data.major].filter(Boolean).join(' ');
      p.interests = (data.keywords || []).join(', ');
    }
    p.email = _currentUser.email || '';
  }
  const fields = [
    { k: 'name_ko', label: '이름 (한글)', ph: '예: 김보람', half: true },
    { k: 'name_en', label: '이름 (영문)', ph: '예: Boram Kim', half: true },
    { k: 'affiliation', label: '현재 소속', ph: '예: 성균관대학교 화학공학과 박사과정' },
    { k: 'email', label: '이메일', half: true },
    { k: 'phone', label: '연락처 (선택)', half: true },
    { k: 'website', label: '홈페이지·Google Scholar·ORCID (선택)' },
    { k: 'interests', label: '연구 분야', ph: '예: 플라즈마 공정, 반도체 식각, 머신러닝' },
    { k: 'summary', label: '자기소개 한 문단 (선택)', type: 'textarea', ph: '취업용 CV 맨 위에 들어가는 짧은 소개' },
  ];
  cvEditing = { key: '__profile' };
  document.getElementById('cv-form-title').textContent = '🪪 CV 기본 정보';
  document.getElementById('cv-form-body').innerHTML =
    fields.map(f => cvFieldHTML(f, f.k === 'affiliation' ? (p.affiliation || fallbackAff) : p[f.k])).join('') +
    `<div class="cv-field-note">🔒 이 정보는 나만 볼 수 있고, 커뮤니티 닉네임과는 따로 저장돼요.</div>`;
  const btn = document.getElementById('cv-form-save');
  btn.disabled = false; btn.textContent = '저장';
  document.getElementById('cv-form-overlay').style.display = 'flex';
}

async function saveCVProfile() {
  const keys = ['name_ko', 'name_en', 'affiliation', 'email', 'phone', 'website', 'interests', 'summary'];
  const data = { user_id: _currentUser.id, updated_at: new Date().toISOString() };
  keys.forEach(k => { data[k] = (document.getElementById('cvf-' + k)?.value || '').trim() || null; });
  const btn = document.getElementById('cv-form-save');
  btn.disabled = true; btn.textContent = '저장 중...';
  const { error } = await _sb.from('cv_profile').upsert(data);
  btn.disabled = false; btn.textContent = '저장';
  if (error) { alert('저장하지 못했어요: ' + error.message); return; }
  closeCVForm();
  await loadCV();
}

function cvFormSubmit() {
  if (cvEditing?.key === '__profile') saveCVProfile(); else saveCVForm();
}

// ── CV 내보내기 ──
function cvBoldMe(authorsEscaped) {
  const p = cvProfile || {};
  let out = authorsEscaped;
  [p.name_en, p.name_ko].filter(n => n && n.trim().length >= 2).forEach(n => {
    const en = esc(n.trim()).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    out = out.replace(new RegExp(en, 'g'), m => `<b>${m}</b>`);
  });
  return out;
}

function buildCVHTML(opts) {
  const L = opts.lang === 'en';
  const p = cvProfile || {};
  const T = (ko, en) => L ? en : ko;
  const block = (title, inner) => inner ? `<section><h2>${title}</h2>${inner}</section>` : '';
  const row = (date, main, sub) => `<div class="row"><div class="dt">${esc(date || '')}</div><div class="bd"><div class="mn">${main}</div>${sub ? `<div class="sb">${sub}</div>` : ''}</div></div>`;
  const items = key => cvSorted(cvSec(key));
  let html = '';

  // 머리글
  const name = L ? (p.name_en || p.name_ko || '') : (p.name_ko || p.name_en || '');
  const sub = L ? (p.name_ko && p.name_en ? p.name_ko : '') : (p.name_ko && p.name_en ? p.name_en : '');
  html += `<header><h1>${esc(name || T('이름', 'Name'))}${sub ? ` <small>${esc(sub)}</small>` : ''}</h1>
    <div class="ct">${[p.affiliation, p.email, p.phone, p.website].filter(Boolean).map(esc).join('<span class="dot">·</span>')}</div></header>`;
  if (p.summary) html += block(T('소개', 'Summary'), `<p class="sum">${esc(p.summary)}</p>`);
  if (p.interests) html += block(T('연구 분야', 'Research Interests'), `<p class="sum">${esc(p.interests)}</p>`);

  html += block(T('학력', 'Education'), items('education').map(r =>
    row(cvRange(r, opts.lang, T('재학중', 'Present')), `<b>${esc([r.role, r.title].filter(Boolean).join(', '))}</b>`, esc([r.org, r.detail].filter(Boolean).join(' · ')))).join(''));

  html += block(T('연구·경력', 'Research Experience'), items('experience').map(r =>
    row(cvRange(r, opts.lang), `<b>${esc(r.title)}</b>${r.org ? ', ' + esc(r.org) : ''}`, esc(r.detail || ''))).join(''));

  // 논문: 종류별로 묶고 번호
  let papers = items('paper');
  if (!opts.includePrep) papers = papers.filter(r => r.status !== 'prep');
  if (papers.length) {
    let inner = '';
    let n = 0;
    CV_PAPER_TYPES.forEach(([tk, tko, ten]) => {
      const grp = papers.filter(r => (r.paper_type || 'etc') === tk);
      if (!grp.length) return;
      inner += `<h3>${L ? ten : tko.replace(/ \(.*\)/, '')}</h3><ol start="${n + 1}">` + grp.map(r => {
        n++;
        const st = r.status && r.status !== 'pub' ? ` <i>(${CV_PAPER_STATUS[r.status][L ? 1 : 0]})</i>` : '';
        const parts = [];
        if (r.authors) parts.push(cvBoldMe(esc(r.authors)));
        parts.push(`“${esc(r.title)}”`);
        if (r.venue) parts.push(`<i>${esc(r.venue)}</i>`);
        if (r.year) parts.push(esc(r.year));
        const link = r.link ? ` <span class="lk">${esc(/^10\./.test(r.link) ? 'doi:' + r.link : r.link)}</span>` : '';
        const role = r.author && !r.authors ? ` <span class="lk">[${esc(r.author)}]</span>` : '';
        return `<li>${parts.join(', ')}.${st}${role}${link}</li>`;
      }).join('') + `</ol>`;
    });
    html += block(T('논문', 'Publications'), inner);
  }

  // 발표
  let confs = items('conf');
  if (!opts.includeAttend) confs = confs.filter(r => r.status !== 'attend');
  if (confs.length) {
    const order = ['invited', 'oral', 'poster', 'attend'];
    let inner = '';
    order.forEach(st => {
      const grp = confs.filter(r => (r.status || 'attend') === st);
      if (!grp.length) return;
      inner += `<h3>${CV_CONF_STATUS[st][L ? 1 : 0]}</h3>` + grp.map(r =>
        row(cvFmtDate(r.date), r.presentation_title ? `“${esc(r.presentation_title)}”` : `<b>${esc(r.title)}</b>`,
          esc([r.presentation_title ? r.title : '', r.location].filter(Boolean).join(', ')))).join('');
    });
    html += block(T('학회 발표', 'Presentations'), inner);
  }

  html += block(T('연구과제', 'Research Projects'), items('project').map(r =>
    row(cvRange(r, opts.lang), `<b>${esc(r.title)}</b>${r.venue ? ', ' + esc(r.venue) : ''}${r.role ? ` <span class="lk">(${esc(r.role)})</span>` : ''}`, esc(r.task || ''))).join(''));

  html += block(T('특허', 'Patents'), items('patent').map(r =>
    row(cvFmtDate(r.start_date), `<b>${esc(r.title)}</b>`, esc([r.role, r.org, r.detail].filter(Boolean).join(' · ')))).join(''));

  html += block(T('수상·장학', 'Honors & Awards'), items('award').map(r =>
    row(cvFmtDate(r.start_date), `<b>${esc(r.title)}</b>${r.org ? ', ' + esc(r.org) : ''}`, esc(r.detail || ''))).join(''));

  html += block(T('강의·조교', 'Teaching Experience'), items('teaching').map(r =>
    row(cvRange(r, opts.lang), `<b>${esc(r.title)}</b>${r.org ? ', ' + esc(r.org) : ''}`, esc([r.role, r.detail].filter(Boolean).join(' · ')))).join(''));

  const skills = items('skill');
  if (skills.length) {
    const cats = [...new Set(skills.map(s => s.role || T('기타', 'Other')))];
    html += block(T('어학·자격·기술', 'Skills & Certifications'), `<table class="sk">` + cats.map(c =>
      `<tr><th>${esc(c)}</th><td>${skills.filter(s => (s.role || T('기타', 'Other')) === c).map(s =>
        esc(s.title) + (s.detail ? ` (${esc(s.detail)})` : '')).join(', ')}</td></tr>`).join('') + `</table>`);
  }

  html += block(T('학술·대외 활동', 'Professional Activities'), items('activity').map(r =>
    row(cvRange(r, opts.lang), `<b>${esc(r.title)}</b>${r.org ? ', ' + esc(r.org) : ''}`, esc([r.role, r.detail].filter(Boolean).join(' · ')))).join(''));

  const today = new Date();
  const upd = L ? `Last updated ${today.toLocaleDateString('en-US', { year: 'numeric', month: 'long' })}` : `${today.getFullYear()}년 ${today.getMonth() + 1}월 기준`;

  return `<!DOCTYPE html><html lang="${L ? 'en' : 'ko'}"><head><meta charset="UTF-8">
<title>${esc(name || 'CV')} - CV</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap" rel="stylesheet">
<style>
  @page { size: A4; margin: 16mm 15mm; }
  body { font-family: 'Noto Sans KR', 'Malgun Gothic', sans-serif; color: #111; font-size: 10.5pt; line-height: 1.5; margin: 0; padding: 28px 34px; background: #fff; }
  header { border-bottom: 2px solid #111; padding-bottom: 10px; margin-bottom: 6px; }
  h1 { font-size: 21pt; margin: 0 0 4px; letter-spacing: -0.5px; }
  h1 small { font-size: 12pt; font-weight: 500; color: #555; margin-left: 6px; }
  .ct { font-size: 9.5pt; color: #333; } .dot { margin: 0 6px; color: #999; }
  section { margin-top: 14px; page-break-inside: auto; }
  h2 { font-size: 11.5pt; text-transform: uppercase; letter-spacing: 0.6px; color: #1e3a8a; border-bottom: 1px solid #cbd5e1; padding-bottom: 2px; margin: 0 0 6px; }
  h3 { font-size: 10pt; margin: 8px 0 3px; color: #333; }
  .row { display: flex; gap: 12px; margin: 3px 0; page-break-inside: avoid; }
  .dt { width: 112px; flex-shrink: 0; color: #444; font-size: 9.5pt; padding-top: 1px; }
  .bd { flex: 1; } .sb { color: #555; font-size: 9.5pt; white-space: pre-line; }
  ol { margin: 2px 0 4px; padding-left: 22px; } li { margin: 2px 0; page-break-inside: avoid; }
  .lk { color: #555; font-size: 9pt; } .sum { margin: 0; white-space: pre-line; }
  table.sk { border-collapse: collapse; } .sk th { text-align: left; font-weight: 700; padding: 2px 14px 2px 0; vertical-align: top; white-space: nowrap; } .sk td { padding: 2px 0; }
  .upd { margin-top: 18px; font-size: 8.5pt; color: #888; text-align: right; }
</style></head><body>${html}<div class="upd">${upd}</div></body></html>`;
}

function cvOpts() {
  return {
    lang: cvLang,
    includePrep: document.getElementById('cv-opt-prep')?.checked,
    includeAttend: document.getElementById('cv-opt-attend')?.checked,
  };
}

function setCVLang(lang, el) {
  cvLang = lang;
  document.querySelectorAll('.cv-lang button').forEach(b => b.classList.toggle('on', b === el));
  refreshCVPreview();
}

function openCVPreview() {
  document.getElementById('cv-preview-overlay').style.display = 'flex';
  refreshCVPreview();
}
function closeCVPreview() { document.getElementById('cv-preview-overlay').style.display = 'none'; }
function refreshCVPreview() {
  const fr = document.getElementById('cv-preview-frame');
  if (fr && document.getElementById('cv-preview-overlay').style.display !== 'none') fr.srcdoc = buildCVHTML(cvOpts());
}
function printCV() {
  const fr = document.getElementById('cv-preview-frame');
  try { fr.contentWindow.focus(); fr.contentWindow.print(); }
  catch (e) {
    const w = window.open('', '_blank');
    w.document.write(buildCVHTML(cvOpts())); w.document.close(); w.focus(); setTimeout(() => w.print(), 400);
  }
}
function downloadCVWord() {
  const html = buildCVHTML(cvOpts()).replace('<html ', '<html xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:w="urn:schemas-microsoft-com:office:word" ');
  const blob = new Blob(['﻿', html], { type: 'application/msword' });
  const a = document.createElement('a');
  const nm = (cvProfile?.name_en || cvProfile?.name_ko || 'my').replace(/[^\w가-힣]+/g, '_');
  a.href = URL.createObjectURL(blob);
  a.download = `CV_${nm}_${new Date().toISOString().slice(0, 7)}.doc`;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(a.href), 2000);
}
