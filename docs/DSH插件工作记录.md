# DSH 插件工作记录（侧边栏插件）

> 记录时间：**2026-09-21**
> 工作区：`D:\工程实践_迁移`（本记录与固件工程无关，换工作区时**整个文件搬走**即可）
> 起因：装了一个侧边栏插件，要确认它能不能用、以及"能不能实时看到 agent 改代码"

---

## 0. 结论速览

| 问题 | 结论 |
|---|---|
| 插件能用吗 | ✅ **能用**（但中间坏过一次，见 §2） |
| 编辑器里能看到 agent 实时改代码吗 | ⚠️ **能"看到"，但要手动点一下** —— 它检测到磁盘变了会弹框，点确认后才换成最新内容 |
| 文件树会自动列出新文件吗 | ⏳ **未测完**（观察没回收，见 §5） |
| 宿主版本 | DSH Desktop **2.0.13**（从 2.0.4 升上来的，升级就是修复手段） |

---

## 1. 插件是什么 / 装在哪 / 怎么注册

**插件**：`dsh-better-sidebar` **v0.18.1**

> DSH web 客户端插件，**VSCode 风格的右侧边栏**：资源管理器 / 编辑器 / 终端 / git / 浏览器，
> **按会话（conversation session）隔离**。
> 上游：<https://github.com/omdsh-dev/DSH-better-sidebar>

**安装位置**（profile 名 `desktop`）：

```
C:\Users\8Kinfe\.dsh\profiles\desktop\
├─ package.json                     ← 声明依赖 + bundle 列表
├─ node_modules\dsh-better-sidebar\ ← 插件本体（含预构建产物）
├─ cordis.yml                       ← 内容是 []（正常）
└─ cordis.patch.yml                 ← 内容是 []（正常，★ 别手动加挂载行）
```

`package.json` 里两处都要有它：

```json
"dependencies": { "dsh-better-sidebar": "0.18.1" },
"dsh": { "profile": { "bundles": [
  "@deepseek-ai/dsh-base",
  "@deepseek-ai/dsh-web-app",
  ...
  "dsh-better-sidebar"        ← ★ 必须在最后
] } }
```

**注册机制（bundle 通道）**：插件自带 `cordis.patch.yml`，内容是一条 `insert`：

```yaml
- insert:
    - id: better-sidebar
      name: 'dsh-better-sidebar'
      disabled: !!js "[...ctx.loader.entries()].some((e) => e.options.name === 'dsh-better-sidebar' && e.options.id !== 'better-sidebar' && !e.disabled)"
```

> ★ **两条重要注意**
> 1. profile 自己的 `cordis.patch.yml` **必须保持 `[]`**。如果里面还留着旧的"手动挂载行"，
>    会和 bundle 通道**双挂载** ⇒ `/sidebar/api` 注册两次 ⇒ **整棵插件树启动失败**。
> 2. 上面那个 `disabled` 守卫是防"聚合包也挂了同一个插件"的。它只能看到**排在自己前面**的行，
>    所以 `dsh-better-sidebar` **必须排在 bundles 列表最后**（`dsh plugin add` 默认就是追加到最后，正常）。

**插件导出**：`lib/index.js`（Node 半边）+ `lib/client.js`（923 KB，web 客户端半边），
客户端声明 `dsh.client.platform = "web"`。

---

## 2. ★ 那次故障：插件把整棵插件树搞崩了

**现象**：13:34:51 启动时，`D:\...\logs\dsh-2026-09-21.log` 里：

```
[E] [host-resolved-root-include] file:///C:/Users/8Kinfe/.dsh/profiles/desktop/node_modules/dsh-better-sidebar/lib/index.js:16
    import { SessionLogOffset } from "@deepseek-ai/dsh-session";
    SyntaxError: The requested module '@deepseek-ai/dsh-session' does not provide an export named 'SessionLogOffset'

[E] Error: failed to import loader entry better-sidebar (dsh-better-sidebar): ...
Error: dsh-plugin-desktop: plugin tree failed to load: failed to apply loader entry include (cordis:include): ...
```

**根因**：**宿主 2.0.4 太旧**，它带的 `@deepseek-ai/dsh-session` 没有导出插件要用的
`SessionLogOffset` ⇒ 插件导入失败 ⇒ **不是"侧边栏没了"，是整个插件树都起不来**。

**修复**：宿主升级到 **2.0.13** 并重启（日志 13:51 那次 `run 1789969865597`）。
重启后日志里**再没有**这条错误，插件正常挂载。

> **教训**：DSH 客户端插件和宿主是**版本强耦合**的。
> 升级插件前先确认宿主版本够新；反过来说，插件坏了**先升宿主**往往就好了。

---

## 3. 排查入口（以后直接看这几个地方）

**日志**：

