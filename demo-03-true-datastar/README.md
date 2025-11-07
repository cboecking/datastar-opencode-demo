# demo-03-true-datastar

Learning Datastar's natural patterns and integrating with OpenCode AI.

## What We Learned

### Datastar Fundamentals

**Datastar is server-driven hypermedia**, not a client-side framework. It's designed for backends that speak its SSE protocol.

1. **Signals** - Reactive state declared in HTML
   ```html
   <body data-signals='{"count": 0, "name": ""}'>
   ```

2. **Reactive Bindings**
   - `data-text="$count"` - Display signal
   - `data-bind="name"` - Two-way input binding
   - `data-show="$sessionId"` - Conditional rendering
   - `data-attr:disabled="$loading"` - Dynamic attributes

3. **Backend Actions**
   ```html
   <button data-on:click="@post('/endpoint')">Click</button>
   ```
   Sends ALL signals to backend as JSON

4. **SSE Protocol** - Backend responds with:
   ```
   event: datastar-patch-signals
   data: signals {"fieldName": "value"}
   ```

### http-nu Integration

**http-nu is Nushell-scriptable HTTP server**

1. **Response metadata** - Use `.response` command
   ```nushell
   .response {headers: {"content-type": "text/event-stream"}}
   "body content"
   ```

2. **SSE formatting** - Use `to sse` (http-nu command) for records
   ```nushell
   # to sse is provided by http-nu, not standard nushell
   {event: "datastar-patch-signals", data: "signals {...}"} | to sse
   ```

3. **Request handling** - Capture `$in` at closure level
   ```nushell
   {|req|
       let body = $in
       if ($req.path == "/endpoint") { ... }
   }
   ```

## Current Implementation

### What Works ✅

1. **Session Creation** - Creates OpenCode session via API
2. **Datastar Reactivity** - UI updates on signal changes
3. **Form Submission** - Sends prompts to OpenCode
4. **http-nu Middleware** - Routes requests, transforms responses

### Architecture

```
Browser (Datastar)
    ↓ @post('/create-session')
http-nu (Nushell)
    ↓ http post
OpenCode API
    ↓ {"id": "ses_..."}
http-nu
    ↓ SSE: signals {"sessionId": "..."}
Datastar → Updates UI
```

## The Streaming Challenge

### Problem

OpenCode provides SSE at `/event` but:

1. **Broadcasts ALL sessions** - Not filtered by session ID
2. **Never closes** - Stream runs forever
3. **Nushell `where` buffering** - Using `where` in pipelines causes buffering (must use `filter` instead)

### Solution

**Use `filter` instead of `where`:**

```nushell
http get $"($OPENCODE_API)/event"
| lines
| filter {|line| $line | str starts-with "data:"}  # ✅ Streams in real-time!
| each {|line| $line | str substring 6.. | from json}
| filter {|event| $event.type? == "message.part.updated"}
```

**Key insight:** `where` buffers the entire stream before filtering, while `filter` processes items one-by-one as they arrive.

### Root Cause

**CRITICAL DISCOVERY:** The buffering issue is caused by `where`, not `lines` or streaming itself.

- ✅ `lines` streams in real-time
- ✅ `each` processes items one-by-one
- ❌ `where` accumulates items before filtering (causes buffering)
- ✅ `filter` (deprecated) streams items one-by-one

**Solution:** Use the deprecated `filter` command instead of `where` for SSE streaming.

### Understanding `filter` vs `where` in Nushell

**The Problem:**

When working with infinite SSE streams, `where` causes significant buffering:

```nu
# ❌ BUFFERS - Won't stream in real-time
http get http://localhost:3030/event
| lines
| where ($it | str starts-with "data:")  # Accumulates before filtering
```

**The Solution:**

Use the deprecated `filter` command which processes one item at a time:

```nu
# ✅ STREAMS - Processes immediately
http get http://localhost:3030/event
| lines
| filter {|line| $line | str starts-with "data:"}  # Streams one-by-one
```

**Why This Matters:**

- `where` was designed for finite collections (like SQL WHERE clauses)
- `filter` was designed for streaming/lazy evaluation
- Nushell deprecated `filter` in favor of `where` for consistency with SQL
- But for SSE/streaming use cases, `filter` is still the correct tool

**Pattern for SSE Streaming:**

```nu
http get http://localhost:3030/event
| lines                                   # ✅ Streams
| filter {|line| /* condition */}         # ✅ Streams (use despite deprecation)
| each {|line| /* transform */}           # ✅ Streams
| filter {|item| /* condition */}         # ✅ Streams
| each {|item| /* final transform */}     # ✅ Streams
```

## Debugging Session: Pure Nushell Streaming

**IMPORTANT DISCOVERY:** Pure nushell `http get` DOES stream in real-time!

### Streaming OpenCode Events (Terminal)

See debug-listen.nu file.

