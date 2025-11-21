# Nginx Setup - Datastar + OpenCode Test

## ✅ Installation Complete

The Datastar + OpenCode SSE test is now served by nginx!

## Access URLs

**Local Access:**
```
http://localhost/datastar-test.html
http://127.0.0.1/datastar-test.html
```

**Network Access:**
```
http://100.83.71.123/datastar-test.html
```

## File Locations

**Source:** `/home/debian/code/vilara/vilara-chuck/datastar-opencode-demo/datastar-opencode-only-super-simple/index.html`

**Served From:** `/var/www/html/datastar-test.html`

**Nginx Config:** `/etc/nginx/sites-available/default`

## Nginx Details

- **Version:** nginx/1.22.1
- **Port:** 80 (HTTP)
- **Status:** Active and running
- **Workers:** 24 processes

## Testing the Page

1. **Ensure OpenCode is running:**
   ```bash
   # If not running, start it
   cd /home/debian/code/vilara/vilara-chuck/opencode
   opencode serve --port 42992
   ```

2. **Open in browser:**
   ```
   http://localhost/datastar-test.html
   ```

3. **Follow the steps:**
   - Click "Create Session"
   - Click "Send Prompt"
   - Click "Start SSE Listener"
   - Watch events appear

## CORS Note

Since the page is served from nginx (port 80) and OpenCode API is on port 42992, you may encounter CORS issues. If so, we can configure nginx as a reverse proxy to avoid CORS.

## Update the Page

To update the served page after making changes:

```bash
sudo cp /home/debian/code/vilara/vilara-chuck/datastar-opencode-demo/datastar-opencode-only-super-simple/index.html /var/www/html/datastar-test.html
sudo chmod 644 /var/www/html/datastar-test.html
```

## Next Steps

If CORS is an issue, we can:
1. Configure nginx as a reverse proxy to OpenCode API
2. Add CORS headers to nginx config
3. Both options avoid browser security restrictions
