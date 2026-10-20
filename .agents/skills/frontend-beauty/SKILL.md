---
name: frontend-beauty
description: Makes product UI look designed, not AI-generic. Use on every frontend slice after tickets exist. Chains skillui (reference URL), oil-ui (directions), jakubkrehel better-* (polish), and optional scroll-world (cinematic landing).
---

# Frontend chiroy

Mahsulot kodi faqat tasdiqlangan TV-N dan keyin. Bu skill dizayn tartibi.

## Zanjir

1. **Reference URL** bo‘lsa — avval `skillui-design` (`DESIGN.md` / tokenlar). Taxminiy palitra yo‘q.
2. **oil-ui** — 2–3 haqiqatan farqli yo‘nalish (layout + tipografika + rang; ikkitasi bir xil ko‘rinmasin). Egaga solishtirib ko‘rsat. U tanlamaguncha “default SaaS” ga tushma.
3. Tanlangan yo‘nalishni qur. Generic hero / gray-on-white / bir xil card-grid taqiqlangan.
4. Qurilgach **better-interface** (yoki torroq: `better-ui`, `better-typography`, `better-colors`, `better-layout`, `better-accessibility`, `better-writing`). HIGH/MEDIUM ni shu slicedda tuzat.
5. **scroll-world** — faqat egasi kino/scroll-diorama landing so‘raganda. Monid/Higgsfield **pul**. Avval narxni ayt, eganing aniq «ha»sisiz clip generate qilma. `prefers-reduced-motion` majburiy.

## Qachon qaysi

| Holat | Skill |
|---|---|
| Saytga o‘xshasin | skillui, keyin oil-ui moslash |
| Yangi vizual til | oil-ui |
| Allaqachon UI bor, «chiroyliroq» | better-interface |
| Figma/skrin | build-design, keyin better-ui |
| Scroll orqali 3D dunyo | scroll-world + ega puli |

Kod yozib bo‘lgach 390 va 1440 da ko‘r. Oil UI va better-* ni o‘qimasdan UI yopma.
