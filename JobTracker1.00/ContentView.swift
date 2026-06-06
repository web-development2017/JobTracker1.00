//
//  ContentView.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import SwiftUI
import SwiftUI

struct ContentView: View {
    // The View only owns the ViewModel. No kitchen sink.
    @State private var viewModel = JobsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Add New Job") {
                    TextField("Enter Job Details...", text: $viewModel.newJobText)
                    
                    Button(action: {
                        // Triggers the asynchronous background task cleanly
                        Task { await viewModel.saveJob() }
                    }) {
                        if viewModel.isSaving {
                            ProgressView() // Lean, native loading spinner
                        } else {
                            Text("Save Job")
                        }
                    }
                    // Performance optimization: Disable button if empty or saving
                    .disabled(viewModel.newJobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
                }
                
                Section("My Jobs") {
                    if viewModel.jobs.isEmpty {
                        Text("No jobs tracked yet.")
                            .foregroundColor(.gray)
                    } else {
                        List(viewModel.jobs) { item in
                            Text(item.job)
                                .font(.body)
                        }
                    }
                }
            }
            .navigationTitle("Job Tracker")
            .task {
                // Initiates a clean, non-blocking background network fetch when the view appears
                await viewModel.fetchJobs()
            }
        }
    }
}
#Preview {
    ContentView()
}
