#!/usr/bin/env python3
"""Setka ofis sahnasi — faqat localhost. bus + board + board/live."""
from __future__ import annotations

import json
import os
import re
import time
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

ROOT = Path(__file__).resolve().parent.parent
SCENE = Path(__file__).resolve().parent
BUS = Path(os.environ.get("BUS_DIR", str(Path.home() / "bus")))
HOST = os.environ.get("SETKA_SCENE_HOST", "127.0.0.1")
PORT = int(os.environ.get("SETKA_SCENE_PORT", "8765"))

ROLES = [
    "orchestrator",
    "backend",
    "frontend",
    "devops",
    "pentester",
    "qa",
]
LABELS = {
    "orchestrator": "Koordinator",
    "backend": "Backend",
    "frontend": "Frontend",
    "devops": "Devops",
    "pentester": "Pentester",
    "qa": "Tester",
}
JOBS = {
    "orchestrator": "Grill, ticket, parallel ish",
    "backend": "Django / DRF / Postgres / Redis",
    "frontend": "UI, oil-ui, better-interface",
    "devops": "Spec vs diff, CI",
    "pentester": "Gate — o‘zi tuzatmaydi",
    "qa": "Ishga tushiradi, bug yozadi",
}

MSG_RE = re.compile(
    r"\[MSG (?P<id>\S+)\]\s+\S+\s+(?P<from>\S+)\s+->\s+(?P<to>\S+)\s+\|\s+(?P<when>[^|]+)\|\s+(?P<subj>.+)"
)


