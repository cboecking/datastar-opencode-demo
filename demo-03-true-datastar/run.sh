#!/usr/bin/env bash
echo "Starting Datastar demo on http://localhost:8080"
cat server.nu | http-nu :8080 -
