#  Xcode Command Line Tools
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "🛠 检查 Xcode Command Line Tools 是否已安装..."
    # 检查 command line tools 是否存在
    if ! xcode-select -p &>/dev/null; then
        echo "❗️未检测到 Xcode Command Line Tools，正在为您自动安装..."
        echo "   (会弹出安装窗口，请按照提示操作，安装完成后按回车继续)"
        xcode-select --install

        # 等待用户安装完成
        read -p "✅ 安装完成后请按回车继续... (Press Enter after the installation is finished)" 
        # 再次检测
        if ! xcode-select -p &>/dev/null; then
            echo "❌ Command Line Tools 仍未安装，无法继续。请安装后重新运行本脚本。"
            exit 1
        fi
        echo "✅ Command Line Tools 已安装，继续下一步..."
    else
        echo "✅ Xcode Command Line Tools 已安装"
    fi
fi


#!/bin/bash

set -e

install_nodejs() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS..."
            echo "🚀 正在 Unix/Linux/macOS 上安装 Node.js..."
            
            echo "📥 Downloading and installing nvm..."
            echo "📥 正在下载并安装 nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            
            echo "🔄 Loading nvm environment..."
            echo "🔄 正在加载 nvm 环境..."
            \. "$HOME/.nvm/nvm.sh"
            
            echo "📦 Downloading and installing Node.js v22..."
            echo "📦 正在下载并安装 Node.js v22..."
            nvm install 22
            
            echo -n "✅ Node.js installation completed! Version: "
            echo -n "✅ Node.js 安装完成！版本: "
            node -v # Should print "v22.17.0".
            echo -n "✅ Current nvm version: "
            echo -n "✅ 当前 nvm 版本: "
            nvm current # Should print "v22.17.0".
            echo -n "✅ npm version: "
            echo -n "✅ npm 版本: "
            npm -v # Should print "10.9.2".
            ;;
        *)
            echo "Unsupported platform: $platform"
            echo "不支持的平台: $platform"
            exit 1
            ;;
    esac
}

# Check if Node.js is already installed and version is >= 18
if command -v node >/dev/null 2>&1; then
    current_version=$(node -v | sed 's/v//')
    major_version=$(echo $current_version | cut -d. -f1)
    
    if [ "$major_version" -ge 18 ]; then
        echo "Node.js is already installed: v$current_version"
        echo "Node.js 已安装: v$current_version"
    else
        echo "Node.js v$current_version is installed but version < 18. Upgrading..."
        echo "Node.js v$current_version 已安装，但版本 < 18。正在升级..."
        install_nodejs
    fi
else
    echo "Node.js not found. Installing..."
    echo "未找到 Node.js。正在安装..."
    install_nodejs
fi

# Check if Claude Code is already installed
if command -v claude >/dev/null 2>&1; then
    echo "Claude Code is already installed: $(claude --version)"
    echo "Claude Code 已安装: $(claude --version)"
else
    echo "Claude Code not found. Installing..."
    echo "未找到 Claude Code。正在安装..."
    
    # Attempt to install globally with npm
    npm install -g @anthropic-ai/claude-code || {
        echo "⚠️  Global installation failed. Attempting to install locally in user directory..."
        echo "⚠️  全局安装失败。尝试在用户目录中进行本地安装..."
        
        # Create a local directory for npm global installs
        mkdir -p ~/.npm-global
        npm config set prefix '~/.npm-global'
        
        # Update PATH for local npm installs
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
        echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
        
        # Reload shell configuration
        source ~/.bashrc || source ~/.zshrc
        
        # Retry installing the package
        npm install -g @anthropic-ai/claude-code
    }
fi

# Configure Claude Code to skip onboarding
echo "Configuring Claude Code to skip onboarding..."
echo "正在配置 Claude Code 跳过入门..."
node --eval '
    const os = require("os");
    const path = require("path");
    const fs = require("fs");
    const homeDir = os.homedir(); 
    const filePath = path.join(homeDir, ".claude.json");
    if (fs.existsSync(filePath)) {
        const content = JSON.parse(fs.readFileSync(filePath, "utf-8"));
        fs.writeFileSync(filePath, JSON.stringify({ ...content, hasCompletedOnboarding: true }, null, 2), "utf-8");
    } else {
        fs.writeFileSync(filePath, JSON.stringify({ hasCompletedOnboarding: true }, null, 2), "utf-8");
    }'

# Prompt user for API key
echo "🔑 Please enter your API key/请输入您的API Key（秘钥）:"
echo "   You can get your API key from/您可在这里获取您的秘钥: https://o3.fan/token"
echo "   Note: The input is hidden for security. Please paste your API key directly/输入内容已隐藏以确保安全,请直接粘贴您的API密钥。"
echo ""
read -s api_key
echo ""

