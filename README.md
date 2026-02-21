# GigLog - Rideshare & Mileage Tracker

GigLog is a privacy-focused iOS application built with SwiftUI designed for rideshare and delivery drivers (Uber, Lyft, DoorDash). 

Unlike other tracking apps, **GigLog does not lock your data inside the app.** Instead, it functions as a smart interface for a CSV file stored in your iPhone's Files App (iCloud Drive or On My iPhone).

**If you delete the app, your data remains safe on your device.**

## 📱 Features

- **Mileage Tracking:** Log Start and End odometer readings.
- **Expense Logging:** Track Gas, Maintenance, Car Washes, and Tolls.
- **Persistent Storage:** Data is saved to a `RideshareLog.csv` file in the user's Documents folder.
- **Excel/Sheets Ready:** The output file can be opened immediately in Microsoft Excel or Google Sheets.
- **Privacy First:** No external servers, no accounts required.

## 🛠 Tech Stack

- **Language:** Swift 6
- **UI Framework:** SwiftUI
- **Architecture:** MVVM
- **Data Persistence:** `FileManager` & `FileHandle` (Direct CSV Manipulation)
- **Permissions:** Security Scoped Bookmarks (to maintain access to the user's file).

## 🚀 Getting Started

### Prerequisites
- Xcode 15+
- iOS 16+

## 💾 How Data is Stored
On the first launch, the app will ask you to Select a Location to store your log.
The app utilizes UIDocumentPickerViewController to let the user choose a folder.
It creates a RideshareLog.csv file.
It saves a Security Scoped Bookmark to UserDefaults so the app can write to this file in the background during future shifts.
