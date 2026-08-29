import SwiftUI

struct ScheduleSettingsPanel: View {
    @EnvironmentObject private var controller: AppController

    var body: some View {
        ScrollView {
            WorkScheduleEditorView(schedule: $controller.workSchedule)
                .padding(32)
        }
    }
}
