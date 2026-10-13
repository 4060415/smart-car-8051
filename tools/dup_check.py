# -*- coding: utf-8 -*-
"""全项目两两对话前缀比对：找出所有共享前 N 步的会话对，量化重复 token。"""
import json, io, os

CACHE = os.path.join(os.path.expanduser("~"), ".dsh", "storages", "session_projcache", "sessions")
D = json.load(io.open(os.path.join(os.path.dirname(os.path.abspath(__file__)), "token_steps.json"), encoding="utf-8"))
SIDS = [s["sid"] for s in D["sessions"]]


def sig(sid):
    """每步的指纹 (turn, step, output)，用于判定两步是同一历史下的同一请求。"""
    o = json.load(io.open(os.path.join(CACHE, sid + ".json"), encoding="utf-8"))
    rq = ((o["record"]["rows"].get("contextTimeline", {}).get("val") or {}).get("requests")) or []
    rq = [q for q in rq if "prompt" in q]
    return [(q.get("turn"), q.get("step"), q.get("output")) for q in rq], rq


S = {}
for sid in SIDS:
    s, rq = sig(sid)
    S[sid] = (s, rq)

print("%-9s %-9s %6s %6s %14s %14s" % ("A", "B", "A步", "公共步", "A输入", "重复输入"))
total_dup = 0
seen = set()
for i, a in enumerate(SIDS):
    for b in SIDS[i + 1:]:
        sa, ra = S[a]
        sb, rb = S[b]
        m = 0
        for x, y in zip(sa, sb):
            if x == y:
                m += 1
            else:
                break
        if m < 20:          # 少于 20 步的巧合不算
            continue
        dup = sum(q["prompt"] for q in ra[:m])
        total_dup += dup
        print("%-9s %-9s %6d %6d %14d %14d" % (a[8:16], b[8:16], len(sa), m,
                                               sum(q["prompt"] for q in ra), dup))
print()
print("重复消费合计（按被重复的那一份计）: %d tokens" % total_dup)
print("项目总计(26会话口径)             : 1983014114")
print("重复占比                         : %.1f%%" % (100.0 * total_dup / 1983014114))
