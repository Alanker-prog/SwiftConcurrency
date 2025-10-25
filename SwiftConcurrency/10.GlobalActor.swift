//
//  10.GlobalActor.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 24.10.2025.
//


/*
 ✴️ Что такое @globalActor и зачем он нужен
    ➡️ В Swift акторы (actors) — это объекты, которые обеспечивают потокобезопасность: только один поток может обращаться к их состоянию одновременно.А глобальный актор (@globalActor) — это способ сказать: «Некоторые функции или свойства должны всегда выполняться в контексте одного и того же акторного потока».
 
 🧩 Итого: что происходит в целом
     ➡️ Создаётся глобальный актор MyFirstGlobalActor, связанный с экземпляром MyNewDataManager.
     ➡️ Метод getData() выполняется в контексте этого актора.
     ➡️ Он вызывает getDataFromDatabase() (потокобезопасно).
     ➡️ Полученные данные передаются на главный поток, где обновляется dataArrey.
     ➡️ SwiftUI автоматически обновит интерфейс, потому что dataArrey — это @Published.

 
 🧩 Такой подход нужен для:
     ➡️ Безопасного обращения к общим данным из разных потоков.
     ➡️ Разделения кода, который работает с данными (MyFirstGlobalActor), и кода, который обновляет UI (@MainActor).
     ➡️ Избежания ошибок наподобие “Modifying state from a background thread”.
 */
import SwiftUI
import Combine

/*
 ✅ @globalActor final class MyFirstGlobalActor { - Класс от которого не льзя наследоваться
 
 ✅ static let shared = MyNewDataManager() - обязательное свойство,(⚠️оно должно всегда называться shared. Это условие Aplle)  которое указывает на реальный экземпляр актора, управляющего выполнением задач.Здесь это экземпляр MyNewDataManager.
 */
@globalActor final class MyFirstGlobalActor {
    
    static let shared = MyNewDataManager()
}

/*
 ✅ actor — это потокобезопасный контейнер для данных и методов.
 ✅ Здесь у нас есть метод getDataFromDatabase(), который просто возвращает массив строк.(В реальном коде он мог бы обращаться к базе данных или API.)
 */
actor MyNewDataManager {
    
    func getDataFromDatabase() -> [String] {
        return ["One", "Two", "Three", "Four"]
    }
}


/*
 ✅ @MainActor @Published var dataArrey: [String] = []
    ➡️ означает, что это свойство dataArrey должно обновляться только на главном потоке (UI). ⚠️ Это очень полезно если наш массив обновляет экран(как раз это наш случай) мы можем указать  @MainActor и он будет оьновляться тоько в главном потоке, и теперь если мы где то забудем превести dataArrey в главный поток компелятор нас предупредит красной ошибкой (без этого он нам бы прсто показывал фиолетывую ошибку уже когда мы собрали приложениев симуляторе)
 
 ✅ let manager = MyFirstGlobalActor.shared -  это ссылка на экземпляр actor MyNewDataManager, который мы указали как shared.
 */
class GlobalActorBootcampViewModel: ObservableObject {
    
   @MainActor @Published var dataArrey: [String] = []
    let manager = MyFirstGlobalActor.shared
    
    @MyFirstGlobalActor func getData() async {
        Task {
            let data = await manager.getDataFromDatabase()
            await MainActor.run {
                self.dataArrey = data
            }
             
        }
    }
}

struct GlobalActorBootcamp: View {
    
    @StateObject var vm = GlobalActorBootcampViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(vm.dataArrey, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
            .task {
               await vm.getData()
            }
        }
    }
}

#Preview {
    GlobalActorBootcamp()
}
