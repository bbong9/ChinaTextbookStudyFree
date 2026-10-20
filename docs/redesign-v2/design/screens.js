/* 课本乐园 v2 · 各屏幕(横屏 844×390) */
const W = 844, H = 390;
const px = (o) => Object.entries(o).map(([k, v]) => `${k}:${typeof v === 'number' ? v + 'px' : v}`).join(';');
const bgSvg = (inner, extra = '') => `<svg class="bg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" ${extra}>${inner}</svg>`;
const cbtn = (icon, pos, o = {}) => `<button type="button" class="cbtn ${o.cls || ''}" style="${px(pos)}" ${o.attr || ''} aria-label="${o.label || ''}">${icon}</button>`;
const pill = (icon, text, pos, o = {}) => `<div class="pill ${o.cls || ''}" style="${px(pos)}">${icon}<span>${text}</span></div>`;
const olabel = (t, pos, o = {}) => `<div class="olabel ${o.cls || ''}" style="${px(pos)}">${t}</div>`;
const skyBase = () => `<rect width="${W}" height="${H}" fill="url(#g-sky)"/>`;
const SEG = ['玩', '认', '练', '写', '说'];

function seg(step) {
  return `<div class="seg" style="left:102px;top:16px">${SEG.map((c, i) =>
    `<button type="button" data-step="${i}" class="${i === step ? 'on' : i < step ? 'done' : ''}">${c}${i < step ? '<i></i>' : ''}</button>`).join('')}</div>`;
}
function lessonHud(step, rightBtns = ['gu', 'help', 'pause']) {
  const pos = [752, 694, 636, 578];
  return `${cbtn(IC.back, { left: 44, top: 16 }, { label: '返回' })}${seg(step)}
    ${rightBtns.slice().reverse().map((b, i) => cbtn(IC[b], { left: pos[i], top: 16 }, { label: b, attr: b === 'gu' ? 'data-act="gu"' : '' })).join('')}
    ${step > 0 ? cbtn(IC.left, { left: 44, top: 326 }, { label: '上一步', attr: `data-step="${step - 1}"` }) : ''}
    ${step < 4 ? cbtn(IC.right, { left: 752, top: 326 }, { label: '下一步', attr: `data-step="${step + 1}"` }) : ''}`;
}
const meadow = (horizon = 210) => `${skyBase()}
  <circle cx="560" cy="-30" r="170" fill="url(#g-sunglow)"/>
  ${S.cloud(170, 70, .8)}${S.cloud(430, 46, .6, 'drift2')}${S.cloud(690, 96, .5)}
  <path d="M0 ${horizon - 14} C90 ${horizon - 60} 180 ${horizon - 58} 260 ${horizon - 30} C340 ${horizon - 70} 440 ${horizon - 72} 520 ${horizon - 40} C600 ${horizon - 66} 700 ${horizon - 70} 844 ${horizon - 36} L844 390 L0 390Z" fill="url(#g-far)"/>
  <path d="M0 ${horizon} C150 ${horizon - 26} 300 ${horizon - 22} 430 ${horizon - 8} C560 ${horizon - 26} 700 ${horizon - 32} 844 ${horizon - 22} L844 390 L0 390Z" fill="url(#g-hill1)"/>
  <path d="M0 ${horizon} C150 ${horizon - 26} 300 ${horizon - 22} 430 ${horizon - 8} C560 ${horizon - 26} 700 ${horizon - 32} 844 ${horizon - 22}" stroke="#E2FFB4" stroke-width="3" fill="none" opacity=".7"/>`;
const watermark = (txt, style) => `<div class="wm" style="${style}">${txt}</div>`;

/* ============ 01 宠物家族 ============ */
function scrPets() {
  const list = [
    ['mituan', '米团', '初始伙伴', '学满 7 天开花'],
    ['fox', '阿橘', '1200', '口算多 1 次提示'],
    ['cat', '奶糖', '1500', '识字闯关 +10% 金币'],
    ['penguin', '冰冰', '2000', '英语单词自动朗读'],
    ['owl', '博博', '连签 7 天', '读书挑战双倍经验'],
    ['dragon', '云宝', 'Lv10 解锁', '成语动画专属解说'],
    ['egg', '神秘蛋', '800', '随机孵化稀有伙伴']
  ];
  const xs = [80, 192, 304, 416, 528, 640, 752];
  let svg = `${meadow(230)}
    <ellipse cx="422" cy="300" rx="420" ry="70" fill="url(#g-hill2)"/>
    ${S.flower(30, 330, '#FF8FB1')}${S.flower(820, 320, '#B89BFF')}${S.tuft(60, 360)}${S.tuft(790, 370)}`;
  xs.forEach((x, i) => {
    svg += `<ellipse cx="${x}" cy="268" rx="50" ry="13" fill="#3E8F2A" opacity=".25"/><ellipse cx="${x}" cy="262" rx="48" ry="12" fill="url(#g-stone)"/>`;
    svg += petAt(list[i][0], x, 266, i === 0 ? 108 : 92, { cls: 'bob', open: true });
  });
  const tags = list.map(([k, n, cost, perk], i) => `<div class="pettag" style="left:${xs[i] - 52}px;top:280px">
    <b>${n}</b><span class="cost">${/^\d+$/.test(cost) ? coinSvg(14) + cost : cost}</span><em>${perk}</em></div>`).join('');
  return `${bgSvg(svg)}
    <div class="title-ribbon" style="left:272px;top:14px;width:300px">宠物家族 · 7 位小伙伴</div>
    <div class="note" style="left:40px;top:66px;width:764px;text-align:center">黏土质感 · 无描边 · 高光+腮红 —— 学习赚金币领养,每只伙伴带一个小技能</div>
    ${tags}`;
}

/* ============ 02 首页地图 ============ */
function scrMap() {
  const pts = [[20, 300], [112, 286], [172, 280], [232, 272], [292, 262], [352, 254], [414, 252], [476, 256], [538, 254], [600, 246], [668, 234], [740, 222], [870, 204]];
  const items = [['日', 'done', 3], ['月', 'done', 3], ['水', 'done', 2], ['火', 'done', 3], ['', 'game', 0], ['山', 'cur', 0], ['石', 'lock', 0], ['田', 'lock', 0], ['禾', 'lock', 0]];
  const road = smoothPath(pts);
  let svg = `${skyBase()}
    <circle cx="520" cy="-30" r="180" fill="url(#g-sunglow)"/>
    ${S.cloud(250, 58, .8)}${S.cloud(470, 34, .6, 'drift2')}${S.cloud(640, 104, .45)}
    <path d="M0 196 C80 150 170 150 250 178 C330 140 420 138 500 170 C580 146 680 140 760 168 C800 156 830 160 844 164 L844 390 L0 390Z" fill="url(#g-far)"/>
    <rect x="560" y="176" width="284" height="4" rx="2" fill="#9C7A5C"/>
    ${S.train(812, 176, .4, [{ grad: 'g-blue' }, { grad: 'g-green2' }])}
    <g class="steam"><circle cx="777" cy="112" r="7" fill="#fff" opacity=".9"/><circle cx="768" cy="98" r="9" fill="#fff" opacity=".7"/><circle cx="756" cy="82" r="11" fill="#fff" opacity=".5"/></g>
    <path d="M0 222 C150 196 300 200 430 214 C560 196 700 190 844 200 L844 390 L0 390Z" fill="url(#g-hill1)"/>
    <path d="M0 222 C150 196 300 200 430 214 C560 196 700 190 844 200" stroke="#E2FFB4" stroke-width="3" fill="none" opacity=".7"/>
    <path d="M0 330 C240 312 540 326 844 306 L844 390 L0 390Z" fill="url(#g-hill2)"/>
    ${S.mushHouse(300, 216, .7)}
    ${S.bush(214, 220, .7)}${S.bush(520, 222, .75)}${S.bush(770, 212, .6)}
    ${S.flower(200, 236, '#FF8FB1')}${S.flower(372, 222, '#FFD23F')}${S.flower(560, 232, '#B89BFF')}${S.flower(708, 214, '#FF8FB1')}${S.flower(820, 230, '#fff')}
    ${S.shroom(244, 232, .7)}${S.shroom(626, 220, .6)}
    ${S.butterfly(470, 150, '#FF9AC1')}${S.butterfly(150, 200, '#FFD23F')}
    <g filter="url(#f-sh)">
      <path d="M-40 312 C-6 292 6 230 10 130 C12 70 8 30 6 -10 L94 -10 C90 30 86 80 88 130 C92 220 104 280 128 306 C90 302 20 314 -40 312Z" fill="url(#g-trunk)"/>
      <path d="M30 40 C26 90 30 140 24 190 M70 60 C74 120 70 170 78 230" stroke="#B8763E" stroke-width="4" fill="none" stroke-linecap="round" opacity=".6"/>
      <path d="M32 294 L32 250 C32 222 74 222 74 250 L74 294Z" fill="url(#g-woodD)"/><circle cx="65" cy="268" r="3" fill="#FFD23F"/>
      <circle cx="54" cy="160" r="17" fill="#8F5527"/><circle cx="54" cy="160" r="13" fill="#FFE59A"/><path d="M54 147 V173 M41 160 H67" stroke="#8F5527" stroke-width="3"/>
    </g>
    <circle cx="-6" cy="-6" r="74" fill="url(#g-canopy2)"/><circle cx="80" cy="-30" r="62" fill="url(#g-canopy)"/><circle cx="146" cy="-14" r="40" fill="url(#g-canopy2)"/>
    ${S.tuft(110, 318)}${S.tuft(400, 330, 1.2)}${S.tuft(640, 314)}${S.stone(180, 312, .8)}${S.stone(560, 300, .7)}
    <path d="${road}" stroke="#CFC4DE" stroke-width="48" fill="none" stroke-linecap="round" transform="translate(0 4)"/>
    <path d="${road}" stroke="#F1ECF7" stroke-width="42" fill="none" stroke-linecap="round"/>
    <path d="${road}" stroke="#fff" stroke-width="3" fill="none" stroke-dasharray="2 18" stroke-linecap="round" opacity=".8"/>`;
  items.forEach(([ch, st, stars], i) => { const [x, y] = pts[i + 1]; svg += cube(x, y + 2, ch, st, stars); });
  svg += S.gift(668, 238, .85);
  svg += `<g transform="translate(668 168)"><path d="M0 22 L-7 12 H7Z" fill="#3D8BF2"/><rect x="-22" y="-8" width="44" height="22" rx="11" fill="url(#g-blue)"/><text x="0" y="8" text-anchor="middle" font-family="ZCOOL KuaiLe" font-size="14" fill="#fff">宝箱</text></g>`;
  svg += `<g transform="translate(352 186)"><path d="M0 22 L-7 12 H7Z" fill="#7563E8"/><rect x="-26" y="-8" width="52" height="22" rx="11" fill="url(#g-violet2)"/><text x="0" y="8" text-anchor="middle" font-family="ZCOOL KuaiLe" font-size="14" fill="#fff">小游戏</text></g>`;
  svg += petAt('mituan', 414, 214, 70, { cls: 'bob' });
  const dock = [['hanzi', '识字游戏'], ['math', '数学火车'], ['eng', '英语气球'], ['animal', '看图识物'], ['story', '故事绘本'], ['idiom', '成语动画'], ['books', '课外书屋']];
  const tops = [['checkin', '签到'], ['shop', '宠物店'], ['task', '任务'], ['parent', '家长']];
  return `${bgSvg(svg)}
    <div class="avatar" style="left:40px;top:12px">${pet('mituan', 52, { style: 'margin-top:4px' })}<span class="lv">Lv3</span></div>
    ${pill(coinSvg(24), '1,280', { left: 108, top: 22 })}
    ${pill(IC.flame(22), '连签 4 天', { left: 216, top: 22 })}
    <div class="taskbar" style="left:336px;top:18px"><span>今日目标</span><div class="bar"><i style="width:60%"></i></div><b>3/5 字</b>${coinSvg(20)}</div>
    ${tops.map(([k, t], i) => `<button type="button" class="topicon" style="left:${560 + i * 62}px;top:6px">${dockIcon(k, 46)}${olabel(t, {})}</button>`).join('')}
    <div class="book-badge" style="left:36px;top:318px">${dockIcon('books', 44)}<span>部编版<br><b>一年级上</b></span></div>
    <div class="dock" style="left:196px;top:316px">${dock.map(([k, t]) => `<button type="button">${dockIcon(k, 46)}${olabel(t, {})}</button>`).join('')}</div>
    <button type="button" class="go" style="left:722px;top:296px">${IC.play('#fff', 26)}<span>闯关</span></button>`;
}

