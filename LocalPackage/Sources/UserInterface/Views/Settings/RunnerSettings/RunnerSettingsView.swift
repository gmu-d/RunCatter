/*
 RunnerSettingsView.swift
 UserInterface

 Created by Takuto Nakamura on 2026/06/08.
 Copyright 2026 Kyome22 (Takuto Nakamura)

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Model
import SwiftUI

struct RunnerSettingsView: View {
    @StateObject var store: RunnerSettings

    var body: some View {
        Form {
            Section {
                Toggle(isOn: Binding<Bool>(
                    get: { store.speedDecreasesUnderLoad },
                    asyncSet: { await store.send(.slowDownUnderLoadToggleSwitched($0)) }
                )) {
                    Text("slowDownUnderLoad", bundle: .module)
                }
                Toggle(isOn: Binding<Bool>(
                    get: { store.isFlippedHorizontally },
                    asyncSet: { await store.send(.flipHorizontallyToggleSwitched($0)) }
                )) {
                    Text("flipHorizontally", bundle: .module)
                }
            } header: {
                Text("appearance", bundle: .module)
            }
            Section {
                Toggle(isOn: Binding<Bool>(
                    get: { store.ramFillConfiguration.isVisible },
                    asyncSet: { isVisible in
                        var configuration = store.ramFillConfiguration
                        configuration.isVisible = isVisible
                        await store.send(.ramFillConfigurationChanged(configuration))
                    }
                )) {
                    Text("showRamFill", bundle: .module)
                }
                LabeledContent {
                    Slider(
                        value: Binding<Double>(
                            get: { Double(store.ramFillConfiguration.lowThreshold) },
                            asyncSet: { value in
                                var configuration = store.ramFillConfiguration
                                configuration.lowThreshold = Int(value.rounded())
                                await store.send(.ramFillConfigurationChanged(configuration))
                            }
                        ),
                        in: 1...99,
                        step: 1
                    )
                    Text(verbatim: "\(store.ramFillConfiguration.lowThreshold)%")
                } label: {
                    Text("lowLoadState", bundle: .module)
                }
                LabeledContent {
                    Slider(
                        value: Binding<Double>(
                            get: { Double(store.ramFillConfiguration.highThreshold) },
                            asyncSet: { value in
                                var configuration = store.ramFillConfiguration
                                configuration.highThreshold = Int(value.rounded())
                                await store.send(.ramFillConfigurationChanged(configuration))
                            }
                        ),
                        in: 1...99,
                        step: 1
                    )
                    Text(verbatim: "\(store.ramFillConfiguration.highThreshold)%")
                } label: {
                    Text("highLoadState", bundle: .module)
                }
                LabeledContent {
                    ColorPicker(
                        selection: Binding<Color>(
                            get: {
                                Color(hex: store.ramFillConfiguration.lowColorHex)
                                    ?? Color(nsColor: .controlAccentColor)
                            },
                            asyncSet: { color in
                                var configuration = store.ramFillConfiguration
                                configuration.lowColorHex = color.hex
                                await store.send(.ramFillConfigurationChanged(configuration))
                            }
                        ),
                        supportsOpacity: false
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                } label: {
                    Text("lowLoadState", bundle: .module)
                }
                LabeledContent {
                    ColorPicker(
                        selection: Binding<Color>(
                            get: {
                                Color(hex: store.ramFillConfiguration.normalColorHex)
                                    ?? Color(nsColor: .controlAccentColor)
                            },
                            asyncSet: { color in
                                var configuration = store.ramFillConfiguration
                                configuration.normalColorHex = color.hex
                                await store.send(.ramFillConfigurationChanged(configuration))
                            }
                        ),
                        supportsOpacity: false
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                } label: {
                    Text("normalLoadState", bundle: .module)
                }
                LabeledContent {
                    ColorPicker(
                        selection: Binding<Color>(
                            get: {
                                Color(hex: store.ramFillConfiguration.highColorHex)
                                    ?? Color(nsColor: .controlAccentColor)
                            },
                            asyncSet: { color in
                                var configuration = store.ramFillConfiguration
                                configuration.highColorHex = color.hex
                                await store.send(.ramFillConfigurationChanged(configuration))
                            }
                        ),
                        supportsOpacity: false
                    ) {
                        EmptyView()
                    }
                    .labelsHidden()
                } label: {
                    Text("highLoadState", bundle: .module)
                }
                Button {
                    Task {
                        await store.send(.ramFillColorsReset)
                    }
                } label: {
                    Text("resetRamFillColors", bundle: .module)
                }
            } header: {
                Text("ramFill", bundle: .module)
            }
            CustomRunnerSettingsSectionView(store: store.customRunnerSettings)
        }
        .formStyle(.grouped)
        .task {
            await store.send(.viewAppeared(String(describing: Self.self)))
        }
    }
}

extension RunnerSettings: ObservableObject {}
