import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var dashboardViewModel: DashboardViewModel
    @State private var exportResult: ExportResult?

    var body: some View {
        NavigationView {
            List {
                Section("Exporter") {
                    Button("Exporter le dernier rapport PDF") {
                        Task {
                            exportResult = await dashboardViewModel.exportLatestReport()
                        }
                    }
                    Button("Exporter les données CSV") {
                        Task {
                            exportResult = await dashboardViewModel.exportCSV()
                        }
                    }
                }

                if let exportResult {
                    Section("Dernière exportation") {
                        Text(exportResult.message)
                            .foregroundColor(exportResult.isSuccess ? .green : .red)
                    }
                }
            }
            .navigationTitle("Rapports")
        }
    }
}
