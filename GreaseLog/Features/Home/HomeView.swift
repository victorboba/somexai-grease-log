import SwiftUI
import SwiftData

/// Every trap on the site, worst first.
///
/// A restaurant manager opens this to answer one question — is anything going to get us
/// cited — so the list is ordered by trouble rather than by name.
struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Trap.name) private var traps: [Trap]

    @State private var editing: Trap?
    @State private var showingSettings = false
    @State private var showingHowTo = false
    @State private var exportFile: ExportFile?
    @State private var exportError: String?

    private var ordered: [Trap] {
        traps.sorted { a, b in
            func rank(_ t: Trap) -> Int {
                switch t.status {
                case .overQuarterRule: 0
                case .overdue: 1
                case .dueSoon: 2
                case .noHistory: 3
                case .current: 4
                }
            }
            return rank(a) == rank(b) ? a.name < b.name : rank(a) < rank(b)
        }
    }

    private var citable: Int { traps.filter { $0.status.isCitable }.count }

    var body: some View {
        NavigationStack {
            Group {
                if traps.isEmpty {
                    ContentUnavailableView {
                        Label("No traps yet", systemImage: "drop.triangle")
                    } description: {
                        Text("Add each grease trap and interceptor once. After that it is a minute per pump-out.")
                    } actions: {
                        Button("Add a trap") { newTrap() }.buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        if citable > 0 {
                            Section {
                                Label("\(citable) \(citable == 1 ? "trap is" : "traps are") citable today",
                                      systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.red)
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                        Section {
                            ForEach(ordered) { trap in
                                Button { editing = trap } label: { TrapRow(trap: trap) }
                                    .buttonStyle(.plain)
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
            }
            .navigationTitle("Grease traps")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingHowTo = true } label: {
                        Label("How do I use this app?", systemImage: "questionmark.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button { newTrap() } label: { Label("Add a trap", systemImage: "plus") }
                        if !traps.isEmpty {
                            Button { exportPDF() } label: {
                                Label("Inspection record (PDF)", systemImage: "doc.richtext")
                            }
                            Button { exportCSV() } label: {
                                Label("Export all as CSV", systemImage: "tablecells")
                            }
                        }
                        Divider()
                        Button { showingSettings = true } label: { Label("Settings", systemImage: "gear") }
                    } label: { Label("More", systemImage: "ellipsis.circle") }
                }
            }
            .sheet(item: $editing) { TrapDetailView(trap: $0) }
            .sheet(isPresented: $showingSettings) { SettingsView() }
            .sheet(isPresented: $showingHowTo) { HowToView() }
            .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
            .alert("Export failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: { Text(exportError ?? "") }
        }
    }

    private func newTrap() {
        let trap = Trap()
        context.insert(trap)
        try? context.save()
        editing = trap
    }

    private func delete(_ offsets: IndexSet) {
        for index in offsets { context.delete(ordered[index]) }
        try? context.save()
    }

    private func exportCSV() {
        do { exportFile = ExportFile(url: try CSVExporter.export(traps)) }
        catch { exportError = error.localizedDescription }
    }

    private func exportPDF() {
        do { exportFile = ExportFile(url: try PDFExporter.export(traps)) }
        catch { exportError = error.localizedDescription }
    }
}

private struct TrapRow: View {
    let trap: Trap

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: trap.status.symbol)
                .foregroundStyle(tint).font(.title3).frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(trap.name.isEmpty ? "Unnamed trap" : trap.name).font(.headline)
                if !trap.location.isEmpty {
                    Text(trap.location).font(.subheadline).foregroundStyle(.secondary)
                }
                Text(dueText).font(.caption).foregroundStyle(tint)
            }
            Spacer()
            if let fullness = trap.latestFullness {
                Text("\(Int(fullness * 100))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(fullness >= 0.25 ? .red : .secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private var dueText: String {
        if trap.status == .overQuarterRule { return trap.status.headline }
        guard let days = trap.daysUntilDue() else { return "No service recorded" }
        if days < 0 { return "Overdue by \(-days) \(-days == 1 ? "day" : "days")" }
        if days == 0 { return "Due today" }
        return "Due in \(days) \(days == 1 ? "day" : "days")"
    }

    private var tint: Color {
        switch trap.status {
        case .overQuarterRule, .overdue: .red
        case .dueSoon: .orange
        case .current: .green
        case .noHistory: .secondary
        }
    }
}
