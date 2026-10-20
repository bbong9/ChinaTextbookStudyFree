/* 课本乐园 v2 · 黏土卡通风美术库(纯 SVG,无外部图片) */
const KAI = "'Kaiti SC','STKaiti','KaiTi','Noto Serif SC',serif";

function rg(id, stops, cx = .38, cy = .3, r = .78) {
  return `<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}">${stops.map(([o, c, op]) => `<stop offset="${o}" stop-color="${c}"${op != null ? ` stop-opacity="${op}"` : ''}/>`).join('')}</radialGradient>`;
}
function lg(id, stops, x2 = 0, y2 = 1) {
  return `<linearGradient id="${id}" x1="0" y1="0" x2="${x2}" y2="${y2}">${stops.map(([o, c, op]) => `<stop offset="${o}" stop-color="${c}"${op != null ? ` stop-opacity="${op}"` : ''}/>`).join('')}</linearGradient>`;
}

const DEFS = `<svg width="0" height="0" style="position:absolute" aria-hidden="true"><defs>
${lg('g-sky', [[0, '#5FCBF5'], [.55, '#9DE2FA'], [1, '#DDF6FF']])}
${lg('g-night', [[0, '#14204A'], [.6, '#2A3B78'], [1, '#41569A']])}
${lg('g-far', [[0, '#A6E5CB'], [1, '#6CC7A8']])}
${lg('g-hill1', [[0, '#BDF074'], [1, '#76CC3F']])}
${lg('g-hill2', [[0, '#9BE35C'], [1, '#5BB733']])}
${lg('g-hill3', [[0, '#7FD04F'], [1, '#48A22B']])}
${rg('g-canopy', [[0, '#C2F584'], [.55, '#6FC946'], [1, '#3F9C2B']])}
${rg('g-canopy2', [[0, '#90DD63'], [.6, '#4FAE36'], [1, '#2F7F24']])}
${lg('g-trunk', [[0, '#DFA36B'], [1, '#A8693A']], 1, 0)}
${rg('g-mush', [[0, '#FFA594'], [.55, '#F45A44'], [1, '#C4352A']], .4, .25, .85)}
${lg('g-stem', [[0, '#FFF9EE'], [1, '#EBD0A6']], 1, 0)}
${lg('g-cubeF', [[0, '#86E4EF'], [1, '#33AEC7']])}
${lg('g-cubeL', [[0, '#E4F6F8'], [1, '#BFE1E7']])}
${lg('g-cubeG', [[0, '#B4A8FF'], [1, '#7563E8']])}
${lg('g-cubeC', [[0, '#FFFFFF'], [1, '#BDF4FB']])}
${rg('g-gold', [[0, '#FFF6B8'], [.5, '#FFCD3C'], [1, '#E2900A']])}
${rg('g-coral', [[0, '#FFB9AB'], [.6, '#FF6F61'], [1, '#D5443A']])}
${rg('g-blue', [[0, '#9CD2FF'], [.6, '#3D8BF2'], [1, '#2366C9']])}
${rg('g-violet2', [[0, '#D9CCFF'], [.6, '#8F72F2'], [1, '#6448CC']])}
${rg('g-green2', [[0, '#C5F59B'], [.6, '#5FC23E'], [1, '#3C9128']])}
${rg('g-stone', [[0, '#FFFFFF'], [.6, '#ECE8F2'], [1, '#C5BED3']])}
${lg('g-water', [[0, '#86DBF6'], [1, '#3AA3DA']])}
${lg('g-wood', [[0, '#F4BD7C'], [1, '#C98443']])}
${lg('g-woodD', [[0, '#C98443'], [1, '#8F5527']])}
${lg('g-cream', [[0, '#FFFDF7'], [1, '#FFEFCF']])}
${rg('g-glow', [[0, '#FFFFFF', .95], [.45, '#C4F7FF', .6], [1, '#C4F7FF', 0]], .5, .5, .5)}
${rg('g-sunglow', [[0, '#FFF6BE', .95], [1, '#FFF6BE', 0]], .5, .5, .5)}
${rg('g-warmglow', [[0, '#FFE58A', .95], [1, '#FFE58A', 0]], .5, .5, .5)}
${rg('p-mt', [[0, '#FFFFFF'], [.5, '#FFF6E3'], [.85, '#F4DCB3'], [1, '#E3C08E']], .4, .32, .78)}
${rg('p-leaf', [[0, '#C9F58C'], [.6, '#6FCB45'], [1, '#3E9B2C']])}
${rg('p-fox', [[0, '#FFD7A0'], [.55, '#FF9A3C'], [1, '#DE6814']])}
${rg('p-cream', [[0, '#FFFFFF'], [.7, '#FFF8EE'], [1, '#EBDCC8']])}
${rg('p-white', [[0, '#FFFFFF'], [.6, '#F6F2EC'], [1, '#D9CEC0']])}
${rg('p-caramel', [[0, '#FBD39E'], [1, '#DD9548']])}
${rg('p-navy', [[0, '#7E95C9'], [.55, '#3D5089'], [1, '#253159']])}
${rg('p-orange', [[0, '#FFD27A'], [1, '#F08A12']])}
${rg('p-violet', [[0, '#D8C8FF'], [.55, '#9D7EF2'], [1, '#6B4FCB']])}
${rg('p-mint', [[0, '#D7FDF2'], [.55, '#86DFC7'], [1, '#3BB393']])}
${rg('p-lav', [[0, '#F0E6FF'], [1, '#B9A1F2']])}
${rg('p-egg', [[0, '#FFFFFF'], [.6, '#FFF3D9'], [1, '#E9CF9F']])}
${rg('p-pink', [[0, '#FFE9EE'], [.55, '#FFB6C4'], [1, '#EC8BA1']])}
${rg('p-yellow', [[0, '#FFF8B5'], [.55, '#FFDA3E'], [1, '#E7AA10']])}
${rg('p-red', [[0, '#FF9F92'], [.6, '#F2463A'], [1, '#B92A22']])}
<filter id="f-sh" x="-30%" y="-30%" width="160%" height="170%"><feDropShadow dx="0" dy="4" stdDeviation="4" flood-color="#1D3B53" flood-opacity=".22"/></filter>
<filter id="f-blur"><feGaussianBlur stdDeviation="8"/></filter>
<filter id="f-gray"><feColorMatrix type="saturate" values="0"/><feComponentTransfer><feFuncA type="linear" slope=".55"/></feComponentTransfer></filter>
</defs></svg>`;

