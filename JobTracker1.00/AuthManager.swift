//
//  AuthManager.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 08/06/2026.
//
import Foundation
import Supabase

@Observable
@MainActor
class AuthManager {
    static let shared = AuthManager()
    
    // Tracks whether a user session exists or not
    var currentUser: User? = nil
    var isAuthenticated: Bool { currentUser != nil }
    
    private init() {
        // Automatically check if a user is already signed in from a previous session
        Task {
            await checkExistingSession()
        }
    }
    
    /// Checks if Supabase has a valid cached session
    func checkExistingSession() async {
        do {
            let session = try await SupabaseManager.client.auth.session
            self.currentUser = session.user
        } catch {
            self.currentUser = nil
        }
    }
    
    /// Signs in an existing user (created manually by the admin)
    func signIn(email: String, password: String) async throws {
        let response = try await SupabaseManager.client.auth.signIn(
            email: email,
            password: password
        )
        self.currentUser = response.user
    }
    
    /// Signs the current user out
    func signOut() async throws {
        try await SupabaseManager.client.auth.signOut()
        self.currentUser = nil
    }
}
