import AllocatedUnfairLock
import AppKit
import Foundation
import Testing

@testable import DataSource
@testable import Model

struct RunnerBarTests {
    private func makeEventBridge(
        recording callStack: AllocatedUnfairLock<[String]>,
        capturing colors: AllocatedUnfairLock<[CGColor?]>? = nil
    ) -> RunnerBar.Action.EventBridge {
        RunnerBar.Action.EventBridge(
            getBundleImage: { name in
                callStack.withLock { $0.append("getBundleImage: \(name)") }
                return NSImage(size: CGSize(width: 10, height: 18))
            },
            setSize: { size in
                callStack.withLock { $0.append("setSize: \(size.width)x\(size.height)") }
            },
            setFrames: { images, isTemplate in
                callStack.withLock { $0.append("setFrames: \(images.count), \(isTemplate)") }
            },
            setColor: { _, _ in },
            setSpeed: { speed in
                callStack.withLock { $0.append("setSpeed: \(speed)") }
            },
            setRamFillState: { level, color in
                callStack.withLock { $0.append("setRamFillState: \(level)") }
                colors?.withLock { $0.append(color) }
            }
        )
    }

    @MainActor @Test
    func send_viewAppeared_applies_latest_runner_bundle_to_event_bridge() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(
                runner: .default,
                frames: [.preset("cat-frame-0"), .preset("cat-frame-1")]
            ))
        }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack)))
        await waitUntil { callStack.withLock(\.self).count >= 4 }
        #expect(sut.isReady)
        #expect(sut.size == CGSize(width: 10, height: 18))
        #expect(sut.isTemplate)
        #expect(callStack.withLock(\.self) == [
            "getBundleImage: cat-frame-0",
            "getBundleImage: cat-frame-1",
            "setSize: 10.0x18.0",
            "setFrames: 2, true",
        ])
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewAppeared_applies_runner_speed_to_event_bridge() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock { $0.runnerSpeeds.send(12.5) }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack)))
        await waitUntil { !callStack.withLock(\.self).isEmpty }
        #expect(callStack.withLock(\.self) == ["setSpeed: 12.5"])
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewAppeared_applies_ram_fill_state_to_event_bridge() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock { $0.runnerRamFillStates.send(RamFillState(level: 13, zone: .high)) }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let colors = AllocatedUnfairLock<[CGColor?]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack, capturing: colors)))
        await waitUntil { !callStack.withLock(\.self).isEmpty }
        #expect(callStack.withLock(\.self) == ["setRamFillState: 13"])
        #expect(colors.withLock(\.self) == [CGColor.from(hex: "#FF3B30")])
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewAppeared_sends_nil_color_when_ram_fill_is_hidden() async {
        let hidden = RamFillConfiguration(
            isVisible: false,
            lowThreshold: 50,
            highThreshold: 80,
            lowColorHex: "#34C759",
            normalColorHex: nil,
            highColorHex: "#FF3B30"
        )
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock { $0.runnerRamFillStates.send(RamFillState(level: 13, zone: .high)) }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let colors = AllocatedUnfairLock<[CGColor?]>(initialState: [])
        let sut = RunnerBar(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.data = { key in
                    key == .ramFillConfiguration ? try? JSONEncoder().encode(hidden) : nil
                }
            }
        ))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack, capturing: colors)))
        await waitUntil { !callStack.withLock(\.self).isEmpty }
        #expect(colors.withLock(\.self) == [nil])
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewAppeared_ignores_thumbnail_bundle() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(runner: .default, frame: .preset("cat-frame-0")))
        }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack)))
        try? await Task.sleep(for: .milliseconds(50))
        #expect(callStack.withLock(\.self).isEmpty)
        #expect(sut.icon == nil)
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewAppeared_with_broken_frames_clears_icon() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        appState.withLock {
            $0.runnerBundles.send(RunnerBundle(runner: .default, frames: [.broken]))
        }
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack)))
        await waitUntil { callStack.withLock(\.self).count >= 2 }
        #expect(sut.icon == nil)
        #expect(sut.size == .zero)
        #expect(callStack.withLock(\.self) == [
            "setSize: 0.0x0.0",
            "setFrames: 0, true",
        ])
        await sut.send(.viewDisappeared)
    }

    @MainActor @Test
    func send_viewDisappeared_stops_observing_streams() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let callStack = AllocatedUnfairLock<[String]>(initialState: [])
        let sut = RunnerBar(.testDependencies(appStateClient: .testDependency(appState)))
        await sut.send(.viewAppeared("RunnerBarTests", makeEventBridge(recording: callStack)))
        await sut.send(.viewDisappeared)
        appState.withLock { $0.runnerSpeeds.send(5.0) }
        try? await Task.sleep(for: .milliseconds(50))
        #expect(callStack.withLock(\.self).isEmpty)
    }
}
