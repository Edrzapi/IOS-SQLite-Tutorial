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
        let fileURL = try! FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("UsersDB.sqlite")
        
        print("Database path: \(fileURL.path)")

        if sqlite3_open(fileURL.path, &db) != SQLITE_OK {
            print("Error opening database.")
        } else {
            print("Database opened successfully.")
        }
    }

    // MARK: - Create the Table
    private func createTable() {
        let query = """
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            age INTEGER
        );
        """

        if sqlite3_exec(db, query, nil, nil, nil) != SQLITE_OK {
            print("Error creating table: \(String(cString: sqlite3_errmsg(db)))")
        } else {
            print("Table 'Users' created (or already exists).")
        }
    }

    // MARK: - Insert User
    func insertUser(name: String, age: Int) {
        let insertQuery = "INSERT INTO Users (name, age) VALUES (?, ?);"
        
        var stmt: OpaquePointer?
        
        if sqlite3_prepare_v2(db, insertQuery, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil) != SQLITE_OK {
                print("Error binding name: \(String(cString: sqlite3_errmsg(db)))")
            }
            if sqlite3_bind_int(stmt, 2, Int32(age)) != SQLITE_OK {
                print("Error binding age: \(String(cString: sqlite3_errmsg(db)))")
            }

            if sqlite3_step(stmt) == SQLITE_DONE {
                print("User added successfully: Name = \(name), Age = \(age)")
            } else {
                print("Error executing insert: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("Error preparing insert: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(stmt)
    }

    // MARK - Fetch Users
    func fetchUsers() -> [User] {
        let fetchQuery = "SELECT * FROM Users;"
        var queryStatement: OpaquePointer?
        var users = [User]()

        if sqlite3_prepare_v2(db, fetchQuery, -1, &queryStatement, nil) != SQLITE_OK {
            print("Error preparing fetch statement")
            return users
        }

        while sqlite3_step(queryStatement) == SQLITE_ROW {
            let id = sqlite3_column_int(queryStatement, 0)
            let name = String(cString: sqlite3_column_text(queryStatement, 1))
            let age = sqlite3_column_int(queryStatement, 2)
            users.append(User(id: Int(id), name: name, age: Int(age)))
        }

        for user in users {
            print(user)
        }
        sqlite3_finalize(queryStatement)
        return users
    }

    // MARK: - Update User
    func updateUser(id: Int, name: String, age: Int) {
        let query = "UPDATE Users SET name = ?, age = ? WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
            sqlite3_bind_int(stmt, 2, Int32(age))
            sqlite3_bind_int(stmt, 3, Int32(id))

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
        let query = "DELETE FROM Users WHERE id = ?;"
        var stmt: OpaquePointer?

        if sqlite3_prepare_v2(db, query, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_int(stmt, 1, Int32(id))

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

    deinit {
        sqlite3_close(db)
    }
}
