#!/bin/bash

# Quick installer for Claudio Commit Skin
# Downloads and installs from sugitup repository

set -e

echo "🚀 Installing Claudio Commit Skin from sugitup repository..."

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    echo "   Please run this script from the root of your project repository"
    exit 1
fi

# Download and execute the main installer
curl -sSL "https://raw.githubusercontent.com/ecologicaleaving/sugitup/main/claudio-commit-skin/install.sh" | bash

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 The commit skin is now active. Next commit will automatically:"
echo "   1. Update PROJECT.md with new version"
echo "   2. Build your project (Flutter APK, npm build, etc.)"
echo "   3. Package artifacts in releases/ directory"
echo "   4. Stage everything for commit"
echo ""
echo "🎯 Try it now:"
echo "   git add . && git commit -m 'feat: your new feature description'"
echo ""