/* ============ 关卡五步:玩 认 练 写 说 ============ */
function bun(x, y, ch) {
  return `<g transform="translate(${x} ${y})"><ellipse cx="0" cy="4" rx="50" ry="13" fill="#9FC9E8"/><ellipse cx="0" cy="0" rx="50" ry="13" fill="#fff"/><ellipse cx="0" cy="0" rx="38" ry="8" fill="#EAF4FB"/>
    <path d="M-34 -2 C-36 -30 -16 -44 0 -44 C16 -44 36 -30 34 -2 C18 4 -18 4 -34 -2Z" fill="url(#p-white)"/>
    <path d="M-8 -40 C-4 -46 4 -46 8 -40 M-14 -36 Q0 -48 14 -36" stroke="#E2D6C6" stroke-width="2" fill="none"/>
    ${spec(-16, -30, 8, 4)}
    <text x="0" y="-8" text-anchor="middle" font-family="${KAI}" font-weight="700" font-size="26" fill="#D9433A">${ch}</text></g>`;
}
function hand(x, y, s = 1, extra = '') {
  return `<g transform="translate(${x} ${y}) scale(${s})" filter="url(#f-sh)">${extra}<g>
    <path d="M-5 0 C-5 -3 5 -3 5 0 L5 26 L-5 26Z" fill="#FFE8D6"/>
    <path d="M-6 20 C-16 22 -18 36 -10 46 C-4 54 14 56 22 46 C28 38 26 26 24 22 C22 18 17 18 16 22 C16 16 10 15 9 20 C9 15 3 14 3 20 L-5 20Z" fill="#FFE8D6"/>
    <ellipse cx="-2" cy="4" rx="2.5" ry="1.6" fill="#fff" opacity=".8"/></g></g>`;
}
function stepPlay() {
  let svg = `${meadow(230)}
    ${S.tree(96, 268, 1.05)}${S.cottage(750, 262, .85)}${S.bush(640, 262, .8)}${S.bush(190, 270, .6)}
    ${S.flower(150, 300, '#FF8FB1')}${S.flower(700, 300, '#FFD23F')}${S.flower(240, 330, '#B89BFF')}${S.tuft(660, 340)}${S.tuft(120, 350)}`;
  svg += petAt('mituan', 422, 262, 168, { cls: 'bob' });
  svg += `<ellipse cx="422" cy="300" rx="214" ry="42" fill="#D9A55A"/><path d="M216 296 C214 340 222 380 230 400 L614 400 C622 380 630 340 628 296 C560 336 284 336 216 296Z" fill="#FFFDF6"/>
    <path d="M216 296 C214 340 222 380 230 400 L614 400 C622 380 630 340 628 296 C560 336 284 336 216 296Z" fill="none" stroke="#F4D9A8" stroke-width="3"/>
    <path d="M240 350 C330 372 514 372 604 350" stroke="#FFC93C" stroke-width="5" fill="none" opacity=".8"/>
    <ellipse cx="422" cy="292" rx="214" ry="40" fill="url(#g-cream)"/><ellipse cx="422" cy="292" rx="214" ry="40" fill="none" stroke="#F2C77D" stroke-width="4"/>
    ${bun(316, 292, '出')}${bun(422, 300, '石')}${bun(528, 292, '山')}
    <path d="M520 240 C510 200 470 196 448 210" stroke="#fff" stroke-width="4" fill="none" stroke-dasharray="3 9" stroke-linecap="round"/>
    <path d="M446 202 L440 214 L454 214Z" fill="#fff"/>
    ${hand(550, 268, 1)}`;
  return `${bgSvg(svg)}${lessonHud(0)}
    <div class="bubble" style="left:536px;top:92px">我饿啦,想吃<button type="button" class="say">${IC.speaker('#fff', 20)}shān</button><i></i></div>
    ${pill(starSvg(20), '第 1/3 题', { left: 44, top: 340 }, { cls: 'sm' })}`;
}
function mountainPic() {
  return `<svg width="224" height="224" viewBox="0 0 224 224" style="border-radius:22px;display:block">
    <rect width="224" height="224" fill="url(#g-sky)"/><circle cx="182" cy="44" r="18" fill="url(#g-gold)"/>${S.cloud(58, 44, .38)}
    <path d="M-6 196 C16 150 38 120 60 106 C80 120 104 150 124 196Z" fill="url(#g-green2)"/>
    <path d="M100 196 C120 152 142 122 164 110 C186 122 208 152 230 196Z" fill="url(#g-green2)"/>
    <path d="M44 200 C68 140 92 80 112 60 C132 80 156 140 180 200Z" fill="url(#g-canopy)"/>
    <path d="M97 78 C104 68 108 62 112 60 C116 62 120 68 127 78 C121 82 117 75 112 81 C107 75 103 82 97 78Z" fill="#fff"/>
    <path d="M52 110 C56 106 58 104 60 104 C62 104 64 106 68 112 C64 114 62 110 60 113 C57 110 55 114 52 110Z" fill="#fff"/>
    <path d="M156 116 C160 112 162 110 164 110 C166 110 168 112 172 118 C168 120 166 116 164 119 C161 116 159 120 156 116Z" fill="#fff"/>
    <rect y="188" width="224" height="40" fill="url(#g-hill2)"/>
    <path d="M60 106 V188 M112 62 V188 M164 112 V188 M56 188 H168" stroke="#FF8A00" stroke-width="5" fill="none" stroke-dasharray="7 7" stroke-linecap="round" class="dash"/>
  </svg>`;
}
function tianzi(ch, size, o = {}) {
  return `<div class="tzg" style="width:${size}px;height:${size}px">
    <svg width="${size}" height="${size}" viewBox="0 0 200 200" class="grid"><g stroke="#F0B7A3" stroke-width="1.4" stroke-dasharray="5 5"><path d="M100 0 V200 M0 100 H200 M0 0 L200 200 M200 0 L0 200"/></g></svg>
    ${o.svg || `<span style="font-family:${KAI};font-size:${size * .92}px">${ch}</span>`}</div>`;
}
function stepLearn() {
  return `<div class="bg" style="background:linear-gradient(160deg,#8D87F2,#A79FF8 60%,#B9B2FF)"></div>
    ${watermark('日月水火山石田禾日月水火山石田禾', 'left:-10px;top:-20px;width:880px;font-size:120px;line-height:130px;letter-spacing:20px')}
    ${lessonHud(1)}
    <div class="piccard" style="left:118px;top:82px">${mountainPic()}<span class="cap">看图:三座山峰</span></div>
    <svg class="abs" style="left:356px;top:120px" width="72" height="60" viewBox="0 0 72 60"><path d="M4 40 C20 8 48 8 62 30" stroke="#fff" stroke-width="5" fill="none" stroke-dasharray="4 9" stroke-linecap="round"/><path d="M54 30 L66 36 L66 22Z" fill="#fff"/></svg>
    <div class="charcard" style="left:432px;top:78px">${tianzi('山', 236)}
      <div class="py">shān</div>${cbtn(IC.speaker(), { right: -20, bottom: -20 }, { label: '读音' })}</div>
    <div class="words" style="left:700px;top:100px">
      ${[['gāo shān', '高<b>山</b>'], ['shān yáng', '<b>山</b>羊'], ['pá shān', '爬<b>山</b>']].map(([p, w]) => `<button type="button"><small>${p}</small><span>${w}</span></button>`).join('')}</div>
    ${pet('mituan', 72, { cls: 'bob abs', style: 'left:362px;top:268px' })}`;
}
function stone(x, y, ch) {
  return `<g transform="translate(${x} ${y})"><ellipse cx="0" cy="14" rx="60" ry="22" fill="#2F86B8" opacity=".35"/><ellipse cx="0" cy="8" rx="56" ry="22" fill="#A79FB8"/><ellipse cx="0" cy="0" rx="56" ry="22" fill="url(#g-stone)"/>
    <ellipse cx="-18" cy="-8" rx="16" ry="4" fill="#fff" opacity=".8"/>
    <text x="0" y="11" text-anchor="middle" font-family="${KAI}" font-weight="700" font-size="34" fill="#3A2E28">${ch}</text></g>`;
}
function stepPractice() {
  let svg = `${skyBase()}${S.cloud(200, 66, .7)}${S.cloud(560, 50, .55, 'drift2')}
    <path d="M0 180 C120 130 240 136 340 162 C440 128 580 126 680 156 C760 140 820 146 844 152 L844 390 L0 390Z" fill="url(#g-far)"/>
    <rect y="214" width="844" height="176" fill="url(#g-water)"/>
    <g stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".55" fill="none"><path d="M250 240 q14 -6 28 0" class="wave"/><path d="M520 250 q14 -6 28 0"/><path d="M370 350 q14 -6 28 0" class="wave"/><path d="M640 360 q14 -6 28 0"/></g>
    <path d="M0 196 C80 186 170 192 214 214 C230 260 200 330 180 390 L0 390Z" fill="url(#g-hill1)"/>
    <path d="M844 190 C760 186 690 194 652 216 C640 270 670 330 690 390 L844 390Z" fill="url(#g-hill1)"/>
    ${S.tree(70, 226, .7)}${S.flower(150, 250, '#FF8FB1')}${S.tuft(30, 300)}${S.tuft(760, 300)}${S.flower(800, 280, '#FFD23F')}
    <g><ellipse cx="330" cy="370" rx="22" ry="8" fill="#5FC23E"/><path d="M330 370 L346 364" stroke="#3C9128" stroke-width="2"/><ellipse cx="610" cy="250" rx="18" ry="6" fill="#5FC23E"/></g>
    ${stone(298, 300, '出')}${stone(430, 300, '山')}${stone(562, 300, '田')}
    <path d="M150 210 C220 120 360 120 424 262" stroke="#fff" stroke-width="4" fill="none" stroke-dasharray="3 10" stroke-linecap="round"/>
    ${S.chest(740, 262, .75, false)}
    <g transform="translate(470 330) rotate(-20)"><g class="hop"><ellipse rx="14" ry="8" fill="url(#p-orange)"/><path d="M12 0 L22 -7 L22 7Z" fill="url(#p-orange)"/><circle cx="-7" cy="-2" r="1.8" fill="#2A2230"/></g></g>`;
  svg += petAt('mituan', 140, 262, 104, { cls: 'bob' });
  return `${bgSvg(svg)}${lessonHud(2)}
    <div class="prompt" style="left:278px;top:80px"><button type="button" class="say">${IC.speaker('#fff', 22)}</button>听一听,跳到 <b>shān</b> 的石头上</div>
    ${pill(starSvg(20) + starSvg(20) + starSvg(20, false), '', { left: 640, top: 80 }, { cls: 'sm' })}`;
}
function stepWrite() {
  const guide = 'M48 78 V158 H152';
  const strokeSvg = `<svg width="290" height="290" viewBox="0 0 200 200" class="abs" style="left:0;top:0">
    <g stroke-linecap="round" stroke-linejoin="round" fill="none">
      <path d="M152 78 V158" stroke="#F0E6D6" stroke-width="18"/>
      <path d="${guide}" stroke="#E3CFB2" stroke-width="20"/>
      <path d="M100 26 V158" stroke="#4A3B33" stroke-width="16"/>
      <path d="${guide}" stroke="#4A3B33" stroke-width="16" stroke-dasharray="184" stroke-dashoffset="184"><animate attributeName="stroke-dashoffset" values="184;0;0" keyTimes="0;.75;1" dur="3.2s" repeatCount="indefinite"/></path>
    </g>
    <g fill="#fff">${[96, 114, 132, 150].map(y => `<circle cx="48" cy="${y}" r="2.6"/>`).join('')}${[66, 84, 102, 120, 138].map(x => `<circle cx="${x}" cy="158" r="2.6"/>`).join('')}</g>
    <g transform="translate(48 78)">${S.starPath(0, 0, 9, 'url(#g-gold)')}<circle cx="-3" cy="0" r="1.3" fill="#7A4A00"/><circle cx="3" cy="0" r="1.3" fill="#7A4A00"/></g>
    <g>${hand(0, 0, .55)}<animateMotion path="${guide}" dur="3.2s" repeatCount="indefinite" keyPoints="0;1;1" keyTimes="0;.75;1" calcMode="linear"/></g>
  </svg>`;
  const fruit = (on) => `<svg width="50" height="50" viewBox="0 0 50 50" ${on ? '' : 'filter="url(#f-gray)"'}><ellipse cx="25" cy="46" rx="14" ry="3" fill="#000" opacity=".15"/><path d="M25 14 C14 6 4 14 6 28 C8 40 18 46 25 42 C32 46 42 40 44 28 C46 14 36 6 25 14Z" fill="url(#p-red)"/><path d="M25 14 C25 8 27 5 30 3" stroke="#8F5527" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M27 9 C33 3 40 6 40 8 C36 12 30 12 27 9Z" fill="#5FC23E"/>${spec(16, 22, 5, 3)}</svg>`;
  const mini = (d, on, name, n) => `<div class="so ${on ? 'on' : ''}"><i>${n}</i><svg width="30" height="30" viewBox="0 0 200 200"><path d="${d}" stroke="${on ? '#FF8A00' : '#4A3B33'}" stroke-width="22" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg><span>${name}</span></div>`;
  return `<div class="bg" style="background:linear-gradient(170deg,#86D45A,#5DB73B)"></div>
    ${watermark('shān shuǐ huǒ yuè rì tián hé shí', 'left:-30px;top:-10px;width:900px;font-family:Nunito;font-weight:900;font-size:110px;line-height:120px')}
    ${lessonHud(3, ['gu', 'redo', 'pause'])}
    ${pet('mituan', 150, { cls: 'bob abs', style: 'left:128px;top:100px' })}
    <div class="fruits" style="left:118px;top:280px">${fruit(true)}${fruit(false)}${fruit(false)}</div>
    <div class="tzg big" style="left:338px;top:58px;width:290px;height:290px">
      <svg width="290" height="290" viewBox="0 0 200 200" class="grid"><g stroke="#E8D3B4" stroke-width="1.2" stroke-dasharray="5 5"><path d="M100 0 V200 M0 100 H200 M0 0 L200 200 M200 0 L0 200"/></g></svg>${strokeSvg}</div>
    <div class="strokes" style="left:660px;top:92px"><h4>笔顺 · 3 画</h4>
      ${mini('M100 26 V174', false, '竖', 1)}${mini('M48 60 V158 H152', true, '竖折', 2)}${mini('M152 60 V158', false, '竖', 3)}</div>`;
}
function stepSpeak() {
  let svg = `<rect width="${W}" height="${H}" fill="#FFD9A6"/>
    <rect width="${W}" height="${H}" fill="url(#g-warmglow)" opacity=".5"/>
    <path d="M300 -10 L544 -10 L700 330 L144 330Z" fill="#fff" opacity=".22"/>
    <ellipse cx="422" cy="350" rx="380" ry="70" fill="url(#g-wood)"/><ellipse cx="422" cy="336" rx="360" ry="54" fill="#F7C68A"/>
    <path d="M0 0 L140 0 C130 80 150 200 112 360 L0 360Z" fill="url(#p-red)"/><path d="M40 0 C36 120 50 240 30 360 M90 0 C86 120 100 220 80 360" stroke="#9E2219" stroke-width="5" fill="none" opacity=".4"/>
    <path d="M844 0 L704 0 C714 80 694 200 732 360 L844 360Z" fill="url(#p-red)"/><path d="M804 0 C808 120 794 240 814 360 M754 0 C758 120 744 220 764 360" stroke="#9E2219" stroke-width="5" fill="none" opacity=".4"/>
    <path d="M0 0 H844 V34 C760 54 680 30 600 46 C520 30 440 54 360 40 C280 54 200 30 120 48 C80 36 40 50 0 40Z" fill="url(#p-red)"/>
    <circle cx="120" cy="196" r="8" fill="url(#g-gold)"/><circle cx="724" cy="196" r="8" fill="url(#g-gold)"/>`;
  svg += petAt('mituan', 230, 330, 150, { cls: 'bob' });
  svg += `<g transform="translate(296 236) rotate(18)"><rect x="-6" y="0" width="12" height="40" rx="6" fill="#3A3550"/><ellipse cx="0" cy="-4" rx="14" ry="16" fill="#5B5675"/><ellipse cx="-4" cy="-10" rx="4" ry="6" fill="#fff" opacity=".4"/></g>`;
  return `${bgSvg(svg)}${lessonHud(4)}
    <div class="speakcard" style="left:372px;top:78px"><div class="big">山</div><div class="pyl">shān</div><div class="phr">高山 gāo shān · 山羊 shān yáng</div></div>
    <div class="wave" style="left:448px;top:300px">${[14, 26, 36, 22, 30, 16].map((h, i) => `<i style="height:${h}px;animation-delay:${i * .12}s"></i>`).join('')}</div>
    <button type="button" class="rec" style="left:556px;top:282px">${IC.mic('#fff', 36)}</button>
    <div class="wave" style="left:652px;top:300px">${[18, 30, 22, 36, 24, 12].map((h, i) => `<i style="height:${h}px;animation-delay:${i * .1}s"></i>`).join('')}</div>
    <div class="bubble left" style="left:96px;top:112px">读得真棒!<span class="stars">${starSvg(22)}${starSvg(22)}${starSvg(22)}</span><i></i></div>`;
}
function guModal() {
  const g = {
    jia: `<path d="M12 76 H88 M16 76 L28 48 L38 76 M38 76 L50 22 L62 76 M62 76 L72 48 L84 76" stroke="#3A2E28" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`,
    jin: `<path d="M12 78 H88 L84 72 L72 42 L64 72 L58 72 L50 18 L42 72 L36 72 L28 42 L16 72Z" fill="#3A2E28"/>`,
    zhuan: `<path d="M20 32 C20 70 30 76 50 76 C70 76 80 70 80 32 M50 14 V76" stroke="#3A2E28" stroke-width="4.5" fill="none" stroke-linecap="round"/>`,
    kai: `<text x="50" y="80" text-anchor="middle" font-family="${KAI}" font-size="78" fill="#3A2E28">山</text>`
  };
  const cols = [['甲骨文', '#FF9F1C', g.jia], ['金文', '#F07A52', g.jin], ['小篆', '#3FB8E3', g.zhuan], ['楷书', '#5DBB3C', g.kai]];
  return `<div class="dim"></div><div class="modal" style="left:212px;top:52px">
    <button type="button" class="xbtn" data-act="gu" aria-label="关闭">${IC.close}</button>
    <div class="evo">${cols.map(([n, c, s], i) => `<div class="col"><b style="background:${c}">${n}</b><svg width="76" height="76" viewBox="0 0 100 100">${s}</svg>${i < 3 ? '<em>›</em>' : ''}</div>`).join('')}</div>
    <hr><p><b>象形字</b>。像三座连在一起的山峰,中间那座最高。本义是地面上高高隆起的部分。</p>
    <div class="evo-foot">${cbtn(IC.speaker(OR, 22), { position: 'relative' }, { cls: 'sm' })}<span>听字源小故事 · 30 秒</span></div></div>`;
}
const LESSON = [stepPlay, stepLearn, stepPractice, stepWrite, stepSpeak];
function scrLesson(state) { return LESSON[state.step]() + (state.gu ? guModal() : ''); }

