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
if [ -f "$rc_file" ] && grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY" "$rc_file"; then
    echo "⚠️ Environment variables already exist in $rc_file. Skipping.../环境变量已存在于 $rc_file 中。跳过..."
else
    # Append new entries
    echo "" >> "$rc_file"
    echo "# Claude Code environment variables" >> "$rc_file"
    echo "export ANTHROPIC_BASE_URL=https://api.o3.fan/anthropic/" >> "$rc_file"
    echo "export ANTHROPIC_API_KEY=$api_key" >> "$rc_file"
    echo "✅ Environment variables added to $rc_file/✅ 环境变量已添加到 $rc_file"
fi

echo ""
echo "🎉 Installation completed successfully!"
echo "🎉 安装成功完成！"
echo ""
echo "🔄 Please restart your terminal or run:"
echo "🔄 请重新启动您的终端或运行："
echo "   source $rc_file"
echo "   source $rc_file"
echo ""
echo "🚀 Then you can start using Claude Code with:"
echo "🚀 然后您可以使用 Claude Code："
echo "   claude"
