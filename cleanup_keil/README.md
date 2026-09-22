# Keil 清除记录

## 为什么要清

原安装位于 `D:\`（安装根目录就是 D 盘根）：
- `D:\C51\` —— C51 产品目录，**`C51.exe`（C 编译器）根本不存在**，仅剩的 `A51.EXE / BL51.EXE / OH51.EXE` 三个文件 PE 头已损坏，运行报 `The file or directory is corrupted and unreadable`；
- `D:\UV4\` —— µVision4 IDE 外壳（42 个文件 / 15.6 MB），里面**没有任何可用的编译工具**；
- `D:\Uninstall.exe` —— Keil 自己的卸载器（uVision4 Setup, FileVersion 1.08）；
- `D:\TOOLS.INI` —— Keil 工具注册文件，`[C51] PATH="D:\\C51"`；
- 注册表 `HKLM\SOFTWARE\WOW6432Node\Keil\Products\C51` = V9.00 / D:\C51。

结论：工具链已经不可用，必须整体重装，先清干净再装。

## 已删除（用户级，已完成）

| 目标 | 结果 |
|---|---|
| `D:\C51\` | ✅ 已删（含 3 个损坏的 exe） |
| `D:\UV4\` | ✅ 已删 |
| `D:\Uninstall.exe` | ✅ 已删 |
| `D:\TOOLS.INI` | ✅ 已删（已备份，见下） |
| `HKCU\Software\Keil`（μVision4 设置、最近工程列表） | ✅ 已删 |
| `C:\Users\8Kinfe\Desktop\Keil uVision4.LNK` | ✅ 已删 |
| `%APPDATA%\...\Start Menu\Programs\Keil uVision4.LNK` | 本来就没有 |

执行脚本：`cleanup_keil_part1_user.ps1`，日志：`cleanup_keil_part1.log`

## 备份（出问题可回滚）

`backup\` 目录下：

| 文件 | 内容 |
|---|---|
| `TOOLS.INI.bak` | 原 `D:\TOOLS.INI`（含 `[UV2]` 用户名/邮箱、`[C51] PATH`） |
| `registry_HKCU_Keil.reg` | `HKCU\Software\Keil` 的完整导出（180 KB） |
| `registry_HKLM_Keil.reg` | `HKLM\SOFTWARE\WOW6432Node\Keil` 的导出 |
| `filelist_D_C51.txt` | 被删文件清单（路径/大小/时间） |
| `filelist_D_UV4.txt` | 同上 |

> 原目录里**没有任何 license 文件**（全盘对应的 `*.LIC` 搜索为空），所以没有授权信息丢失；重装后按注册机重新注册即可。

## 还需要管理员权限的 3 项（未完成）

这三项都在 HKLM / ProgramData，普通权限删不掉：

1. `HKLM\SOFTWARE\WOW6432Node\Keil\Products\C51`
2. 卸载登记项 `HKLM\...\Uninstall\Keil μVision4`（`UninstallString = D:\Uninstall.exe`，现在指向已删除的文件）
3. `C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Keil uVision4.LNK`（指向已删除的 `D:\UV4\UV4.EXE`）

**怎么删**：开始菜单搜 `PowerShell` → 右键 → **以管理员身份运行** → 粘贴：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "D:\工程实践_迁移\cleanup_keil\cleanup_keil_part2_admin.ps1"
```

脚本会删掉上面 3 项，并顺带复查一遍用户级项，最后打印汇总。
日志：`cleanup_keil_part2.log`

### 不删也能重装

新的 `C51V900.exe` 安装器会**覆盖同名注册表项**（`Keil μVision4`）并重建开始菜单快捷方式，所以这 3 项只是"指向已删文件的死链接"，**不阻塞重装**。方便的话先跑一下 part2 更干净。

## 重装之后

见 `..\docs\开发环境与工具链.md`。要点：装到 `C:\Keil`（路径不带中文空格）、用注册机注册（评估版代码上限 2KB，本课题会超）、把 `C:\Keil` 加入杀软排除目录。
