import SwiftUI

enum AlertType2 {
    case delete2
    case save
    case error2
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
    @State private var isAlertPresented2 = false
    @State var alertType2: AlertType2 = .save
    @EnvironmentObject var todoStore: ToDoStore
    @FocusState var isKeyboad2: Bool
    @Environment(\.presentationMode) var presentation
    
    init(todo: Binding<ToDoItem>, isPresented: Binding<Bool>) {
        self._todo = todo
        self._isPresented = isPresented
        self._editedTask = State(initialValue: todo.wrappedValue.task)
        self._editedDueDate = State(initialValue: todo.wrappedValue.dueDate)
    }
    
    var body: some View {
            VStack{
                Form {
                    TextField("ToDoの編集", text: $editedTask)
                        .focused($isKeyboad2)
                        .toolbar{
                            ToolbarItemGroup(placement: .keyboard){
                                Spacer()
                                Button("完了", action:{
                                    isKeyboad2 = false
                                })
                            }
                        }
                    DatePicker("締切日", selection: $editedDueDate, displayedComponents: .date).environment(\.locale, Locale(identifier: "ja_JP"))
                }
                Button("削除", action: {
                    isAlertPresented2 = true
                    alertType2 = .delete2
                })
                .foregroundColor(.red)
                .padding()
                Spacer()
            }
            .navigationTitle("ToDoの編集")
            .navigationBarItems(
                trailing: Button("保存") {
                    if editedTask.isEmpty{
                        isAlertPresented2 = true
                        alertType2 = .error2
                    }else{
                        todo.task = editedTask
                        todo.dueDate = editedDueDate
                        isAlertPresented2 = true
                        alertType2 = .save
                    }
                }
            )
            .alert(isPresented: $isAlertPresented2) {
                switch alertType2 {
                case .delete2:
                    return Alert(
                        title: Text("ToDoを削除しますか？"),
                        message: Text("ToDo: \(todo.task)\n締切日: \(formattedDate(date: todo.dueDate))"),
                        primaryButton: .cancel(Text("キャンセル")),
                        secondaryButton: .destructive(Text("削除"), action: {
                            if let index = todoStore.todos.firstIndex(where: { $0.id == todo.id }) {
                                todoStore.todos.remove(at: index)
                                self.presentation.wrappedValue.dismiss()
                            }
                        })
                    )
                case .save:
                    return Alert(
                        title: Text("ToDoを保存しました"),
                        message: Text("ToDo: \(editedTask)\n締切日: \(formattedDate(date: editedDueDate))"),
                        dismissButton: .default(Text("OK")){
                            self.presentation.wrappedValue.dismiss()
                        }
                    )
                case .error2:
                    return Alert(
                        title: Text("エラー"),
                        message: Text("ToDoを入力してください。"),
                        dismissButton: .default(Text("OK"))
                    )
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
    @FocusState var isKeyboad: Bool
    @State var isEditViewActive = false
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("新しいToDoを入力してください", text: $todoText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .disabled(isEditingModalPresented)
                    .focused($isKeyboad)
                    .toolbar{
                        ToolbarItemGroup(placement: .keyboard){
                            Spacer()
                            Button("完了", action: {
                                isKeyboad = false
                            })
                        }
                    }
                
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
                        NavigationLink(destination: EditTodoView(todo: $todoStore.todos[todoStore.todos.firstIndex(where: { $0.id == todo.id })!], isPresented: $isEditingModalPresented)) {
                            VStack(alignment: .leading) {
                                Text("ToDo: \(todo.task)")
                                    .foregroundColor(determineTextColor(for: todo))
                                Text("締切日: \(formattedDate(date: todo.dueDate))")
                                    .font(.footnote)
                                    .foregroundColor(determineTextColor(for: todo))
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button("削除", role: .destructive) {
                                if let todo = todoStore.todos.first(where: { $0.id == todo.id }) {
                                    selectedTodoForDeletion = todo
                                    isAlertPresented = true
                                    alertType3 = .delete
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
                Spacer()
            }
            .navigationBarTitle("ToDoリスト")
        }
        .environmentObject(todoStore)
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
