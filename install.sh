#!/bin/bash

set -e

# 检测并自动安装 Xcode Command Line Tools（仅限 macOS）
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "🛠 检查 Xcode Command Line Tools 是否已安装..."
    echo "🛠 Checking if Xcode Command Line Tools is installed..."
    # 检查 command line tools 是否存在
    if ! xcode-select -p &>/dev/null; then
        echo "❗️未检测到 Xcode Command Line Tools，正在为您自动安装..."
        echo "❗️Xcode Command Line Tools not detected, installing automatically..."
        echo "   (会弹出安装窗口，请按照提示操作，安装完成后按回车继续)"
        echo "   (Installation window will pop up, please follow the instructions and press Enter to continue after installation)"
        xcode-select --install

        # 等待用户安装完成
        read -p "✅ 安装完成后请按回车继续... (Press Enter after the installation is finished): " 
        # 再次检测
        if ! xcode-select -p &>/dev/null; then
            echo "❌ Command Line Tools 仍未安装，无法继续。请安装后重新运行本脚本。"
            echo "❌ Command Line Tools still not installed, cannot continue. Please install and run the script again."
            exit 1
        fi
        echo "✅ Command Line Tools 已安装，继续下一步..."
        echo "✅ Command Line Tools installed, continuing..."
    else
        echo "✅ Xcode Command Line Tools 已安装"
        echo "✅ Xcode Command Line Tools is installed"
    fi
fi

install_nodejs() {
    local platform=$(uname -s)
    
    case "$platform" in
        Linux|Darwin)
            echo "🚀 Installing Node.js on Unix/Linux/macOS..."
            echo "🚀 正在 Unix/Linux/macOS 上安装 Node.js..."
            
            echo "📥 Downloading and installing nvm..."
            echo "📥 正在下载并安装 nvm..."
            
            # 尝试多个镜像源下载 nvm
            nvm_installed=false
            nvm_urls=(
                "https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh"
                "https://gitee.com/mirrors/nvm/raw/v0.40.3/install.sh"
                "https://cdn.jsdelivr.net/gh/nvm-sh/nvm@v0.40.3/install.sh"
            )
            
            for url in "${nvm_urls[@]}"; do
                echo "🔄 Trying to download from: $url"
                echo "🔄 尝试从以下地址下载: $url"
                
                if curl -o- --connect-timeout 30 --max-time 120 "$url" | bash; then
                    nvm_installed=true
                    echo "✅ NVM installation successful from: $url"
                    echo "✅ NVM 从以下地址安装成功: $url"
                    break
                else
                    echo "❌ Failed to download from: $url, trying next mirror..."
                    echo "❌ 从以下地址下载失败: $url，尝试下一个镜像..."
                fi
            done
            
            if [ "$nvm_installed" = false ]; then
                echo "❌ All NVM download attempts failed. Please check your network connection."
                echo "❌ 所有 NVM 下载尝试都失败了。请检查您的网络连接。"
                echo "💡 You can try running the script again or install Node.js manually."
                echo "💡 您可以尝试重新运行脚本或手动安装 Node.js。"
                exit 1
            fi
            
            echo "🔄 Loading nvm environment..."
            echo "🔄 正在加载 nvm 环境..."
            
            # 检查 nvm.sh 是否存在
            if [ ! -f "$HOME/.nvm/nvm.sh" ]; then
                echo "❌ NVM installation failed. File $HOME/.nvm/nvm.sh not found."
                echo "❌ NVM 安装失败。未找到文件 $HOME/.nvm/nvm.sh。"
                exit 1
            fi
            
            # 设置 NVM 环境变量
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
            
            # 验证 nvm 是否可用
            if ! command -v nvm &> /dev/null; then
                echo "❌ NVM command not available after installation."
                echo "❌ 安装后 NVM 命令不可用。"
                exit 1
            fi
            
            # 检查并修复 npm 配置冲突
            if [ -f "$HOME/.npmrc" ]; then
                echo "🔧 Checking npm configuration for conflicts..."
                echo "🔧 检查 npm 配置冲突..."
                
                # 备份原始 .npmrc
                cp "$HOME/.npmrc" "$HOME/.npmrc.backup.$(date +%Y%m%d_%H%M%S)"
                echo "📋 Backed up original .npmrc to .npmrc.backup.$(date +%Y%m%d_%H%M%S)"
                echo "📋 已备份原始 .npmrc 到 .npmrc.backup.$(date +%Y%m%d_%H%M%S)"
                
                # 移除冲突的配置项
                if grep -q "prefix\|globalconfig" "$HOME/.npmrc"; then
                    echo "🔧 Removing conflicting npm configurations..."
                    echo "🔧 移除冲突的 npm 配置..."
                    
                    # 创建临时文件，移除 prefix 和 globalconfig 行
                    grep -v "^prefix\|^globalconfig" "$HOME/.npmrc" > "$HOME/.npmrc.tmp" || true
                    mv "$HOME/.npmrc.tmp" "$HOME/.npmrc"
                fi
            fi
            
            echo "📦 Downloading and installing Node.js v22..."
            echo "📦 正在下载并安装 Node.js v22..."
            
            # 尝试安装 Node.js，如果失败则重试
            max_retries=3
            retry_count=0
            
            while [ $retry_count -lt $max_retries ]; do
                if nvm install 22; then
                    echo "✅ Node.js v22 installation successful!"
                    echo "✅ Node.js v22 安装成功！"
                    
                    # 设置默认版本
                    nvm use 22
                    nvm alias default 22
                    
                    break
                else
                    retry_count=$((retry_count + 1))
                    echo "❌ Node.js installation failed. Retry $retry_count/$max_retries..."
                    echo "❌ Node.js 安装失败。重试 $retry_count/$max_retries..."
                    
                    if [ $retry_count -eq $max_retries ]; then
                        echo "❌ Node.js installation failed after $max_retries attempts."
                        echo "❌ Node.js 安装在 $max_retries 次尝试后失败。"
                        exit 1
                    fi
                    
                    sleep 5
                fi
            done
            
            echo -n "✅ Node.js installation completed! Version: "
            echo -n "✅ Node.js 安装完成！版本: "
            node -v
            echo -n "✅ Current nvm version: "
            echo -n "✅ 当前 nvm 版本: "
            nvm current
            echo -n "✅ npm version: "
            echo -n "✅ npm 版本: "
            npm -v
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
        source ~/.bashrc 2>/dev/null || source ~/.zshrc 2>/dev/null || true
        
        # Update current session PATH
        export PATH=~/.npm-global/bin:$PATH
        
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

