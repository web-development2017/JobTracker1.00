//
//  ContentView.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import SwiftUI
import Supabase

struct ContentView: View {
    @State private var jobs: [Job] = []
    @State private var newJobText = "" // Just one text field needed now
    
    var body: some View {
        NavigationStack {
            VStack {
                // Form to add a new job
                Form {
                    Section("Add New Job") {
                        TextField("Enter Job Details...", text: $newJobText)
                        Button("Save Job") {
                            Task { await saveJob() }
                        }
                        .disabled(newJobText.isEmpty)
                    }
                    
                    // List to view existing jobs
                    Section("My Jobs") {
                        if jobs.isEmpty {
                            Text("No jobs tracked yet.")
                        } else {
                            List(jobs) { item in
                                VStack(alignment: .leading) {
                                    Text(item.job).font(.body)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Job Manager")
            .task {
                await fetchJobs()
            }
        }
    }
    
    // FETCH JOBS FROM SUPABASE
    func fetchJobs() async {
        do {
            let fetchedJobs: [Job] = try await SupabaseManager.client
                .from("Jobs") // Looks at your 'jobs' table
                .select()
                .execute()
                .value
            
            await MainActor.run {
                self.jobs = fetchedJobs
            }
        } catch {
            print("Error fetching jobs: \(error)")
        }
    }
    
    // INSERT JOB INTO SUPABASE
    func saveJob() async {
        let freshJob = Job(id: nil, createdAt: nil, job: newJobText)
        
        do {
            let _ = try await SupabaseManager.client
                .from("Jobs")
                .insert(freshJob)
                .execute()
            
            // Clear field and refresh the list
            await MainActor.run {
                newJobText = ""
            }
            await fetchJobs()
            
        } catch {
            print("Error saving job: \(error)")
        }
    }
}

#Preview {
    ContentView()
}
