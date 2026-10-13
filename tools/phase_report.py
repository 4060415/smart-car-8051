# -*- coding: utf-8 -*-
"""阶段（phase）汇总：把 23 个会话按项目阶段归类并汇总 token。

阶段划分依据 = 每个会话首轮需求（turnOutline.turns[0].prompt）实测内容，不是猜测。
输出：docs/token消耗_分阶段.md
"""
import json, io, os, datetime

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
D = json.load(io.open(os.path.join(HERE, "token_steps.json"), encoding="utf-8"))

# phase -> list of (sid8, 干什么)
PHASES = [
    ("① 前期准备：硬件与工具链", [
        ("6ebe08d6", "焊好小车、USB 上电、装/清 Keil、跑通工具链"),
        ("6a719abf", "两个工作区合并（工程实践 → 工程实践_迁移）"),
        ("0be72792", "避障模块 + 遥控功能的初步检测方法"),
        ("915f3600", "开发前置准备：啃原理图、追引脚、列引脚表"),
        ("b284b805", "D5 发光二极管不亮的硬件排查"),
    ]),
    ("② 基础功能编写：遥控 / 超声 / 避障原型", [
        ("de7eca3a", "遥控解码程序：码值表核对、按键映射、跑通遥控"),
        ("6a0877a9", "超声波跟随小车小程序（红外避障原型）"),
    ]),
    ("③ 主程序编写与设计评审", [
        ("7fc2ee62", "绕开 Keil 2 KB 限额、程序体积核算、设计方案评审"),
        ("39c402ce", "同上延续（主开发长会话，111 轮）"),
    ]),
    ("④ C 版移植（汇编 → C51 等价移植）", [
        ("546c3655", "汇编转 .c 工程、逐函数带注释、模块拆分"),
        ("6eb77bba", "同上分支（原理讲解）"),
        ("23018133", "同上分支（移植修复收尾）"),
    ]),
    ("⑤ 基础功能联调与优化（①~⑥ 调参/上机）", [
        ("27310e4c", "六项基础功能上机联调：寻光、循迹、避障、转弯、刹车"),
        ("79b99d53", "手动模式按住前进步态 + 避障分级智能化讨论"),
    ]),
    ("⑥ 创新功能⑦录制 / ⑧回放", [
        ("8d5efa7e", "示教创新功能：设计冻结 → 端口分配 → 编码实现"),
    ]),
    ("⑦ 上机验证与 bug 排查", [
        ("047139ca", "烧录测试清单、遥控偶发失灵、跑着停车显示 0 排查"),
    ]),
    ("⑧ 文档与交付物（流程图 / 报告 / 体积账）", [
        ("367856aa", "程序流程图（word 黑白线框，对照最终程序）"),
        ("1d3f5224", "第二次作业《硬件设计与实现》实验报告"),
        ("3f10c9e1", "编译朋友的独立工程成 hex"),
        ("ff037add", "审计流程图与最终程序一致性"),
        ("97642b52", "skill/插件工作记录、进度汇报、烧录"),
    ]),
    ("⑨ 元工作：token 统计与工作区维护", [
        ("a2bd088d", "删原始资料省 token 的影响评估"),
        ("28894b31", "本次 token 消耗评估"),
    ]),
]

# 同目录下另外 3 个更早（09-07）的会话：workspace.json 未收录，但内容属于前期准备。
# 数据直接从 projcache 读，因为它们没有进入 token_steps.json。
EXTRA = [
    ("a4315c96-718a-4d68-b1b1-a27ee4c1220a", "① 前期准备（09-07 设计文档期）",
     "系统方案设计报告 + 系统功能图 + 系统硬件框图"),
    ("5f3bdc5f-9fe6-4827-8f87-5a44d460396a", "① 前期准备（09-07 设计文档期）",
     "拆解局部功能电路图 + 设计原理分析"),
    ("4c39cf1b-089e-4800-b059-e6fa5c72d4a5", "① 前期准备（09-07 设计文档期）",
     "系统功能模块 docx 素材整理"),
]


