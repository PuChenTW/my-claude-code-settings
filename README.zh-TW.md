# Claude 與 Codex 設定

[English](README.md) | 繁體中文

Claude Code 與 Codex CLI 的全域配置，強制執行 Linus Torvalds 風格的程式設計原則：無情的簡潔、效能優先思維，以及零抽象膨脹。

## 安裝

```bash
./setup.sh
```

請先確認 `jq`、`claude`、`codex` 都已在 `PATH`。這個總控腳本會驗證需求並呼叫兩個專屬安裝器：

- `setup_claude.sh` 會更新 `~/.claude/`、重新設定 SessionStart hook、安裝 Claude 端的 MCP 伺服器
- `setup_codex.sh` 會更新 `~/.codex/`、重新設定排程任務、安裝 Codex 端的 MCP 伺服器

若只想設定其中一個客戶端，可直接執行對應的腳本。

## 功能

- 複製程式設計指南到 `~/.claude/CLAUDE.md`
- 將相同模板複製到 `~/.codex/AGENTS.md`（覆寫前會備份），並透過每日 crontab 自動更新日期
- 設定 SessionStart hook 在每次對話開始時更新日期
- 安裝 Playwright MCP 伺服器以進行網頁自動化
- 選擇性安裝 Context7 MCP 伺服器以取得最新的函式庫文件（需要 API 金鑰）
- 在所有專案中強制執行簡潔優先原則

> 需要系統有 `crontab` 指令。如果缺少，腳本會顯示跳過訊息，請自行手動更新 `AGENTS.md` 的日期。

## 客製化

您可以修改 `PROMPT_TEMPLATE.md` 來使用自己的程式設計指南和原則，而非預設的 Linus Torvalds 風格規則。

**重要**：第一行必須保持 `- **Current date**: YYYY-MM-DD` 格式，以便 SessionStart hook 自動更新日期。請從第二行開始加入您的客製化內容。

修改 `PROMPT_TEMPLATE.md` 後，再次執行 `./setup.sh` 來套用變更。

## Hooks

當 Claude Code 寫入或編輯檔案時自動執行的格式化 hooks。

### 安裝 Hooks 到專案

```bash
./setup-hooks.sh <專案路徑>
```

安裝內容：
- Hook 腳本到 `<專案>/.claude/hooks/`
- 設定檔到 `<專案>/.claude/settings.json`（如果存在會合併）

### 現有 Hooks

- **format-python.sh**：使用 ruff 透過 uvx 自動格式化 Python 檔案
  - 在 Write/Edit/MultiEdit 操作時執行
  - 格式化程式碼並修正樣式問題
  - 忽略未使用的 import (F401)，因為 Claude 會在實作前先加入 import
  - 顯示錯誤但不阻擋執行（讓 Claude 看到並修正問題）

- **format-shellscript.sh**：使用 shellcheck 和 shfmt 檢查並格式化 shell 腳本
  - 在 Write/Edit/MultiEdit 操作時執行
  - 使用 shellcheck 檢查並用 shfmt 格式化（2 空格縮排，bash 風格）
  - 顯示錯誤但不阻擋執行（讓 Claude 看到並修正問題）

### 需求

- jq：`brew install jq`（macOS）或 `apt install jq`（Linux）
- uvx（來自 uv）：https://docs.astral.sh/uv/getting-started/installation/
- shellcheck：`brew install shellcheck`（macOS）或 `apt install shellcheck`（Linux）
- shfmt：`brew install shfmt`（macOS）或 `go install mvdan.cc/sh/v3/cmd/shfmt@latest`（Linux）

## MCP 伺服器

安裝腳本會安裝以下 MCP 伺服器：

### Playwright MCP
- 安裝時**自動安裝**
- 啟用網頁開發和測試的瀏覽器自動化功能
- 不需要額外設定

### Context7 MCP
- **選擇性** - 安裝時會提示輸入 API 金鑰
- 提供最新的、版本特定的函式庫文件
- 在此取得 API 金鑰：https://context7.com/dashboard
- 如果安裝時跳過，稍後可使用以下指令安裝：
  ```bash
  claude mcp add -s user context7 -- npx -y @upstash/context7-mcp --api-key YOUR_API_KEY
  ```

列出已安裝的 MCP 伺服器：`claude mcp list`

## 理念

好的程式碼就是簡單的程式碼。複雜的解決方案表示理解不足。每一行都是負債——積極刪除。