```nu
# Stream and parse events - USE filter NOT where!
http get -m 15sec http://localhost:3030/event
| lines
| filter {|line| $line | str starts-with "data:"}
| each {|line| $line | str substring 6.. | from json}
| filter {|event| $event.type? == "message.part.updated" and $event.properties?.part?.type? == "text"}
| each {|event| $event.properties?.part?.text?}
```

```nu
# Simplified: just get the text deltas
http get -m 15sec http://localhost:3030/event
| lines
| filter {|line| $line | str starts-with "data:"}
| each {|line| $line | str substring 6.. | from json}
| filter {|event| $event.type? == "message.part.updated" and $event.data?.properties?.part?.type? == "text"}
| each {|event| $event.data?.properties?.delta?}
```

### Sending Messages to OpenCode

See debug-write.nu file.

```nu
# One-liner: create session and send message
http post http://localhost:3030/session ""
| get id
| $"http://localhost:3030/session/($in)/message"
| http post $in ({parts: [{type: "text", text: "create a whale"}]} | to json) -H [Content-Type application/json]
```

### Event Structure to Extract

**What we want:** `message.part.updated` events with `type: "text"`

Also see reference to 'delta' above.

```json
{
  "type": "message.part.updated",
  "properties": {
    "part": {
      "id": "prt_...",
      "sessionID": "ses_...",
      "messageID": "msg_...",
      "type": "text",           // ← Filter for this
      "text": "Hello world!"    // ← Extract this
    }
  }
}
```

**Other event types to ignore:**
- `server.connected` - Initial connection
- `message.updated` - Metadata only (no text)
- `session.updated` - Session info
- `session.idle` - Session idle notification
- `message.part.updated` with `type: "reasoning"` - Internal reasoning
- `message.part.updated` with `type: "step-start"` - Tool invocation

### http-nu Streaming

**As of http-nu 0.5.1**, the TLS crypto provider issue has been fixed. You can now use nushell's `http get` command directly in http-nu closures:

```nu
{|req|
    http get http://localhost:3030/event | lines  # ✅ Works!
}
```

**For streaming with filtering:**
```nu
http get http://localhost:3030/event
| lines
| filter {|line| $line | str starts-with "data:"}  # ✅ Streams in real-time!
```

**Note:** Use `filter` (instead of `where`) to enable real-time streaming without buffering.

## Comparison: xs TodoMVC Tutorial

### Reference Implementation

The [xs + Datastar TodoMVC tutorial](https://cablehead.github.io/xs/tutorials/datastar-todomvc/) demonstrates the "native" Datastar way with **xs** (event sourcing).

**Key Architecture:**

```
User Action → POST /add
    ↓
.append todos (event stored)
    ↓
.cat -f (follow mode) → Real-time aggregation
    ↓
minijinja-cli (JSON → HTML)
    ↓
SSE: datastar-patch-elements
    ↓
Browser updates #todos element
```

**What's Different:**

1. **Event Sourcing** - xs stores immutable events, aggregates into projections
2. **Real-time streams work** - `.cat -f` provides true streaming (no buffering)
3. **HTML patches** - Uses `datastar-patch-elements` to update DOM directly
4. **Server-side rendering** - minijinja templates generate HTML fragments
5. **Single source of truth** - Server owns all state, browser just displays

**Why It Works:**

- **xs is designed for streaming** - `.cat -f` emits events immediately
- **Backend speaks Datastar** - Directly generates Datastar SSE format
- **No impedance mismatch** - All components designed to work together

### Our Challenge

We're integrating with **OpenCode** (AI coding agent) which:

1. **Has its own SSE format** - `message.part.updated` not `datastar-patch-signals`
2. **Broadcasts all sessions** - Needs client-side filtering
3. **Nushell buffering** - `| lines` blocks on infinite streams

**Key Insight:** xs was purpose-built for this use case. OpenCode was not.

### The xs Advantage

If building from scratch with Datastar, **xs + http-nu + minijinja** is the ideal stack:

```nushell
# Real-time event processing in Nushell
.cat todos -f
| lines
| from json
| # Aggregate state
| to json
| minijinja-cli template.html
| # Wrap in SSE
```

This works because:
- **xs streams properly** - No buffering
- **Nushell processes events** - One at a time as they arrive
- **minijinja renders** - Pure server-side HTML
- **Datastar receives** - Native `datastar-patch-elements` events

### Lessons Learned

1. **Server-driven is powerful** - When backend speaks Datastar natively
2. **Event sourcing fits naturally** - Append events, stream projections
3. **Nushell works great** - When streams have proper boundaries
4. **Integration has costs** - Bridging non-Datastar backends requires compromise

## Usage

```bash
# Terminal 1: Start OpenCode
opencode serve --port 3030

# Terminal 2: Start demo
cd demo-03-true-datastar
./run.sh

# Browser
open http://localhost:8080
```

## Next Steps

If pursuing Option A:
1. Add EventSource connection in `<script>` tag
2. Filter events by sessionId
3. Update Datastar signals on message receipt
4. Keep all other Datastar reactivity unchanged
