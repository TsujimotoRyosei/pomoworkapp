import SwiftUI

enum AlertType2 {
    case delete
    case save
    case error
}

enum AlertType3{
    case delete
    case error
}
struct ToDoItem: Identifiable, Codable {
    var id = UUID()
    var isChecked: Bool
    var task: String
    var dueDate: Date
}

class ToDoStore: ObservableObject {
    private let todosKey = "todos"
    
    @Published var todos: [ToDoItem] {
        didSet {
            if let encoded = try? JSONEncoder().encode(todos) {
                UserDefaults.standard.set(encoded, forKey: todosKey)
            }
        }
    }
    
    init() {
        if let savedTodos = UserDefaults.standard.data(forKey: todosKey),
           let decodedTodos = try? JSONDecoder().decode([ToDoItem].self, from: savedTodos) {
            self.todos = decodedTodos
        } else {
            self.todos = []
        }
    }
}

struct EditTodoView: View {
    @Binding var todo: ToDoItem
    @Binding var isPresented: Bool
    
    @State private var editedTask: String
    @State private var editedDueDate: Date
    @State private var isAlertPresented = false
    @State var alertType2: AlertType2 = .save
    @EnvironmentObject var todoStore: ToDoStore
    
    init(todo: Binding<ToDoItem>, isPresented: Binding<Bool>) {
        self._todo = todo
        self._isPresented = isPresented
        self._editedTask = State(initialValue: todo.wrappedValue.task)
        self._editedDueDate = State(initialValue: todo.wrappedValue.dueDate)
    }
    
    var body: some View {
        NavigationView {
            VStack{
                Form {
                    TextField("ToDoを編集", text: $editedTask)
                    DatePicker("締切日", selection: $editedDueDate, displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP"))
                }
                Button("削除", action: {
                    isAlertPresented = true
                    alertType2 = .delete
                })
                .foregroundColor(.red)
                .padding()
                
                Spacer()
            }
            .navigationTitle("ToDoを編集")
            .navigationBarItems(
                leading: Button("キャンセル") {
                    isPresented = false
                },
                trailing: Button("保存") {
                    if editedTask.isEmpty{
                        isAlertPresented = true
                        alertType2 = .error
                    }else{
                        todo.task = editedTask
                        todo.dueDate = editedDueDate
                        isAlertPresented = true
                    }
                }
            )
            .alert(isPresented: $isAlertPresented) {
                switch alertType2 {
                case .delete:
                    return Alert(
                        title: Text("ToDoを削除しますか？"),
                        message: Text("ToDo: \(todo.task)\n締切日: \(formattedDate(date: todo.dueDate))"),
                        primaryButton: .cancel(Text("キャンセル")),
                        secondaryButton: .destructive(Text("削除"), action: {
                            if let index = todoStore.todos.firstIndex(where: { $0.id == todo.id }) {
                                todoStore.todos.remove(at: index)
                                isPresented = false
                            }
                        })
                    )
                case .save:
                    return Alert(
                        title: Text("ToDoを保存しました"),
                        message: Text("ToDo: \(editedTask)\n締切日: \(formattedDate(date: editedDueDate))"),
                        dismissButton: .default(Text("OK")){
                            isPresented = false
                        }
                    )
                case .error:
                    return Alert(
                        title: Text("エラー"),
                        message: Text("ToDoを入力してください。"),
                        dismissButton: .default(Text("OK"))
                    )
                }
            }
        }
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
}


struct TodoView: View {
    @StateObject var todoStore = ToDoStore()
    @State private var todoText: String = ""
    @State private var selectedDate = Date()
    @State private var selectedItem: ToDoItem?
    @State private var editingIndex: Int?
    @State private var isEditingModalPresented = false
    @State private var isAlertPresented = false
    @State private var selectedTodoForDeletion: ToDoItem?
    @State var alertType3: AlertType3 = .delete
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("新しいToDoを追加", text: $todoText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .disabled(isEditingModalPresented)
                
                DatePicker("締切日", selection: $selectedDate, displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP"))
                    .padding()
                    .disabled(isEditingModalPresented)
                
                Button("追加", action: {
                    if todoText.isEmpty{
                        isAlertPresented = true
                        selectedTodoForDeletion = nil
                        alertType3 = .error
                    }else{
                        let newToDo = ToDoItem(isChecked: false, task: todoText, dueDate: selectedDate)
                        todoStore.todos.append(newToDo)
                        todoText = ""
                        selectedDate = Date()
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                })
                .padding()
                
                List {
                    ForEach(sortedTodos()) { todo in
                        VStack(alignment: .leading) {
                            Text("ToDo: \(todo.task)")
                                .foregroundColor(determineTextColor(for: todo))
                            Text("締切日: \(formattedDate(date: todo.dueDate))")
                                .font(.footnote)
                                .foregroundColor(determineTextColor(for: todo))
                        }
                        .swipeActions(edge: .leading) {
                            Button("編集") {
                                selectedItem = todo
                                if let index = todoStore.todos.firstIndex(where: { $0.id == todo.id }) {
                                    editingIndex = index
                                }
                                isEditingModalPresented = true
                            }
                            .tint(.blue)
                        }
                        .swipeActions(edge: .trailing) {
                            Button("削除", role: .destructive) {
                                if let todo = todoStore.todos.first(where: { $0.id == todo.id }) {
                                    selectedTodoForDeletion = todo
                                    isAlertPresented = true
                                }
                            }
                            .tint(.red)
                        }
                    }
                }
                .alert(isPresented: $isAlertPresented) {
                    switch alertType3{
                    case .delete:
                        return Alert(
                            title: Text("このToDo削除しますか？"),
                            message: Text("ToDo: \(selectedTodoForDeletion?.task ?? "")\n締切日: \(formattedDate(date: selectedTodoForDeletion?.dueDate ?? Date()))"),
                            primaryButton: .cancel(Text("キャンセル")),
                            secondaryButton: .destructive(Text("削除"), action: {
                                if let todo = selectedTodoForDeletion,
                                   let index = todoStore.todos.firstIndex(where: { $0.id == todo.id }) {
                                    todoStore.todos.remove(at: index)
                                }
                            })
                        )
                    case .error:
                        return Alert(
                            title: Text("エラー"),
                            message: Text("ToDoを入力してください。"),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .sheet(isPresented: $isEditingModalPresented, content: {
                    if let selectedItem = selectedItem,
                       let index = todoStore.todos.firstIndex(where: { $0.id == selectedItem.id }) {
                        EditTodoView(todo: $todoStore.todos[index], isPresented: $isEditingModalPresented)
                            .environmentObject(todoStore)
                    }
                })
                
                Spacer()
            }
            .navigationBarTitle("ToDoリスト")
        }
    }
    
    func sortedTodos() -> [ToDoItem] {
        return todoStore.todos.sorted(by: { $0.dueDate < $1.dueDate })
    }
    
    func formattedDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    func determineTextColor(for todo: ToDoItem) -> Color {
        let currentDate = Date()
        if Calendar.current.isDate(todo.dueDate, inSameDayAs: currentDate) {
            return .primary
        } else if todo.dueDate < currentDate {
            return .red
        } else {
            return .primary
        }
    }
}

struct TodoView_Previews: PreviewProvider {
    static var previews: some View {
        TodoView()
    }
}
