{|req|
    const OPENCODE_API = "http://localhost:3030"

    # Capture request body at closure level (before branching)
    let body = $in

    # Route requests
    if ($req.path == "/") {
        open index.html
    } else if ($req.path == "/create-session") {
        # Call OpenCode to create session (using curl since nushell http needs TLS provider)
        let session = (curl -s -X POST $"($OPENCODE_API)/session" | from json)

        # Return session ID as Datastar signal
        .response {headers: {"content-type": "text/event-stream"}}
        $"event: datastar-patch-signals
data: signals {\"sessionId\": \"($session.id)\"}

"
    } else if ($req.path == "/send-prompt") {
        # Get signals from Datastar (using captured body)
        let signals = ($body | from json)
        let session_id = ($signals | get sessionId)
        let prompt = ($signals | get prompt)

        # Send message to OpenCode (using curl since nushell http needs TLS provider)
        let request_body = ({parts: [{type: "text", text: $prompt}]} | to json)
        curl -s -X POST $"($OPENCODE_API)/session/($session_id)/message" -H "Content-Type: application/json" -d $request_body | ignore

        # Stream OpenCode SSE events and transform to Datastar format
        .response {headers: {"content-type": "text/event-stream"}}

        # Stream OpenCode events, filtering for this session only
        # Manual SSE formatting since to sse needs records not lists
        curl -N -s $"($OPENCODE_API)/event"
        | lines
        | each { |line|
            if ($line | str starts-with "data: ") {
                let json_str = ($line | str substring 6..)
                try {
                    let event = ($json_str | from json)
                    # Filter: only message.part.updated events for our session with text
                    if ($event.type == "message.part.updated" and
                        $event.properties?.part?.type == "text" and
                        $event.properties?.part?.sessionId == $session_id) {
                        let text = $event.properties.part.text
                        # Use to json for proper escaping
                        let signal_update = ({response: $text, loading: false} | to json)
                        # Manually format SSE
                        $"event: datastar-patch-signals\ndata: signals ($signal_update)\n\n"
                    }
                } catch { null }
            }
        }
        | compact
        | str join
    } else {
        .response {status: 404}
        "Not found"
    }
}
