#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Datastar + OpenCode Demo"
echo
echo "Starting http-nu server on :8080..."
echo "Visit: http://localhost:8080"
echo
echo "Make sure OpenCode is running:"
echo "  opencode serve --port 3030"
echo

# Serve using the Nushell server script
cat server.nu | http-nu :8080 -