/* ============ 结算 ============ */
function scrResult() {
  let svg = `${skyBase()}<g transform="translate(330 210)"><g class="spin">${Array.from({ length: 12 }, (_, i) => `<path d="M0 0 L-40 -460 L40 -460Z" fill="#fff" opacity=".22" transform="rotate(${i * 30})"/>`).join('')}</g></g>
    ${S.cloud(90, 90, .6)}${S.cloud(760, 70, .5, 'drift2')}
    <path d="M0 290 C200 270 500 280 844 262 L844 390 L0 390Z" fill="url(#g-hill1)"/>
    ${S.chest(330, 318, 1.25, true)}
    ${Array.from({ length: 16 }, (_, i) => `<rect x="${120 + (i * 53) % 420}" y="${110 + (i * 37) % 160}" width="8" height="12" rx="2" fill="${['#FF6F61', '#FFC93C', '#3D8BF2', '#5FC23E', '#B89BFF'][i % 5]}" transform="rotate(${i * 27} ${124 + (i * 53) % 420} ${116 + (i * 37) % 160})" class="confetti" style="animation-delay:${(i % 6) * .3}s"/>`).join('')}`;
  svg += petAt('mituan', 170, 330, 128, { cls: 'jump' });
  return `${bgSvg(svg)}
    <div class="stars3" style="left:250px;top:8px">${starSvg(56)}${starSvg(74)}${starSvg(56)}</div>
    <div class="ribbon" style="left:222px;top:84px">闯关成功!</div>
    <div class="reward" style="left:520px;top:60px">
      <h4>本关收获</h4>
      <div class="row">${coinSvg(30)}<span>金币</span><b>+30</b></div>
      <div class="row">${starSvg(30)}<span>经验</span><b>+20</b></div>
      <div class="xp"><span>Lv3</span><div class="bar"><i style="width:72%"></i></div><span>Lv4</span></div>
      <div class="row"><svg width="30" height="30" viewBox="0 0 30 30"><ellipse cx="15" cy="17" rx="12" ry="9" fill="url(#g-wood)"/><circle cx="10" cy="15" r="1.6" fill="#8F5527"/><circle cx="17" cy="19" r="1.6" fill="#8F5527"/><circle cx="20" cy="13" r="1.6" fill="#8F5527"/></svg><span>宠物饼干</span><b>×1</b></div>
      <div class="row"><span class="mini-card" style="font-family:${KAI}">山</span><span>新字卡入册</span><b>5/8</b></div>
    </div>
    <button type="button" class="btn cream" style="left:520px;top:318px;width:128px">再练一次</button>
    <button type="button" class="btn orange" style="left:660px;top:318px;width:144px">下一关 ${IC.play('#fff', 16)}</button>`;
}

