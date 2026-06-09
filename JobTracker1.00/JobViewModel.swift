//
//  JobViewModel.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//

import Foundation
import Observation
import Supabase

@Observable
final class JobsViewModel {
    // Read-only from the outside to protect data integrity, mutable only inside this class
    private(set) var jobs: [Job] = []
    
    // UI state bound directly to the View
    var newJobText = ""
    var isSaving = false
    
    // Tracks all available workers fetched from the cloud
    private(set) var workers: [Profile] = []

    // Tracks the currently selected worker in the UI picker (nil means "General Queue")
    var selectedWorker: Profile? = nil
    
    @MainActor
    func fetchJobs() async {
        // 1. Grab the current user's ID. If not logged in, empty the list and stop.
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            self.jobs = []
            return
        }
        
        do {
            // 2. Start the baseline query to the Jobs table
            var query = SupabaseManager.client.from("Jobs").select()
            
            // 3. If they are a worker (NOT an admin), restrict the rows they can fetch
            if !AuthManager.shared.isAdmin {
                // Filter: where assigned_to is NULL (general queue) OR assigned_to equals currentUserId
                query = query.or("assigned_to.is.null,assigned_to.eq.\(currentUserId)")
            }
            
            // 4. Execute the customized query
            let fetchedJobs: [Job] = try await query.execute().value
            
            self.jobs = fetchedJobs
        } catch {
            print("Error fetching filtered jobs: \(error)")
        }
    }
    /// Fetches all profiles from the public profiles table so admins can assign tasks
    @MainActor
    func fetchWorkers() async {
        do {
            let fetchedWorkers: [Profile] = try await SupabaseManager.client
                .from("profiles")
                .select()
                .execute()
                .value
            
            self.workers = fetchedWorkers
        } catch {
            print("Error fetching workers: \(error)")
        }
    }
    
    /// Updates the status and assignment of a job cleanly in Supabase and refreshes the UI
    @MainActor
    func updateJobStatus(job: Job, newStatus: Job.JobStatus) async {
        guard let jobId = job.id else { return }
        guard let currentUserId = AuthManager.shared.currentUser?.id else { return }
        
        // Create a mutable copy of the job to update fields
        var updatedJob = job
        updatedJob.status = newStatus
        
        // If a worker is accepting an unassigned job, officially stamp their ID onto it
        if newStatus == .inProgress && job.assigned_to == nil {
            updatedJob.assigned_to = currentUserId
        }
        
        do {
            try await SupabaseManager.client
                .from("Jobs")
                .update(updatedJob)
                .eq("id", value: jobId)
                .execute()
                
            // Refresh the list to reflect changes instantly
            await fetchJobs()
        } catch {
            print("Error updating job status: \(error)")
        }
    }
    
    // Inserts a new job and optimizes performance by updating locally
    @MainActor
    func saveJob() async {
        // Lean check: Don't send empty strings or spaces to the database
        let trimmedJob = newJobText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedJob.isEmpty else { return }
        
        // Security check: Ensure we have a valid logged-in user to stamp as the creator
        guard let currentUserId = AuthManager.shared.currentUser?.id else {
            print("Error: Cannot save job because no user is logged in.")
            return
        }
        
        isSaving = true
        
        // If a worker is selected, status is .offered and assigned_to is set.
        // Otherwise, it defaults to .unassigned and open to anyone.
        let initialStatus: Job.JobStatus = (selectedWorker != nil) ? .offered : .unassigned

        let freshJob = Job(
            id: nil,
            createdAt: nil,
            job: trimmedJob,
            status: initialStatus,
            created_by: currentUserId,
            assigned_to: selectedWorker?.id // 👈 Passes the picked worker's UUID
        )
        
        do {
            // We remove the Type expectation [Job] and just execute the network request
            try await SupabaseManager.client
                .from("Jobs")
                .insert(freshJob)
                .execute()
            
            self.newJobText = ""
            self.selectedWorker = nil            // Refresh our local array cleanly from the cloud database
            await fetchJobs()
        } catch {
            print("Error saving job: \(error)")
    }
        
        // This 'defer' or trailing block always runs at the very end, ensuring the loader stops
        self.isSaving = false
    }
    /// Deletes a job from Supabase and updates the UI locally
    @MainActor
    func deleteJob(at offsets: IndexSet) async {
        // 1. Find the item the user swiped on
        guard let index = offsets.first else { return }
        let jobToDelete = jobs[index]
        
        // 2. Performance Optimization: Optimistically remove it from the UI immediately
        // This makes the app feel instant to the user
        jobs.remove(at: index)
        
        // 3. If the job doesn't have an ID (e.g., failed to save earlier), stop here
        guard let jobId = jobToDelete.id else { return }
        
        do {
            try await SupabaseManager.client
                .from("Jobs")
                .delete()
                .eq("id", value: jobId)
                .execute()
                
            print("Successfully deleted job from cloud database.")
        } catch {
            print("Error deleting job from cloud: \(error)")
            // Put the job back exactly where it was instead of reloading everything
            jobs.insert(jobToDelete, at: index)
        }
    }
}
