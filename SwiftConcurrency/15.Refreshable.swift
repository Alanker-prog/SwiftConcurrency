//
//  15.Refreshable.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 31.10.2025.
//

import SwiftUI
import Combine

/*
⚙️🔻 func getData() async throws -> [String] { - асинхронная функция возврашает стринговый массив
      ➡️ try? - означает: если кто-то отменит задачу (например, при уходе с экрана), ошибки не будет — просто пропустит.
      ➡️ Task.sleep — приостанавливает выполнение текущей задачи на указанный промежуток времени, на две секунды
      ➡️ return ["Aplle", "Orange", "Banana"].shuffled() - Возвращает массив строк (названия фруктов), shuffled() перемешивает порядок элементов, чтобы каждый раз список был случайным.
 */
final class RefreshableBootcampDataService {
    
    func getData() async throws -> [String] {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
       return ["Aplle", "Orange", "Banana"].shuffled()
    }
    
}

/*
 ✅ @Published private(set) var items: [String] = []
    ➡️ @Published сообщает SwiftUI: «следи за этим свойством».private(set) значит: ViewModel может изменять items, но View — только читать.  = [] Начальное значение — пустой массив.
 
 ⚙️🔻 func loadData() async {
    ➡️ try await manager.getData() — пробует загрузить данные и класса DataService из функции getData()
    ➡️ await приостанавливает функцию, пока не завершится асинхронная операция. После 2 секунд возвращаются данные.
    ➡️ Полученный результат присваивает в items: -> items = ["Banana", "Orange", "Apple"]
    ➡️ Поскольку items — @Published, SwiftUI автоматически обновит интерфейс.
    ⚠️ Если вдруг произошла ошибка — она попадёт в catch, и выведется в консоль.
 */
final class RefreshableBootcampViewModel: ObservableObject {
    @Published private(set) var items: [String] = []
    let manager = RefreshableBootcampDataService()
    
    func loadData() async {
            do {
                items = try await manager.getData()
            } catch {
                print(error)
            }
        }
    }

/*
 🔴 .refreshable { await vm.loadData() }
 ⚠️ Это встроенный SwiftUI модификатор, появившийся с iOS 15.Добавляет возможность потянуть вниз, чтобы обновить список.
 ➡️ Когда пользователь делает «pull to refresh», вызывается vm.loadData().Поскольку метод async, используется await.
 🔁 После отпускания экрана SwiftUI показывает спиннер загрузки,ждёт 2 секунды (из-за Task.sleep),и обновляет список фруктов в случайном порядке.
 ❕Так же можно добавить ProgressView во время ожидания этих 2 секунд, чтобы пользователь видел, что идёт загрузка
 
 🟡 .task { await vm.loadData() }
     ➡️ Это автоматический вызов при первом отображении View на экране. .task создаёт асинхронную задачу, которая выполняется один раз при появлении View.То есть сразу после загрузки экрана выполняется await vm.loadData().
     ✅ Таким образом: при открытии экрана данные загружаются автоматически, при потягивании вниз можно обновить их вручную.
 */
struct RefreshableBootcamp: View {
    
    @StateObject private var vm = RefreshableBootcampViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEach(vm.items, id: \.self) { item in
                        Text(item)
                            .font(.headline)
                    }
                }
            }
            .refreshable {
               await vm.loadData()
            }
            .navigationTitle("Refreshable")
            .task {
               await vm.loadData()
            }
        }
    }
}

#Preview {
    RefreshableBootcamp()
}