# Check if API key is provided via environment variable
if [ -n "$API_KEY" ]; then
    echo "✅ API key detected from environment variable/检测到环境变量中的API密钥"
    api_key="$API_KEY"
else
    # Prompt user for API key
    echo "🔑 Please enter your API key/请输入您的API Key（秘钥）:"
    echo "   You can get your API key from/您可在这里获取您的秘钥: https://o3.fan/token"
    echo "   Note: The input is hidden for security. Please paste your API key directly/输入内容已隐藏以确保安全,请直接粘贴您的API密钥。"
    echo ""
    read -s api_key
    echo ""
fi

if [ -z "$api_key" ]; then
    echo "⚠️  API key cannot be empty. Please run the script again./API 密钥不能为空。请再次运行脚本。"
    exit 1
fi

# Check if MODEL is provided via environment variable
if [ -n "$MODEL" ]; then
    echo "✅ Model detected from environment variable: $MODEL/检测到环境变量中的模型: $MODEL"
    claude_model="$MODEL"
else
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
fi

echo "Selected model/已选择模型: $claude_model"

# Check if MAX_TOKENS is provided via environment variable
if [ -n "$MAX_TOKENS" ]; then
    echo "✅ Max tokens detected from environment variable: $MAX_TOKENS/检测到环境变量中的最大令牌数: $MAX_TOKENS"
    max_tokens="$MAX_TOKENS"
else
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
fi

# Validate the max_tokens value
if ! [[ "$max_tokens" =~ ^[0-9]+$ ]] || [ "$max_tokens" -le 0 ] || [ "$max_tokens" -gt 64000 ]; then
    echo "⚠️ Invalid value for max tokens. Setting to default (64000)."
    echo "⚠️ 最大输出令牌数值无效。设置为默认值 (64000)。"
    max_tokens="64000"
fi

# Convert to integer
max_tokens=$(printf "%d" "$max_tokens")

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

# Refresh current session environment variables
export ANTHROPIC_BASE_URL=https://api.o3.fan
export ANTHROPIC_API_KEY="$api_key"
export CLAUDE_MODEL="$claude_model"
export CLAUDE_CODE_MAX_OUTPUT_TOKENS="$max_tokens"

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
