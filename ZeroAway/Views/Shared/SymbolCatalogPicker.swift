import SwiftUI

/// Shared SF Symbol grid with search — used by icon settings and presence editor.
struct SymbolCatalogPicker: View {
    @Binding var selection: String
    var cellSide: CGFloat = 50
    var gridSpacing: CGFloat = 10

    @State private var search = ""

    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: cellSide, maximum: cellSide), spacing: gridSpacing)]
    }

    private var filteredSymbols: [String] {
        let all = SFSymbolCatalog.available
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return all }
        return all.filter { $0.lowercased().contains(q) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text(L("icons.symbols.title"))
                    .font(.title3.weight(.semibold))
                Spacer()
                Text("\(filteredSymbols.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }

            TextField(L("common.search_ellipsis"), text: $search)
                .textFieldStyle(.roundedBorder)

            ScrollView {
                LazyVGrid(columns: gridColumns, alignment: .leading, spacing: gridSpacing) {
                    ForEach(filteredSymbols, id: \.self) { name in
                        symbolCell(name)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func symbolCell(_ name: String) -> some View {
        let selected = selection == name
        return Button {
            selection = name
        } label: {
            Image(systemName: name)
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.monochrome)
                .foregroundStyle(selected ? Color.accentColor : Color.primary)
                .frame(width: cellSide, height: cellSide)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(selected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(selected ? Color.accentColor.opacity(0.8) : Color.clear, lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .help(name)
    }
}
