import SwiftUI
import SwiftData

/// One trap: what it is, when it was last done, and what the depth says.
struct TrapDetailView: View {
    @Bindable var trap: Trap
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.requestReview) private var requestReview

    @State private var addingService = false
    @State private var addingCheck = false
    @State private var editingService: ServiceRecord?
    @State private var exportFile: ExportFile?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trap.status.headline).font(.headline)
                            Text(trap.status.detail).font(.caption).foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: trap.status.symbol).foregroundStyle(tint)
                    }
                }

                Section("The trap") {
                    TextField("Name", text: $trap.name)
                    TextField("Location", text: $trap.location)
                    Picker("Type", selection: Binding(
                        get: { trap.kind }, set: { trap.kind = $0 })) {
                        ForEach(TrapKind.allCases) { Text($0.name).tag($0) }
                    }
                    Text(trap.kind.hint).font(.caption).foregroundStyle(.secondary)
                    TextField("Permit number", text: $trap.permitNumber)
                }

                Section {
                    LabeledContent("Capacity") {
                        TextField("gallons", value: $trap.capacityGallons, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Liquid depth") {
                        TextField("inches", value: $trap.liquidDepthInches, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Stepper("Clean every \(trap.requiredIntervalDays) days",
                            value: $trap.requiredIntervalDays, in: 7...365, step: 7)
                } header: {
                    Text("What your programme requires")
                } footer: {
                    Text("Liquid depth is what the quarter rule is measured against, so it is worth getting from the tank drawing rather than guessing.")
                }

                Section {
                    ForEach(trap.sortedServices) { service in
                        Button { editingService = service } label: { ServiceRow(service: service) }
                            .buttonStyle(.plain)
                    }
                    .onDelete(perform: deleteServices)
                    Button { addingService = true } label: {
                        Label("Record a pump-out", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Services")
                } footer: {
                    Text("Photograph the manifest. That is the document an inspector asks for, and paper copies go missing.")
                }

                Section {
                    ForEach(trap.sortedChecks) { check in
                        HStack {
                            Text(check.date.formatted(date: .abbreviated, time: .omitted))
                            Spacer()
                            Text("\(check.greaseInches, format: .number) + \(check.solidsInches, format: .number) in")
                                .foregroundStyle(.secondary).font(.callout.monospacedDigit())
                        }
                    }
                    .onDelete(perform: deleteChecks)
                    Button { addingCheck = true } label: {
                        Label("Add a depth check", systemImage: "ruler")
                    }
                } header: {
                    Text("Depth checks")
                } footer: {
                    if trap.liquidDepthInches <= 0 {
                        Text("Set the liquid depth above and the app will work out the quarter rule for you.")
                    } else {
                        Text("Cleaning is required once grease and solids together reach \(trap.liquidDepthInches * 0.25, format: .number.precision(.fractionLength(1))) inches — a quarter of \(trap.liquidDepthInches, format: .number) in.")
                    }
                }

                Section {
                    Button { exportPDF() } label: {
                        Label("Inspection record for this trap", systemImage: "doc.richtext")
                    }
                }
            }
            .navigationTitle(trap.name.isEmpty ? "Trap" : trap.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { save(); dismiss() }
                }
            }
            .sheet(isPresented: $addingService) { ServiceEditorView(trap: trap, service: nil) }
            .sheet(item: $editingService) { ServiceEditorView(trap: trap, service: $0) }
            .sheet(isPresented: $addingCheck) { DepthCheckEditorView(trap: trap) }
            .sheet(item: $exportFile) { ShareSheet(url: $0.url) }
        }
    }

    private var tint: Color {
        switch trap.status {
        case .overQuarterRule, .overdue: .red
        case .dueSoon: .orange
        case .current: .green
        case .noHistory: .secondary
        }
    }

    private func save() {
        try? context.save()
        WidgetSync.update(with: (try? context.fetch(FetchDescriptor<Trap>())) ?? [])
    }

    private func deleteServices(_ offsets: IndexSet) {
        let list = trap.sortedServices
        for index in offsets { context.delete(list[index]) }
        save()
    }

    private func deleteChecks(_ offsets: IndexSet) {
        let list = trap.sortedChecks
        for index in offsets { context.delete(list[index]) }
        save()
    }

    private func exportPDF() {
        save()
        if let url = try? PDFExporter.export([trap], siteName: trap.location) {
            exportFile = ExportFile(url: url)
            ReviewPrompter.recordSuccess(request: requestReview)
        }
    }
}