/* ---------- 宠物通用部件 ---------- */
function eyes(l, r, y, s = 1) {
  return [l, r].map(x => `<ellipse cx="${x}" cy="${y}" rx="${6.3 * s}" ry="${7.8 * s}" fill="#2A2230"/><circle cx="${x + 2.1 * s}" cy="${y - 3.1 * s}" r="${2.7 * s}" fill="#fff"/><circle cx="${x - 1.7 * s}" cy="${y + 2.8 * s}" r="${1.2 * s}" fill="#fff" opacity=".9"/>`).join('');
}
function blush(l, r, y) {
  return `<ellipse cx="${l}" cy="${y}" rx="7.5" ry="4.5" fill="#FF8597" opacity=".5"/><ellipse cx="${r}" cy="${y}" rx="7.5" ry="4.5" fill="#FF8597" opacity=".5"/>`;
}
function mouth(cx, y, open = true) {
  return open
    ? `<path d="M${cx - 7} ${y} Q${cx} ${y + 11} ${cx + 7} ${y} Q${cx} ${y + 2} ${cx - 7} ${y}Z" fill="#B93A4A"/><path d="M${cx - 4} ${y + 5} Q${cx} ${y + 9} ${cx + 4} ${y + 5} Q${cx} ${y + 3} ${cx - 4} ${y + 5}Z" fill="#FF8C93"/>`
    : `<path d="M${cx - 6} ${y} Q${cx - 3} ${y + 4} ${cx} ${y} Q${cx + 3} ${y + 4} ${cx + 6} ${y}" stroke="#2A2230" stroke-width="2.6" fill="none" stroke-linecap="round"/>`;
}
const spec = (cx, cy, rx = 13, ry = 6, rot = -28, op = .65) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" transform="rotate(${rot} ${cx} ${cy})" fill="#fff" opacity="${op}"/>`;
const BODY = 'M60 32 C90 32 106 54 106 80 C106 106 86 118 60 118 C34 118 14 106 14 80 C14 54 30 32 60 32Z';
const shadow = (cx = 60, cy = 123, rx = 32) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="5.5" fill="#173A2A" opacity=".2"/>`;
const feet = (fill) => `<ellipse cx="44" cy="115" rx="12" ry="7.5" fill="${fill}"/><ellipse cx="76" cy="115" rx="12" ry="7.5" fill="${fill}"/>`;

const PET_ART = {
  mituan: (o) => `${shadow()}
    <ellipse cx="13" cy="86" rx="8" ry="13" transform="rotate(32 13 86)" fill="url(#p-mt)"/>
    <ellipse cx="107" cy="86" rx="8" ry="13" transform="rotate(-32 107 86)" fill="url(#p-mt)"/>
    ${feet('url(#p-mt)')}
    <path d="M60 36 L60 20" stroke="#4BA83A" stroke-width="4.5" stroke-linecap="round"/>
    <path d="M60 22 C50 9 35 11 31 20 C41 29 54 28 60 22Z" fill="url(#p-leaf)"/>
    <path d="M60 20 C70 5 87 7 91 16 C81 27 66 26 60 20Z" fill="url(#p-leaf)"/>
    ${o.bloom ? `<g transform="translate(60 14)">${[0, 72, 144, 216, 288].map(a => `<circle cx="${Math.cos(a * Math.PI / 180) * 7}" cy="${Math.sin(a * Math.PI / 180) * 7}" r="6" fill="#FFB3CF"/>`).join('')}<circle r="4.5" fill="#FFD23F"/></g>` : ''}
    <path d="${BODY}" fill="url(#p-mt)"/>
    ${spec(40, 50)}
    ${eyes(46, 74, 76)}${blush(32, 88, 90)}${mouth(60, 88, o.open !== false)}`,
  fox: () => `${shadow()}
    <path d="M94 104 C120 98 122 68 108 54 C104 74 96 84 84 92Z" fill="url(#p-fox)"/>
    <path d="M108 54 C117 63 120 76 117 86 C110 80 105 68 108 54Z" fill="#FFF8F0"/>
    <path d="M28 60 C20 38 24 20 33 13 C45 22 53 34 56 46Z" fill="url(#p-fox)"/>
    <path d="M92 60 C100 38 96 20 87 13 C75 22 67 34 64 46Z" fill="url(#p-fox)"/>
    <path d="M34 48 C31 36 33 27 36 22 C43 28 47 36 49 43Z" fill="#FFD0BE"/>
    <path d="M86 48 C89 36 87 27 84 22 C77 28 73 36 71 43Z" fill="#FFD0BE"/>
    ${feet('#E37419')}
    <path d="${BODY}" fill="url(#p-fox)"/>
    <path d="M18 84 C32 78 48 82 60 93 C72 82 88 78 102 84 C100 106 82 117 60 117 C38 117 20 106 18 84Z" fill="url(#p-cream)"/>
    ${spec(40, 50)}${eyes(45, 75, 70)}
    <ellipse cx="60" cy="88" rx="5.5" ry="4" fill="#2A2230"/>
    <path d="M54 95 Q57 99 60 95 Q63 99 66 95" stroke="#2A2230" stroke-width="2.4" fill="none" stroke-linecap="round"/>
    ${blush(32, 88, 86)}`,
  cat: () => `${shadow()}
    <path d="M100 104 C118 102 118 80 110 74" stroke="url(#p-caramel)" stroke-width="9" fill="none" stroke-linecap="round"/>
    <path d="M24 62 C20 44 22 26 28 18 C40 24 50 34 54 44Z" fill="url(#p-white)"/>
    <path d="M96 62 C100 44 98 26 92 18 C80 24 70 34 66 44Z" fill="url(#p-caramel)"/>
    <path d="M30 50 C28 38 30 30 32 26 C39 31 44 37 47 43Z" fill="#FFC6C2"/>
    ${feet('url(#p-white)')}
    <path d="${BODY}" fill="url(#p-white)"/>
    <path d="M70 36 C88 38 102 52 104 70 C94 74 80 70 74 58 C70 50 68 42 70 36Z" fill="url(#p-caramel)"/>
    ${spec(40, 50)}${eyes(45, 75, 74)}
    <path d="M56 84 L64 84 L60 89Z" fill="#FF8FA3"/>
    <path d="M60 89 Q56 95 51 92 M60 89 Q64 95 69 92" stroke="#2A2230" stroke-width="2.3" fill="none" stroke-linecap="round"/>
    <path d="M14 80 L30 83 M14 89 L30 88 M106 80 L90 83 M106 89 L90 88" stroke="#B7A898" stroke-width="2" stroke-linecap="round"/>
    ${blush(31, 89, 92)}`,
  penguin: () => `${shadow()}
    <ellipse cx="46" cy="117" rx="12" ry="6" fill="url(#p-orange)"/><ellipse cx="74" cy="117" rx="12" ry="6" fill="url(#p-orange)"/>
    <path d="M24 66 C10 74 8 92 16 98 C22 88 26 80 28 72Z" fill="url(#p-navy)"/>
    <path d="M96 66 C110 74 112 92 104 98 C98 88 94 80 92 72Z" fill="url(#p-navy)"/>
    <path d="M60 16 C88 16 102 42 102 74 C102 104 86 118 60 118 C34 118 18 104 18 74 C18 42 32 16 60 16Z" fill="url(#p-navy)"/>
    <path d="M60 40 C70 30 88 34 90 52 C92 72 86 100 60 110 C34 100 28 72 30 52 C32 34 50 30 60 40Z" fill="url(#p-cream)"/>
    ${spec(38, 32, 11, 5)}${eyes(48, 72, 62, .9)}
    <path d="M53 72 Q60 68 67 72 Q60 82 53 72Z" fill="url(#p-orange)"/>
    ${blush(40, 80, 76)}
    <path d="M28 88 Q60 102 92 88 L92 96 Q60 110 28 96Z" fill="url(#g-coral)"/>
    <path d="M78 98 L86 116 L76 116 L72 100Z" fill="url(#g-coral)"/>`,
  owl: () => `${shadow()}
    <path d="M28 46 L22 18 L48 36Z" fill="url(#p-violet)"/><path d="M92 46 L98 18 L72 36Z" fill="url(#p-violet)"/>
    <path d="M18 70 C6 82 8 100 18 104 C22 92 24 82 26 76Z" fill="#7D60D8"/><path d="M102 70 C114 82 112 100 102 104 C98 92 96 82 94 76Z" fill="#7D60D8"/>
    ${feet('url(#p-orange)')}
    <path d="${BODY}" fill="url(#p-violet)"/>
    <ellipse cx="60" cy="94" rx="24" ry="20" fill="url(#p-cream)"/>
    <path d="M50 90 l4 3 l4 -3 M62 90 l4 3 l4 -3 M56 99 l4 3 l4 -3" stroke="#C8B6F5" stroke-width="2" fill="none" stroke-linecap="round"/>
    <circle cx="44" cy="64" r="15" fill="#fff"/><circle cx="76" cy="64" r="15" fill="#fff"/>
    ${eyes(45, 75, 65, 1.05)}
    <path d="M55 74 L65 74 L60 82Z" fill="url(#p-orange)"/>
    ${blush(28, 92, 80)}
    <path d="M60 18 L86 28 L60 38 L34 28Z" fill="#3A2F5C"/><rect x="48" y="30" width="24" height="9" rx="3" fill="#3A2F5C"/>
    <path d="M84 29 L86 44" stroke="#FFC93C" stroke-width="2.5"/><circle cx="86" cy="46" r="3.5" fill="#FFC93C"/>`,
  dragon: () => `${shadow()}
    <path d="M22 66 C4 54 2 36 10 32 C16 44 24 50 32 54Z" fill="url(#p-lav)"/>
    <path d="M98 66 C116 54 118 36 110 32 C104 44 96 50 88 54Z" fill="url(#p-lav)"/>
    <path d="M40 40 C34 28 34 18 38 12 C44 20 48 28 50 36Z" fill="url(#g-gold)"/>
    <path d="M80 40 C86 28 86 18 82 12 C76 20 72 28 70 36Z" fill="url(#g-gold)"/>
    ${feet('url(#p-mint)')}
    <path d="${BODY}" fill="url(#p-mint)"/>
    <ellipse cx="60" cy="98" rx="24" ry="15" fill="url(#p-cream)"/>
    <g fill="#fff"><circle cx="52" cy="34" r="7"/><circle cx="62" cy="30" r="8"/><circle cx="71" cy="35" r="6"/></g>
    ${spec(38, 52)}${eyes(46, 74, 70)}
    <circle cx="56" cy="81" r="1.8" fill="#2A2230"/><circle cx="64" cy="81" r="1.8" fill="#2A2230"/>
    ${mouth(60, 86, false)}${blush(32, 88, 84)}`,
  egg: () => `${shadow(60, 123, 28)}
    <path d="M60 14 C84 14 98 52 98 78 C98 102 82 118 60 118 C38 118 22 102 22 78 C22 52 36 14 60 14Z" fill="url(#p-egg)"/>
    <ellipse cx="46" cy="48" rx="8" ry="7" fill="#8CC8FF"/><ellipse cx="74" cy="38" rx="5" ry="5" fill="#FFC93C"/>
    <ellipse cx="76" cy="90" rx="9" ry="8" fill="#FFB3D1"/><ellipse cx="42" cy="96" rx="5" ry="5" fill="#86D96A"/>
    <path d="M26 70 L38 62 L46 72 L56 62 L66 72 L76 62 L94 70" stroke="#C59C5E" stroke-width="3" fill="none" stroke-linejoin="round" stroke-linecap="round"/>
    ${spec(42, 30, 10, 5, -35)}
    <path d="M104 26 l2.5 6 6 2.5 -6 2.5 -2.5 6 -2.5 -6 -6 -2.5 6 -2.5Z" fill="#FFD23F"/>
    <path d="M14 44 l2 4.5 4.5 2 -4.5 2 -2 4.5 -2 -4.5 -4.5 -2 4.5 -2Z" fill="#FFD23F"/>`,
  duck: () => `${shadow(62, 123, 34)}
    <ellipse cx="50" cy="118" rx="10" ry="5" fill="url(#p-orange)"/><ellipse cx="74" cy="118" rx="10" ry="5" fill="url(#p-orange)"/>
    <path d="M104 78 L118 64 L112 86Z" fill="url(#p-yellow)"/>
    <ellipse cx="66" cy="90" rx="42" ry="28" fill="url(#p-yellow)"/>
    <ellipse cx="78" cy="88" rx="18" ry="12" transform="rotate(-15 78 88)" fill="#FFE97A"/>
    <circle cx="46" cy="52" r="27" fill="url(#p-yellow)"/>
    ${spec(36, 36, 9, 5)}
    <ellipse cx="22" cy="60" rx="14" ry="7" fill="url(#p-orange)"/>
    ${eyes(38, 56, 48, .8)}${blush(30, 62, 60)}`,
  pig: () => `${shadow()}
    <path d="M26 50 C20 34 24 24 30 22 C38 28 44 36 46 44Z" fill="url(#p-pink)"/>
    <path d="M94 50 C100 34 96 24 90 22 C82 28 76 36 74 44Z" fill="url(#p-pink)"/>
    ${feet('#EC8BA1')}
    <path d="${BODY}" fill="url(#p-pink)"/>
    ${spec(40, 50)}${eyes(44, 76, 70)}
    <ellipse cx="60" cy="88" rx="15" ry="11" fill="#FF9DB2"/>
    <ellipse cx="55" cy="88" rx="2.6" ry="3.6" fill="#B24E68"/><ellipse cx="65" cy="88" rx="2.6" ry="3.6" fill="#B24E68"/>
    ${blush(28, 92, 88)}`,
  sheep: () => `${shadow()}
    <rect x="38" y="100" width="12" height="20" rx="6" fill="#5B4A55"/><rect x="70" y="100" width="12" height="20" rx="6" fill="#5B4A55"/>
    <g fill="url(#p-white)">${[[30, 56], [52, 42], [76, 44], [94, 60], [100, 82], [88, 102], [62, 108], [36, 102], [20, 82], [60, 76]].map(([x, y]) => `<circle cx="${x}" cy="${y}" r="20"/>`).join('')}</g>
    <ellipse cx="30" cy="66" rx="12" ry="6" transform="rotate(-25 30 66)" fill="#6B5864"/>
    <ellipse cx="90" cy="66" rx="12" ry="6" transform="rotate(25 90 66)" fill="#6B5864"/>
    <ellipse cx="60" cy="76" rx="22" ry="25" fill="#FBE6D6"/>
    ${eyes(51, 69, 74, .75)}${mouth(60, 88, false)}
    <ellipse cx="46" cy="86" rx="5" ry="3" fill="#FF8597" opacity=".5"/><ellipse cx="74" cy="86" rx="5" ry="3" fill="#FF8597" opacity=".5"/>
    <g fill="#fff"><circle cx="50" cy="52" r="10"/><circle cx="62" cy="48" r="11"/><circle cx="72" cy="54" r="9"/></g>`
};
const PET_NAME = { mituan: '米团', fox: '阿橘', cat: '奶糖', penguin: '冰冰', owl: '博博', dragon: '云宝', egg: '神秘蛋' };

function pet(kind, size, o = {}) {
  const h = Math.round(size * 130 / 120);
  return `<svg class="${o.cls || ''}" width="${size}" height="${h}" viewBox="0 0 120 130" style="${o.style || ''}" aria-label="${PET_NAME[kind] || kind}" role="img"${o.filter ? ` filter="url(#${o.filter})"` : ''}>${PET_ART[kind](o)}</svg>`;
}
/* 在 SVG 场景里放宠物(x,y 为脚底中心) */
function petAt(kind, x, y, size, o = {}) {
  const s = size / 120;
  return `<g transform="translate(${x - size / 2} ${y - 123 * s}) scale(${s})"${o.filter ? ` filter="url(#${o.filter})"` : ''}><g class="${o.cls || ''}">${PET_ART[kind](o)}</g></g>`;
}

/* ---------- 场景部件 ---------- */
const S = {};
S.cloud = (x, y, s = 1, anim = 'drift') => `<g transform="translate(${x} ${y}) scale(${s})"><g class="${anim}">
  <ellipse cx="6" cy="24" rx="62" ry="10" fill="#C4E6FA" opacity=".7"/>
  <circle cx="-32" cy="8" r="20" fill="#fff"/><circle cx="-4" cy="-6" r="28" fill="#fff"/><circle cx="28" cy="4" r="22" fill="#fff"/><circle cx="50" cy="14" r="13" fill="#fff"/>
  <rect x="-52" y="6" width="114" height="20" rx="10" fill="#fff"/></g></g>`;
S.tree = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})">
  <ellipse cx="0" cy="2" rx="40" ry="8" fill="#2D6B1F" opacity=".25"/>
  <path d="M-12 2 C-9 -30 -8 -60 -6 -92 L6 -92 C8 -60 9 -30 12 2Z" fill="url(#g-trunk)"/>
  <circle cx="-36" cy="-98" r="32" fill="url(#g-canopy2)"/><circle cx="36" cy="-100" r="30" fill="url(#g-canopy2)"/>
  <circle cx="0" cy="-132" r="42" fill="url(#g-canopy)"/><circle cx="-24" cy="-108" r="30" fill="url(#g-canopy)"/><circle cx="26" cy="-110" r="30" fill="url(#g-canopy)"/>
  <ellipse cx="-14" cy="-152" rx="15" ry="8" fill="#fff" opacity=".35"/></g>`;