/* ============ 签到 ============ */
function scrCheckin() {
  const days = [['1', 'coin', 10, 'got'], ['2', 'coin', 10, 'got'], ['3', 'cookie', 1, 'got'], ['4', 'coin', 20, 'got'], ['5', 'coin', 20, 'today'], ['6', 'shard', 1, '']];
  const icon = (k) => k === 'coin' ? coinSvg(40) : k === 'cookie'
    ? `<svg width="40" height="40" viewBox="0 0 30 30"><ellipse cx="15" cy="16" rx="12" ry="10" fill="url(#g-wood)"/><circle cx="10" cy="14" r="1.8" fill="#8F5527"/><circle cx="17" cy="19" r="1.8" fill="#8F5527"/><circle cx="20" cy="12" r="1.8" fill="#8F5527"/></svg>`
    : pet('egg', 38);
  let svg = `${meadow(270)}${S.tree(800, 300, .8)}${S.flower(40, 330, '#FF8FB1')}${S.flower(560, 360, '#FFD23F')}${S.tuft(480, 370)}`;
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon" style="left:150px;top:14px;width:300px">每日签到 ${IC.flame(22)} 连签 4 天</div>
    <div class="board" style="left:104px;top:72px">
      ${days.map(([d, k, n, st]) => `<div class="day ${st}"><b>第${d}天</b>${icon(k)}<span>${k === 'shard' ? '宠物蛋碎片' : (k === 'coin' ? '×' + n : '饼干×1')}</span>${st === 'got' ? `<i class="stamp">✓</i>` : ''}${st === 'today' ? '<em>领取</em>' : ''}</div>`).join('')}
      <div class="day d7"><b>第7天 · 大奖</b><svg width="120" height="90" viewBox="-60 -100 120 110">${S.chest(0, 0, .95, false)}</svg><span>神秘蛋 + 50 金币</span></div>
    </div>
    <div class="timepanel" style="left:584px;top:70px">
      <h4>今日学习时长</h4>
      <div class="ring" style="--p:60"><b>18</b><small>/ 30 分钟</small></div>
      ${[['10 分钟', 'open', '已领 10 金币'], ['20 分钟', 'near', '还差 2 分钟'], ['30 分钟', '', '宠物饼干 ×2']].map(([t, s, d]) => `<div class="ladder ${s}"><svg width="40" height="34" viewBox="-50 -84 100 90">${S.chest(0, 0, .9, s === 'open')}</svg><span><b>${t}</b><small>${d}</small></span></div>`).join('')}
      <p class="eye">学满 20 分钟会提醒休息眼睛</p>
    </div>
    ${pet('mituan', 84, { cls: 'bob abs', style: 'left:26px;top:290px' })}`;
}

/* ============ 宠物小屋 ============ */
function scrPetHome() {
  let svg = `<rect width="${W}" height="${H}" fill="#FFE3CC"/>
    <g fill="#FFD2B3">${Array.from({ length: 60 }, (_, i) => `<circle cx="${(i % 12) * 74 + ((Math.floor(i / 12) % 2) * 37) + 20}" cy="${Math.floor(i / 12) * 54 + 20}" r="5"/>`).join('')}</g>
    <rect y="236" width="${W}" height="14" fill="#F2B98C"/>
    <rect y="250" width="${W}" height="140" fill="url(#g-wood)"/>
    <g stroke="#C98443" stroke-width="2" opacity=".55">${[280, 314, 352].map(y => `<path d="M0 ${y} H844"/>`).join('')}${[120, 300, 500, 700].map((x, i) => `<path d="M${x} ${250 + i % 2 * 34} v34"/>`).join('')}</g>
    <g filter="url(#f-sh)"><rect x="596" y="58" width="150" height="128" rx="64" fill="#C98443"/><rect x="606" y="68" width="130" height="110" rx="56" fill="url(#g-sky)"/>${S.cloud(660, 116, .35)}<path d="M671 68 V178 M606 124 H736" stroke="#C98443" stroke-width="6"/></g>
    <path d="M580 50 C600 90 590 160 600 200 L572 200 L572 50Z" fill="url(#g-coral)"/><path d="M762 50 C742 90 752 160 742 200 L770 200 L770 50Z" fill="url(#g-coral)"/>
    <g filter="url(#f-sh)"><rect x="210" y="70" width="84" height="74" rx="10" fill="url(#g-wood)"/><rect x="218" y="78" width="68" height="58" rx="6" fill="#E6F6FF"/></g>
    ${petAt('egg', 252, 134, 46)}
    <g filter="url(#f-sh)"><path d="M40 236 L48 196 H92 L100 236Z" fill="url(#g-coral)"/><circle cx="58" cy="176" r="22" fill="url(#g-canopy)"/><circle cx="80" cy="168" r="22" fill="url(#g-canopy)"/><circle cx="70" cy="148" r="20" fill="url(#g-canopy)"/></g>
    <ellipse cx="422" cy="312" rx="200" ry="40" fill="#FFB9C6"/><ellipse cx="422" cy="312" rx="170" ry="30" fill="none" stroke="#fff" stroke-width="4" stroke-dasharray="2 12" stroke-linecap="round"/>
    <ellipse cx="422" cy="300" rx="104" ry="26" fill="url(#g-violet2)"/><ellipse cx="422" cy="294" rx="86" ry="18" fill="#D9CCFF"/>
    <g transform="translate(580 296)"><ellipse rx="34" ry="10" fill="#3D8BF2"/><ellipse cy="-4" rx="30" ry="8" fill="#9CD2FF"/><ellipse cx="-8" cy="-10" rx="10" ry="6" fill="url(#g-wood)"/></g>
    <g transform="translate(270 300)"><circle r="16" fill="url(#g-coral)"/><path d="M-16 0 C-6 4 6 -4 16 0" stroke="#fff" stroke-width="3" fill="none"/>${spec(-5, -7, 5, 3)}</g>`;
  svg += petAt('mituan', 422, 302, 176, { cls: 'bob' });
  const bar = (ic, name, v, c) => `<div class="stat"><span class="si">${ic}</span><span class="sn">${name}</span><div class="bar"><i style="width:${v}%;background:${c}"></i></div></div>`;
  const acts = [['🍪', '喂食', '×3'], ['🫧', '洗澡', ''], ['⚽', '玩耍', ''], ['🎀', '装扮', '新']];
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    ${pill(coinSvg(24), '1,280', { left: 104, top: 22 })}
    <div class="nametag" style="left:322px;top:16px"><b>米团</b><span>Lv3</span><div class="bar"><i style="width:64%"></i></div><small>再得 120 经验 → 开花形态</small></div>
    <div class="stats" style="left:40px;top:258px">${bar(IC.heart(18), '开心', 82, 'linear-gradient(90deg,#FF9FB0,#FF6F61)')}${bar(coinSvg(18), '饱饱', 56, 'linear-gradient(90deg,#FFE07A,#FFB020)')}${bar(`<svg width="18" height="18" viewBox="0 0 20 20"><path d="M10 2 C14 8 16 11 16 13.5 A6 6 0 0 1 4 13.5 C4 11 6 8 10 2Z" fill="#3D8BF2"/></svg>`, '干净', 90, 'linear-gradient(90deg,#9CD2FF,#3D8BF2)')}</div>
    <div class="acts" style="left:604px;top:258px">${acts.map(([e, t, b]) => `<button type="button"><span class="e">${e}</span><span>${t}</span>${b ? `<i>${b}</i>` : ''}</button>`).join('')}</div>
    <button type="button" class="topicon" style="left:768px;top:6px">${dockIcon('shop', 46)}${olabel('宠物店', {})}</button>
    <button type="button" class="topicon" style="left:706px;top:6px">${dockIcon('task', 46)}${olabel('图鉴 3/7', {})}</button>
    <div class="bubble" style="left:520px;top:110px">今天学了 3 个字,<br>我好开心!<i></i></div>`;
}

