#!/bin/bash

# Quick fix script for OpenHands permission issues

echo "🔧 OpenHands Permission Fix"
echo "============================"

echo ""
echo "🔐 Current User: $(whoami) (ID: $(id -u))"

echo ""
echo "📁 Checking current directory permissions..."
echo "   • ~/.openhands: $(ls -ld ~/.openhands 2>/dev/null || echo 'NOT FOUND')"
echo "   • workspace: $(ls -ld workspace 2>/dev/null || echo 'NOT FOUND')"
echo "   • openhands-logs: $(ls -ld openhands-logs 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "🔧 Creating directories..."
mkdir -p ~/.openhands workspace openhands-logs

echo ""
echo "🔑 Attempting to fix permissions..."

# Try to fix ownership first
if sudo chown -R $(id -u):$(id -g) ~/.openhands workspace openhands-logs 2>/dev/null; then
    echo "✅ Ownership fixed with sudo chown"
else
    echo "⚠️  chown failed, trying chmod..."
    if sudo chmod 755 ~/.openhands workspace openhands-logs 2>/dev/null; then
        echo "✅ Permissions fixed with sudo chmod"
    else
        echo "❌ Both chown and chmod failed"
        echo "   Manual intervention required"
    fi
fi

echo ""
echo "🔍 Testing write permissions..."
if touch ~/.openhands/test-write 2>/dev/null; then
    rm -f ~/.openhands/test-write
    echo "✅ ~/.openhands write test passed"
else
    echo "❌ ~/.openhands write test failed"
fi

if touch workspace/test-write 2>/dev/null; then
    rm -f workspace/test-write
    echo "✅ workspace write test passed"
else
    echo "❌ workspace write test failed"
fi

echo ""
echo "📋 Final directory permissions:"
echo "   • ~/.openhands: $(ls -ld ~/.openhands 2>/dev/null || echo 'NOT FOUND')"
echo "   • workspace: $(ls -ld workspace 2>/dev/null || echo 'NOT FOUND')"
echo "   • openhands-logs: $(ls -ld openhands-logs 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "🚀 Next steps:"
echo "   • Run: ./start.sh"
echo "   • Or: docker compose up -d"
echo "   • Debug: ./debug-permissions.sh"
