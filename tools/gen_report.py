# -*- coding: utf-8 -*-
"""Generate docs/token消耗评估.md from tools/token_steps.json."""
import json, io, os, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
D = json.load(io.open(os.path.join(HERE, "token_steps.json"), encoding="utf-8"))

OFF = {"input": 0.22, "cacheRead": 0.007, "output": 0.66}
PEAK = {"input": 0.44, "cacheRead": 0.014, "output": 1.32}


def band(ts):
    t = datetime.datetime.fromtimestamp(ts / 1000)
    if t.weekday() <= 4 and ((9 <= t.hour < 12) or (14 <= t.hour < 18)):
        return PEAK
    return OFF


def f(n):
    return "{:,}".format(int(round(n)))


def mm(n):
    return "{:.2f}".format(n / 1e6)


sessions = sorted(D["sessions"], key=lambda s: s["firstAt"] or 0)
L = []
W = L.append

# ---------- aggregates ----------
tot = {"prompt": 0, "cr": 0, "out": 0, "req": 0, "turns": 0, "tools": 0, "wall": 0}
for s in sessions:
    s["_prompt"] = sum(q["prompt"] for q in s["allSteps"])
    s["_cr"] = sum(q["cacheRead"] for q in s["allSteps"])
    s["_out"] = sum(q["output"] for q in s["allSteps"])
    tot["prompt"] += s["_prompt"]
    tot["cr"] += s["_cr"]
    tot["out"] += s["_out"]
    tot["req"] += s["requests"]
    tot["turns"] += s["turns"]
    tot["tools"] += s["toolCalls"] or 0
    tot["wall"] += s["wallMs"] or 0
tot["unc"] = tot["prompt"] - tot["cr"]

per_day = {}
peak_cost = 0.0
for s in sessions:
    for q in s["allSteps"]:
        d = datetime.datetime.fromtimestamp(q["time"] / 1000)
        day = d.strftime("%Y-%m-%d")
        a = per_day.setdefault(day, {"prompt": 0, "cr": 0, "out": 0, "req": 0, "unc": 0, "cost": 0.0})
        unc = q["prompt"] - q["cacheRead"]
        a["prompt"] += q["prompt"]
        a["cr"] += q["cacheRead"]
        a["out"] += q["output"]
        a["unc"] += unc
        a["req"] += 1
        r = band(q["time"])
        a["cost"] += (unc * r["input"] + q["cacheRead"] * r["cacheRead"] + q["output"] * r["output"]) / 1e6
        peak_cost += (unc * r["input"] + q["cacheRead"] * r["cacheRead"] + q["output"] * r["output"]) / 1e6

# ---------- report ----------
W("# Token 消耗评估 —— 工程实践_迁移")
W("")
W("> **数据源**：DSH 逐请求账本 `~/.dsh/storages/session_projcache/sessions/<sid>.json` 的")
W("> `record.rows.contextTimeline.val.requests[]`（**1 个元素 = 1 次 LLM 请求 = 1 个 step**），")
W("> 辅以 `contextActivity.days`（按天）、`turnOutline.turns[]`（轮）与")
W("> `~/.dsh/storages/usage-stats-cache.json`（官方定价与真实计费采样）。")
W(">")
W("> **统计范围**：工作区 `D:\\工程实践_迁移`（`workspace.json` 中 `7d4397f4-…`）的 23 个会话；")
W("> 时间为 UTC+8。生成脚本 `tools/token_steps.py`，原始数据 `tools/token_steps.json`。")
W("")
W("## 0. 口径（不看会误读数字）")
W("")
W("- **step（步）= 一次模型请求**。一轮（turn，你发一次话）里模型要「请求→调工具→再请求」很多次，")
W("  所以 514 轮对应 **5,544 步**，平均一轮 10.8 步。")
W("- **`prompt`（输入）是该次请求携带的全部上下文**：系统提示 + 28 个工具定义（实测 7,559 tokens）")
W("  + 全部历史消息。同一段上下文会被反复重发，所以**输入总量随步数被成倍放大**。")
W("- **`cacheRead`** = 其中命中前缀缓存的部分，单价约为未命中输入的 1/30。")
W("- **`uncached` = prompt − cacheRead`**，按全价计费的**真实新增输入**。")
W("- **`output`** = 模型生成量，含思考链与工具调用参数。")
W("- 下表「输入合计」是**按请求累加**的服务端输入量，**不等于「读了多少不重复的字」**。")
W("")
W("## 1. 总账")
W("")
W("| 指标 | 数值 |")
W("|---|---|")
W("| 会话数 | {:,} |".format(len(sessions)))
W("| 轮数 turn（人类发言） | {:,} |".format(tot["turns"]))
W("| **步数 step（LLM 请求）** | **{:,}** |".format(tot["req"]))
W("| 工具调用次数 | {:,} |".format(tot["tools"]))
W("| 输入合计（prompt，按请求累加） | **{:,}** （{:.0f} M） |".format(tot["prompt"], tot["prompt"] / 1e6))
W("| └ 其中命中缓存 cacheRead | {:,} （{:.1f} %） |".format(tot["cr"], 100.0 * tot["cr"] / tot["prompt"]))
W("| └ **未命中缓存 uncached（全价计费）** | **{:,}** （{:.1f} M） |".format(tot["unc"], tot["unc"] / 1e6))
W("| 输出合计 output | **{:,}** （{:.1f} M） |".format(tot["out"], tot["out"] / 1e6))
W("| 累计墙钟时长 | {:.1f} 小时 |".format(tot["wall"] / 3600000.0))
W("")
W("**一句话**：这个项目烧掉的不是「读完工程」的那点字，而是 **5,544 次请求每次都把同一份上下文重发一遍**。")
W("真实全价输入只有 **{:.1f} M**，但因为重发，服务端看到的输入是 **{:.0f} M**（放大 {:.0f} 倍）。".format(
    tot["unc"] / 1e6, tot["prompt"] / 1e6, tot["prompt"] / max(tot["unc"], 1)))
