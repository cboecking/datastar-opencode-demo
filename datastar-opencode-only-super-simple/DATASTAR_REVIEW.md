# Datastar Purity Review

Line-by-line review of index.html for Datastar best practices conformance.

## Issues Found

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

### 🟡 MEDIUM: console.log() in expressions

**Lines 44, 54:**
```javascript
console.log('Prompt text:', $promptText)
```

**Issue:** Not idiomatic Datastar. Expressions should be focused on data flow, not debugging.

**Fix:** Remove or add comment that this is for debugging only

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

1. ✅ **Using `data-signals__ifmissing`** - Correct pattern for defaults
2. ✅ **Using `data-bind:promptText`** - Proper two-way binding
3. ✅ **Using `data-show`** - Idiomatic conditional rendering
4. ✅ **Using `data-text`** - Proper text binding
5. ✅ **Signal naming** - Lowercase, descriptive
6. ✅ **No external JavaScript files** - Pure HTML

---

## Verdict

**For a pure Datastar application:** ❌ Would not pass review

**For a demo showing OpenCode/Datastar integration:** ⚠️ Acceptable with caveats

**Key Issue:** The example mixes Datastar patterns with raw JavaScript because OpenCode doesn't speak Datastar's SSE event format. Purists will flag:
1. Raw `fetch()` instead of `@post()`
2. Manual `EventSource` instead of backend-driven SSE
3. Complex inline JavaScript

**Resolution Options:**
1. Add prominent comments explaining why we deviate
2. Create a wrapper backend that translates OpenCode → Datastar events
3. Mark this as "integration example" not "pure Datastar"

---

## Recommended Changes for Purity

See `index-pure.html` for a version that uses only Datastar patterns (would require backend changes).