def extra_sessions():
    import glob
    CACHE = os.path.join(os.path.expanduser("~"), ".dsh", "storages", "session_projcache", "sessions")
    res = {}
    for sid, _, what in EXTRA:
        o = json.load(io.open(os.path.join(CACHE, "session-" + sid + ".json"), encoding="utf-8"))
        r = o["record"]["rows"]
        rq = (r.get("contextTimeline", {}).get("val") or {}).get("requests") or []
        rq = [q for q in rq if "prompt" in q]
        res[sid[:8]] = {
            "sid": "session-" + sid,
            "label": what,
            "turns": len(set(q.get("turn") for q in rq)),
            "steps": rq,
            "tools": None,
            "wallMs": ((r.get("contextTimeline", {}).get("val") or {}).get("timing") or {}).get("wallMs") or 0,
            "firstAt": rq[0]["time"] if rq else 0,
        }
    return res


EXTRA_S = extra_sessions()

by = {s["sid"][8:16]: s for s in D["sessions"]}
used = set()
for _, lst in PHASES:
    for sid, _ in lst:
        used.add(sid)
assert used == set(by), (set(by) - used, used - set(by))

# 把 EXTRA 并入“① 前期准备”
for sid8, ph, what in EXTRA:
    e = EXTRA_S[sid8[:8]]
    by[sid8] = {"sid": e["sid"], "turns": e["turns"], "requests": len(e["steps"]),
                "toolCalls": 0, "wallMs": e["wallMs"], "allSteps": e["steps"],
                "_extra": True}
    for name, lst in PHASES:
        if name.startswith("①"):
            lst.append((sid8, what + "（09-07，未列入 workspace.json）"))
            break

L = []
W = L.append


def f(n):
    return "{:,}".format(int(round(n)))


W("# Token 消耗评估（按项目阶段）—— 工程实践_迁移")
W("")
W("> **阶段划分方法**：不是按时间切，而是**按每个会话首轮需求的实际内容**归类")
W("> （`turnOutline.turns[0].prompt`，见 `tools/phase_report.py` 里的映射与理由）。")
W("> 数据源与口径同 `docs/token消耗评估.md`：**1 步 = 1 次 LLM 请求**，")
W("> 「输入合计」是该次请求携带的整段上下文，会被反复重发。")
W("")
W("> **范围**：`D:\\工程实践_迁移` 目录下全部 **8+15+3 = 26 个会话**（09-07 ~ 09-22）。")
W("> 其中 3 个 09-07 的设计文档期会话未被 `workspace.json` 收录，已在阶段① 中单独标注；")
W("> 阶段①~⑨ 的 23 个会话来自 `workspace.json`。")
W("")
W("## 总表")
W("")
W("| 阶段 | 会话 | 轮 | 步 | 工具 | 输入合计 | 未命中(全价) | 输出 | 占比 | 时长 |")
W("|---|---|---|---|---|---|---|---|---|---|")

tot = {"prompt": 0, "cr": 0, "out": 0, "req": 0, "turns": 0, "tools": 0, "wall": 0}
summary = []
for name, lst in PHASES:
    a = {"prompt": 0, "cr": 0, "out": 0, "req": 0, "turns": 0, "tools": 0, "wall": 0}
    for sid, _ in lst:
        s = by[sid]
        a["prompt"] += sum(q["prompt"] for q in s["allSteps"])
        a["cr"] += sum(q["cacheRead"] for q in s["allSteps"])
        a["out"] += sum(q["output"] for q in s["allSteps"])
        a["req"] += s["requests"]
        a["turns"] += s["turns"]
        a["tools"] += s["toolCalls"] or 0
        a["wall"] += s["wallMs"] or 0
    a["unc"] = a["prompt"] - a["cr"]
    summary.append((name, lst, a))
    for k in tot:
        tot[k] += a[k]
tot["unc"] = tot["prompt"] - tot["cr"]