S.bush = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})">
  <circle cx="-22" cy="-14" r="18" fill="url(#g-canopy2)"/><circle cx="22" cy="-14" r="18" fill="url(#g-canopy2)"/><circle cx="0" cy="-24" r="24" fill="url(#g-canopy)"/>
  <rect x="-38" y="-16" width="76" height="16" rx="8" fill="url(#g-canopy2)"/><circle cx="-8" cy="-34" r="5" fill="#fff" opacity=".35"/></g>`;
S.flower = (x, y, c = '#FF8FB1', s = 1) => `<g transform="translate(${x} ${y}) scale(${s})">
  <path d="M0 0 C1 -8 -1 -14 0 -20" stroke="#4FAE34" stroke-width="2.5" fill="none"/><path d="M0 -8 C6 -12 10 -10 11 -7 C6 -5 3 -6 0 -8Z" fill="#5DBB3C"/>
  <g transform="translate(0 -24)">${[0, 72, 144, 216, 288].map(a => `<circle cx="${(Math.cos((a - 90) * Math.PI / 180) * 5.5).toFixed(1)}" cy="${(Math.sin((a - 90) * Math.PI / 180) * 5.5).toFixed(1)}" r="4.8" fill="${c}"/>`).join('')}<circle r="3.6" fill="#FFD23F"/></g></g>`;
S.tuft = (x, y, s = 1) => `<path transform="translate(${x} ${y}) scale(${s})" d="M0 0 C-2 -10 -8 -16 -12 -18 C-6 -12 -4 -6 -3 0Z M2 0 C2 -12 4 -20 8 -24 C6 -14 6 -6 6 0Z M7 0 C10 -8 14 -12 18 -13 C14 -8 12 -4 11 0Z" fill="#4AA932"/>`;
S.stone = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})"><ellipse cx="0" cy="0" rx="24" ry="11" fill="url(#g-stone)"/><ellipse cx="-6" cy="-4" rx="10" ry="3" fill="#fff" opacity=".7"/></g>`;
S.shroom = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})"><rect x="-6" y="-18" width="12" height="18" rx="5" fill="url(#g-stem)"/>
  <path d="M-20 -16 C-20 -34 -8 -40 0 -40 C8 -40 20 -34 20 -16 C10 -20 -10 -20 -20 -16Z" fill="url(#g-mush)"/><circle cx="-8" cy="-28" r="3.5" fill="#fff"/><circle cx="6" cy="-32" r="3" fill="#fff"/><circle cx="11" cy="-22" r="2.4" fill="#fff"/></g>`;
S.mushHouse = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})" filter="url(#f-sh)">
  <path d="M-50 0 C-48 -40 -44 -70 -40 -82 L40 -82 C44 -70 48 -40 50 0Z" fill="url(#g-stem)"/>
  <path d="M-16 0 L-16 -30 C-16 -44 16 -44 16 -30 L16 0Z" fill="url(#g-woodD)"/><circle cx="9" cy="-18" r="2.5" fill="#FFD23F"/>
  <circle cx="29" cy="-50" r="11" fill="#9A5E2B"/><circle cx="29" cy="-50" r="8" fill="#FFE59A"/>
  <path d="M-94 -70 C-94 -150 -40 -182 0 -182 C40 -182 94 -150 94 -70 C60 -82 -60 -82 -94 -70Z" fill="url(#g-mush)"/>
  <ellipse cx="0" cy="-74" rx="86" ry="10" fill="#F5D6B6"/>
  <g fill="#fff"><ellipse cx="-46" cy="-122" rx="16" ry="12"/><ellipse cx="8" cy="-150" rx="20" ry="14"/><ellipse cx="52" cy="-112" rx="15" ry="11"/><ellipse cx="-12" cy="-100" rx="10" ry="8"/><ellipse cx="-72" cy="-90" rx="8" ry="6"/></g>
  <ellipse cx="-30" cy="-158" rx="22" ry="8" transform="rotate(-20 -30 -158)" fill="#fff" opacity=".35"/></g>`;
S.cottage = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})" filter="url(#f-sh)">
  <rect x="-58" y="-90" width="116" height="90" rx="10" fill="url(#g-stem)"/>
  <path d="M-74 -84 C-60 -100 -20 -150 0 -154 C20 -150 60 -100 74 -84 C50 -92 -50 -92 -74 -84Z" fill="url(#p-fox)"/>
  <rect x="34" y="-160" width="16" height="40" rx="4" fill="#C5703A"/>
  <path d="M-14 0 L-14 -40 C-14 -56 14 -56 14 -40 L14 0Z" fill="url(#g-woodD)"/>
  <circle cx="-36" cy="-54" r="13" fill="#9A5E2B"/><circle cx="-36" cy="-54" r="10" fill="#9EDBF6"/><path d="M-36 -64 V-44 M-46 -54 H-26" stroke="#9A5E2B" stroke-width="2.5"/>
  <circle cx="36" cy="-54" r="13" fill="#9A5E2B"/><circle cx="36" cy="-54" r="10" fill="#9EDBF6"/><path d="M36 -64 V-44 M26 -54 H46" stroke="#9A5E2B" stroke-width="2.5"/>
  <ellipse cx="0" cy="-118" rx="10" ry="10" fill="#9EDBF6" stroke="#C5703A" stroke-width="4"/></g>`;
S.coin = (x, y, r = 12) => `<g transform="translate(${x} ${y})"><circle r="${r}" fill="#D98A0B"/><circle r="${r * .86}" cy="${-r * .08}" fill="url(#g-gold)"/>${S.starPath(0, -r * .06, r * .5, '#FFF3B0')}</g>`;
S.starPath = (cx, cy, r, fill, extra = '') => {
  let d = '';
  for (let i = 0; i < 10; i++) {
    const a = -Math.PI / 2 + i * Math.PI / 5, rr = i % 2 ? r * .48 : r;
    d += (i ? 'L' : 'M') + (cx + Math.cos(a) * rr).toFixed(1) + ' ' + (cy + Math.sin(a) * rr).toFixed(1);
  }
  return `<path d="${d}Z" fill="${fill}" stroke="${fill}" stroke-width="${r * .22}" stroke-linejoin="round" ${extra}/>`;
};
S.star = (cx, cy, r, on = true) => on
  ? `${S.starPath(cx, cy + r * .12, r, '#E08A00')}${S.starPath(cx, cy, r, 'url(#g-gold)')}<ellipse cx="${cx - r * .25}" cy="${cy - r * .3}" rx="${r * .22}" ry="${r * .12}" fill="#fff" opacity=".8"/>`
  : `${S.starPath(cx, cy + r * .12, r, '#B9C3CF')}${S.starPath(cx, cy, r, '#DCE3EC')}`;
S.gift = (x, y, s = 1) => `<g transform="translate(${x} ${y}) scale(${s})" filter="url(#f-sh)">
  <rect x="-26" y="-40" width="52" height="40" rx="8" fill="url(#g-coral)"/><rect x="-30" y="-50" width="60" height="16" rx="7" fill="#FF8A7D"/>
  <rect x="-6" y="-50" width="12" height="50" fill="url(#g-gold)"/>
  <path d="M0 -50 C-14 -70 -30 -62 -22 -52Z M0 -50 C14 -70 30 -62 22 -52Z" fill="url(#g-gold)"/>
  <ellipse cx="-16" cy="-28" rx="5" ry="9" fill="#fff" opacity=".35"/></g>`;
S.chest = (x, y, s = 1, open = false) => `<g transform="translate(${x} ${y}) scale(${s})" filter="url(#f-sh)">
  ${open ? `<ellipse cx="0" cy="-46" rx="70" ry="50" fill="url(#g-warmglow)"/>` : ''}
  <rect x="-40" y="-44" width="80" height="44" rx="8" fill="url(#g-wood)"/>
  <rect x="-40" y="-44" width="80" height="8" fill="#B87536"/>
  <rect x="-44" y="-46" width="10" height="46" rx="3" fill="url(#g-gold)"/><rect x="34" y="-46" width="10" height="46" rx="3" fill="url(#g-gold)"/>
  ${open
    ? `<path d="M-40 -46 L-36 -86 C-20 -96 20 -96 36 -86 L40 -46Z" fill="#7B4420"/>
       <g>${S.coin(-14, -52, 10)}${S.coin(8, -56, 11)}${S.coin(-2, -66, 9)}${S.coin(22, -48, 8)}</g>
       <path d="M-42 -86 C-24 -110 24 -110 42 -86 L38 -98 C20 -118 -20 -118 -38 -98Z" fill="url(#g-wood)"/>`
    : `<path d="M-42 -44 C-42 -74 42 -74 42 -44Z" fill="url(#g-wood)"/><rect x="-44" y="-62" width="10" height="18" rx="3" fill="url(#g-gold)"/><rect x="34" y="-62" width="10" height="18" rx="3" fill="url(#g-gold)"/>`}
  <rect x="-9" y="-52" width="18" height="18" rx="4" fill="url(#g-gold)"/><circle cx="0" cy="-44" r="3" fill="#8F5527"/></g>`;
S.butterfly = (x, y, c = '#FF9AC1') => `<g transform="translate(${x} ${y})"><g class="flutter"><ellipse cx="-6" cy="-3" rx="6" ry="8" fill="${c}"/><ellipse cx="6" cy="-3" rx="6" ry="8" fill="${c}"/><ellipse cx="-5" cy="6" rx="4" ry="5" fill="${c}" opacity=".8"/><ellipse cx="5" cy="6" rx="4" ry="5" fill="${c}" opacity=".8"/><rect x="-1.2" y="-6" width="2.4" height="14" rx="1.2" fill="#5B3A2A"/></g></g>`;
S.train = (x, y, s = 1, cars = [], engineSign = '') => {
  const wheel = (cx) => `<circle cx="${cx}" cy="0" r="13" fill="#3A3550"/><circle cx="${cx}" cy="0" r="6" fill="url(#g-gold)"/>`;
  let out = `<g transform="translate(${x} ${y}) scale(${s})">`;
  cars.forEach((c, i) => {
    const cx = -150 - i * 132;
    out += `<g filter="url(#f-sh)"><rect x="${cx - 58}" y="-62" width="118" height="56" rx="12" fill="url(#${c.grad || 'g-blue'})"/>
      <rect x="${cx - 50}" y="-70" width="102" height="12" rx="6" fill="#fff" opacity=".9"/>
      ${c.label != null ? `<rect x="${cx - 32}" y="-56" width="66" height="44" rx="12" fill="#FFFDF6"/><text x="${cx + 1}" y="-23" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="32" fill="${c.ink || '#2B3A55'}">${c.label}</text>` : ''}
      ${wheel(cx - 30)}${wheel(cx + 32)}<rect x="${cx + 58}" y="-24" width="20" height="6" rx="3" fill="#3A3550"/></g>`;
  });
  out += `<g filter="url(#f-sh)">
    <rect x="-80" y="-74" width="120" height="68" rx="14" fill="url(#g-coral)"/>
    <rect x="-84" y="-128" width="64" height="66" rx="12" fill="url(#g-coral)"/>
    <rect x="-90" y="-138" width="76" height="16" rx="8" fill="#B8392F"/>
    <rect x="-74" y="-118" width="44" height="32" rx="8" fill="#BFEAFF"/>
    <rect x="-6" y="-112" width="22" height="40" rx="6" fill="#3A3550"/><rect x="-12" y="-120" width="34" height="12" rx="6" fill="#3A3550"/>
    <path d="M40 -60 L70 -40 L70 -10 L40 -10Z" fill="url(#g-gold)"/>
    <circle cx="20" cy="-46" r="12" fill="#FFF3B0"/><circle cx="20" cy="-46" r="7" fill="#FFD23F"/>
    ${wheel(-52)}${wheel(10)}
    ${engineSign}</g></g>`;
  return out;
};
S.fence = (x1, x2, y) => {
  let o = `<rect x="${x1}" y="${y - 30}" width="${x2 - x1}" height="8" rx="4" fill="url(#g-wood)"/><rect x="${x1}" y="${y - 14}" width="${x2 - x1}" height="8" rx="4" fill="url(#g-wood)"/>`;
  for (let x = x1 + 8; x < x2; x += 34) o += `<path d="M${x - 6} ${y} L${x - 6} ${y - 38} L${x} ${y - 46} L${x + 6} ${y - 38} L${x + 6} ${y}Z" fill="url(#g-wood)"/>`;
  return o;
};

/* 平滑路线 */
function smoothPath(pts) {
  let d = `M${pts[0][0]} ${pts[0][1]}`;
  for (let i = 0; i < pts.length - 1; i++) {
    const p0 = pts[i - 1] || pts[i], p1 = pts[i], p2 = pts[i + 1], p3 = pts[i + 2] || p2;
    const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6];
    const c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
    d += ` C${c1[0].toFixed(1)} ${c1[1].toFixed(1)} ${c2[0].toFixed(1)} ${c2[1].toFixed(1)} ${p2[0]} ${p2[1]}`;
  }
  return d;
}

/* 地图上的 3D 字块 */
function cube(x, y, ch, state, stars = 0) {
  const W = 50, H = 42, D = 7;
  const face = { done: 'url(#g-cubeF)', cur: 'url(#g-cubeC)', lock: 'url(#g-cubeL)', game: 'url(#g-cubeG)' }[state];
  const side = { done: '#1F8EA6', cur: '#4CC8DC', lock: '#9CC9D2', game: '#5140B8' }[state];
  const ink = { done: '#0B4F5E', cur: '#0B4F5E', lock: '#7FAFB9', game: '#fff' }[state];
  let o = `<g transform="translate(${x} ${y})">`;
  if (state === 'cur') o += `<ellipse cx="0" cy="-14" rx="52" ry="40" fill="url(#g-glow)" class="pulse"/>`;
  o += `<ellipse cx="0" cy="${D + 2}" rx="29" ry="6" fill="#2C5E3A" opacity=".22"/>
    <rect x="${-W / 2}" y="${-H + D}" width="${W}" height="${H}" rx="12" fill="${side}"/>
    <rect x="${-W / 2}" y="${-H}" width="${W}" height="${H}" rx="12" fill="${face}"/>
    <rect x="-18" y="${-H + 4}" width="36" height="7" rx="3.5" fill="#fff" opacity=".45"/>`;
  if (state === 'game') o += `<g transform="translate(0 -20)" fill="#fff"><rect x="-13" y="-13" width="11" height="11" rx="3"/><rect x="2" y="-13" width="11" height="11" rx="3" opacity=".7"/><rect x="-13" y="2" width="11" height="11" rx="3" opacity=".7"/><rect x="2" y="2" width="11" height="11" rx="3"/></g>`;
  else o += `<text x="0" y="-10" text-anchor="middle" font-family="${KAI}" font-size="29" font-weight="700" fill="${ink}">${ch}</text>`;
  if (stars) for (let i = 0; i < 3; i++) o += S.star(-15 + i * 15, -H - 10 - (i === 1 ? 4 : 0), 6.5, i < stars);
  if (state === 'lock') o += `<g transform="translate(16 -36)"><circle r="8" fill="#fff" opacity=".9"/><rect x="-4" y="-2" width="8" height="6" rx="1.5" fill="#8AAAB6"/><path d="M-2.5 -2 V-4 a2.5 2.5 0 0 1 5 0 V-2" stroke="#8AAAB6" stroke-width="1.6" fill="none"/></g>`;
  return o + '</g>';
}

/* ---------- 图标 ---------- */
const OR = '#FF8A00', ORD = '#D66A00';
const IC = {
  back: `<svg width="30" height="30" viewBox="0 0 32 32"><g fill="none" stroke-linecap="round" stroke-linejoin="round" stroke-width="5.5"><g stroke="${ORD}" transform="translate(0 1.5)"><path d="M12 7 L5 14 L12 21"/><path d="M6 14 H18 C24 14 27 18 27 25"/></g><g stroke="${OR}"><path d="M12 7 L5 14 L12 21"/><path d="M6 14 H18 C24 14 27 18 27 25"/></g></g></svg>`,
  pause: `<svg width="26" height="26" viewBox="0 0 26 26"><rect x="5" y="4" width="6" height="19" rx="3" fill="${ORD}"/><rect x="15" y="4" width="6" height="19" rx="3" fill="${ORD}"/><rect x="5" y="3" width="6" height="18" rx="3" fill="${OR}"/><rect x="15" y="3" width="6" height="18" rx="3" fill="${OR}"/></svg>`,
  help: `<span class="ic-t" style="font-family:Nunito;font-weight:900;font-size:28px">?</span>`,
  gu: `<span class="ic-t" style="font-family:'ZCOOL KuaiLe';font-size:26px">古</span>`,
  left: `<svg width="26" height="26" viewBox="0 0 26 26"><path d="M17 5 L8 13 L17 21" stroke="${ORD}" stroke-width="5.5" fill="none" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 1.5)"/><path d="M17 5 L8 13 L17 21" stroke="${OR}" stroke-width="5.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  right: `<svg width="26" height="26" viewBox="0 0 26 26"><path d="M9 5 L18 13 L9 21" stroke="${ORD}" stroke-width="5.5" fill="none" stroke-linecap="round" stroke-linejoin="round" transform="translate(0 1.5)"/><path d="M9 5 L18 13 L9 21" stroke="${OR}" stroke-width="5.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  speaker: (c = OR, s = 26) => `<svg width="${s}" height="${s}" viewBox="0 0 26 26"><path d="M3 10 H8 L14 5 V21 L8 16 H3Z" fill="${c}" stroke="${c}" stroke-width="2" stroke-linejoin="round"/><path d="M17.5 9.5 C19.5 11.5 19.5 14.5 17.5 16.5 M20.5 6.5 C24 10 24 16 20.5 19.5" stroke="${c}" stroke-width="2.6" fill="none" stroke-linecap="round"/></svg>`,
  mic: (c = '#fff', s = 34) => `<svg width="${s}" height="${s}" viewBox="0 0 34 34"><rect x="11" y="3" width="12" height="19" rx="6" fill="${c}"/><path d="M6 15 C6 22 11 26 17 26 C23 26 28 22 28 15" stroke="${c}" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M17 26 V31 M11 31 H23" stroke="${c}" stroke-width="3" stroke-linecap="round"/></svg>`,
  redo: `<svg width="26" height="26" viewBox="0 0 26 26"><path d="M20 9 A8.5 8.5 0 1 0 21 16" stroke="${OR}" stroke-width="4" fill="none" stroke-linecap="round"/><path d="M21 3 V10 H14" stroke="${OR}" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>`,
  play: (c = '#fff', s = 22) => `<svg width="${s}" height="${s}" viewBox="0 0 22 22"><path d="M6 3.5 L18 11 L6 18.5Z" fill="${c}" stroke="${c}" stroke-width="2.5" stroke-linejoin="round"/></svg>`,
  close: `<svg width="20" height="20" viewBox="0 0 20 20"><path d="M5 5 L15 15 M15 5 L5 15" stroke="#fff" stroke-width="4" stroke-linecap="round"/></svg>`,
  heart: (s = 18) => `<svg width="${s}" height="${s}" viewBox="0 0 20 20"><path d="M10 17 C2 11 2 5 6 4 C8 3.5 9.5 5 10 6 C10.5 5 12 3.5 14 4 C18 5 18 11 10 17Z" fill="url(#g-coral)"/></svg>`,
  flame: (s = 20) => `<svg width="${s}" height="${s}" viewBox="0 0 20 20"><path d="M10 2 C12 6 16 8 16 12.5 C16 16 13 18.5 10 18.5 C7 18.5 4 16 4 12.5 C4 9.5 6 8 7 6 C7.5 8 8.5 9 9.5 9 C9.5 6 9 4 10 2Z" fill="#FF7A2E"/><path d="M10 10 C11 12 13 13 13 15 C13 17 11.5 18 10 18 C8.5 18 7 17 7 15 C7 13.5 8.5 12.5 10 10Z" fill="#FFD23F"/></svg>`,
  lock: (c = '#fff', s = 22) => `<svg width="${s}" height="${s}" viewBox="0 0 22 22"><rect x="4" y="9.5" width="14" height="10" rx="3" fill="${c}"/><path d="M7 10 V7 a4 4 0 0 1 8 0 V10" stroke="${c}" stroke-width="2.6" fill="none"/></svg>`
};
const coinSvg = (s = 24) => `<svg width="${s}" height="${s}" viewBox="-13 -13 26 26">${S.coin(0, 0, 12)}</svg>`;
const starSvg = (s = 24, on = true) => `<svg width="${s}" height="${s}" viewBox="-13 -13 26 27">${S.star(0, 0, 11, on)}</svg>`;