/* ============ 宠物商店 ============ */
function scrShop() {
  const slots = [['fox', '阿橘', '1200', true], ['cat', '奶糖', '1500'], ['penguin', '冰冰', '2000'], ['owl', '博博', '连签 7 天'], ['dragon', '云宝', 'Lv10 解锁', false, true], ['egg', '神秘蛋', '800']];
  let svg = `<rect width="${W}" height="${H}" fill="#FFF1CC"/><rect width="${W}" height="${H}" fill="url(#g-warmglow)" opacity=".4"/>
    <g>${Array.from({ length: 15 }, (_, i) => `<path d="M${i * 60} 0 H${i * 60 + 60} V36 C${i * 60 + 60} 54 ${i * 60} 54 ${i * 60} 36Z" fill="${i % 2 ? '#fff' : '#FF6F61'}"/>`).join('')}</g>
    <rect x="320" y="172" width="490" height="16" rx="6" fill="url(#g-woodD)"/><rect x="320" y="318" width="490" height="16" rx="6" fill="url(#g-woodD)"/>
    <ellipse cx="174" cy="290" rx="120" ry="24" fill="#F2C77D"/><ellipse cx="174" cy="284" rx="110" ry="20" fill="url(#g-cream)"/>
    <path d="M110 40 L238 40 L300 290 L48 290Z" fill="#fff" opacity=".35"/>`;
  svg += petAt('fox', 174, 290, 170, { cls: 'bob' });
  slots.forEach(([k, n, c, sel, lock], i) => {
    const x = 400 + (i % 3) * 160, y = i < 3 ? 172 : 318;
    svg += `${sel ? `<ellipse cx="${x}" cy="${y - 50}" rx="70" ry="60" fill="url(#g-warmglow)"/>` : ''}<ellipse cx="${x}" cy="${y - 2}" rx="40" ry="9" fill="#8F5527" opacity=".25"/>`;
    svg += petAt(k, x, y - 4, 84, { filter: lock ? 'f-gray' : '' });
  });
  const tags = slots.map(([k, n, c, sel, lock], i) => {
    const x = 400 + (i % 3) * 160, y = i < 3 ? 172 : 318;
    const coin = /^\d+$/.test(c);
    return `<div class="ptag ${sel ? 'sel' : ''}" style="left:${x - 56}px;top:${y + 8}px"><b>${n}</b><span>${coin ? coinSvg(16) + c : (lock ? IC.lock('#8A97A8', 14) : '') + c}</span></div>`;
  }).join('');
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon" style="left:104px;top:14px;width:200px">宠物商店</div>
    ${pill(coinSvg(24), '1,280', { left: 690, top: 18 })}
    ${tags}
    <div class="showcase" style="left:56px;top:306px"><b>阿橘 · 爱跑步的小狐狸</b><span class="skill">技能:口算赛跑多 1 次提示</span></div>
    <button type="button" class="btn orange" style="left:96px;top:346px;width:156px;height:38px;font-size:17px">${coinSvg(20)} 1200 领养</button>
    <div class="note small" style="left:400px;top:62px">你有 1,280 金币,可以领养阿橘!</div>`;
}

/* ============ 数学小火车 ============ */
function scrMath() {
  const sign = `<rect x="-78" y="-176" width="100" height="38" rx="12" fill="#FFFDF6" stroke="#FFC93C" stroke-width="3"/><text x="-28" y="-149" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="22" fill="#D5443A">8 + 5</text>`;
  let svg = `${meadow(250)}${S.tree(70, 252, .8)}${S.bush(780, 250, .7)}
    <rect y="300" width="${W}" height="10" fill="#9C7A5C"/>${Array.from({ length: 29 }, (_, i) => `<rect x="${i * 30}" y="296" width="14" height="22" rx="3" fill="#C79B70"/>`).join('')}
    <rect y="294" width="${W}" height="6" rx="3" fill="#7E8698"/>
    ${S.train(700, 290, .9, [{ grad: 'g-blue', label: 12 }, { grad: 'g-green2', label: 13 }, { grad: 'g-violet2', label: 14 }])}
    ${S.tuft(30, 380)}${S.flower(360, 372, '#FF8FB1')}${S.flower(620, 376, '#FFD23F')}
    <g class="steam"><circle cx="650" cy="150" r="9" fill="#fff" opacity=".9"/><circle cx="636" cy="126" r="12" fill="#fff" opacity=".7"/><circle cx="618" cy="100" r="15" fill="#fff" opacity=".5"/></g>`;
  svg += petAt('penguin', 652, 214, 46);
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="qboard" style="left:282px;top:16px"><span>8 + 5 = </span><b>?</b></div>
    ${pill(`<svg width="22" height="22" viewBox="0 0 22 22"><circle cx="11" cy="12" r="9" fill="#fff" stroke="#3D8BF2" stroke-width="3"/><path d="M11 7 V12 L14 14" stroke="#3D8BF2" stroke-width="2.5" fill="none" stroke-linecap="round"/></svg>`, '00:42', { left: 600, top: 22 })}
    ${pill(IC.flame(22), '连对 ×4', { left: 704, top: 22 })}
    <div class="note" style="left:262px;top:88px;width:320px;text-align:center">点对的车厢,挂到小火车上 · 答对 10 题到站</div>`;
}

