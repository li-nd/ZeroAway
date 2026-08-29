import SwiftUI

struct SessionModePicker: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L("menubar.session_mode"))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                powerChip

                Rectangle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 1, height: 28)

                HStack(spacing: 6) {
                    ForEach(SessionDuration.allCases) { duration in
                        durationChip(duration)
                    }
                }
                .opacity(controller.isActive ? 1 : 0.55)
            }
        }
    }

    private var powerChip: some View {
        let isOff = !controller.isActive
        return Button {
            if isOff {
                controller.selectSession(.duration(controller.duration))
            } else {
                controller.selectSession(.off)
            }
        } label: {
            Text(isOff ? L("menubar.session_off") : L("menubar.session_on"))
                .font(.system(size: 12, weight: .semibold))
                .frame(minWidth: 44)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isOff ? Color.primary.opacity(0.06) : Color.accentColor.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isOff ? Color.primary.opacity(0.12) : Color.accentColor.opacity(0.5), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!controller.isTrusted || controller.isNotWorking)
        .help(isOff ? L("menubar.session_on_help") : L("menubar.session_off_help"))
    }

    private func durationChip(_ duration: SessionDuration) -> some View {
        let isSelected = controller.isActive && controller.duration == duration
        return Button {
            controller.selectSession(.duration(duration))
        } label: {
            Text(duration.label)
                .font(.system(size: 12, weight: isSelected ? .semibold : .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!controller.isTrusted || controller.isNotWorking)
        .help(duration.sessionLabel)
    }
}
