# RAM Fill Level Implementation Plan (Design Doc #1: Dynamic Fill Masking, Option A)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fill the bottom of the menu-bar runner with the system accent color proportionally to RAM usage (5% quantization, 20 levels), riding the existing CALayer template-mask pipeline with zero added CPU cost.

**Architecture:** Extend the existing telemetry loop (`AppDelegate` → `RunnerService`) with a new `AppState` stream carrying the quantized RAM fill level. The `RunnerBar` store forwards it through a new `EventBridge` closure to a `fillLayer` sublayer of `RunnerLayer`, which is clipped by the same template mask (sublayers are masked by their superlayer's mask). Appearance changes resolve `controlAccentColor` alongside the existing tint color.

**Tech Stack:** Swift 6.2, AppKit/CoreAnimation, Swift Testing, LUCA architecture (`DataSource` ← `Model` ← `UserInterface`).

## Global Constraints

- Xcode 26.5+, macOS 26.3+, Swift 6.2 with `ExistentialAny`.
- Fill is rendered only in template (monochrome) mode; in color mode `fillLayer` stays hidden (v1 scope).
- RAM percentage scale: `Percentage.value` is 0–100 (`Percentage(rawValue: 0.5).value == 50.0`).
- Quantization: `level = clamp(Int(percentage / 5.0), 0...20)` — anti-jitter only; no bitmap cache.
- CODING_STYLE.md: English identifiers, no comments, no `// MARK:`, member ordering (stored deps → state → init → public → private helpers → nested types), trailing commas in multiline collections, snake_case test names `subject_condition_expectation`, whole-value `#expect` assertions.
- License header on all files under `LocalPackage/Sources/`; none on test files.
- Build/test: from `LocalPackage/`, `xcodebuild test -scheme LocalPackage-Package -destination 'platform=macOS,arch=arm64'` (CI parity). `AsyncStreamBundle` replays `latestValue` on subscription (verified by existing tests).

### Task 1: DataSource — AppState stream

**Files:**
- Modify: `LocalPackage/Sources/DataSource/Entities/AppState.swift`

- [ ] Add `public var runnerRamFillLevels = AsyncStreamBundle<Int>()` after `runnerSpeeds`.

### Task 2: Model — RunnerService quantizer

**Files:**
- Modify: `LocalPackage/Sources/Model/Services/RunnerService.swift`
- Test: `LocalPackage/Tests/ModelTests/ServiceTests/RunnerServiceTests.swift`

**Interfaces:**
- Produces: `func updateRamFillLevel(from memoryInfo: MemoryInfo?) -> Void`; `static func ramFillLevel(usagePercentage: Double?) -> Int`

- [ ] Failing tests (mirror `updateRunnerSpeed` tests):
  - `updateRamFillLevel_sends_quantized_fill_level_proportional_to_memory_usage`: `MemoryInfo(percentage: Percentage(rawValue: 0.5), ...)` → latest `runnerRamFillLevels` == 10
  - `updateRamFillLevel_sends_zero_fill_level_when_memoryInfo_is_nil`: → 0
  - `ramFillLevel_clamps_at_full_memory_usage`: percentage 1.0 (value 100) → 20
- [ ] Run: `xcodebuild test ... -only-testing:ModelTests/RunnerServiceTests` → FAIL (symbol missing)
- [ ] Implement in `RunnerService`:

```swift
func updateRamFillLevel(from memoryInfo: MemoryInfo?) {
    appStateClient.send(\.runnerRamFillLevels, Self.ramFillLevel(usagePercentage: memoryInfo?.percentage.value))
}

static func ramFillLevel(usagePercentage: Double?) -> Int {
    guard let usagePercentage else { return .zero }
    return min(20, max(0, Int(usagePercentage / 5.0)))
}
```

- [ ] Run tests → PASS
- [ ] Wire in `AppDelegate`: `runnerService.updateRamFillLevel(from: value.memoryInfo)` after the `updateRunnerSpeed` call.

### Task 3: Model — RunnerBar store + EventBridge

**Files:**
- Modify: `LocalPackage/Sources/Model/Stores/RunnerBar.swift`
- Test: `LocalPackage/Tests/ModelTests/StoreTests/RunnerBarTests.swift`

**Interfaces:**
- Consumes: `AppState.runnerRamFillLevels.stream` (Task 1)
- Produces: `EventBridge.setFillColor: @MainActor @Sendable (CGColor) -> Void`, `EventBridge.setRamFillLevel: @MainActor @Sendable (Int) -> Void`

- [ ] Update `makeEventBridge` in tests to record `"setFillColor"` and `"setRamFillLevel: \(level)"` (existing exact-stack expectations stay valid — no appearance/level events are sent in those tests).
- [ ] New test `send_viewAppeared_applies_ram_fill_level_to_event_bridge`: pre-send 13 → `["setRamFillLevel: 13"]`.
- [ ] Store changes:
  - state: `@ObservationIgnored private var fillColor = CGColor.black`
  - 4th immediate task consuming `runnerRamFillLevels.stream` → `update(ramFillLevel:)` → `eventBridge?.setRamFillLevel(value)`
  - `update(appearance:)`: resolve `fillColor = NSColor.controlAccentColor.cgColor` inside `performAsCurrentDrawingAppearance`, then `eventBridge?.setFillColor(fillColor)` after `setColor`
  - EventBridge: append `setFillColor` / `setRamFillLevel` closures + init params at the end.
- [ ] Run RunnerBarTests → PASS

### Task 4: UserInterface — RunnerLayer fill sublayer + view wiring

**Files:**
- Modify: `LocalPackage/Sources/UserInterface/Views/RunnerBar/RunnerLayer.swift`
- Modify: `LocalPackage/Sources/UserInterface/Views/RunnerBar/RunnerBarView.swift`

- [ ] `RunnerLayer`: add `private let fillLayer = CALayer()`, `private var fillColor: CGColor?`, `private var ramFillLevel = Int.zero`. In `init`: `fillLayer.isHidden = true`, `addSublayer(fillLayer)` (sublayer inherits the superlayer's template mask automatically).
- [ ] `setFrames`: after `frame` update, call `updateRamFill()` inside the same transaction (re-fit fill to new bounds).
- [ ] New methods:

```swift
func setFillColor(_ color: CGColor) {
    fillColor = color
    updateRamFill()
}

func setRamFillLevel(_ level: Int) {
    ramFillLevel = level
    updateRamFill()
}

private func updateRamFill() {
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    fillLayer.backgroundColor = fillColor
    fillLayer.frame = CGRect(origin: .zero, size: CGSize(width: bounds.width, height: bounds.height * CGFloat(ramFillLevel) / 20.0))
    fillLayer.isHidden = fillColor == nil || ramFillLevel == .zero || mask == nil
    CATransaction.commit()
}
```

- [ ] `RunnerBarView` EventBridge: `setFillColor: { runnerLayer.setFillColor($0) }`, `setRamFillLevel: { runnerLayer.setRamFillLevel($0) }`.
- [ ] Coordinate note: `RunnerLayer` is not geometry-flipped, so sublayer origin `.zero` anchors to the visually bottom edge regardless of the root button layer's flip state.

### Task 5: Full verification

- [ ] `xcodebuild test -scheme LocalPackage-Package -destination 'platform=macOS,arch=arm64'` → all PASS
- [ ] Manual QA (user): run app, toggle Dark/Light, stress RAM (`memory_pressure`), confirm fill follows memory usage, Activity Monitor shows no CPU regression.