for name, lst, a in sorted(summary, key=lambda x: -x[2]["prompt"]):
    W("| {} | {} | {} | {} | {} | **{}** | {} | {} | **{:.1f}%** | {:.0f} 分 |".format(
        name, len(lst), a["turns"], f(a["req"]), f(a["tools"]),
        f(a["prompt"]), f(a["unc"]), f(a["out"]),
        100.0 * a["prompt"] / tot["prompt"], a["wall"] / 60000.0))
W("| **合计** | **{}** | **{}** | **{}** | **{}** | **{}** | **{}** | **{}** | 100% | {:.0f} 分 |".format(
    sum(len(x[1]) for x in summary), tot["turns"], f(tot["req"]), f(tot["tools"]),
    f(tot["prompt"]), f(tot["unc"]), f(tot["out"]), tot["wall"] / 60000.0))
W("")

W("## 一句话读法")
W("")
top = sorted(summary, key=lambda x: -x[2]["prompt"])
W("- **最烧 token 的阶段是「{}」**，占 **{:.1f}%**（{} tokens）。".format(
    top[0][0], 100.0 * top[0][2]["prompt"] / tot["prompt"], f(top[0][2]["prompt"])))
W("- 前 3 个阶段合计占 **{:.1f}%**：{}".format(
    100.0 * sum(x[2]["prompt"] for x in top[:3]) / tot["prompt"],
    "、".join(x[0].split("：")[0] for x in top[:3])))
W("- **前期准备只占 {:.1f}%**（{} tokens）。它跨 09-07 与 09-17 两段，共 {} 个会话，".format(
    100.0 * [x for x in summary if x[0].startswith("①")][0][2]["prompt"] / tot["prompt"],
    f([x for x in summary if x[0].startswith("①")][0][2]["prompt"]),
    len([x for x in summary if x[0].startswith("①")][0][1])))
W("  但**这段上下文最短、会话最短**，所以单价最低——「准备得久」和「烧得多」不是一回事。")
W("- 贵的不是「哪件事难」，而是**这件事在多少个长会话里被反复继续**：")
W("  ③④⑤ 这几个阶段都是由 500~860 步的超长会话撑起来的。")
W("- ⚠️ **去掉重复重跑后，全项目真实量级是 {:.1f} 亿**（现在是 {:.1f} 亿）；".format(
    (tot["prompt"] - 460312910) / 1e8, tot["prompt"] / 1e8))
W("  而 **④ C 版移植去重后只有约 2.2 亿**（现在 4.2 亿）。详见下节「重复消费审计」。")
W("")

W("## 分阶段明细")
W("")
for name, lst, a in summary:
    W("### {} —— {} tokens（{:.1f}%）".format(name, f(a["prompt"]), 100.0 * a["prompt"] / tot["prompt"]))
    W("")
    W("轮 {} / 步 {} / 工具 {} / 未命中 {} / 输出 {} / 时长 {:.0f} 分".format(
        a["turns"], f(a["req"]), f(a["tools"]), f(a["unc"]), f(a["out"]), a["wall"] / 60000.0))
    W("")
    W("| 会话 | 干了什么 | 轮 | 步 | 输入合计 | 未命中 | 输出 |")
    W("|---|---|---|---|---|---|---|")
    for sid, what in sorted(lst, key=lambda x: -sum(q["prompt"] for q in by[x[0]]["allSteps"])):
        s = by[sid]
        p = sum(q["prompt"] for q in s["allSteps"])
        c = sum(q["cacheRead"] for q in s["allSteps"])
        o = sum(q["output"] for q in s["allSteps"])
        W("| `{}` | {} | {} | {} | {} | {} | {} |".format(sid, what, s["turns"], f(s["requests"]), f(p), f(p - c), f(o)))
    W("")