```
C:\Users\8Kinfe\AppData\Roaming\DSH Desktop\logs\dsh-YYYY-MM-DD.log        ← 启动期 / 插件树
C:\Users\8Kinfe\AppData\Roaming\DSH Desktop\logs\host\dsh-YYYY-MM-DD.log   ← 运行期
C:\Users\8Kinfe\AppData\Roaming\DSH Desktop\logs\*-error.log              ← 只看错误的话
```

**日志里的启动分隔线**（用来确认当前跑的是哪个版本）：

```
--- dsh-plugin-desktop DSH Desktop <版本> win32 node v<版本> run <时间戳> ---
```

**本次用过的诊断命令**（PowerShell）：

```powershell
# 插件装没装 / 版本
Get-ChildItem 'C:\Users\8Kinfe\.dsh\profiles\desktop\node_modules\dsh-better-sidebar'

# 最近 3 天改过的配置文件
Get-ChildItem 'C:\Users\8Kinfe\.dsh' -Recurse -File -Force |
  Where-Object { $_.LastWriteTime -gt (Get-Date).AddDays(-3) } |
  Sort-Object LastWriteTime -Descending

# 插件有没有加载失败
Select-String -Path 'C:\Users\8Kinfe\AppData\Roaming\DSH Desktop\logs\dsh-*.log' `
  -Pattern 'better-sidebar|failed to import loader entry|plugin tree failed'
```

> ⚠️ **`http://127.0.0.1:43120` 从命令行直接请求会返回 `403`（空 body）**，
> 带浏览器 UA 也一样 —— 服务器有 host/令牌校验，**别用它来判插件活没活**，看日志。

---

## 4. ★ "能实时看到 agent 改代码吗" —— 实测结论

### 4.1 实测过程

1. 我在工作区建 `sidebar_live_test.md`（v1）→ 用户在侧边栏编辑器里打开
2. 我依次写 **v2（13:57:43）→ v3（13:57:55）→ v4（13:58:06）**，每笔间隔约 10 秒
3. **侧边栏弹出了确认框**：

   > **「文件已在磁盘更新，刷新将丢弃未保存编辑」**

4. ⇒ **它检测到了变化，但要用户点一下才换内容**，不会静默自动刷新

### 4.2 源码证据

**服务端没有任何文件监听** —— 整个 `src` 里只有 `stat()`，**没有 `fs.watch` / chokidar / watchFile**。
（`bundle-route.ts` 里的 ETag 只服务于**插件自身 UI 的 HMR**，不是用户文件。）
客户端有 `use-polling.ts`（`window.setInterval` 定时轮询）。

**编辑器明确只支持手动刷新** —— `src/client/EditorHost.tsx` 原文注释：

```
// Manual refresh (issue #167): bumping the sequence re-runs the load effect
// with the same path/scope — the only reload entry besides open/close.
```

```tsx
const refreshFile = (): void => {
  if (toolbar?.dirty === true) {                 // 只有存在未保存草稿时才拦
    const confirmed = window.confirm(t('refreshUnsavedConfirm'))
    if (!confirmed) return
  }
  setReloadSeq(sequence => sequence + 1)
}
```

**文案 key**（简体在 `src/client/locales.ts:130`）：

```
refresh: '刷新'
refreshUnsavedConfirm: '文件已在磁盘更新，刷新将丢弃未保存编辑。继续吗？'
```

### 4.3 结论

> **这是有意设计，不是 bug。**
> 重载入口只有两个：**手动点「刷新」** 和 **关掉标签再打开**。
> 设计意图（issue #167 / PR #228）：宁可让你点一下，也**不肯在你正编辑时把内容偷偷换掉**。
> 所以当你点「刷新」而当时**手里有没保存的改动**，它会先弹框确认，防止你的草稿被冲掉。

---

## 5. 遗留 / 未完成

| 项 | 状态 |
|---|---|
| **文件树会不会自动列出新建文件** | ⏳ **未测完**。当时新建了 `sidebar_live_test2.md` 让用户观察，**观察结果没回收**。要测：新建任意文件 → **什么都别按** → 看树里冒不冒出来 |
| 两个测试文件 | ✅ 已删（`sidebar_live_test.md`、`sidebar_live_test2.md`） |
| 插件自身 UI 的 HMR | 未测。理论上 `bundle-route.ts` 的 ETag + 304 支持，但 DSH 侧的 HMR 只有在跑 `pnpm run dev:web` 时才免刷新 |

**想重新复现"实时刷新"测试**：在工作区随便建一个 `.md` → 侧边栏打开它 → 让我改它 →
观察是"弹框要你点"还是"自己变了"。

---

## 6. 一句话总结

**插件能用；它和宿主版本强耦合（宿主旧了会把整棵插件树带崩，升级宿主即修复）；
它不会自动刷新文件内容，检测到磁盘变化后弹框让你点 —— 这是防丢草稿的有意设计。**
