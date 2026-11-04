import SwiftUI

struct TableImportContent: View {
    @Bindable var viewModel: TableImportViewModel
    let onClose: () -> Void
    @State private var parsingTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("table_import_intro".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
            PasteButton(payloadType: String.self) { strings in
                let text = strings.joined(separator: "\n")
                parsingTask?.cancel()
                parsingTask = Task { await viewModel.prepare(from: text) }
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent).tint(Color.accent)
            .frame(maxWidth: .infinity)

            if viewModel.isParsing { ProgressView("table_import_reading".localized()) }
            if viewModel.hasInput && !viewModel.isParsing {
                Text(String(format: "table_import_ready".localized(), viewModel.importableRows.count))
                    .font(.bodyCustom.weight(.semibold)).foregroundStyle(Color.textPrimary)
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.importableRows.prefix(5))) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .top, spacing: 12) {
                                Text(row.source.origin).frame(maxWidth: .infinity, alignment: .leading)
                                Image(systemName: "arrow.right").foregroundStyle(Color.accent)
                                Text(row.source.translated).frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .font(.bodyCustom).foregroundStyle(Color.textPrimary)
                            if row.reusesCard {
                                Text("table_import_reuse".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
                            }
                        }
                        .padding(12)
                    }
                }
                .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                if viewModel.importableRows.count > 5 {
                    Text("table_import_preview_limit".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
                }
                if !viewModel.skippedRows.isEmpty {
                    DisclosureGroup(String(format: "table_import_skipped".localized(), viewModel.skippedRows.count)) {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(viewModel.skippedRows) { row in
                                if let reason = row.skipReason {
                                    Text(String(format: "table_import_skipped_row".localized(), row.lineLabel, reason.localized()))
                                        .font(.captionCustom).foregroundStyle(Color.textSecondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .font(.bodyCustom).foregroundStyle(Color.textPrimary).tint(Color.accent)
                }
                Toggle("table_import_header".localized(), isOn: $viewModel.firstRowIsHeader)
                    .font(.captionCustom).foregroundStyle(Color.textPrimary).tint(Color.accent)
                StudyLanguagePairPicker(pair: $viewModel.languagePair)
                Text("table_import_group".localized()).font(.captionCustom).foregroundStyle(Color.textSecondary)
                TextField("table_import_group".localized(), text: $viewModel.groupName)
                    .font(.bodyCustom).padding(12)
                    .background(Color.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(Color.textPrimary)


            }
            if let error = viewModel.errorMessage {
                Text(error).font(.captionCustom).foregroundStyle(Color.red)
            }
        }
        .padding(.horizontal)
        .onDisappear { parsingTask?.cancel() }
        .alert("import_success_title".localized(), isPresented: $viewModel.showSuccessAlert) {
            Button("ok".localized()) { onClose() }
        } message: { Text(viewModel.successMessage) }
    }
}
