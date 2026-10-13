# -*- coding: utf-8 -*-
"""Per-turn / per-step token audit for the 工程实践_迁移 workspace sessions.

Source: %USERPROFILE%\\.dsh\\storages\\session_projcache\\sessions\\<sid>.json
Record of interest: record.rows.contextTimeline.val.requests[]
Each element = one LLM request (one "step") with:
  prompt = total input tokens of that request, cacheRead, output, turn, step
"""
import json, io, os, datetime

CACHE = r"C:\Users\8Kinfe\.dsh\storages\session_projcache\sessions"

SIDS = [
    "session-6ebe08d6-c811-42f2-b5c5-2c01bbc06b0b",
    "session-6a719abf-df43-4ba0-ac40-644eab57a8da",
    "session-0be72792-0642-4e4d-94ae-4a0a7b08f0ef",
    "session-915f3600-f951-4ce3-be8c-bddc61fc025a",
    "session-b284b805-aa38-4cd5-9e6e-2f37c9a47d1e",
    "session-de7eca3a-fd2f-45d6-9c0d-99761b8d3033",
    "session-6a0877a9-91aa-46bd-a25a-18561ede0aa9",
    "session-7fc2ee62-735a-4b18-81b7-d9acda21fb12",
    "session-39c402ce-48d9-4c57-90ec-4c24453e83b6",
    "session-27310e4c-7bc0-45f1-bda2-e74371f1e8cf",
    "session-1d3f5224-1c69-4d75-9027-3b500262b089",
    "session-8d5efa7e-d14c-4b8f-92de-1bd08edf5548",
    "session-546c3655-4112-4f12-9c70-c03f11175aa3",
    "session-6eb77bba-a060-4e72-91dd-3701e25ec100",
    "session-23018133-411c-4282-9615-c2a323ce7ba9",
    "session-047139ca-4eb7-4bea-9d6e-99435540c545",
    "session-367856aa-8490-4588-8a8a-69c270077f0e",
    "session-3f10c9e1-f756-49da-8a54-f36bebc28c01",
    "session-ff037add-c751-4aab-8eca-6f6c3fdbbcce",
    "session-79b99d53-20a3-46c2-ab7c-3195886c809e",
    "session-97642b52-a8a8-4dab-a358-9c407202bfca",
    "session-a2bd088d-1416-4f0a-ad8b-a43f59b6df9f",
    "session-28894b31-838e-4655-a5af-45caea0c7ec9",
]


def load(sid):
    with io.open(os.path.join(CACHE, sid + ".json"), encoding="utf-8") as fh:
        return json.load(fh)


def rows(o):
    return o.get("record", {}).get("rows", {})


def build():
    out = []
    for sid in SIDS:
        o = load(sid)
        r = rows(o)
        tl = (r.get("contextTimeline", {}).get("val") or {})
        reqs = tl.get("requests") or []
        outline = (r.get("turnOutline", {}).get("val") or {})
        prompts = {t.get("turn"): (t.get("prompt") or "") for t in (outline.get("turns") or [])}
        timing = (tl.get("timing") or {})
        # group steps by turn
        turns = {}
        for q in reqs:
            t = q.get("turn", 1)
            g = turns.setdefault(t, {"turn": t, "steps": 0, "sysCost": 0, "cacheRead": 0,
                                     "output": 0, "worst": 0, "first": 0, "last": 0})
            g["steps"] += 1
            g["sysCost"] += q.get("prompt", 0)
            g["cacheRead"] += q.get("cacheRead", 0)
            g["output"] += q.get("output", 0)
            g["worst"] = max(g["worst"], q.get("prompt", 0))
            if g["first"] == 0:
                g["first"] = q.get("prompt", 0)
            g["last"] = q.get("prompt", 0)
        per = []
        for t in sorted(turns):
            g = turns[t]
            g["prompt"] = prompts.get(t, "")
            per.append(g)
        out.append({
            "sid": sid,
            "model": tl.get("model"),
            "days": sorted(((r.get("contextActivity", {}).get("val") or {}).get("days") or {}).keys()),
            "firstAt": reqs[0]["time"] if reqs else None,
            "lastAt": reqs[-1]["time"] if reqs else None,
            "requests": len(reqs),
            "turns": len(per),
            "wallMs": timing.get("wallMs"),
            "toolCalls": timing.get("toolCalls"),
            "toolsMs": timing.get("toolsMs"),
            "levels": {"assistant": reqs and sum(1 for q in reqs), "subagent": 0},
            "perTurn": per,
            "allSteps": [{"turn": q.get("turn"), "step": q.get("step"), "prompt": q.get("prompt", 0),
                          "cacheRead": q.get("cacheRead", 0), "output": q.get("output", 0),
                          "time": q.get("time")} for q in reqs],
        })
    return out


def main():
    data = build()
    grand = {"requests": 0, "sysCost": 0, "cacheRead": 0, "output": 0, "turns": 0, "toolCalls": 0}
    for s in data:
        grand["requests"] += s["requests"]
        grand["turns"] += s["turns"]
        grand["toolCalls"] += s["toolCalls"] or 0
        for g in s["perTurn"]:
            grand["sysCost"] += g["sysCost"]
            grand["cacheRead"] += g["cacheRead"]
            grand["output"] += g["output"]
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "token_steps.json")
    with io.open(out, "w", encoding="utf-8") as fh:
        json.dump({"grand": grand, "sessions": data}, fh, ensure_ascii=False, indent=1)
    print(json.dumps(grand))
    print("wrote", out)


if __name__ == "__main__":
    main()