/* 地图底部入口的小插图(60×60) */
const DOCK = {
  hanzi: `${cube(30, 46, '字', 'done')}`,
  math: `<g transform="translate(34 50) scale(.36)">${S.train(0, 0, 1)}</g>`,
  eng: `<path d="M30 46 C28 50 32 54 30 58" stroke="#8B9AB0" stroke-width="1.5" fill="none"/><ellipse cx="30" cy="25" rx="18" ry="21" fill="url(#g-coral)"/><path d="M27 45 L33 45 L30 49Z" fill="#D5443A"/><text x="30" y="33" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="22" fill="#fff">A</text>${spec(22, 15, 5, 3, -30, .6)}`,
  animal: `<g transform="translate(2 4) scale(.46)">${PET_ART.duck()}</g>`,
  story: `<path d="M6 16 C16 12 24 13 30 18 L30 52 C24 47 16 46 6 50Z" fill="url(#g-blue)"/><path d="M54 16 C44 12 36 13 30 18 L30 52 C36 47 44 46 54 50Z" fill="url(#g-blue)"/><path d="M10 18 C18 15 24 16 29 20 L29 48 C24 44 18 43 10 46Z" fill="#FFFDF6"/><path d="M50 18 C42 15 36 16 31 20 L31 48 C36 44 42 43 50 46Z" fill="#FFF3DA"/>${S.starPath(20, 30, 6, '#FFC93C')}<circle cx="41" cy="30" r="6" fill="#FFB3A7"/>`,
  idiom: `<rect x="10" y="10" width="40" height="42" rx="6" fill="#F8EBCB"/><rect x="6" y="6" width="48" height="9" rx="4.5" fill="url(#g-woodD)"/><rect x="6" y="48" width="48" height="9" rx="4.5" fill="url(#g-woodD)"/><text x="30" y="42" text-anchor="middle" font-family="${KAI}" font-weight="700" font-size="26" fill="#B4352A">成</text>`,
  books: `<rect x="10" y="38" width="42" height="12" rx="3" fill="url(#g-coral)"/><rect x="14" y="26" width="36" height="12" rx="3" fill="url(#g-green2)"/><rect x="8" y="14" width="40" height="12" rx="3" fill="url(#g-violet2)"/><path d="M12 18 H40 M16 30 H44 M14 42 H46" stroke="#fff" stroke-width="2" opacity=".6"/>`,
  checkin: `<rect x="8" y="12" width="44" height="40" rx="9" fill="#FFFDF6"/><path d="M8 21 C8 16 12 12 17 12 H43 C48 12 52 16 52 21 V24 H8Z" fill="url(#g-coral)"/><rect x="18" y="6" width="5" height="12" rx="2.5" fill="#8F5527"/><rect x="37" y="6" width="5" height="12" rx="2.5" fill="#8F5527"/><path d="M20 38 L27 44 L41 30" stroke="#5FC23E" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>`,
  shop: `<rect x="10" y="26" width="40" height="28" rx="5" fill="#FFFDF6"/><path d="M6 16 H54 L52 28 C48 32 44 32 40 28 C36 32 32 32 30 28 C28 32 24 32 20 28 C16 32 12 32 8 28Z" fill="url(#g-coral)"/><path d="M18 16 L16 28 M30 16 V28 M42 16 L44 28" stroke="#fff" stroke-width="5" opacity=".9"/><rect x="24" y="36" width="12" height="18" rx="3" fill="url(#g-wood)"/>${IC.heart(12).replace('<svg', '<svg x="40" y="34"')}`,
  task: `<rect x="12" y="8" width="36" height="46" rx="6" fill="#FFFDF6"/><rect x="22" y="4" width="16" height="9" rx="4" fill="url(#g-gold)"/><path d="M19 22 l3 3 6 -6 M19 34 l3 3 6 -6" stroke="#5FC23E" stroke-width="3" fill="none" stroke-linecap="round"/><path d="M31 23 H41 M31 35 H41 M19 46 H41" stroke="#C9B9A0" stroke-width="3" stroke-linecap="round"/>`,
  parent: `<g transform="translate(30 30)"><circle r="20" fill="url(#g-blue)"/>${[0, 45, 90, 135, 180, 225, 270, 315].map(a => `<rect x="-5" y="-26" width="10" height="10" rx="3" fill="#3D8BF2" transform="rotate(${a})"/>`).join('')}<circle r="9" fill="#FFFDF6"/></g>`,
  pethouse: `<g transform="translate(30 56) scale(.3)">${S.mushHouse(0, 0, 1)}</g>`
};
const dockIcon = (k, s = 50) => `<svg width="${s}" height="${s}" viewBox="0 0 60 60" style="overflow:visible">${DOCK[k]}</svg>`;
