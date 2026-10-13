# -*- coding: utf-8 -*-
"""汇编/A51 文件在本项目里的真实 token 成本（修正 token 定标：非ASCII 3B/token，ASCII 4B/token）。

区分两笔账：
  1) 首次读入成本：文件被 read 进上下文的那一次，按全价计费。
  2) 驻留成本：读入后内容留在上下文里，随每个后续请求重发（按缓存价）。
     给两种口径：同轮剩余请求数（收紧）/ 本会话剩余请求数（上界）。
"""
import json, io, os, collections

CACHE = os.path.join(os.path.expanduser("~"), ".dsh", "storages", "session_projcache", "sessions")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
D = json.load(io.open(os.path.join(ROOT, "tools", "token_steps.json"), encoding="utf-8"))
SIDS = [s["sid"] for s in D["sessions"]]
EXTRA = ["session-a4315c96-718a-4d68-b1b1-a27ee4c1220a",
         "session-5f3bdc5f-9fe6-4827-8f87-5a44d460396a",
         "session-4c39cf1b-089e-4800-b059-e6fa5c72d4a5"]
STD = {"input": 0.44, "cacheRead": 0.014}


def toks(path):
    p = os.path.join(ROOT, path.replace("/", os.sep))
    if not os.path.exists(p):
        return None
    raw = open(p, "rb").read()
    txt = raw.decode("utf-8", "replace")
    na = sum(1 for ch in txt if ord(ch) > 127)
    return int(na / 3.0 + max(len(raw) - na * 3, 0) / 4.0)


T = {}
for sid in SIDS:
    T[sid] = [x for x in D["sessions"] if x["sid"] == sid][0]["allSteps"]

rows = collections.defaultdict(lambda: {"reads": 0, "first": 0, "turn": 0, "sess": 0, "tok": 0})
for sid in SIDS + EXTRA:
    p = os.path.join(CACHE, sid + ".json")
    if not os.path.exists(p):
        continue
    tl = (json.load(io.open(p, encoding="utf-8"))["record"]["rows"]
          .get("contextTimeline", {}).get("val") or {})
    ops = [x for x in (tl.get("fileOps") or [])
           if x.get("kind") == "read" and not x.get("err")]
    steps = T.get(sid)
    if steps is None:
        steps = [q for q in (tl.get("requests") or []) if "prompt" in q]
    seen = set()
    for op in ops:
        name = op["path"].replace("\\", "/").split("/")[-1].lower()
        if not (name.endswith((".asm", ".lst", ".m51")) or name == "config.h"):
            continue
        t = toks(op["path"])
        if not t:
            continue
        turn = None
        after_turn = after_sess = 0
        for q in steps:
            if q.get("time") and q["time"] > op["time"]:
                after_sess += 1
                if q.get("turn") == (op.get("turn") if op.get("turn") else q.get("turn")):
                    pass
        # 同轮剩余：取“读之后、turn 号等于读入所在 turn”的请求数
        rturn = None
        for q in steps:
            if q.get("time") and q["time"] > op["time"]:
                rturn = q.get("turn")
                break
        after_turn = sum(1 for q in steps
                         if q.get("time") and q["time"] > op["time"] and q.get("turn") == rturn)
        r = rows[name]
        r["reads"] += 1
        r["tok"] = t
        if name not in seen:
            r["first"] += t          # 每个会话首次读入按全价
            seen.add(name)
        r["turn"] += t * after_turn
        r["sess"] += t * after_sess

print("%-22s %5s %8s %12s %14s %14s" % ("文件", "读次数", "tokens", "首次全价(每个会话)", "驻留(同轮)", "驻留(会话上界)"))
tot = collections.Counter()
for name, r in sorted(rows.items(), key=lambda kv: -kv[1]["sess"]):
    print("%-22s %5d %8d %12d %14d %14d" % (
        name, r["reads"], r["tok"], r["first"], r["turn"], r["sess"]))
    for k in ("first", "turn", "sess"):
        tot[k] += r[k]
print()
print("合计: 首次全价 %d tokens, 同理驻留 %d, 会话驻留上界 %d" % (tot["first"], tot["turn"], tot["sess"]))
for label, key in (("首次全价（实测）", "first"), ("+ 同轮驻留（收紧）", "turn"), ("+ 会话驻留（上界）", "sess")):
    c = tot["first"] * STD["input"] / 1e6 + max(tot[key] - tot["first"], 0) * STD["cacheRead"] / 1e6
    print("  %-18s 费用 ≈ $%.2f" % (label, c))