/* ============ 英语气球 ============ */
function balloon(x, y, grad, pic, word, delay) {
  return `<g transform="translate(${x} ${y})"><g class="float" style="animation-delay:${delay}s">
    <path d="M0 50 C-6 70 8 90 0 130" stroke="#8B9AB0" stroke-width="1.6" fill="none"/>
    <ellipse cx="0" cy="0" rx="46" ry="52" fill="url(#${grad})"/><path d="M-6 50 L6 50 L0 58Z" fill="#9A3A30" opacity=".5"/>
    ${spec(-20, -26, 10, 6, -30, .6)}
    <circle cx="0" cy="2" r="30" fill="#fff" opacity=".95"/>${pic}</g></g>`;
}
function scrEnglish() {
  const apple = `<g transform="translate(0 4)"><path d="M0 -10 C-10 -18 -22 -10 -20 2 C-18 14 -8 20 0 16 C8 20 18 14 20 2 C22 -10 10 -18 0 -10Z" fill="url(#p-red)"/><path d="M0 -10 C0 -16 2 -19 5 -21" stroke="#8F5527" stroke-width="2.5" fill="none" stroke-linecap="round"/><path d="M2 -16 C8 -22 14 -18 14 -17 C10 -13 5 -13 2 -16Z" fill="#5FC23E"/></g>`;
  const sun = `<g>${Array.from({ length: 8 }, (_, i) => `<rect x="-2.5" y="-24" width="5" height="9" rx="2.5" fill="#FFB020" transform="rotate(${i * 45})"/>`).join('')}<circle r="13" fill="url(#g-gold)"/></g>`;
  const fish = `<g><path d="M14 0 L24 -9 L24 9Z" fill="#3D8BF2"/><ellipse rx="17" ry="11" fill="url(#g-blue)"/><circle cx="-8" cy="-2" r="2.4" fill="#2A2230"/></g>`;
  const ball = `<g><circle r="16" fill="url(#g-coral)"/><path d="M-16 0 C-6 6 6 -6 16 0 M0 -16 C6 -6 -6 6 0 16" stroke="#fff" stroke-width="3" fill="none"/></g>`;
  const cat = `<g transform="translate(-22 -26) scale(.37)">${PET_ART.cat()}</g>`;
  let svg = `${skyBase()}${S.cloud(110, 300, .7)}${S.cloud(460, 340, .8, 'drift2')}${S.cloud(760, 290, .6)}${S.cloud(640, 60, .4)}
    ${balloon(180, 170, 'g-coral', apple, 'apple', 0)}${balloon(330, 130, 'g-blue', fish, 'fish', .6)}${balloon(470, 190, 'g-gold', ball, 'ball', 1.2)}${balloon(620, 140, 'g-violet2', cat, 'cat', .3)}
    <g transform="translate(740 200)"><g class="pop">${Array.from({ length: 8 }, (_, i) => `<rect x="-3" y="-44" width="6" height="16" rx="3" fill="#FFC93C" transform="rotate(${i * 45})"/>`).join('')}${sun}</g></g>
    <path d="M0 360 C240 340 600 352 844 336 L844 390 L0 390Z" fill="url(#g-hill1)"/>`;
  svg += petAt('penguin', 90, 382, 110, { cls: 'bob' });
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="prompt" style="left:250px;top:16px"><button type="button" class="say">${IC.speaker('#fff', 22)}</button>Find the <b style="font-family:Nunito;font-size:26px">apple</b><small>苹果</small></div>
    ${pill(starSvg(20), '3 / 8', { left: 704, top: 22 })}
    <div class="plus" style="left:760px;top:120px">+5</div>`;
}

/* ============ 看图识动物(幼儿) ============ */
function scrAnimals() {
  let svg = `${meadow(230)}
    <g filter="url(#f-sh)" transform="translate(720 230)"><path d="M-80 0 V-90 L0 -150 L80 -90 V0Z" fill="url(#p-red)"/><path d="M-90 -86 L0 -158 L90 -86" stroke="#fff" stroke-width="10" fill="none" stroke-linejoin="round"/>
      <rect x="-34" y="-74" width="68" height="74" rx="4" fill="#FFF3DA"/><path d="M-34 -74 L34 0 M34 -74 L-34 0" stroke="#D5443A" stroke-width="7"/><circle cx="0" cy="-112" r="14" fill="#FFF3DA"/></g>
    ${S.fence(0, 600, 250)}
    <ellipse cx="150" cy="320" rx="112" ry="36" fill="url(#g-water)"/><ellipse cx="130" cy="312" rx="40" ry="8" fill="#fff" opacity=".35"/>
    ${S.flower(300, 360, '#FF8FB1')}${S.flower(620, 350, '#FFD23F')}${S.tuft(260, 380)}${S.tuft(580, 380)}${S.tuft(800, 360)}`;
  svg += petAt('duck', 150, 328, 92, { cls: 'bob' }) + petAt('pig', 312, 350, 96);
  svg += `<ellipse cx="488" cy="296" rx="70" ry="64" fill="url(#g-glow)" class="pulse"/>` + petAt('sheep', 488, 348, 108);
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon green" style="left:104px;top:14px;width:240px">看图识动物 · 3–6 岁</div>
    <div class="animalcard" style="left:560px;top:74px"><div class="ch" style="font-family:${KAI}">羊</div><div><b>yáng</b><span>sheep</span><em>咩咩~ 羊毛软软的</em></div>${cbtn(IC.speaker(), { right: -16, top: -16 }, { cls: 'sm' })}</div>
    <button type="button" class="topicon" style="left:756px;top:296px">${dockIcon('task', 46)}${olabel('图鉴 6/20', {})}</button>
    <div class="note" style="left:104px;top:68px">点一点小动物,听它的名字和叫声</div>`;
}