W("- ④ C 版移植的 4.2 亿里有 **48% 是重跑**：`546c3655` 的 515 步中有 482 步")
W("  与 `23018133` 的前 482 步 **完全一致**，546c3655 真正新增内容只有 33 步（542 万 tokens）。")
W("  该阶段**去重后的真实工作量约 2.2 亿**（按本阶段口径）。")
W("")
W("## 重复消费审计（重要）")
W("")
W("对 26 个会话做**两两逐步指纹比对**（指纹 = 轮号 + 步号 + 输出长度），")
W("凡步步相同即视为同一条对话被重跑。结果（脚本 `tools/dup_check.py`）：")
W("")
W("| 会话 A | 会话 B | A 的步数 | 公共前缀步数 | A 的输入合计 | **被重复消费的输入** |")
W("|---|---|---|---|---|---|")
W("| `7fc2ee62` | `39c402ce` | 607 | **565** | 245,964,944 | **230,434,633** |")
W("| `546c3655` | `23018133` | 515 | **482** | 203,467,642 | **198,040,625** |")
W("| `546c3655` | `6eb77bba` | 515 | 89 | 203,467,642 | 15,918,826 |")
W("| `6eb77bba` | `23018133` | 97 | 89 | 18,169,697 | 15,918,826 |")
W("")
W("**结论：重复消费合计 460,312,910 tokens ≈ 全项目的 23.2%。**")
W("")
W("具体是两条对话各自被跑了多遍：")
W("")
W("- **主开发对话**：`7fc2ee62`（79 轮）与 `39c402ce`（111 轮）**前 65 轮逐字相同**、")
W("  前 565 步完全一致 → `7fc2ee62` 的 94% 是 `39c402ce` 的子集。保留长的那条可省 **2.46 亿**。")
W("- **C 版移植对话**：`546c3655`（35 轮）与 `23018133`（27 轮）**前 27 轮逐字相同**、")
W("  482 步完全一致 → `546c3655` 的 97% 是 `23018133` 的子集。保留长的那条可省 **2.03 亿**。")
W("")
W("  拆开看这条 C 对话（逐段实测）：")
W("")
W("  | 部分 | 步数 | 输入合计 | 未命中 | 输出 |")
W("  |---|---|---|---|---|")
W("  | 两条共有的 482 步（重跑） | 482 | 198,040,625 | 323,121 | 608,413 |")
W("  | `546c3655` 真正新增的尾部 | 33 | 5,427,017 | 336,329 | 34,188 |")
W("  | `23018133` 真正新增 | 0 | 0 | 0 | 0 |")
W("")
W("  即：**4.2 亿的「C 版移植」里，真正的新增工作只有约 2.1 亿**，其余是同一段对话重跑。")
W("- `6eb77bba` 是这条 C 对话在第 89 步分出的短分支，与两者共享 89 步，")
W("  但保留了「怎么绕过 2 KB 限额」的口头解释，**有独立价值，不建议删**。")
W("")
W("⚠️ 机制说明：这不是模型在重复劳动，而是**同一条对话被先后完整重跑**——")
W("推测与 09-17 的工作区合并（会话 `6a719abf`）以及中途切换模型版本有关")
W("（同一序列里出现过 `deepseek-flash`、`deepseek-v4-flash`、`deepseek-v4-pro` 三种模型）。")
W("下次换模型 / 换工作区时，走**「继续同一会话」或 fork**，不要从头再喂一遍整段对话。")
W("")
W("## 附：口径与费用")
W("")
W("- 「输入合计」= 各次请求的 prompt 累加（含 99.5% 的缓存命中重发）；「未命中」才是全价计费部分。")
W("- 费用按 `deepseek-v4-flash` 工作日分时价估算：本次全量约 **$22**；")
W("  部分会话缺定价（如 `v4-flash-vision-exp`、`v4-pro`），按官方采样到的已计费下限为 **$17.0**。")
W("- 会话重跑会造成重复账，见上节「重复消费审计」（4.6 亿 / 23.2%）。")
W("")

out = os.path.join(ROOT, "docs", "token消耗_分阶段.md")
with io.open(out, "w", encoding="utf-8") as fh:
    fh.write("\n".join(L) + "\n")
print("wrote", out)
print("total prompt=%d unc=%d out=%d" % (tot["prompt"], tot["unc"], tot["out"]))
for name, lst, a in sorted(summary, key=lambda x: -x[2]["prompt"]):
    print("%-46s %14d  %5.1f%%" % (name, a["prompt"], 100.0 * a["prompt"] / tot["prompt"]))