def _read(p: Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except OSError:
        return ""


def tickets() -> list[dict]:
    out = []
    folder = ROOT / "board" / "tickets"
    if not folder.is_dir():
        return out
    for f in sorted(folder.glob("TV-*.md")):
        text = _read(f)
        meta = {}
        for line in text.splitlines():
            if ":" in line and line.split(":", 1)[0] in {
                "id",
                "title",
                "role",
                "column",
                "blocked_by",
                "ready_when",
                "sha",
            }:
                k, v = line.split(":", 1)
                meta[k] = v.strip()
            elif line.startswith("# "):
                break
        body = []
        grab = False
        for line in text.splitlines():
            if line.startswith("## "):
                grab = True
            if grab:
                body.append(line)
        out.append(
            {
                "id": meta.get("id", f.stem),
                "title": meta.get("title", f.stem),
                "role": meta.get("role", ""),
                "column": meta.get("column", "Backlog"),
                "blocked_by": meta.get("blocked_by", ""),
                "sha": meta.get("sha", ""),
                "body": "\n".join(body).strip()[:1200],
            }
        )
    return out


def live_doc(role: str) -> dict:
    p = ROOT / "board" / "live" / f"{role}.json"
    if not p.is_file():
        return {}
    try:
        data = json.loads(_read(p) or "{}")
        return data if isinstance(data, dict) else {}
    except json.JSONDecodeError:
        return {}


def presence_age(role: str) -> int | None:
    p = BUS / "presence" / role
    if not p.is_file():
        return None
    try:
        return max(0, int(time.time() - p.stat().st_mtime))
    except OSError:
        return None


def messages_for(role: str) -> list[dict]:
    found = []
    for box in ("inbox", "outbox"):
        text = _read(BUS / box / f"{role}.md")
        if not text:
            continue
        chunks = re.split(r"\n(?=\[MSG )", text)
        for ch in chunks[-12:]:
            m = MSG_RE.search(ch)
            if not m:
                continue
            sut = ""
            for line in ch.splitlines():
                if line.startswith("СУТЬ:") or line.startswith("SUT:"):
                    sut = line.split(":", 1)[-1].strip()
            found.append(
                {
                    "id": m.group("id"),
                    "from": m.group("from"),
                    "to": m.group("to"),
                    "when": m.group("when").strip(),
                    "subject": m.group("subj").strip(),
                    "summary": sut,
                    "box": box,
                }
            )
    found.sort(key=lambda x: x.get("when") or "", reverse=True)
    return found[:8]


def events(role: str | None = None) -> list[dict]:
    p = ROOT / "board" / "live" / "events.jsonl"
    if not p.is_file():
        return []
    rows = []
    for line in _read(p).splitlines()[-120:]:
        try:
            row = json.loads(line)
        except json.JSONDecodeError:
            continue
        if role and row.get("role") != role:
            continue
        rows.append(row)
    return list(reversed(rows[-40:]))


def handoff(role: str) -> str:
    text = _read(BUS / "handoffs" / f"{role}.md")
    if not text:
        text = _read(ROOT / "bus" / "handoffs" / f"{role}.md")
    return text.strip()[:1500]


def infer_state(role: str, age: int | None, tix: list[dict], live: dict) -> str:
    if live.get("state") in {"working", "waiting", "done", "blocked", "offline"}:
        return live["state"]
    if age is None or age > 900:
        return "offline"
    mine = [t for t in tix if t.get("role") == role]
    if any("Gate" in (t.get("column") or "") for t in mine) and role == "pentester":
        return "working"
    if any("Ishda" in (t.get("column") or "") for t in mine):
        return "working"
    if any("Done" in (t.get("column") or "") for t in mine) and not any(
        c in (t.get("column") or "") for t in mine for c in ("Ishda", "Gate", "Backlog")
    ):
        return "done"
    if age <= 900:
        return "waiting"
    return "offline"


def infer_now(role: str, tix: list[dict], live: dict, msgs: list[dict]) -> str:
    if live.get("now"):
        return str(live["now"])
    active = [
        t
        for t in tix
        if t.get("role") == role and any(x in (t.get("column") or "") for x in ("Ishda", "Gate"))
    ]
    if active:
        t = active[0]
        return f"{t['id']} · {t['title']} ({t['column']})"
    if msgs:
        m = msgs[0]
        return m.get("summary") or m.get("subject") or ""
    h = handoff(role)
    if h:
        return h.splitlines()[0][:160]
    return "Stolda. Ticket kutilyapti."


def pipeline(tix: list[dict], lives: dict) -> str:
    stages = [v.get("stage") for v in lives.values() if v.get("stage")]
    if stages:
        order = ["grill", "spec", "tickets", "build", "gate", "qa", "done"]
        present = [s for s in order if s in stages]
        if present:
            return present[-1] if "done" not in present else (
                "done" if all(s == "done" for s in stages) else present[-2] if len(present) > 1 else present[0]
            )
    cols = [t.get("column") or "" for t in tix]
    if any("Gate" in c for c in cols):
        return "gate"
    if any("Ishda" in c for c in cols):
        return "build"
    if any("Chiqarish" in c or "Prod" in c for c in cols):
        return "qa"
    if tix and all("Done" in (t.get("column") or "") for t in tix):
        return "done"
    if tix:
        return "tickets"
    return "grill"


def snapshot() -> dict:
    tix = tickets()
    lives = {r: live_doc(r) for r in ROLES}
    people = []
    for role in ROLES:
        age = presence_age(role)
        live = lives[role]
        msgs = messages_for(role)
        state = infer_state(role, age, tix, live)
        people.append(
            {
                "id": role,
                "label": LABELS[role],
                "job": JOBS[role],
                "state": state,
                "now": infer_now(role, tix, live, msgs),
                "ticket": live.get("ticket"),
                "stage": live.get("stage"),
                "updated": live.get("updated"),
                "alive": age is not None and age <= 900,
                "age_s": age,
                "tickets": [t for t in tix if t.get("role") == role],
                "messages": msgs,
                "events": events(role)[:12],
                "handoff": handoff(role),
            }
        )
    return {
        "pipeline": pipeline(tix, lives),
        "people": people,
        "tickets": tix,
        "events": events()[:30],
        "bus": str(BUS),
        "generated": time.strftime("%Y-%m-%dT%H:%M:%S"),
    }


def demo_snapshot() -> dict:
    data = snapshot()
    fake_now = {
        "orchestrator": "TV-004 ni backend va frontendga parallel yubordi",
        "backend": "TV-003 · DRF /auth/login, test yozilmoqda",
        "frontend": "oil-ui yo‘nalish 2: qabul qilingan. Login ekrani",
        "devops": "Spec vs diff: OpenAPI contract hali yo‘q",
        "pentester": "TV-002 sha 9f3c — Strix kutilyapti",
        "qa": "Stendni kutmoqda. TV-001 qabul mezoni tayyor",
    }
    fake_state = {
        "orchestrator": "working",
        "backend": "working",
        "frontend": "working",
        "devops": "waiting",
        "pentester": "blocked",
        "qa": "waiting",
    }
    for p in data["people"]:
        p["state"] = fake_state[p["id"]]
        p["now"] = fake_now[p["id"]]
        p["alive"] = True
        p["age_s"] = 12
        p["events"] = [
            {
                "t": data["generated"],
                "role": p["id"],
                "state": p["state"],
                "now": p["now"],
                "ticket": "TV-003" if p["id"] == "backend" else None,
            }
        ]
    data["pipeline"] = "build"
    data["events"] = [
        {
            "t": data["generated"],
            "role": p["id"],
            "state": p["state"],
            "now": p["now"],
            "ticket": p.get("ticket"),
            "stage": "build",
        }
        for p in data["people"]
    ]
    if not data["tickets"]:
        data["tickets"] = [
            {
                "id": "TV-001",
                "title": "Grill yakunlandi",
                "role": "orchestrator",
                "column": "Done",
                "blocked_by": "",
                "sha": "",
                "body": "",
            },
            {
                "id": "TV-003",
                "title": "Login API",
                "role": "backend",
                "column": "Ishda",
                "blocked_by": "",
                "sha": "",
                "body": "",
            },
            {
                "id": "TV-004",
                "title": "Login ekrani",
                "role": "frontend",
                "column": "Ishda",
                "blocked_by": "TV-003",
                "sha": "",
                "body": "",
            },
        ]
        for p in data["people"]:
            p["tickets"] = [t for t in data["tickets"] if t["role"] == p["id"]]
    return data


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(SCENE), **kwargs)

    def log_message(self, fmt: str, *args) -> None:
        sys_stderr = __import__("sys").stderr
        sys_stderr.write("%s - %s\n" % (self.address_string(), fmt % args))

    def end_headers(self) -> None:
        path = urlparse(self.path).path
        if path in {"/", "/index.html"} or path.endswith((".html", ".js", ".css")):
            self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path == "/api/live":
            demo = parse_qs(parsed.query).get("demo", ["0"])[0] in {"1", "true", "yes"}
            payload = demo_snapshot() if demo else snapshot()
            raw = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(raw)))
            self.end_headers()
            self.wfile.write(raw)
            return
        if parsed.path in {"/", "/index.html"}:
            self.path = "/index.html"
        return SimpleHTTPRequestHandler.do_GET(self)


def main() -> None:
    httpd = ThreadingHTTPServer((HOST, PORT), Handler)
    print(f"Setka ofis: http://{HOST}:{PORT}", flush=True)
    httpd.serve_forever()


if __name__ == "__main__":
    main()
