//
//  14.MVVM.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 29.10.2025.
//

/*
 🧩 Общая идея продемонстрировать разницу между обычным классом и актором
    ➡️ View — MVVMBootcamp (SwiftUI интерфейс);
    ➡️ ViewModel — MVVMBootcampViewModel;
    ➡️ Model / Manager — MyManagerClass и MyManagerActor, которые имитируют загрузку данных.
    🟢 Задача: При нажатии на кнопку вызвать асинхронный метод, получить строку "Some Data!" и обновить текст на экране.
 */
import SwiftUI
import Combine

/*
 ✅ Это класс (reference type), не потокобезопасен сам по себе.
    ➡️ От final class запрещенно заследоваться другим классам
    ➡️ Метод getData() — асинхронный (async) и потенциально может выбрасывать ошибку (throws),но на самом деле просто возвращает строку "Some Data!".
    ⚠️ В реальном проекте здесь мог бы быть сетевой запрос, например: try await URLSession.shared.data(from: url)
 */
final class MyManagerClass {
    func getData() async throws -> String {
        "Some Data!"
    }
}

/*
 ✅ actor — это специальный тип, потокобезопасный по умолчанию.
    ➡️ Любой доступ к данным внутри actor требует await, чтобы гарантировать, что только одна задача взаимодействует с актором в данный момент.
    ➡️ В остальном — тот же метод, возвращающий "Some Data!".
 */
actor MyManagerActor {
    func getData() async throws -> String {
        "Some Data!"
    }
}

/*
 🔸 @MainActor гарантирует, что все свойства и методы ViewModel выполняются в главном потоке (UI-потоке).Это значит, что когда View обновляет @Published свойство — это всегда безопасно для SwiftUI.(все методы и пременные в этом классе будет выполняться в главном потоке)
 
 🔸 @Published private(set) var myData
    @Published делает это свойство наблюдаемым — SwiftUI автоматически обновит интерфейс, если значение изменится.
    private(set) — (закрытый набор данных), это свойство можно изменить только внутри ViewModel, но не извне.

 ✅ private var tasks: [Task<Void, Never>]
    ➡️ private var: Это приватный массив с двумя асинхронными ЗАДАЧАМИ, его можно использовать только внутри этого класса
    ➡️ var tasks: Объявление свойства (переменной), которое можно изменять.В данном случае это массив, в который можно добавлять или удалять элементы (таски).
    ❕Task — это встроенный тип в Swift Concurrency, который представляет асинхронную задачу, выполняемую параллельно.Тип задачи указывается двумя generic-параметрами:Task<Success, Failure>
    ➡️ [Task<Void, Never>] - Task это массив С ДВУМЯ ЗАДАЧАМИ <Void, Never>.
    ⚠️ Success = Тип возвращаемого значения задачи
    ⚠️ Failure = Тип ошибки (должен соответствовать Error), либо Never, если ошибок быть не может,в нашем случае это Never!
    ➡️ Задача <Void = успеху(Success)
    ➡️ Задача Never> = говорит о том что задача не будет выдовать ошибки
 
 🔻⚙️ func cancelTasks() {
       ➡️ tasks.forEach({ $0.cancel() }) - Перебирает все активные задачи через цыкл forEach в tasks и вызывает cancel() — это отменяет их выполнение. Потом очищает массив, приравнимая к пустому массиву tasks = []
       ➡️ Обычно вызывается, например, при onDisappear, чтобы не было утечек.
 
 🔻⚙️ func onCallActionButtonPressed() {
      ➡️ let task = Task { - Создаем асинхронную задачу(Task) и ее результат добавлем в let task
      ⚠️ Мы специально создаем Task(задачу) в ViewModel что бы код был чище в основном экране struct MVVMBootcamp
      ➡️ myData = try await managerActor.getData() - Результат ("Some Data!") присваивается в myData.
      ➡️ } catch { - Если произошла ошибка — она ловится в блоке catch.
      ➡️ tasks.append(task) - Сохраняет задачу в массив tasks, чтобы при необходимости можно было отменить
 */

@MainActor
final class MVVMBootcampViewModel: ObservableObject {
    
    var managerClass = MyManagerClass()
    var managerActor = MyManagerActor()
    
    @Published private(set) var myData: String = "Starting text"
    private var tasks: [Task<Void, Never>] = []
    
    func cancelTasks() {
        tasks.forEach({ $0.cancel() })
        tasks = []
    }
    
    func onCallActionButtonPressed() {
       let task = Task {
           do {
              // myData = try await managerClass.getData()
               myData = try await managerActor.getData()
           } catch {
               print(error)
           }
        }
        tasks.append(task)
    }
    
}

struct MVVMBootcamp: View {
    
   @StateObject private var vm = MVVMBootcampViewModel()
    
    var body: some View {
        VStack{
            Button(vm.myData) {
                vm.onCallActionButtonPressed()
            }
        }
    }
}

#Preview {
    MVVMBootcamp()
}
