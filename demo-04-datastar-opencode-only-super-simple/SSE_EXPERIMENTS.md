# SSE Integration Experiments

The purpose of this document is to explore different approaches for integrating OpenCode's SSE events with Datastar.

This is important because understanding the "Datastar purist way" helps us write maintainable, idiomatic code.

## Evaluation Criteria

For each approach, we'll evaluate:
- ✅ **Works?** - Does it function correctly?
- 📊 **Datastar Purity** - How idiomatic is it? (1-5 scale)
- 🎯 **Simplicity** - How easy to understand? (1-5 scale)
- 🔧 **Maintainability** - How easy to modify? (1-5 scale)

## Baseline: Current 3-Step Approach

**Pattern:**
```html
<!-- Step 1: Create Session -->
<button data-on:click="fetch(...).then(...)">Create Session</button>

<!-- Step 2: Send Prompt -->
<button data-on:click="fetch(...).then(...)">Send Prompt</button>

<!-- Step 3: Start SSE -->
<button data-on:click="const es = new EventSource(...)">Start SSE Listener</button>
```

**Evaluation:**
- ✅ Works: YES
- 📊 Datastar Purity: 2/5 (uses signals, but manual EventSource)
- 🎯 Simplicity: 4/5 (clear separate steps)
- 🔧 Maintainability: 3/5 (three separate actions to coordinate)

**Notes:** Clear for learning but requires user to remember 3 steps.

---

## Experiment 1: Combined Button with Signals (SKIPPED)

**Pattern:**
```html
<div data-signals="{sessionId: '', sseActive: false, events: []}">
  <button data-on:click="
    fetch(...).then(r => r.json()).then(d => {
      $sessionId = d.id;
      const es = new EventSource('/event');
      es.onopen = () => $sseActive = true;
      es.onmessage = e => $events.push(JSON.parse(e.data));
    })
  ">Create Session & Connect SSE</button>
</div>
```

**Hypothesis:** More "Datastar" by using signals to track state, combining related actions.

**Why Skipped:**
This approach is a middle ground between the baseline (2/5 purity) and Experiment 2 (4/5 purity). It would likely score ~3/5:
- More imperative than reactive
- Combines actions in one handler (less declarative)
- Doesn't leverage Datastar's reactive patterns like `data-init`
- Offers no unique insights beyond Experiment 2

Since Experiment 2 (data-init pattern) is clearly superior from a Datastar purity standpoint, testing this hybrid approach adds no value.

**Evaluation:**
- ✅ Works: Likely YES (similar to baseline)
- 📊 Datastar Purity: ~3/5 (estimated - imperative, not reactive)
- 🎯 Simplicity: 3/5 (estimated - one button but long handler)
- 🔧 Maintainability: 3/5 (estimated - imperative logic)

---

## Experiment 2: data-init Auto-Connect Pattern ✅ WINNER

**Pattern:**
```html
<div data-signals="{sessionId: '', sseActive: false}">
  <button data-on:click="fetch(...).then(r => r.json()).then(d => $sessionId = d.id)">
    Create Session
  </button>

  <!-- Auto-connect when sessionId exists -->
  <div data-show="$sessionId !== '' && !$sseActive"
       data-init="const es = new EventSource('/event');
                  es.onopen = () => $sseActive = true;
                  es.onmessage = e => $events.push(e.data);">
  </div>
</div>
```

**Hypothesis:** Uses Datastar's `data-init` to react to state changes, more declarative.

**Test Results:**
- ✅ SSE auto-connects immediately after session creation
- ✅ "SSE Connection Active" message appears
- ✅ Events received and displayed correctly
- ✅ Fully reactive and declarative

**Evaluation:**
- ✅ Works: YES (perfectly!)
- 📊 Datastar Purity: 4/5 (uses signals, data-init, data-show - very idiomatic)
- 🎯 Simplicity: 4/5 (automatic, user just clicks once)
- 🔧 Maintainability: 5/5 (declarative, state-driven, clear flow)

**Key Learning:** This is the "Datastar way" for OpenCode integration. Reactive, declarative, and leverages Datastar's strengths while working with OpenCode's JSON events.

---

## Experiment 3: @get() for SSE (Purest Attempt)

**Pattern:**
```html
<button data-on:click="
  fetch(...).then(r => r.json()).then(d => {
    $sessionId = d.id;
    @get('http://127.0.0.1:42992/event')  // Datastar's SSE action
  })
">Create Session & Connect</button>
```

**Hypothesis:** Most "Datastar purist" but may not work because OpenCode sends JSON events, not Datastar HTML patches.

**Test Results:**
- SSE connection appears to open (no errors)
- No events appear in UI or console
- No errors thrown
- POST/response worked as expected

**Conclusion:** `@get()` silently ignores non-Datastar events. It opens the SSE connection but doesn't process OpenCode's JSON events because they lack the expected format (`datastar-patch-elements`, `datastar-merge-signals`, etc.).

**Evaluation:**
- ✅ Works: NO (opens connection but processes nothing)
- 📊 Datastar Purity: 5/5 (most idiomatic, but incompatible)
- 🎯 Simplicity: 5/5 (one line of code)
- 🔧 Maintainability: N/A (doesn't work for OpenCode)

**Key Learning:** Datastar's `@get()` is SSE-format-specific. It requires Datastar event types, not arbitrary JSON events.

---

## Results Summary

| Approach | Works | Purity | Simplicity | Maintainability | Notes |
|----------|-------|--------|------------|-----------------|-------|
| Baseline | ✅ | 2/5 | 4/5 | 3/5 | Manual 3-step process |
| Exp 1: Combined Button | Skipped | ~3/5 | ~3/5 | ~3/5 | No purity value over Exp 2 |
| **Exp 2: data-init** | **✅** | **4/5** | **4/5** | **5/5** | **WINNER - Reactive & declarative** |
| Exp 3: @get() | ❌ | 5/5 | 5/5 | N/A | Silently ignores JSON events |

## Recommendation

**Use Experiment 2 (data-init pattern) for OpenCode/Datastar integration.**

**Why:**
1. ✅ **Most "Datastar purist" that actually works** - Leverages reactive patterns (data-init, data-show, signals)
2. ✅ **Automatic and seamless** - SSE connects when session exists, no manual steps
3. ✅ **Declarative** - State-driven, not imperative
4. ✅ **Maintainable** - Clear separation of concerns, easy to understand flow
5. ✅ **Idiomatic Datastar** - Uses framework features as intended

**Key Insight:**
- Datastar's `@get()` only works with Datastar-formatted SSE events
- For non-Datastar SSE sources (like OpenCode's JSON events), use manual EventSource
- Wrap EventSource in Datastar's reactive patterns (data-init + signals) for idiomatic integration

**Implementation:**
See `index-experiment2-init.html` for the complete working pattern.
