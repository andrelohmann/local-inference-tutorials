#!/bin/bash

# Debug script for OpenHands permission issues

echo "🔍 OpenHands Permission Debug"
echo "============================="

echo ""
echo "🔐 Current User Info:"
echo "   • User ID: $(id -u)"
echo "   • Group ID: $(id -g)"
echo "   • Username: $(whoami)"
echo "   • Groups: $(groups)"

echo ""
echo "📁 Directory Permissions:"
echo "   • ~/.openhands: $(ls -ld ~/.openhands 2>/dev/null || echo 'NOT FOUND')"
echo "   • workspace: $(ls -ld workspace 2>/dev/null || echo 'NOT FOUND')"
echo "   • openhands-logs: $(ls -ld openhands-logs 2>/dev/null || echo 'NOT FOUND')"

echo ""
echo "🐳 Container Info:"
echo "   • OpenHands container status: $(docker compose ps openhands --format table 2>/dev/null || echo 'NOT RUNNING')"
echo "   • OpenHands container user: $(docker exec openhands id 2>/dev/null || echo 'CONTAINER NOT ACCESSIBLE')"

echo ""
echo "📝 Environment Variables:"
echo "   • SANDBOX_USER_ID: ${SANDBOX_USER_ID}"
echo "   • SANDBOX_VOLUMES: ${SANDBOX_VOLUMES}"

echo ""
echo "🔍 OpenHands Container Volume Mounts:"
docker inspect openhands --format='{{range .Mounts}}{{printf "%s -> %s (%s)\n" .Source .Destination .Type}}{{end}}' 2>/dev/null || echo "Container not found"

echo ""
echo "📋 Recent OpenHands Logs (last 20 lines):"
docker compose logs --tail=20 openhands 2>/dev/null || echo "No logs available"

echo ""
echo "🚀 Quick Fix Commands:"
echo "   • Recreate directories: mkdir -p ~/.openhands workspace openhands-logs"
echo "   • Fix permissions: chmod 755 ~/.openhands workspace openhands-logs"
echo "   • Restart containers: docker compose down && docker compose up -d"
