---
name: graphify-first
description: Maps the repo with Graphify and answers from the graph instead of re-reading files. Use at session start, before large exploration, when context is full, or when asking where X is called.
---

# Graphify avval

Barcha rollar. Token tejash.

## Map

`graphify-out/graph.json` yo‘q yoki git HEAD ancha oldinda bo‘lsa:

```bash
# skill: npx skills add Graphify-Labs/graphify
# CLI:  uv tool install graphifyy && graphify install --platform cursor
```

Chatda `/graphify .` yoki CLI bilan joriy papkani map qil. Natija:

- `graphify-out/GRAPH_REPORT.md`
- `graphify-out/graph.json`
- `graphify-out/graph.html`

## So‘rash

«X qayerda chaqiladi, Y ni o‘zgartirsang nima sinadi» — avval graph.json/report. Grep/Read — aniq fayl kerak bo‘lganda.

Tencent Code-Graph MCP bor bo‘lsa, graphify dan keyin uni ham so‘ra. Ikkalasi o‘rnini bosmaydi: graphify mahalliy xarita, Tencent chuqur call-graph.

Har katta slice oxirida xaritani yangila.
