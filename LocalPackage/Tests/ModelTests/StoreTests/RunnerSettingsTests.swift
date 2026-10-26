import AllocatedUnfairLock
import Foundation
import Testing

@testable import DataSource
@testable import Model

struct RunnerSettingsTests {
    private func makeSetRecorder() -> (lock: AllocatedUnfairLock<[String]>, client: UserDefaultsClient) {
        let setCallStack = AllocatedUnfairLock<[String]>(initialState: [])
        let client = testDependency(of: UserDefaultsClient.self) {
            $0.set = { value, key in
                let entry = "set: \(key) = \(value ?? "nil")"
                setCallStack.withLock { $0.append(entry) }
            }
        }
        return (setCallStack, client)
    }

    @MainActor @Test
    func send_slowDownUnderLoadToggleSwitched_persists_and_updates_runner_speed() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let recorder = makeSetRecorder()
        let sut = RunnerSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: recorder.client
        ))
        await sut.send(.slowDownUnderLoadToggleSwitched(true))
        #expect(sut.speedDecreasesUnderLoad)
        #expect(recorder.lock.withLock(\.self) == ["set: SPEED_DECREASES_UNDER_LOAD = true"])
        #expect(appState.withLock(\.runnerSpeeds.latestValue) == 1.0)
    }

    @MainActor @Test
    func send_flipHorizontallyToggleSwitched_persists_and_resends_current_bundle() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let bundle = RunnerBundle(runner: .default, frame: .preset("cat-frame-0"))
        appState.withLock { $0.runnerBundles.send(bundle) }
        let recorder = makeSetRecorder()
        let sut = RunnerSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            userDefaultsClient: recorder.client
        ))
        await sut.send(.flipHorizontallyToggleSwitched(true))
        #expect(sut.isFlippedHorizontally)
        #expect(recorder.lock.withLock(\.self) == ["set: IS_FLIPPED_HORIZONTALLY = true"])
        #expect(appState.withLock(\.runnerBundles.latestValue) == bundle)
    }

    @MainActor @Test
    func send_ramFillConfigurationChanged_persists_and_updates_ram_fill_state() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let stored = AllocatedUnfairLock<[String: Data]>(initialState: [:])
        let sut = RunnerSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            systemInfoObserverClient: testDependency(of: SystemInfoObserverClient.self) {
                $0.currentSystemInfo = { .cpuZero() }
            },
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.set = { value, key in
                    if let data = value as? Data {
                        stored.withLock { $0[key] = data }
                    }
                }
                $0.data = { key in
                    stored.withLock { $0[key] }
                }
            }
        ))
        var configuration = RamFillConfiguration.default
        configuration.highThreshold = 85
        await sut.send(.ramFillConfigurationChanged(configuration))
        #expect(sut.ramFillConfiguration == configuration)
        #expect(stored.withLock { $0[.ramFillConfiguration] } != nil)
        #expect(appState.withLock(\.runnerRamFillStates.latestValue) == RamFillState(level: 0, zone: .normal))
    }

    @MainActor @Test
    func send_ramFillConfigurationChanged_clamps_inverted_thresholds() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let stored = AllocatedUnfairLock<[String: Data]>(initialState: [:])
        let sut = RunnerSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            systemInfoObserverClient: testDependency(of: SystemInfoObserverClient.self) {
                $0.currentSystemInfo = { .cpuZero() }
            },
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.set = { value, key in
                    if let data = value as? Data {
                        stored.withLock { $0[key] = data }
                    }
                }
                $0.data = { key in
                    stored.withLock { $0[key] }
                }
            }
        ))
        await sut.send(.ramFillConfigurationChanged(RamFillConfiguration(
            isVisible: true,
            lowThreshold: 95,
            highThreshold: 10,
            lowColorHex: nil,
            normalColorHex: nil,
            highColorHex: nil
        )))
        #expect(sut.ramFillConfiguration.lowThreshold == 9)
        #expect(sut.ramFillConfiguration.highThreshold == 10)
    }

    @MainActor @Test
    func send_ramFillColorsReset_restores_default_colors_and_visibility() async {
        let appState = AllocatedUnfairLock<AppState>(initialState: .init())
        let stored = AllocatedUnfairLock<[String: Data]>(initialState: [:])
        let sut = RunnerSettings(.testDependencies(
            appStateClient: .testDependency(appState),
            systemInfoObserverClient: testDependency(of: SystemInfoObserverClient.self) {
                $0.currentSystemInfo = { .cpuZero() }
            },
            userDefaultsClient: testDependency(of: UserDefaultsClient.self) {
                $0.set = { value, key in
                    if let data = value as? Data {
                        stored.withLock { $0[key] = data }
                    }
                }
                $0.data = { key in
                    stored.withLock { $0[key] }
                }
            }
        ))
        var configuration = RamFillConfiguration.default
        configuration.isVisible = false
        configuration.lowColorHex = "#00FF00"
        await sut.send(.ramFillConfigurationChanged(configuration))
        await sut.send(.ramFillColorsReset)
        #expect(sut.ramFillConfiguration.isVisible == true)
        #expect(sut.ramFillConfiguration.lowColorHex == "#34C759")
        #expect(sut.ramFillConfiguration.normalColorHex == nil)
        #expect(sut.ramFillConfiguration.highColorHex == "#FF3B30")
        #expect(sut.ramFillConfiguration.lowThreshold == configuration.lowThreshold)
        #expect(stored.withLock { $0[.ramFillConfiguration] } != nil)
    }
}