if [ -z "$api_key" ]; then
    echo "⚠️  API key cannot be empty. Please run the script again./API 密钥不能为空。请再次运行脚本。"
    exit 1
fi

# Prompt user for model selection
echo "🤖 Please select a model/请选择模型 (Default: claude-sonnet-4-20250514/默认: claude-sonnet-4-20250514):"
echo "   1. claude-3-7-sonnet-20250219"
echo "   2. claude-3-7-sonnet-20250219-thinking"
echo "   3. claude-opus-4-20250514"
echo "   4. claude-opus-4-20250514-thinking"
echo "   5. claude-sonnet-4-20250514-thinking"
echo "   6. Custom model name/自定义模型名称"
echo "   Press Enter to use default/按回车使用默认值"
echo ""
read -p "Enter your choice (1-6) or press Enter for default/输入您的选择 (1-6) 或按回车使用默认值: " model_choice

case "$model_choice" in
    1)
        claude_model="claude-3-7-sonnet-20250219"
        ;;
    2)
        claude_model="claude-3-7-sonnet-20250219-thinking"
        ;;
    3)
        claude_model="claude-opus-4-20250514"
        ;;
    4)
        claude_model="claude-opus-4-20250514-thinking"
        ;;
    5)
        claude_model="claude-sonnet-4-20250514-thinking"
        ;;
    6)
        echo "Please enter custom model name/请输入自定义模型名称:"
        read -p "Custom model name/自定义模型名称: " claude_model
        if [ -z "$claude_model" ]; then
            claude_model="claude-sonnet-4-20250514"
        fi
        ;;
    *)
        claude_model="claude-sonnet-4-20250514"
        ;;
esac

echo "Selected model/已选择模型: $claude_model"

# Prompt user for max output tokens
echo ""
echo "📊 Please set max output tokens/请设置最大输出令牌数 (Default: 64000/默认: 64000):"
echo "   1. Use default (64000)/使用默认值 (64000)"
echo "   2. Custom value/自定义值"
echo ""
read -p "Enter your choice (1-2) or press Enter for default/输入您的选择 (1-2) 或按回车使用默认值: " token_choice

case "$token_choice" in
    2)
        echo "Please enter custom max output tokens/请输入自定义最大输出令牌数:"
        read -p "Max output tokens/最大输出令牌数: " max_tokens
        if [ -z "$max_tokens" ]; then
            max_tokens="64000"
        fi
        ;;
    *)
        max_tokens="64000"
        ;;
esac

echo "Max output tokens set to/最大输出令牌数设置为: $max_tokens"

# Detect current shell and determine rc file
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash)
        rc_file="$HOME/.bashrc"
        ;;
    zsh)
        rc_file="$HOME/.zshrc"
        ;;
    fish)
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    *)
        rc_file="$HOME/.profile"
        ;;
esac

# Add environment variables to rc file
echo ""
echo "📝 Adding environment variables to $rc_file.../正在向$rc_file添加环境变量..."

# Check if variables already exist to avoid duplicates
if [ -f "$rc_file" ] && grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY\|CLAUDE_MODEL\|CLAUDE_CODE_MAX_OUTPUT_TOKENS" "$rc_file"; then
    echo "⚠️ Environment variables already exist in $rc_file. Skipping.../环境变量已存在于 $rc_file 中。跳过..."
else
    # Append new entries
    echo "" >> "$rc_file"
    echo "# Claude Code environment variables" >> "$rc_file"
    echo "export ANTHROPIC_BASE_URL=https://api.o3.fan" >> "$rc_file"
    echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
    echo "export CLAUDE_MODEL=$claude_model" >> "$rc_file"
    echo "export CLAUDE_CODE_MAX_OUTPUT_TOKENS=$max_tokens" >> "$rc_file"
    echo "✅ Environment variables added to $rc_file/✅ 环境变量已添加到 $rc_file"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo "🎉 安装成功完成！"
echo ""
echo "🔄 Please restart your terminal or run:"
echo "🔄 请重新启动您的终端或运行："
echo "   source $rc_file"
echo ""
echo "🚀 Then you can start using Claude Code with:"
echo "🚀 然后您可以使用 Claude Code：（使用方法：关闭该窗口，再次打开终端输入：claude  即可使用）"
echo "   claude"
echo ""
echo "📋 Configuration Summary/配置摘要:"
echo "   API Base URL/API 基础地址: https://api.o3.fan"
echo "   Model/模型: $claude_model"
echo "   Max Output Tokens/最大输出令牌数: $max_tokens"