W("")
W("## 2. 按会话（时间顺序）")
W("")
W("| # | 会话 | 起止 | 模型 | 轮 | 步 | 工具 | 输入合计 | 缓存命中 | 未命中 | 输出 | 时长 |")
W("|---|---|---|---|---|---|---|---|---|---|---|---|")
for i, s in enumerate(sessions, 1):
    t0 = datetime.datetime.fromtimestamp(s["firstAt"] / 1000)
    t1 = datetime.datetime.fromtimestamp(s["lastAt"] / 1000)
    span = "%s→%s" % (t0.strftime("%m-%d %H:%M"), t1.strftime("%H:%M") if t0.date() == t1.date() else t1.strftime("%m-%d %H:%M"))
    W("| {} | `{}` | {} | {} | {} | {} | {} | {} | {} | **{}** | {} | {} 分 |".format(
        i, s["sid"][8:16], span, (s["model"] or "").replace("deepseek-", ""),
        s["turns"], f(s["requests"]), f(s["toolCalls"] or 0),
        f(s["_prompt"]), f(s["_cr"]), f(s["_prompt"] - s["_cr"]), f(s["_out"]),
        "{:.0f}".format((s["wallMs"] or 0) / 60000.0)))
W("")
W("> ⚠️ **分叉（fork）账**：`546c3655` / `23018133` / `6eb77bba` 三个会话在 09-20 23:38 由同一前缀分出，")
W("> 前 9 轮的步数、输出长度逐项一致；`7fc2ee62` 与 `39c402ce` 同样在 09-18 18:41 同源。")
W("> 分叉后两边各自续跑，同一段前缀的输入被**重付一遍**。按会话去重后，下面的总量大约要打 **8 折**。")
W("")
W("## 3. 按天")
W("")
W("| 日期 | 请求数 | 输入合计 | 未命中 | 输出 | 估算费用(USD) |")
W("|---|---|---|---|---|---|")
for day in sorted(per_day):
    a = per_day[day]
    W("| {} | {} | {} | {} | {} | {:.2f} |".format(day, f(a["req"]), f(a["prompt"]), f(a["unc"]), f(a["out"]), a["cost"]))
W("| **合计** | **{}** | **{}** | **{}** | **{}** | **{:.2f}** |".format(
    f(tot["req"]), f(tot["prompt"]), f(tot["unc"]), f(tot["out"]), peak_cost))
W("")
W("按官方 `deepseek-v4-flash` 工作日分时价（高峰 = 周一~五 09:00–12:00 / 14:00–18:00，")
W("输入 $0.44、缓存 $0.014、输出 $1.32 每 M；其余时段为低谷价 $0.22/$0.007/$0.66）估算。")
W("DSH 自带计费采样只覆盖了部分会话，得到 **$17.0** 的已计费下限；上表按全量 token 重算，量级一致。")
W("")
W("## 4. 每个步骤花了多少 —— 分布")
W("")
allst = []
for s in sessions:
    prev = None
    for q in s["allSteps"]:
        q2 = dict(q)
        q2["sid8"] = s["sid"][8:16]
        q2["delta"] = q["prompt"] if prev is None else q["prompt"] - prev
        prev = q["prompt"]
        allst.append(q2)
allst_sorted = sorted(allst, key=lambda q: q["prompt"])
n = len(allst_sorted)


def pct(p):
    return allst_sorted[min(n - 1, int(n * p))]


W("单步（1 次请求）的输入量分布（n={:,} 步）：".format(n))
W("")
W("| 分位 | 单步输入 tokens | 说明 |")
W("|---|---|---|")
for p, label in ((0.10, "P10 最轻"), (0.25, "P25"), (0.50, "P50 中位"), (0.75, "P75"), (0.90, "P90"), (0.99, "P99 最重")):
    q = pct(p)
    W("| {} | {} | 会话 `{}` 第 {} 轮第 {} 步 |".format(label, f(q["prompt"]), q["sid8"], q["turn"], q["step"]))
