//
//  ContentView.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import SwiftUI
import Auth

struct ContentView: View {
    // The View only owns the ViewModel. No kitchen sink.
    @State private var viewModel = JobsViewModel()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Add New Job") {
                    TextField("Enter Job Details...", text: $viewModel.newJobText)
                    
                    // 👇 If the user is an admin, show the assignment picker
                    if AuthManager.shared.isAdmin {
                        Picker("Assign To", selection: Bindable(viewModel).selectedWorker) {
                            Text("General Queue (Unassigned)").tag(Optional<Profile>.none)
                            
                            ForEach(viewModel.workers) { worker in
                                Text(worker.email ?? "Unknown Worker")
                                    .tag(Optional<Profile>.some(worker))
                            }
                        }
                        .pickerStyle(.navigationLink) // Clean, native nested menu style
                    }
                    
                    Button(action: {
                        Task { await viewModel.saveJob() }
                    }) {
                        if viewModel.isSaving {
                            ProgressView()
                        } else {
                            Text("Save Job")
                        }
                    }
                    .disabled(viewModel.newJobText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSaving)
                }
                
                Section("My Jobs") {
                    if viewModel.jobs.isEmpty {
                        Text("No jobs tracked yet.")
                            .foregroundColor(.gray)
                    } else {
                        List {
                            ForEach(viewModel.jobs) { item in
                                Text(item.job)
                                    .font(.body)
                                    .deleteDisabled(!canModify(job: item))
                            }
                            .onDelete { indexSet in
                                // This triggers the delete function we just fixed in the ViewModel
                                Task { await viewModel.deleteJob(at: indexSet) }
                            }
                        }
                    }
                }
                Button(role: .destructive) {
                    Task {
                        do {
                            try await AuthManager.shared.signOut()
                        } catch {
                            print("Failed to sign out: \(error.localizedDescription)")
                        }
                    }
                } label: {
                    Label("Sign Out", systemImage: "arrow.left.circle")
                }
                .padding()
            }
            .navigationTitle("Job Tracker")
            .task {
                await viewModel.fetchJobs()
                // 👇 Fetch the workers list if the user is an Admin
                if AuthManager.shared.isAdmin {
                    await viewModel.fetchWorkers()
                }
            }
        }
    }
    func canModify(job: Job) -> Bool {
        // 1. Admins have a master key and can change anything
        if AuthManager.shared.isAdmin { return true }
        
        // 2. Otherwise, grab the current user's ID
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return false }
        
        // 3. Explicitly look at created_by. If it's missing (NULL), block non-admins.
            guard let jobCreatorId = job.created_by else { return false }
            
        // 4. They must be the creator AND the job must still be unstarted
        let isCreator = (jobCreatorId == currentUserId)
        let isUnstarted = (job.status == .unassigned || job.status == .offered)
        
        return isCreator && isUnstarted
    }
}
#Preview {
    ContentView()
}