/* ============ 成语 · 选择 ============ */
function idiomArt(id, w, h, full) {
  return `<svg width="${w}" height="${h}" viewBox="${full ? '0 92 400 185' : '0 0 400 300'}" preserveAspectRatio="xMidYMid slice">
    <defs><linearGradient id="${id}-sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#A9E2F2"/><stop offset="1" stop-color="#F3F7DC"/></linearGradient></defs>
    <rect width="400" height="300" fill="url(#${id}-sky)"/><circle cx="320" cy="60" r="26" fill="url(#g-gold)"/>
    <path d="M0 170 C80 120 160 130 220 150 C290 110 360 120 400 140 V300 H0Z" fill="url(#g-far)"/>
    <path d="M0 190 C120 176 280 182 400 172 V300 H0Z" fill="url(#g-hill1)"/>
    <g stroke="#7BBF3F" stroke-width="4" stroke-linecap="round">${[210, 232, 256, 282].map(y => `<path d="M${20} ${y} C140 ${y - 6} 260 ${y - 6} 380 ${y - 10}"/>`).join('')}</g>
    ${full ? Array.from({ length: 9 }, (_, i) => S.tuft(30 + i * 42, 230 + (i % 3) * 24, 1.8)).join('') : ''}
    <g transform="translate(250 228)"><path d="M-26 0 L-22 -40 L22 -40 L26 0Z" fill="url(#g-trunk)"/><ellipse cx="0" cy="-40" rx="22" ry="8" fill="#F2C890"/><ellipse cx="0" cy="-40" rx="12" ry="4" fill="none" stroke="#C98443" stroke-width="2"/></g>
    ${full ? '' : `<g transform="translate(296 222)"><ellipse rx="22" ry="13" fill="url(#p-white)"/><circle cx="-18" cy="-6" r="11" fill="url(#p-white)"/><ellipse cx="-22" cy="-22" rx="4" ry="12" fill="url(#p-white)" transform="rotate(-20 -22 -22)"/><ellipse cx="-14" cy="-22" rx="4" ry="12" fill="url(#p-white)" transform="rotate(10 -14 -22)"/><path d="M-24 -8 l4 3 M-20 -8 l-4 3" stroke="#2A2230" stroke-width="1.8"/><g fill="#FFC93C">${S.starPath(-30, -38, 5, '#FFC93C')}${S.starPath(-10, -42, 4, '#FFC93C')}</g></g>`}
    <g transform="translate(130 236)">
      <path d="M40 10 L74 -78" stroke="#A8693A" stroke-width="5" stroke-linecap="round"/><path d="M70 -80 L90 -76 L84 -66 L66 -70Z" fill="#9AA3B5"/>
      <path d="M-30 0 C-30 -30 -18 -44 0 -44 C18 -44 30 -30 30 0Z" fill="url(#g-blue)"/>
      <circle cx="0" cy="-58" r="17" fill="#FFE0C2"/>
      <path d="M-8 -58 q3 2 6 0 M3 -58 q3 2 6 0" stroke="#2A2230" stroke-width="2" fill="none" stroke-linecap="round"/>
      <ellipse cx="-9" cy="-52" rx="3.5" ry="2" fill="#FF8597" opacity=".6"/><ellipse cx="10" cy="-52" rx="3.5" ry="2" fill="#FF8597" opacity=".6"/>
      <ellipse cx="0" cy="-74" rx="30" ry="7" fill="url(#g-gold)"/><path d="M-14 -76 C-12 -92 12 -92 14 -76Z" fill="url(#g-gold)"/>
      ${full ? `<text x="26" y="-82" font-family="Nunito" font-weight="900" font-size="16" fill="#3D8BF2">z</text><text x="38" y="-96" font-family="Nunito" font-weight="900" font-size="20" fill="#3D8BF2">z</text>` : ''}
    </g></svg>`;
}
function scrIdiomPick() {
  let svg = `<rect width="${W}" height="${H}" fill="#1E5B6B"/><rect width="${W}" height="${H}" fill="url(#g-glow)" opacity=".18"/>
    <g fill="#2B7480" opacity=".7"><path d="M60 140 L100 110 L140 140 V200 H60Z"/><path d="M50 140 H150 L100 104Z"/><path d="M680 120 L720 90 L760 120 V200 H680Z"/><path d="M670 120 H770 L720 84Z"/></g>
    ${[0, 1, 2].map(i => `<path d="M0 ${330 + i * 22} ${Array.from({ length: 15 }, (_, k) => `C${k * 60 + 20} ${300 + i * 22} ${k * 60 + 40} ${300 + i * 22} ${k * 60 + 60} ${330 + i * 22}`).join(' ')} V390 H0Z" fill="${['#2E8C8A', '#3BA39A', '#2A6E86'][i]}"/>`).join('')}
    ${[0, 1, 2].map(i => `<path d="M0 ${330 + i * 22} ${Array.from({ length: 15 }, (_, k) => `C${k * 60 + 20} ${300 + i * 22} ${k * 60 + 40} ${300 + i * 22} ${k * 60 + 60} ${330 + i * 22}`).join(' ')}" stroke="#E8C98A" stroke-width="2" fill="none" opacity=".6"/>`).join('')}
    <circle cx="422" cy="170" r="134" fill="url(#g-glow)" opacity=".45"/>`;
  const medal = (cx, cy, r, inner, lockd) => `<div class="medal ${lockd ? 'lock' : ''}" style="left:${cx - r}px;top:${cy - r}px;width:${r * 2}px;height:${r * 2}px">${inner}${lockd ? `<span class="lk">${IC.lock('#fff', 30)}</span>` : ''}</div>`;
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    ${medal(150, 168, 82, idiomArt('m1', 164, 164, false), false)}
    ${medal(422, 158, 118, idiomArt('m2', 236, 236, false), false)}
    ${medal(694, 168, 82, idiomArt('m3', 164, 164, true), true)}
    <div class="plaque sm" style="left:84px;top:264px">揠苗助长</div>
    <div class="plaque" style="left:322px;top:290px">守株待兔</div>
    <div class="plaque sm lock" style="left:628px;top:264px">亡羊补牢</div>
    <div class="tag-now" style="left:330px;top:40px">正在学</div>
    ${pet('dragon', 108, { cls: 'bob abs', style: 'left:214px;top:180px' })}
    <button type="button" class="topicon" style="left:704px;top:6px">${dockIcon('idiom', 44)}${olabel('成语册 12', {})}</button>
    <button type="button" class="topicon" style="left:768px;top:6px">${dockIcon('task', 44)}${olabel('收藏', {})}</button>
    <div class="note dark" style="left:40px;top:346px">左右滑动换成语 · 每个约 2 分钟动画</div>`;
}
function scrIdiomPlay() {
  return `<div class="bg">${idiomArt('ip', W, H, true)}</div>
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon" style="left:104px;top:14px;width:220px">守株待兔 · 3/4</div>
    ${cbtn(IC.pause, { left: 752, top: 16 })}
    <div class="chapters" style="left:420px;top:24px">${['种田', '兔撞树', '天天等', '田荒了'].map((t, i) => `<span class="${i === 2 ? 'on' : i < 2 ? 'done' : ''}">${t}</span>`).join('')}</div>
    <div class="subtitle" style="left:120px;top:322px">农夫放下锄头,天天守在树桩旁,等着再捡兔子……</div>
    <div class="ideacard" style="left:600px;top:96px"><b>成语小卡</b><p>比喻死守经验、不知变通,也比喻想不劳而获。</p><span>出自《韩非子》</span></div>`;
}

/* ============ 绘本故事 ============ */
function scrStory() {
  const chars = [['小', 'xiǎo'], ['狐', 'hú'], ['狸', 'li'], ['低', 'dī'], ['头', 'tóu'], ['一', 'yí'], ['看', 'kàn'], [',', ''], ['月', 'yuè', 1], ['亮', 'liang', 1], ['掉', 'diào'], ['进', 'jìn'], ['水', 'shuǐ'], ['里', 'lǐ'], ['啦', 'la'], ['!', '']];
  let svg = `<rect width="${W}" height="${H}" fill="url(#g-night)"/>
    ${Array.from({ length: 26 }, (_, i) => `<circle cx="${(i * 97) % 844}" cy="${(i * 53) % 170 + 10}" r="${i % 3 ? 1.6 : 2.6}" fill="#fff" class="twinkle" style="animation-delay:${(i % 5) * .4}s"/>`).join('')}
    <circle cx="640" cy="80" r="40" fill="url(#g-gold)"/><circle cx="660" cy="68" r="36" fill="#1E2C60"/>
    <circle cx="640" cy="80" r="80" fill="url(#g-warmglow)" opacity=".25"/>
    <path d="M0 200 C100 170 220 180 300 196 C400 168 560 172 844 190 V390 H0Z" fill="#244A3E"/>
    <g fill="#1B3A30">${[60, 140, 760, 820].map((x, i) => `<path d="M${x} 210 L${x - 30} 210 L${x} ${120 + i * 10} L${x + 30} 210Z"/>`).join('')}</g>
    <ellipse cx="520" cy="300" rx="260" ry="62" fill="#2D5DA1"/><ellipse cx="520" cy="300" rx="260" ry="62" fill="none" stroke="#5C8FD6" stroke-width="4"/>
    <g class="wobble"><ellipse cx="560" cy="304" rx="26" ry="9" fill="#FFE58A" opacity=".85"/></g>
    <path d="M300 300 q12 -4 24 0 M640 330 q12 -4 24 0" stroke="#9CC0F2" stroke-width="3" fill="none" stroke-linecap="round" opacity=".7"/>
    ${Array.from({ length: 7 }, (_, i) => `<circle cx="${180 + i * 90}" cy="${150 + (i % 3) * 30}" r="3.5" fill="#FFF59A" class="twinkle" style="animation-delay:${i * .3}s"/>`).join('')}`;
  svg += `<g transform="rotate(12 300 290)">${petAt('fox', 300, 292, 150)}</g>`;
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon blue" style="left:104px;top:14px;width:250px">小狐狸找月亮 · 3/8</div>
    <button type="button" class="pybtn" style="left:690px;top:20px">拼音 开</button>
    <div class="storytext" style="left:104px;top:288px">${chars.map(([c, p, hl]) => `<ruby class="${hl ? 'hl' : ''}">${c}<rt>${p}</rt></ruby>`).join('')}</div>
    <button type="button" class="btn orange" style="left:640px;top:300px;width:160px">${IC.speaker('#fff', 22)} 读给我听</button>`;
}

/* ============ 课外书屋 ============ */
function scrReading() {
  const spines = ['#FF6F61', '#3D8BF2', '#5FC23E', '#FFC93C', '#8F72F2', '#FF9FB0', '#3FB8E3'];
  let svg = `<rect width="${W}" height="${H}" fill="#E9B27A"/>
    <g stroke="#D3975B" stroke-width="3">${Array.from({ length: 14 }, (_, i) => `<path d="M${i * 64} 0 V390"/>`).join('')}</g>
    <g filter="url(#f-sh)"><circle cx="110" cy="130" r="62" fill="#8F5527"/><circle cx="110" cy="130" r="52" fill="url(#g-sky)"/><circle cx="84" cy="100" r="26" fill="url(#g-canopy)"/><circle cx="134" cy="160" r="30" fill="url(#g-canopy2)"/><path d="M110 78 V182 M58 130 H162" stroke="#8F5527" stroke-width="6"/></g>
    ${[60, 168].map(y => `<rect x="560" y="${y + 84}" width="250" height="12" rx="4" fill="url(#g-woodD)"/>${Array.from({ length: 14 }, (_, i) => `<rect x="${566 + i * 17}" y="${y + 84 - 54 - (i % 3) * 8}" width="14" height="${54 + (i % 3) * 8}" rx="3" fill="${spines[(i + y) % 7]}"/>`).join('')}`).join('')}
    <rect x="0" y="300" width="${W}" height="90" fill="url(#g-woodD)"/>`;
  svg += petAt('owl', 740, 372, 96, { cls: 'bob' });
  const books = [['神笔马良', 'g-coral', 68, '继续读'], ['七色花', 'g-blue', 20, '继续读'], ['大头儿子和小头爸爸', 'g-violet2', 0, '导读 5 分钟']];
  return `${bgSvg(svg)}
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="title-ribbon green" style="left:104px;top:14px;width:250px">课外书屋 · 快乐读书吧</div>
    <div class="grades" style="left:220px;top:72px">${['一', '二', '三', '四', '五', '六'].map((g, i) => `<button type="button" class="${i === 1 ? 'on' : ''}">${g}年级</button>`).join('')}</div>
    <div class="shelf" style="left:220px;top:116px">${books.map(([t, g, p, b]) => `<div class="book3d"><svg width="88" height="116" viewBox="0 0 88 116"><rect x="6" y="4" width="80" height="110" rx="6" fill="#E9DFCF"/><rect x="0" y="0" width="80" height="110" rx="6" fill="url(#${g})"/><rect x="0" y="0" width="10" height="110" rx="4" fill="#000" opacity=".15"/><rect x="16" y="14" width="56" height="44" rx="8" fill="#fff" opacity=".9"/>${S.starPath(44, 36, 12, '#FFC93C')}</svg><b>《${t}》</b><div class="bar"><i style="width:${p}%"></i></div><button type="button" class="${p ? 'go2' : ''}">${b}</button></div>`).join('')}</div>
    <div class="challenge" style="left:30px;top:200px"><b>本周阅读挑战</b><div class="dots">${[1, 1, 1, 0, 0].map(d => `<i class="${d ? 'on' : ''}"></i>`).join('')}</div><span>3/5 天 · 每天 15 分钟</span></div>`;
}

