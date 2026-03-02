//
//  ContentView.swift
//  GigLog
//
//  Created by Ashesh Patel on 2026-02-20.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var storageManager = StorageManager()
  
    var body: some View {
      StorageSetupView()
        .environmentObject(storageManager)
    }
}

#Preview {
    ContentView()
}
