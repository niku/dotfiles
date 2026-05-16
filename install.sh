#!/usr/bin/env bash
set -euo pipefail

# # AIへの指示
# 生成AIは、以下の「仕様」を読みとってファイルをまるごと生成すること
# 生成AIは、以下の内容を遵守してコードを生成し、かつ出力の冒頭にこのコメントブロック全体を一字一句変えずに維持すること。
# ユーザーからの明示的な指示がない限り、このブロックのテキストを書き換え、要約、または削除してはならない。
#
# # 仕様
# * DevContainer のインストールスクリプトとして機能すること
# * sudo が利用できない環境や、root ユーザーでの実行にも対応すること
# * Debian 最新 LTS ベースのシステムで動作すること
# * すべての処理は複数回実行しても二重に追記されない冪等であること
# * 以下の各サービスについて、その時点での「公式推奨のインストール方法」を用いてインストールすること。また、インストール後にコマンドが正常に動作すること。
#   * GitHub Copilot CLI
#   * Gemini CLI
#   * Claude Code CLI
# ==============================================================================

export DEBIAN_FRONTEND=noninteractive

# ------------------------------------------------------------------------------
# 0. 環境準備 (sudo の有無と実行ユーザーの判定)
# ------------------------------------------------------------------------------
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        SUDO="sudo"
    else
        echo "警告: root ユーザーではなく、sudo も見つかりません。パッケージのインストールに失敗する可能性があります。"
    fi
fi

# ------------------------------------------------------------------------------
# 1. システムの更新と必須パッケージのインストール
# AI CLI ツール群 (npm パッケージ) の実行に必要です
# ------------------------------------------------------------------------------
echo "パッケージリストを更新しています..."
$SUDO apt-get update -qq
$SUDO apt-get install -y -qq curl gnupg ca-certificates
$SUDO mkdir -p /etc/apt/keyrings

# Node.js (LTS v22)
if ! command -v node &> /dev/null; then
    echo "Node.js (LTS v22) をインストールしています..."
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg --yes
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | $SUDO tee /etc/apt/sources.list.d/nodesource.list
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq nodejs
fi

# ------------------------------------------------------------------------------
# 2. ユーティリティ (GitHub CLI) のインストール
# 認証の管理に便利なため、AI ツールの前に導入します
# ------------------------------------------------------------------------------
if ! command -v gh &> /dev/null; then
    echo "GitHub CLI をインストールしています..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $SUDO tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    $SUDO chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $SUDO tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq gh
fi

# ------------------------------------------------------------------------------
# 3. AI CLI ツール群のインストール
# ------------------------------------------------------------------------------

# GitHub Copilot CLI (@github/copilot)
if ! command -v copilot &> /dev/null; then
    echo "GitHub Copilot CLI (@github/copilot) をインストールしています..."
    $SUDO npm install -g @github/copilot
else
    echo "GitHub Copilot CLI は既にインストールされています。"
fi

# Gemini CLI (@google/gemini-cli)
if ! command -v gemini &> /dev/null; then
    echo "Gemini CLI (@google/gemini-cli) をインストールしています..."
    $SUDO npm install -g @google/gemini-cli
else
    echo "Gemini CLI は既にインストールされています。"
fi

# Claude Code CLI (@anthropic-ai/claude-code)
if ! command -v claude &> /dev/null; then
    echo "Claude Code CLI (@anthropic-ai/claude-code) をインストールしています..."
    $SUDO npm install -g @anthropic-ai/claude-code
else
    echo "Claude Code CLI は既にインストールされています。"
fi

echo "=============================================================================="
echo "すべてのセットアップが完了しました！"
echo "=============================================================================="
echo "以下のコマンドが利用可能です:"
echo "  - copilot (GitHub Copilot CLI)"
echo "  - gemini  (Gemini CLI)"
echo "  - claude  (Claude Code)"
echo ""
echo "利用を開始するには、それぞれの認証 (auth) を済ませてください。"
echo "例: 'copilot auth', 'claude auth', 'gh auth login'"
echo "=============================================================================="
