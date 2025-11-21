# Datastar Implementation Review

Review of the working OpenCode/Datastar integration showing dual-channel communication.

## ✅ Working Implementation Summary

This demo successfully integrates OpenCode's dual-channel API with Datastar's reactive signals:
- **Channel 1:** POST response with complete message data (immediate)
- **Channel 2:** SSE stream with real-time AI processing events

**Key Learning:** Textarea binding requires **value syntax** `data-bind="signalName"` not colon syntax.

## Implementation Patterns

### 🔴 CRITICAL: Using raw `fetch()` instead of `@post()` action

**Lines 24, 44:**
```html
<!-- Current (anti-pattern) -->
<button data-on:click="fetch('http://127.0.0.1:42992/session', {...})...">
```

**Datastar Way:**
```html
<!-- Should be -->
<button data-on:click="@post('/session')">
```

**Why it matters:**
- `@post()` is the idiomatic Datastar action helper
- Automatically sends signals in request body
- Expects SSE response with Datastar events (`datastar-patch-elements`, `datastar-merge-signals`)
- Safer (@ prefix indicates safe action)

**BUT - Special Case for This Example:**
OpenCode uses a **dual-channel pattern**:
1. **POST response:** Immediate JSON (message ID, initial result)
2. **SSE stream:** Real-time events as AI processes

This is fundamentally different from Datastar's single-channel SSE approach where `@post()` expects the POST response itself to be an SSE stream with `datastar-patch-elements` events.

**Why we use raw `fetch()`:**
- Need to handle JSON response to get message ID
- SSE events come on separate `/event` endpoint
- Can't use `@post()` because response is JSON, not SSE

**Recommendation:** Add comment explaining dual-channel architecture

---

### ✅ FIXED: Textarea Data Binding

**Critical Discovery:** Textareas require different binding syntax than inputs!

**❌ Wrong (doesn't work):**
```html
<textarea data-bind:promptText>Default text</textarea>
```

**✅ Correct (works):**
```html
<textarea data-bind="promptText">Default text</textarea>
```

**Why it matters:**
- The **colon syntax** (`data-bind:signalName`) works for `<input>` elements
- The **value syntax** (`data-bind="signalName"`) is required for `<textarea>` elements
- This is documented in the Datastar docs (line 2516) but easy to miss

**Implementation pattern:**
1. Initialize signal in `data-signals`: `{promptText: 'default value'}`
2. Bind textarea using value syntax: `data-bind="promptText"`
3. Textarea content and signal stay synchronized

---

### 🟡 MEDIUM: Complex inline JavaScript

**Lines 24, 44, 54:**
Very long JavaScript expressions in `data-on:click` attributes.

**Datastar Philosophy:** Keep expressions simple. Complex logic should be in backend.

**Options:**
1. Break into multiple steps
2. Move complexity to backend
3. Add comments explaining necessity

---

### 🟡 MEDIUM: Creating EventSource manually

**Line 54:**
```javascript
const es = new EventSource('http://127.0.0.1:42992/event')
```

**Datastar Way:** SSE connections should be initiated by backend responses to `@get()` calls, not manually created in JavaScript.

**Pure Datastar Pattern:**
```html
<button data-on:click="@get('/start-events')">
```

Backend responds with:
```
event: datastar-patch-elements
data: elements <div>...</div>
```

**BUT:** OpenCode's architecture separates concerns:
- **POST /session/:id/message** → Returns JSON response
- **GET /event** → Separate SSE stream for real-time updates

This dual-channel approach is different from Datastar's expectation that POST responses are SSE streams. Both channels are needed:
1. POST to send message and get ID
2. SSE to watch AI processing in real-time

---

### 🟢 MINOR: Unnecessary element IDs

**Lines 28, 41, 60:**
```html
<div id="status" class="status">
<textarea id="prompt-input" data-bind:promptText>
<div id="events" data-show="$events.length > 0">
```

**Issue:** These IDs aren't used for Datastar operations. Only needed if:
- Backend sends `datastar-patch-elements` targeting specific IDs
- Or using getElementById (which we're not anymore)

**Fix:** Can remove IDs unless needed for:
1. Backend morphing
2. Accessibility (label `for` attribute needs the textarea ID)

---

### 🟢 MINOR: Inline styles instead of classes

**Line 41:**
```html
style="width: 100%; min-height: 80px; ..."
```

**Better:** Use CSS classes in `<style>` block

---

## What's Actually Good ✅

1. ✅ **Explicit signal initialization** - Using `data-signals` to create signals with defaults
2. ✅ **Correct textarea binding** - Using `data-bind="promptText"` (value syntax)
3. ✅ **Using `data-show`** - Idiomatic conditional rendering
4. ✅ **Using `data-text`** - Proper text binding for displaying POST response
5. ✅ **Signal naming** - Lowercase, descriptive (`$promptText`, `$postResponse`)
6. ✅ **No external JavaScript files** - Pure HTML
7. ✅ **Dual-channel display** - Clearly shows both immediate POST response and SSE events

---

## Verdict

**For a pure Datastar application:** ⚠️ Hybrid approach (justified by API constraints)

**For OpenCode/Datastar integration demo:** ✅ Working implementation

**Assessment:**
This implementation successfully demonstrates:
1. ✅ **Reactive signals work correctly** - Textarea binding, signal updates, data flow
2. ✅ **Dual-channel display** - Both POST response and SSE events visible
3. ✅ **Proper Datastar patterns** - Signals, data-bind, data-show, data-text used correctly
4. ⚠️ **Necessary deviations** - Raw `fetch()` and manual `EventSource` required by OpenCode's API

**Why hybrid approach is justified:**
- OpenCode uses dual-channel: JSON POST response + separate SSE endpoint
- Datastar's `@post()` expects SSE response, not JSON
- Raw `fetch()` + manual `EventSource` is the correct bridge between these patterns

**Key Learnings:**
1. Textarea requires `data-bind="signalName"` (value syntax) not `data-bind:signalName` (colon syntax)
2. Explicit signal initialization via `data-signals` ensures binding works correctly
3. Datastar's reactivity works perfectly once signals are properly configured

---

## Implementation Success

This demo proves OpenCode and Datastar can work together effectively by:
- Using Datastar for reactive UI (signals, binding, conditional display)
- Using raw fetch/EventSource to bridge OpenCode's dual-channel API
- Displaying both channels clearly for debugging and understanding