private struct ServiceRow: View {
    let service: ServiceRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline.weight(.medium))
                Text(service.haulerName.isEmpty ? "Hauler not recorded" : service.haulerName)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if service.gallonsRemoved > 0 {
                Text("\(service.gallonsRemoved, format: .number) gal")
                    .font(.caption.monospacedDigit()).foregroundStyle(.secondary)
            }
            if service.manifestPhoto != nil {
                Image(systemName: "photo").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

struct ServiceEditorView: View {
    let trap: Trap
    var service: ServiceRecord?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var date = Date()
    @State private var hauler = ""
    @State private var permit = ""
    @State private var manifest = ""
    @State private var gallons: Double = 0
    @State private var disposal = ""
    @State private var technician = ""
    @State private var notes = ""
    @State private var photo: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                Section("Who") {
                    TextField("Hauler", text: $hauler)
                    TextField("Hauler permit number", text: $permit)
                    TextField("Technician", text: $technician)
                }
                Section {
                    TextField("Manifest number", text: $manifest)
                    LabeledContent("Gallons removed") {
                        TextField("gallons", value: $gallons, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    TextField("Disposal site", text: $disposal)
                } header: {
                    Text("The manifest")
                } footer: {
                    Text("These four fields are what a FOG inspection checks: that a permitted hauler took a recorded quantity to a named site on a given date.")
                }
                Section {
                    PhotoField(data: $photo, label: "Manifest photo")
                }
                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(service == nil ? "Pump-out" : "Edit pump-out")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() } }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard let s = service else { return }
        date = s.date; hauler = s.haulerName; permit = s.haulerPermit
        manifest = s.manifestNumber; gallons = s.gallonsRemoved
        disposal = s.disposalSite; technician = s.technician
        notes = s.notes; photo = s.manifestPhoto
    }

    private func save() {
        let record = service ?? ServiceRecord()
        record.date = date; record.haulerName = hauler; record.haulerPermit = permit
        record.manifestNumber = manifest; record.gallonsRemoved = gallons
        record.disposalSite = disposal; record.technician = technician
        record.notes = notes; record.manifestPhoto = photo
        if service == nil {
            record.trap = trap
            context.insert(record)
        }
        try? context.save()
        WidgetSync.update(with: (try? context.fetch(FetchDescriptor<Trap>())) ?? [])
        dismiss()
    }
}

struct DepthCheckEditorView: View {
    let trap: Trap
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var date = Date()
    @State private var grease: Double = 0
    @State private var solids: Double = 0
    @State private var checkedBy = ""

    private var fullness: Double? {
        trap.liquidDepthInches > 0 ? (grease + solids) / trap.liquidDepthInches : nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("When") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Checked by", text: $checkedBy)
                }
                Section {
                    LabeledContent("Grease layer") {
                        TextField("inches", value: $grease, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Solids layer") {
                        TextField("inches", value: $solids, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                } header: {
                    Text("Measurements")
                } footer: {
                    if let f = fullness {
                        Text(f >= 0.25
                             ? "That is \(Int(f * 100))% of the liquid depth. Most programmes require cleaning at 25% regardless of the date."
                             : "That is \(Int(f * 100))% of the liquid depth. The quarter rule kicks in at 25%.")
                        .foregroundStyle(f >= 0.25 ? .red : .secondary)
                    } else {
                        Text("Set the trap's liquid depth to see this as a percentage.")
                    }
                }
            }
            .navigationTitle("Depth check")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let check = DepthCheck(date: date)
                        check.greaseInches = grease
                        check.solidsInches = solids
                        check.checkedBy = checkedBy
                        check.trap = trap
                        context.insert(check)
                        try? context.save()
                        WidgetSync.update(with: (try? context.fetch(FetchDescriptor<Trap>())) ?? [])
                        dismiss()
                    }
                }
            }
        }
    }
}