W("")
W("**关键结论：单步成本几乎完全由「这轮对话已经多长了」决定，而不是这一步干了什么。**")
W("")
W("- 单步 **中位 {} tokens**、**P99 {} tokens**：单步成本呈「长会话地板抬高」而不是尖峰。".format(
    f(pct(0.50)["prompt"]), f(pct(0.99)["prompt"])))
W("- 最直观的例子：`27310e4c` 第 37 轮从第 14 步到第 19 步，连续 6 次请求的输入都是 "
  "**78.9 万~79.2 万 tokens**——那是在**轮询/等待**，每轮询一次就为整段历史付一次全价。")
W("- 因此「哪一步贵」几乎不取决于这一步在干什么，只取决于**它排在一段多长的上下文后面**。")
W("- 单步**新增**上下文（本步 `prompt` 相对上一步的增量）平均仅 **{:,} tokens**，".format(
    round(sum(q["delta"] for q in allst) / n)) +
  "也就是说：**每步真正新增的信息量约 1k，但每步都要把整段上下文重发一遍**。")
W("")
W("## 5. 最贵的 15 轮（turn）")
W("")
rows = []
for s in sessions:
    for g in s["perTurn"]:
        rows.append((g["sysCost"], s["sid"][8:16], g["turn"], g["steps"], g["output"],
                     (g["prompt"] or "").replace("\n", " ")[:52]))
rows.sort(reverse=True)
W("| 输入合计 | 会话 | 轮 | 步数 | 输出 | 你的那句指令 |")
W("|---|---|---|---|---|---|")
for r in rows[:15]:
    W("| {} | `{}` | {} | {} | {} | {} |".format(f(r[0]), r[1], r[2], r[3], f(r[4]), r[5].replace("|", "/")))
W("")
W("## 6. 单步最贵的请求（上下文长度峰值）")
W("")
allst.sort(key=lambda q: -q["prompt"])
W("| 单步输入 | 会话 | 轮/步 | 输出 | 时间 |")
W("|---|---|---|---|---|")
for q in allst[:10]:
    W("| {} | `{}` | {}/{} | {} | {} |".format(
        f(q["prompt"]), q["sid8"], q["turn"], q["step"], f(q["output"]),
        datetime.datetime.fromtimestamp(q["time"] / 1000).strftime("%m-%d %H:%M")))
W("")
W("## 7. 为什么这么贵（三个放大器）")
W("")
W("1. **固定底盘大**：系统提示 + 28 个工具定义约 **9.3k tokens**（其中工具定义实测 **7,559**，")
W("   其中 `workflow` 一项 1001、`subagent_fork` 377、`pwsh` 1109）。**每一次请求都要重付这份底盘。**")
W("2. **长会话重发**：一亿 tokens 级的会话（`39c402ce` 863 步）平均每步上下文 **443k tokens**。")
W("   上下文一直不压缩，尾部的每一步都在为前面所有工作付费。")
W("3. **工具输出直接进上下文**：`pwsh`/`read`/`grep` 的原始输出没有自动摘要。")
W("   glob 全项目扫描、整份读 116 KB 的 `main.c`、读 29 KB 的 README —— 这些在 AGENTS.md 里")
W("   已被明令禁止，属于**可省而未省**的部分。")
W("")
W("## 8. 可操作的省钱项（按收益排序）")
W("")
W("| 措施 | 预期收益 |")
W("|---|---|")
W("| 长会话到 200~300 步就 `/compact` 或开新会话，别一路跑到 800+ 步 | 最大项。尾部长尾的每步成本 ∝ 全长 |")
W("| 严守 AGENTS.md 的搜索纪律：`glob` 只带 `firmware/` 前缀，不整份读 `main.c`/`README.md` | 减少单步上下文激增（P99 那类 790k 步骤）|")
W("| 把「一次性大输出」改成 `pwsh` 里先过滤/截断再回传 | 工具输出是上下文增长主来源 |")
W("| fork 会话要克制：`7fc2ee62`/`39c402ce` 这类同前缀双跑会整份重付 | 本次至少 2 份重复账 |")
W("| 轮询/等待型空转：`27310e4c` 第 37 轮 6 步共约 474 万 tokens，只产出 3k 输出 | 等一次 ≈ 付一次全上下文全价 |")
W("| 高频轻任务（改注释、跑构建）换更小模型/更低 effort | 输出单价敏感 |")
W("")
W("## 9. 明细附录")
W("")
W("完整逐会话 / 逐轮 / 逐步数据在 `tools/token_steps.json`（含每步 `prompt`/`cacheRead`/`output`/`turn`/`step`/时间戳）。")
W("")

out = os.path.join(ROOT, "docs", "token消耗评估.md")
with io.open(out, "w", encoding="utf-8") as fh:
    fh.write("\n".join([x for x in L if x is not None]))
print("wrote", out, len(L), "lines")
print("totals: req=%d prompt=%d unc=%d out=%d cost=%.2f" % (tot["req"], tot["prompt"], tot["unc"], tot["out"], peak_cost))
