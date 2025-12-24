# myShop

myShop (formerly Mpesa Shop) is a robust, offline-first business management solution tailored for small retail shops and M-Pesa agents. It empowers business owners to track inventory, reconcile accounts, managing customer data, and visualize financial performance without requiring an active internet connection.

# Screenshots

| Dashboard | Inventory | Reports |
| (Place screenshot here) | (Place screenshot here) | (Place screenshot here) |

# Features

# Financial Tracking

##Transaction Logging: Record Incoming (sales/deposits) and Outgoing (expenses/withdrawals) transactions.

Daily Overview: Instant dashboard metrics for "Items Sold" and "Total Revenue" for the current day.

History: Searchable and editable transaction logs.

# Inventory Management

Visual Stock: Attach photos to items using the device camera (supports zoom).

Categorization: Organize products by custom categories (e.g., Electronics, Cables).

Smart Sales: Calculate totals automatically with support for line-item Discounts.

Stock Control: One-tap restocking and selling logic.

# Accounting & Reconciliation

Reconciliation Tool: Compare physical cash/digital balances against system expectations.

Inline Calculation: Input fields support math operations (e.g., 5000 + 150).

Disparity Tracking: Automatically highlights variances between expected and actual counts.

Audit Trail: View historical reconciliation reports.

# Analytics & Reporting

Profit Engine: Real-time Net Profit calculation: (Selling Price - Discount) - Cost Price.

Expense Tracking: Dedicated logging for supply restocking costs.

Reports:

Periodical: Weekly, Monthly, and Yearly Income vs. Expense breakdowns.

Performance: "Items Sold" leaderboard ranked by quantity and profitability.

# Customer Management

CRM: Store profiles with Name, Phone, ID, and Store location.

Bulk Import: Import customer lists via CSV.

Smart Actions: Double-tap to copy details; sorting A-Z by name.

# Utilities & Security

Cash Counter: Built-in denomination calculator for physical cash counting.

Offline-First: All data persists locally via SQLite.

Full Backup: Generates a secure ZIP archive containing the database and all item images for seamless device migration.

# Tech Stack

Framework: Flutter (Dart)

Database: sqflite (Local SQLite)

Architecture: MVC / Service Pattern

Key Dependencies:

csv: Data import

archive: Backup compression (ZIP)

share_plus: File export

image_picker: Camera integration

path_provider: File system access

# Project Structure

lib/
├── db/
│   └── db_provider.dart       # Database initialization & migrations
├── models/
│   ├── customer.dart
│   ├── inventory_items.dart
│   └── transaction_model.dart
├── screens/
│   ├── home_screen.dart       # Main Dashboard
│   ├── inventory_screen.dart  # Stock management
│   ├── accounting_screen.dart # Reconciliation logic
│   └── reports_screen.dart    # Analytics charts/lists
├── services/
│   └── backup_service.dart    # Zip/Unzip & Export logic
└── main.dart                  # Entry point & Routes



# Getting Started

Prerequisites

Flutter SDK installed.

Android device or Emulator (Min SDK 21).

Installation

Clone the project (or copy files to your local machine):

git clone [https://github.com/yourusername/mpesa_shop_app.git](https://github.com/yourusername/mpesa_shop_app.git)
cd mpesa_shop_app



Install Dependencies:

flutter pub get



Setup Assets:
Ensure your app icon is placed at:
assets/icon/apppic.jpg

Run the App:

flutter run



Building for Release

To generate an APK for installation on physical devices:

flutter build apk



Output: build/app/outputs/flutter-apk/app-release.apk

🤝 Contributing

Contributions, issues, and feature requests are welcome!

Fork the Project

Create your Feature Branch (git checkout -b feature/AmazingFeature)

Commit your Changes (git commit -m 'Add some AmazingFeature')

Push to the Branch (git push origin feature/AmazingFeature)

Open a Pull Request

📄 License

Copyright © 2025. All Rights Reserved.

This software is proprietary. Unauthorized copying, modification, distribution, or use of this software is strictly prohibited without prior written permission from the copyright holder.