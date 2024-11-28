import SwiftUI

struct MainView: View {
    @State private var userName: String = "" // TextField input for user name
    @State private var userAge: String = "" // TextField input for user age
    @State private var userId: String = ""  // TextField input for user ID (update/delete)
    @State private var users: [User] = []   // Array to store fetched users
    @State private var showUsersSheet: Bool = false // Controls whether the user list sheet is shown

    let dbHelper = DatabaseHelper.shared // Access the DBHelper singleton

    var body: some View {

            VStack(spacing: 30) {
                Text("User Management").font(.title)
                // MARK: - Input Fields
                Group {
                    TextField("Enter Name", text: $userName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    TextField("Enter Age", text: $userAge)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)

                    TextField("Enter User ID (For Update/Delete)", text: $userId)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }

                // MARK: - CRUD Buttons
                Group {
                    Button(action: addUser) {
                        Text("Add User")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: fetchUsers) {
                        Text("Fetch Users")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .onTapGesture {
                                showUsersSheet.toggle() // Show the sheet when the button is tapped
                            }
                    }

                    Button(action: updateUser) {
                        Text("Update User")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }

                    Button(action: deleteUser) {
                        Text("Delete User")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                // MARK: - User List Sheet
                .sheet(isPresented: $showUsersSheet) {
                    // Sheet content to show users
                    VStack {
                        Text("Users List")
                            .font(.title)
                            .padding()

                        // Check if users array is empty, to help debug
                        if users.isEmpty {
                            Text("No users found")
                                .foregroundColor(.red)
                        } else {
                            List(users, id: \.id) { user in
                                VStack(alignment: .leading) {
                                    Text("ID: \(user.id)")
                                        .font(.headline)
                                    Text("Name: \(user.name)")
                                    Text("Age: \(user.age)")
                                }
                            }
                            .listStyle(PlainListStyle())
                        }
                    }
                    .onAppear(perform: fetchUsers) // Fetch users when the sheet appears
                }
            }
           
        }
    

    // MARK: - CRUD Functions

    private func addUser() {
        guard let age = Int(userAge), !userName.isEmpty else { return }
        dbHelper.insertUser(name: userName, age: age)
        fetchUsers() // Refresh user list
    }

    private func fetchUsers() {
        // Fetching users from the database
        users = dbHelper.fetchUsers() // Make sure the result is assigned to the users state array
        print("Fetched users: \(users)") // Debug print to check users array
    }

    private func updateUser() {
        guard let id = Int(userId), let age = Int(userAge), !userName.isEmpty else { return }
        dbHelper.updateUser(id: id, name: userName, age: age)
        fetchUsers() // Refresh user list
    }

    private func deleteUser() {
        guard let id = Int(userId) else { return }
        dbHelper.deleteUser(id: id)
        fetchUsers() // Refresh user list
    }
}

#Preview {
    MainView()
}
