//
//  SupabaseManager.swift
//  JobTracker1.00
//
//  Created by Rich Taylor on 06/06/2026.
//
import Foundation
import Supabase

enum SupabaseManager {
    static let client = SupabaseClient(
        supabaseURL: URL(string: "https://xonoevyczmarqxicueqy.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inhvbm9ldnljem1hcnF4aWN1ZXF5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA3MDkzNjYsImV4cCI6MjA5NjI4NTM2Nn0.132qI6z2FBDBBC-iupRt41axLnoFMsWibaWmclLMWLY"
    )
}
