@echo off
chcp 65001 > nul
setlocal enabledelayedexpansion

echo.
echo 🚀 Claude Code Windows Installation Script
echo 🚀 Claude Code Windows 安装脚本
echo ========================================
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ⚠️  This script requires administrator privileges.
    echo ⚠️  此脚本需要管理员权限。
    echo.
    echo Please right-click and "Run as administrator"
    echo 请右键点击并选择"以管理员身份运行"
    pause
    exit /b 1
)

REM Check if WSL is installed
echo 🔍 Checking WSL installation...
echo 🔍 检查 WSL 安装状态...
wsl --list >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo 📥 WSL not found. Installing WSL with Ubuntu...
    echo 📥 未找到 WSL。正在安装 WSL 和 Ubuntu...
    
    REM Enable WSL feature
    echo 🔧 Enabling WSL feature...
    echo 🔧 正在启用 WSL 功能...
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
    
    REM Install WSL
    wsl --install -d Ubuntu-22.04
    
    echo.
    echo ⚠️  WSL installation requires a system restart.
    echo ⚠️  WSL 安装需要重启系统。
    echo.
    echo Please restart your computer and run this script again.
    echo 请重启计算机后再次运行此脚本。
    pause
    exit /b 0
)

REM Check if Ubuntu is installed
echo 🔍 Checking Ubuntu installation...
echo 🔍 检查 Ubuntu 安装状态...
wsl --list | findstr "Ubuntu" >nul 2>&1
if %errorLevel% neq 0 (
    echo.
    echo 📥 Ubuntu not found. Installing Ubuntu-22.04...
    echo 📥 未找到 Ubuntu。正在安装 Ubuntu-22.04...
    wsl --install -d Ubuntu-22.04
    
    echo.
    echo ⚠️  Please complete Ubuntu setup (username and password) and run this script again.
    echo ⚠️  请完成 Ubuntu 设置（用户名和密码）后再次运行此脚本。
    pause
    exit /b 0
)

REM Create temporary Linux script
echo 🔄 Creating installation script for WSL...
echo 🔄 正在为 WSL 创建安装脚本...

set TEMP_SCRIPT=%TEMP%\install_claude_code.sh

(
echo #!/bin/bash
echo set -e
echo.
echo # Update system
echo echo "📦 Updating system packages..."
echo echo "📦 正在更新系统包..."
echo sudo apt update -y
echo sudo apt upgrade -y
echo.
echo # Install Node.js via nvm
echo if ! command -v node ^>/dev/null 2^>^&1; then
echo     echo "🚀 Installing Node.js..."
echo     echo "🚀 正在安装 Node.js..."
echo     
echo     # Install curl if not present
echo     sudo apt install -y curl
echo     
echo     # Install nvm
echo     curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh ^| bash
echo     
echo     # Load nvm
echo     export NVM_DIR="$HOME/.nvm"
echo     [ -s "$NVM_DIR/nvm.sh" ] ^&^& \. "$NVM_DIR/nvm.sh"
echo     
echo     # Install Node.js
echo     nvm install 22
echo     nvm use 22
echo else
echo     echo "✅ Node.js is already installed"
echo     echo "✅ Node.js 已安装"
echo fi
echo.
echo # Install Claude Code
echo if ! command -v claude ^>/dev/null 2^>^&1; then
echo     echo "🤖 Installing Claude Code..."
echo     echo "🤖 正在安装 Claude Code..."
echo     
echo     # Configure npm to avoid permission issues
echo     mkdir -p ~/.npm-global
echo     npm config set prefix '~/.npm-global'
echo     
echo     # Update PATH
echo     echo 'export PATH=~/.npm-global/bin:$PATH' ^>^> ~/.bashrc
echo     export PATH=~/.npm-global/bin:$PATH
echo     
echo     # Install Claude Code
echo     npm install -g @anthropic-ai/claude-code
echo else
echo     echo "✅ Claude Code is already installed"
echo     echo "✅ Claude Code 已安装"
echo fi
echo.
echo # Configure Claude Code to skip onboarding
echo echo "⚙️  Configuring Claude Code..."
echo echo "⚙️  正在配置 Claude Code..."
echo node --eval "
echo const os = require('os'^);
echo const path = require('path'^);
echo const fs = require('fs'^);
echo const homeDir = os.homedir(^); 
echo const filePath = path.join(homeDir, '.claude.json'^);
echo if (fs.existsSync(filePath^)^) {
echo     const content = JSON.parse(fs.readFileSync(filePath, 'utf-8'^)^);
echo     fs.writeFileSync(filePath, JSON.stringify({...content, hasCompletedOnboarding: true}, null, 2^), 'utf-8'^);
echo } else {
echo     fs.writeFileSync(filePath, JSON.stringify({hasCompletedOnboarding: true}, null, 2^), 'utf-8'^);
echo }
echo "
echo.
echo echo "🎉 Installation completed in WSL!"
echo echo "🎉 WSL 中的安装已完成！"
echo echo ""
echo echo "To configure Claude Code, please run:"
echo echo "要配置 Claude Code，请运行："
echo echo "wsl"
echo echo "然后运行以下命令来配置环境变量："
echo echo ""
) > "%TEMP_SCRIPT%"

