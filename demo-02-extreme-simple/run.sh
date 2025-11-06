#!/usr/bin/env bash
echo "Starting on http://localhost:8080"
cat server.nu | http-nu :8080 -