/* ============ 家长中心 ============ */
function scrParent() {
  const tabs = [['学习设置', '#fff', '#3D8BF2'], ['学习报告', '#FF7F6E'], ['时间管理', '#5DBB3C'], ['账户', '#FFA41B'], ['关于', '#8F72F2']];
  const row = (ic, name, ctl) => `<div class="prow"><span class="pic">${ic}</span><b>${name}</b><div class="ctl">${ctl}</div></div>`;
  const chips = (arr, on) => arr.map((t, i) => `<span class="chip ${i === on ? 'on' : ''}">${t}</span>`).join('');
  const week = [12, 18, 25, 20, 30, 16, 18];
  return `<div class="bg" style="background:linear-gradient(180deg,#5AA8EE,#7CC0F5)"></div>
    <svg class="bg" width="${W}" height="${H}">${S.cloud(780, 340, .8)}${S.cloud(60, 360, .6)}</svg>
    ${cbtn(IC.back, { left: 44, top: 16 })}
    <div class="ptabs" style="left:104px;top:14px">${tabs.map(([t, c, tc], i) => `<span style="background:${i ? c : '#fff'};color:${i ? '#fff' : tc}" class="${i ? '' : 'on'}">${t}</span>`).join('')}</div>
    <div class="ppanel" style="left:44px;top:62px">
      ${row('⏱', '每日学习时长', chips(['15 分', '20 分', '30 分', '45 分'], 2))}
      ${row('🚀', '识字速度', chips(['5 字/天', '10 字/天', '15 字/天'], 0))}
      ${row('👀', '护眼提醒', `<span class="tog on"><i></i></span><span class="hint">每 20 分钟休息一下</span>`)}
      ${row('📚', '教材版本', `<span class="hint strong">部编版 · 一年级上</span><span class="arrow">›</span>`)}
      ${row('🔒', '宠物商店消费', `<span class="tog on"><i></i></span><span class="hint">只能用学习金币,无真钱购买</span>`)}
    </div>
    <div class="report" style="left:560px;top:62px"><h4>本周报告</h4>
      <div class="kpi"><span><b>42</b>新认字</span><span><b>20</b>分钟/天</span><span><b>96%</b>正确率</span></div>
      <div class="chart">${week.map((v, i) => `<div><i style="height:${v * 3}px;${i === 6 ? 'background:linear-gradient(#FFC93C,#FF8A00)' : ''}"></i><small>${'一二三四五六日'[i]}</small></div>`).join('')}</div>
      <p>易错字:<b style="font-family:${KAI}">田 · 禾</b></p></div>
    <div class="note small" style="left:44px;top:356px">进入家长中心需先答一道题(如 12 × 3 = ?),防止孩子误入</div>`;
}

const SCREENS = [
  { id: 'pets', group: '01 视觉语言', title: '宠物家族', note: '把熊猫换成 7 只黏土风小伙伴:米团是开局伙伴,其余用学习赚的金币或连签/等级解锁。每只伙伴都有一个和学习挂钩的小技能。', render: scrPets },
  { id: 'map', group: '02 主线闯关', title: '首页 · 闯关地图', note: '横屏大场景:字块铺在弯曲小路上,已完成显示星星、当前关发光、宠物站在上面。蘑菇屋 = 宠物小屋、树洞 = 课外书屋、小火车 = 数学,底部是全部玩法入口。', render: scrMap },
  { id: 'l0', group: '02 主线闯关', title: '关卡 ① 玩 · 喂宠物', note: '每个字按 玩→认→练→写→说 五步。顶部深色药丸条可点(试试点「认」「写」),右上「古」打开字源卡。玩:听音,把对的包子拖给米团。', render: scrLesson, state: { step: 0, gu: false }, lesson: true },
  { id: 'l1', group: '02 主线闯关', title: '关卡 ② 认 · 看图识字', note: '左边插画里三座山峰用虚线描出「山」的形状,右边是田字格大字+拼音+读音,旁边是组词。', render: scrLesson, state: { step: 1, gu: false }, lesson: true },
  { id: 'gu', group: '02 主线闯关', title: '字源卡(点「古」)', note: '甲骨文 → 金文 → 小篆 → 楷书,一句话讲清造字道理。正式版的古文字字形需用权威字形库替换,图中是示意。', render: scrLesson, state: { step: 1, gu: true }, lesson: true },
  { id: 'l2', group: '02 主线闯关', title: '关卡 ③ 练 · 跳石头过河', note: '听读音跳到正确的字上,对岸是宝箱。干扰字选形近字(出/田),练的是真正的辨认。', render: scrLesson, state: { step: 2, gu: false }, lesson: true },
  { id: 'l3', group: '02 主线闯关', title: '关卡 ④ 写 · 笔顺描红', note: '星星是起笔点,手指演示当前笔画(动画),右侧笔顺列表高亮第几画。写对一遍点亮一个果子,三个果子过关。', render: scrLesson, state: { step: 3, gu: false }, lesson: true },
  { id: 'l4', group: '02 主线闯关', title: '关卡 ⑤ 说 · 小舞台跟读', note: '舞台+话筒,按住录音,语音评分后给星星。', render: scrLesson, state: { step: 4, gu: false }, lesson: true },
  { id: 'result', group: '02 主线闯关', title: '闯关结算', note: '光芒+宝箱打开+彩纸,奖励清单:金币、经验(升级进度)、宠物饼干、字卡收集。', render: scrResult },
  { id: 'checkin', group: '03 奖励与宠物', title: '每日签到 · 学习时长', note: '7 天签到,第 7 天大宝箱(神秘蛋);右侧今日学习时长环,10/20/30 分钟各一个宝箱,学满 20 分钟提醒护眼。', render: scrCheckin },
  { id: 'pethome', group: '03 奖励与宠物', title: '宠物小屋', note: '开心/饱饱/干净三个状态条,喂食用闯关得的饼干。学习让宠物成长、解锁形态(米团 Lv5 开花)。', render: scrPetHome },
  { id: 'shop', group: '03 奖励与宠物', title: '宠物商店', note: '货架展示 6 只可领养伙伴,部分用连签/等级解锁(灰色剪影)。只能用学习金币,没有真钱购买。', render: scrShop },
  { id: 'math', group: '04 趣味游戏', title: '数学 · 小火车口算', note: '车头举着算式,车厢装着答案,点对的车厢挂上去。计时+连对加成。', render: scrMath },
  { id: 'eng', group: '04 趣味游戏', title: '英语 · 单词气球', note: '听单词,戳中对应图片的气球。冰冰(企鹅)陪练。', render: scrEnglish },
  { id: 'animals', group: '05 幼儿 · 故事 · 成语 · 阅读', title: '幼儿 · 看图识动物', note: '农场大场景,点动物弹出字卡:汉字+拼音+英文+叫声。图鉴收集。', render: scrAnimals },
  { id: 'idiom', group: '05 幼儿 · 故事 · 成语 · 阅读', title: '成语动画 · 选择', note: '国风青绿夜色+海水纹,圆形画框转盘选成语,云宝(小龙)当解说。', render: scrIdiomPick },
  { id: 'idiomplay', group: '05 幼儿 · 故事 · 成语 · 阅读', title: '成语动画 · 播放', note: '分 4 幕播放,顶部是章节进度,底部字幕,右侧成语小卡。', render: scrIdiomPlay },
  { id: 'story', group: '05 幼儿 · 故事 · 成语 · 阅读', title: '睡前绘本', note: '夜景+拼音文字,朗读时高亮当前词。', render: scrStory },
  { id: 'reading', group: '05 幼儿 · 故事 · 成语 · 阅读', title: '课外书屋', note: '树洞书屋,按年级对应课本「快乐读书吧」必读书,带阅读进度和每周挑战。', render: scrReading },
  { id: 'parent', group: '06 家长', title: '家长中心', note: '学习设置 + 本周报告。保留原来的识字速度、每日目标,新增时长、护眼和消费开关。', render: scrParent }
];
