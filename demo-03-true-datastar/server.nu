{|req|
    const OPENCODE_API = "http://localhost:3030"

    # Capture request body at closure level (before branching)
    let body = $in

    # Route requests
    if ($req.path == "/") {
        open index.html
    } else if ($req.path == "/create-session") {
        # Call OpenCode to create session
        let session = (curl -s -X POST $"($OPENCODE_API)/session" | from json)

        # Generate HTML fragment with session UI (single line for SSE)
        let html = $"<div><p>Session: <code>($session.id)</code></p><form data-on:submit=\"@post\('/send-prompt', \{contentType: 'form'\}\)\"><input type=\"hidden\" name=\"sessionId\" value=\"($session.id)\"><input type=\"text\" name=\"prompt\" placeholder=\"Enter your prompt...\" required><button type=\"submit\">Send</button></form><h2>Response</h2><div data-text=\"\$response\" class=\"response-box\"></div></div>"

        # Return HTML fragment as Datastar element patch
        .response {headers: {"content-type": "text/event-stream"}}
        $"event: datastar-patch-elements
data: selector #app
data: mode inner
data: elements ($html)

event: datastar-patch-signals
data: signals {\"sessionId\": \"($session.id)\", \"response\": \"\"}

"
    } else if ($req.path == "/send-prompt") {
        # Parse form data from Datastar form submission (URL-encoded)
        # Format: sessionId=ses_xxx&prompt=hello+world
        let form_data = ($body
            | split row '&'
            | each { |pair| $pair | split row '=' }
            | reduce -f {} { |pair, acc| $acc | insert ($pair.0) ($pair.1 | url decode) }
        )
        let session_id = ($form_data | get sessionId)
        let prompt = ($form_data | get prompt)

        # Send message to OpenCode (using curl - nushell http has TLS crypto provider issue in http-nu)
        let request_body = ({parts: [{type: "text", text: $prompt}]} | to json)
        curl -s -X POST $"($OPENCODE_API)/session/($session_id)/message" -H "Content-Type: application/json" -d $request_body | ignore

        # Stream OpenCode events and transform to Datastar HTML fragments
        .response {headers: {"content-type": "text/event-stream"}}

        # Simplest test - just pass through raw curl output (no lines parsing)
        curl -N -s $"($OPENCODE_API)/event"
    } else {
        .response {status: 404}
        "Not found"
    }
}
