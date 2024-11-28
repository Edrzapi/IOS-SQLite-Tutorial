import SQLite3
import SwiftUI

class DatabaseHelper {
    static let shared = DatabaseHelper() // Singleton instance for global access
    private var db: OpaquePointer? // Pointer to the SQLite database

    private init() {
        openDatabase() // Open or create the database
        createTable()  // Ensure the "Users" table exists
    }

    // MARK: - Open the Database
    private func openDatabase() {
        // Locate the app's sandboxed "Documents" directory
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory,        // Find the "Documents" directory
                 in: .userDomainMask,            // Limit search to the app's sandboxed user area
                 appropriateFor: nil,            // No additional context needed
                 create: false)                  // Don't create the directory; it must exist
            .appendingPathComponent("UsersDB.sqlite") // Changed the database file name here
        
        // Print the file path (useful for debugging to confirm where the DB is stored)
        print("Database path: \(fileURL.path)")

        // Open the database (or create it if it doesn't exist)
        if sqlite3_open(fileURL.path, &db) != SQLITE_OK { // Pass the path to open
            print("Error opening database.") // Log an error if the operation fails
        } else {
            print("Database opened successfully.")
        }
    }

    // MARK: - Create the Table
    private func createTable() {
        // SQL query to create the "Users" table if it doesn't already exist
        let query = """
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT, -- Auto-incrementing unique identifier for each user
            name TEXT,                            -- Stores the user's name (text field)
            age INTEGER                           -- Stores the user's age (integer field)
        );
        """
        
        // Execute the SQL query using sqlite3_exec
        if sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK {
            // Fetch and print a detailed error message if table creation fails
            print("Error creating table: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("Table 'Users' created (or already exists).")
        }
    }

    // MARK: - Insert User
    func insertUser(name: String, age: Int) {
        let insertQuery = "INSERT INTO users (name, age) VALUES (?, ?);"
        
        var stmt: OpaquePointer?
        
        // Prepare the statement
        if sqlite3_prepare_v2(db, insertQuery, -1, &stmt, nil) == SQLITE_OK {
            // Bind parameters
            if sqlite3_bind_text(stmt, 1, name, -1, nil) != SQLITE_OK {
                print("Error binding name: \(sqlite3_errmsg(db))") // Debug error
            }
            if sqlite3_bind_int(stmt, 2, Int32(age)) != SQLITE_OK {
                print("Error binding age: \(sqlite3_errmsg(db))") // Debug error
            }

            // Execute the statement
            if sqlite3_step(stmt) == SQLITE_DONE {
                print("User added successfully: Name = \(name), Age = \(age)") // Debug success
            } else {
                print("Error executing insert: \(sqlite3_errmsg(db))") // Debug error
            }
        } else {
            print("Error preparing insert: \(sqlite3_errmsg(db))") // Debug error
        }
        
        // Finalize statement to free memory
        sqlite3_finalize(stmt)
    }


    // MARK: - Fetch All Users
    func fetchUsers() -> [User] {
        let query = "SELECT * FROM Users;" // Query to fetch all users
        var stmt: OpaquePointer?          // Pointer to the prepared statement
        var users: [User] = []            // Array to store fetched users

        // Prepare the statement
        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            // Iterate through all rows
            while sqlite3_step(stmt) == SQLITE_ROW {
                // Extract data from each column
                let id = Int(sqlite3_column_int(stmt, 0))
                let name = String(cString: sqlite3_column_text(stmt, 1))
                let age = Int(sqlite3_column_int(stmt, 2))

                // Create a User object and append to the list
                users.append(User(id: id, name: name, age: age))
            }
        } else {
            print("Error fetching users: \(String(cString: sqlite3_errmsg(db)))")
        }

        sqlite3_finalize(stmt) // Finalize statement to release resources
        return users
    }

    // MARK: - Update User
    func updateUser(id: Int, name: String, age: Int) {
        // Use parameterized SQL to prevent SQL Injection
        let query = "UPDATE Users SET name = ?, age = ? WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, name, -1, nil) // Bind `name`
            sqlite3_bind_int(stmt, 2, Int32(age))     // Bind `age`
            sqlite3_bind_int(stmt, 3, Int32(id))      // Bind `id`

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("User updated successfully!")
            } else {
                print("Failed to update user.")
            }
        } else {
            print("Error preparing update: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(stmt)
    }

    // MARK: - Delete User
    func deleteUser(id: Int) {
        let query = "DELETE FROM Users WHERE id = ?;" // Parameterized query
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id)) // Bind `id`

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("User deleted successfully!")
            } else {
                print("Failed to delete user.")
            }
        } else {
            print("Error preparing delete: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(stmt)
    }

    // Close database when the instance is destroyed
    deinit {
        sqlite3_close(db)
    }
}
