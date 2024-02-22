import SwiftUI

struct ContentView: View {
    @State var selection = 1
    
    var body: some View {
        TabView(selection: $selection){
            PomoView()
                .tabItem {
                    Label("ポモタイマー",systemImage: "timer.circle")
                }
                .tag(1)
            TodoView()
                .tabItem {
                    Label("ToDoリスト",systemImage: "checkmark.circle")
                }
                .tag(2)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