REM Execute the script in WSL
echo 🔄 Executing installation in WSL...
echo 🔄 正在 WSL 中执行安装...
wsl bash "%TEMP_SCRIPT%"

REM Clean up
del "%TEMP_SCRIPT%"

echo.
echo 🎉 Installation completed successfully!
echo 🎉 安装成功完成！
echo.
echo 📋 Next steps/后续步骤:
echo 1. Open WSL by typing: wsl
echo 1. 输入 wsl 打开 WSL
echo 2. Configure environment variables/配置环境变量:
echo.

REM Prompt for configuration
echo 🔑 Would you like to configure Claude Code now? (y/n)
echo 🔑 您想现在配置 Claude Code 吗？(y/n)
set /p configure_now=
if /i "!configure_now!"=="y" (
    echo.
    echo 🔄 Opening WSL to configure Claude Code...
    echo 🔄 正在打开 WSL 配置 Claude Code...
    
    REM Create configuration script
    set CONFIG_SCRIPT=%TEMP%\configure_claude.sh
    
    (
    echo #!/bin/bash
    echo.
    echo echo "🔑 Please enter your API key/请输入您的API Key（秘钥）:"
    echo echo "   You can get your API key from/您可在这里获取您的秘钥: https://o3.fan/token"
    echo echo "   Note: The input is hidden for security/输入内容已隐藏以确保安全"
    echo echo ""
    echo read -s api_key
    echo echo ""
    echo.
    echo if [ -z "$api_key" ]; then
    echo     echo "⚠️  API key cannot be empty/API 密钥不能为空"
    echo     exit 1
    echo fi
    echo.
    echo # Model selection
    echo echo "🤖 Please select a model/请选择模型 (Default: claude-sonnet-4-20250514):"
    echo echo "   1. claude-3-7-sonnet-20250219"
    echo echo "   2. claude-3-7-sonnet-20250219-thinking"
    echo echo "   3. claude-opus-4-20250514"
    echo echo "   4. claude-opus-4-20250514-thinking"
    echo echo "   5. claude-sonnet-4-20250514-thinking"
    echo echo "   6. Custom model name/自定义模型名称"
    echo echo "   Press Enter to use default/按回车使用默认值"
    echo echo ""
    echo read -p "Enter your choice (1-6^) or press Enter for default/输入您的选择 (1-6^) 或按回车使用默认值: " model_choice
    echo.
    echo case "$model_choice" in
    echo     1^) claude_model="claude-3-7-sonnet-20250219" ;;
    echo     2^) claude_model="claude-3-7-sonnet-20250219-thinking" ;;
    echo     3^) claude_model="claude-opus-4-20250514" ;;
    echo     4^) claude_model="claude-opus-4-20250514-thinking" ;;
    echo     5^) claude_model="claude-sonnet-4-20250514-thinking" ;;
    echo     6^) 
    echo         echo "Please enter custom model name/请输入自定义模型名称:"
    echo         read -p "Custom model name/自定义模型名称: " claude_model
    echo         if [ -z "$claude_model" ]; then
    echo             claude_model="claude-sonnet-4-20250514"
    echo         fi
    echo         ;;
    echo     *^) claude_model="claude-sonnet-4-20250514" ;;
    echo esac
    echo.
    echo echo "Selected model/已选择模型: $claude_model"
    echo.
    echo # Max tokens
    echo echo "📊 Please set max output tokens/请设置最大输出令牌数 (Default: 64000):"
    echo echo "   1. Use default (64000^)/使用默认值 (64000^)"
    echo echo "   2. Custom value/自定义值"
    echo echo ""
    echo read -p "Enter your choice (1-2^) or press Enter for default/输入您的选择 (1-2^) 或按回车使用默认值: " token_choice
    echo.
    echo case "$token_choice" in
    echo     2^)
    echo         echo "Please enter custom max output tokens/请输入自定义最大输出令牌数:"
    echo         read -p "Max output tokens/最大输出令牌数: " max_tokens
    echo         if [ -z "$max_tokens" ]; then
    echo             max_tokens="64000"
    echo         fi
    echo         ;;
    echo     *^) max_tokens="64000" ;;
    echo esac
    echo.
    echo echo "Max output tokens set to/最大输出令牌数设置为: $max_tokens"
    echo.
    echo # Add to bashrc
    echo echo "📝 Adding environment variables to ~/.bashrc..."
    echo echo "📝 正在向 ~/.bashrc 添加环境变量..."
    echo.
    echo if ! grep -q "ANTHROPIC_BASE_URL\|ANTHROPIC_API_KEY\|CLAUDE_MODEL\|CLAUDE_CODE_MAX_OUTPUT_TOKENS" ~/.bashrc; then
    echo     echo "" ^>^> ~/.bashrc
    echo     echo "# Claude Code environment variables" ^>^> ~/.bashrc
    echo     echo "export ANTHROPIC_BASE_URL=https://api.o3.fan" ^>^> ~/.bashrc
    echo     echo "export ANTHROPIC_API_KEY=$api_key" ^>^> ~/.bashrc
    echo     echo "export CLAUDE_MODEL=$claude_model" ^>^> ~/.bashrc
    echo     echo "export CLAUDE_CODE_MAX_OUTPUT_TOKENS=$max_tokens" ^>^> ~/.bashrc
    echo     echo "✅ Environment variables added/✅ 环境变量已添加"
    echo else
    echo     echo "⚠️  Environment variables already exist/环境变量已存在"
    echo fi
    echo.
    echo # Load environment variables
    echo source ~/.bashrc
    echo.
    echo echo "🎉 Configuration completed successfully!"
    echo echo "🎉 配置成功完成！"
    echo echo ""
    echo echo "📋 Configuration Summary/配置摘要:"
    echo echo "   API Base URL/API 基础地址: https://api.o3.fan"
    echo echo "   Model/模型: $claude_model"
    echo echo "   Max Output Tokens/最大输出令牌数: $max_tokens"
    echo echo ""
    echo echo "🚀 You can now start using Claude Code with:"
    echo echo "🚀 您现在可以使用 Claude Code："
    echo echo "   claude"
    echo echo ""
    echo echo "💡 To access WSL in the future, just type: wsl"
    echo echo "💡 将来要访问 WSL，只需输入: wsl"
    ) > "%CONFIG_SCRIPT%"
    
    wsl bash "%CONFIG_SCRIPT%"
    del "%CONFIG_SCRIPT%"
)

echo.
echo 🎉 Setup completed! You can now use Claude Code by typing:
echo 🎉 设置完成！您现在可以通过输入以下命令使用 Claude Code：
echo.
echo wsl
echo claude
echo.
pause
