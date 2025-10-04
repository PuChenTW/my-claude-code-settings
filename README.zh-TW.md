# Claude Code 設定

[English](README.md) | 繁體中文

Claude Code 的全域配置，強制執行 Linus Torvalds 風格的程式設計原則：無情的簡潔、效能優先思維，以及零抽象膨脹。

## 安裝

```bash
./setup.sh
```

這會將 `CLAUDE.md` 安裝到 `~/.claude/` 並設定 SessionStart hook 來保持日期更新。

## 功能

- 複製程式設計指南到 `~/.claude/CLAUDE.md`
- 設定 SessionStart hook 在每次對話開始時更新日期
- 在所有專案中強制執行簡潔優先原則

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

### 需求

- jq：`brew install jq`（macOS）或 `apt install jq`（Linux）
- uvx（來自 uv）：https://docs.astral.sh/uv/getting-started/installation/

## 理念

好的程式碼就是簡單的程式碼。複雜的解決方案表示理解不足。每一行都是負債——積極刪除。
