# AGENTS.md — 智能移动机器人（红外遥控动作录制与回放）

> **唯一工作区**：`D:\工程实践_迁移`。原工程 `D:\工程实践` 保留作回退，**别去那里改**。
> 本文件是给 agent 的**入口**。人看的完整手册是 `README.md`（29 KB）—— **别整份读**，按下表按需读。

## 项目是什么

STC89C52RC（8051）智能小车。工具链 Keil C51（`D:\keli`，**Eval 版，2048 B 硬上限**）。
两份固件并存：

- **汇编版**（基线，已冻结）：`firmware/car/car_asm.asm` + `firmware/car/config.h`
- **C 版**（★ 后续联调优化都在这里做）：`firmware/c51/main.c`（**116 KB，别整份读**）

功能 = 块①~⑧：电机 / 红外遥控 / 模式状态机 / 寻光 / 循迹 / 避障 + **⑦录制 ⑧回放**。

## ★ 搜索纪律（最重要 —— 省 token 的关键）

本工程 **2400 个文件 / 345 MB，真正的源码只有 `firmware/` 那 3.8 MB**。

- **`glob` 不读任何 ignore 文件**（代码里写死 `--no-ignore`），会把噪音全列出来。
  ⇒ **glob 必须带 `firmware/` 前缀**，如 `firmware/**/*.asm`。
  ⇒ **禁止** `glob **/*.h` 这类全项目扫描：会带出 `_toolchain_pkg/` 里几百个工具链头文件。
- **`grep` 读 `.ignore`（已配好）**，可以放心按目录搜。
- **不要读/搜**：`原始资料/`（只读原件）、`refs/`（派生素材）、`_toolchain_pkg/`、`现场照片/`、`Objects/`、`Listings/`。

## 按需读文档（不要整份读 README）

| 要干什么 | 读 |
|---|---|
| 权威状态 / 上机清单 | `docs/正式固件开发记录.md` |
| ★ 动核心代码前必读：C17 冻结基线的改动门槛 | `docs/C17冻结说明.md` |
| 编译 / 烧录 / 看串口速查 | `docs/开发工作须知.md` |
| 上手板子与工具链 | `docs/开发前置信息.md` |
| 创新功能（⑦⑧）的一切 | `docs/示教创新功能设计冻结.md` |
| C 版是怎么做成的 | `docs/C版移植方案.md` 第 11 节 |
| 上机结论的逐项证据 | `docs/上机验证记录.md` |

## 构建

```powershell
# C 版（当前主力）
powershell -NoProfile -ExecutionPolicy Bypass -File firmware\c51\build_c_abs.ps1
# 汇编正式固件
powershell -NoProfile -ExecutionPolicy Bypass -File firmware\car\build.ps1
```

烧录：STC-ISP → 型号 `STC89C52RC` → 串口 `COM7`（COM3–6 是蓝牙虚拟口，别选）→ 打开 hex → 【下载/编程】→ **然后才冷启动**。

## 改代码的铁律

- ★ **C17 已冻结为稳定基线**：**没有测试依据不许重构** 避障状态机 / Timer ISR / PWM 底层 / 超声波状态机 / `cur_act`。
- ★ **`Cxx`/`Txx`/`Rxx` 编号必须带含义注释**（例 `C17（避障分级）`）；对照表在 `docs/正式固件开发记录.md` §C17 开头。
- **遥控键值有 4 个副本，改一处要四处同改**：`firmware/remote/remote.asm`、`firmware/car/config.h`、`firmware/car/car_asm.asm`、`firmware/c51/main.c`。
- **`firmware/car/config.h` 是唯一需要现场核对的引脚文件**；实测对不上时只改这一个文件。
- ⚠️ **C 版的避障模型与汇编版不同**（红外全局 / 直接刹车 / 关不掉；超声波受手动开关）—— **既有避障判据全部作废**。
- ⚠️ **DATA 段（30H~7FH）要按 `-Ir` 诊断变体算账**：普通变体 74/80 B，`-Ir` 变体 **79/80 B —— 只剩 1 字节**。**加任何全局变量前先算 `-Ir`，且三个变体都要编。**
- **`.ps1` 必须纯 ASCII**（无 BOM 的 UTF-8 会被 Windows PowerShell 当 GBK 读，中文注释会乱码/报错）。`.md` 不受影响。
- **`原始资料/` 是只读参考区**，不要在里面改东西。

## 交付与验收口径

- **hex 进 git**：验收靠 **hex 的 SHA256 指纹**与"逐字节相同"比对；改了代码就要重新报指纹。
- 体积账按 `code` 与 flash 占比报（C 版占 8 KB flash；汇编版已超 Eval 2048 B 上限，hex 由 `tools/lst2hex.py` 从 A51 清单回退生成）。
- **已定案 / 未定案必须分开写**：`遥控偶发失灵` 已定案（**不是固件问题**，是 0038 接收头朝向 / 机械连接）；`跑着偶发停车 + 数码管显示 0` **未定案** —— 定案前不要写进报告。
- ⚠️ 归档文档里的 ✅ **不可无条件引用**（至少"循迹方向已上机验证"是错记）。

## 版本控制

2026-09-22 已 `git init`（基线提交 `f4d7356`，207 个文件）。
**要看改了什么用 `git diff` / `git status`，不要重读整个文件。**
身份是**仓库内**配置（`user.name=工程实践`）；要改成自己的：`git config user.email "你的邮箱"`。
