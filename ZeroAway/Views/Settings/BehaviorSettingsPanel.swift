import SwiftUI

struct BehaviorSettingsPanel: View {
    @EnvironmentObject private var controller: AppController
    @ObservedObject private var presence = PresenceMonitor.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SettingsPageHeader(title: L("behavior.title"), subtitle: L("behavior.subtitle"))

                SettingsPaddedCard {
                    VStack(alignment: .leading, spacing: 0) {
                        idleThresholdSection

                        Divider().padding(.vertical, 4)

                        nudgeDistanceSection

                        Divider().padding(.vertical, 4)

                        scheduleGateSection

                        Divider().padding(.vertical, 4)

                        presenceGateSection

                        Divider().padding(.vertical, 4)

                        resumeSessionSection
                    }
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var idleThresholdSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("behavior.idle.title"))
                    .font(.headline)
                Spacer(minLength: 12)
                Text(DurationFormat.short(seconds: controller.idleThreshold))
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }

            Text(L("behavior.idle.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { IdleThresholdSlider.position(for: controller.idleThreshold) },
                        set: { controller.idleThreshold = IdleThresholdSlider.seconds(for: $0) }
                    ),
                    in: 0...1
                )

                HStack {
                    Text(DurationFormat.short(seconds: IdleThresholdSlider.minSeconds))
                    Spacer()
                    Text(DurationFormat.short(seconds: IdleThresholdSlider.maxSeconds))
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
    }

    private var nudgeDistanceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("behavior.nudge.title"))
                    .font(.headline)
                Spacer(minLength: 12)
                Text("\(controller.nudgeDistance) px")
                    .font(.body.monospacedDigit().weight(.medium))
                    .foregroundStyle(Color.accentColor)
            }

            Text(L("behavior.nudge.caption"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { Double(controller.nudgeDistance) },
                        set: { controller.nudgeDistance = Int($0.rounded()) }
                    ),
                    in: Double(NudgeDistanceSlider.minPixels)...Double(NudgeDistanceSlider.maxPixels),
                    step: 1
                )

                HStack {
                    Text("\(NudgeDistanceSlider.minPixels) px")
                    Spacer()
                    Text("\(NudgeDistanceSlider.maxPixels) px")
                }
                .font(.caption2)
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
    }

    private var scheduleGateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("behavior.schedule.title"))
                        .font(.headline)
                    Text(
                        controller.workSchedule.enabled
                            ? L("behavior.schedule.caption_on")
                            : L("behavior.schedule.caption_off")
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle(
                    "",
                    isOn: Binding(
                        get: { controller.workSchedule.enabled },
                        set: { enabled in
                            var schedule = controller.workSchedule
                            schedule.enabled = enabled
                            controller.workSchedule = schedule
                        }
                    )
                )
                .toggleStyle(.switch)
                .labelsHidden()
            }

            if controller.workSchedule.enabled {
                TimelineView(.periodic(from: .now, by: 30)) { context in
                    if let status = ScheduleEvaluator.gateStatusLine(
                        now: context.date,
                        schedule: controller.workSchedule
                    ) {
                        Label(status.text, systemImage: status.isActive ? "checkmark.circle" : "clock")
                            .font(.caption)
                            .foregroundStyle(status.isActive ? Color.green : Color.orange)
                    }
                }
            }
        }
        .padding(.vertical, 14)
    }

    private var presenceGateSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("behavior.presence.title"))
                        .font(.headline)
                    Text(L("behavior.presence.caption_settings"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Toggle("", isOn: $controller.requirePresenceApp)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }

            if controller.requirePresenceApp, let status = presence.gateStatusLine {
                Label(status.text, systemImage: status.isSatisfied ? "checkmark.circle" : "info.circle")
                    .font(.caption)
                    .foregroundStyle(status.isSatisfied ? Color.green : Color.orange)
            }
        }
        .padding(.vertical, 14)
    }

    private var resumeSessionSection: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L("behavior.resume_session"))
                    .font(.headline)
                Text(L("behavior.resume_session.caption"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Toggle("", isOn: $controller.resumeSessionOnLaunch)
                .toggleStyle(.switch)
                .labelsHidden()
        }
        .padding(.vertical, 14)
    }
}
