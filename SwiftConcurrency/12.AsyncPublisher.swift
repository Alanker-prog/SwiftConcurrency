//
//  12.AsyncPublisher.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 28.10.2025.
//
/*
  🟡 AsyncSequence - смотри 18 урок! Вкратце представь, что элементы(данные) появляются со временем — например, каждую секунду.Проще говоря, это такой источник данных, который постепенно выдаёт элементы во времени, и ты можешь их асинхронно получать с помощью for await.
 
 ➡️ Здесь цикл ждёт, пока появится новое значение.
 Когда оно приходит — цикл выполняет итерацию, потом снова ждёт.
 
 @Published - Автоматически создаёт Publisher для свойства
 .values - Превращает Combine Publisher в асинхронную последовательность
 for await in - Асинхронно слушает поток данных
 @MainActor.run - Обеспечивает безопасное обновление UI из главного потока
 Task - Позволяет запустить асинхронный код внутри обычного метода
 ObservableObject - Сообщает SwiftUI, когда нужно перерисовать View
 */
import SwiftUI
import Combine

/*
 ✅ Асинхроная функция func addData() async добавляет в публичный стринговый массив -> @Published var myData: [String] = [] , данные с задержкой в 2 секунды
 */
class AsyncPublisherBootcampDataManager {
    
    @Published var myData: [String] = []
    
    func addData() async {
        myData.append("Apple")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Banana")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Orange")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        myData.append("Watermelon")
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
    
}


/*
 ✅ @MainActor @Published var dataArrey: [String] = []
    ➡️ @Published делает dataArrey издателем (Publisher) — SwiftUI будет слушать его изменения. @MainActor гарантирует, что все изменения этого свойства происходят в главном потоке (UI-потоке).
 
 ✅ let manager = AsyncPublisherBootcampDataManager()
    ➡️ manager это пременная(объект) через которуый мы получаем и управляем данными из класса AsyncPublisherBootcampDataManager()
 
 ❕cancellables нужен нужен для работы старого Combine-подхода
 
 ✅ init() {
        addSubscribers()
    }
    ➡️ При создании экземпляра ViewModel сразу вызывается addSubscribers() — то есть сразу начинается подписка на поток данных из manager.
 
   ✴️ private func addSubscribers() {
 
      ✅ Task { - Создаёт новую асинхронную задачу. Внутри можно использовать await, а код не блокирует основной поток.
 
      ✅ for await value in
         ➡️ Это асинхронный цикл, который: ждёт пока manager.myData изменится, получает новое значение value каждый раз, когда Publisher публикует обновление.Цикл не блокирует поток, он приостанавливается до следующего обновления данных.(❌ Если в Task после цыкла for in есть еще какая-то логика нужно прописать оператор break в противном случае код после цыкла не отработает. Или нужно делать два Task если у вас несколько подписчиков)
      
      ✅ manager.$myData.values
         ➡️ manager.$myData — это Publisher, который создаётся автоматически благодаря @Published свойству myData в manager.
         ⚠️ .values — превращает Publisher из Combine в асинхронную последовательность (AsyncSequence).⚠️
         ➡️ Это и есть AsyncPublisher — мост между Combine и Swift Concurrency.
 
      ✅ await MainActor.run { ... }
         ➡️ Поскольку dataArrey — свойство, связанное с главным потоком (@MainActor),мы обновляем его только внутри MainActor, чтобы не нарушить потокобезопасность.
 
      ✅ self.dataArrey = value
         ➡️ то есть каждое новое значение из менеджера записывается в dataArrey, что вызовет обновление интерфейса SwiftUI.
 */
class AsyncPublisherBootcampViewModel: ObservableObject {
    
    @MainActor @Published var dataArrey: [String] = []
    let manager = AsyncPublisherBootcampDataManager()
    var cancellables = Set<AnyCancellable>()
    
    init() {
        addSubscribers()
    }
    
    private func addSubscribers() {
        Task {
            for await value in manager.$myData.values {
                await MainActor.run {
                    self.dataArrey = value
                }
            }
        }
        
    // ❌ старый метод Combine-подхода Он делает то же самое, только с помощью реактивных операторов. 🔄 Новый асинхронный подход с for await делает то же самое, но в более понятной форме.
//        manager.$myData
//            .receive(on: DispatchQueue.main, options: nil)
//            .sink { dataArrey in
//                self.dataArrey = dataArrey
//            }
//            .store(in: &cancellables)
    }
    
    /*
    ✅ Это просто асинхронный вызов функции внутри менеджера, которая изменяет myData (например, добавляет новые строки в массив).После каждого обновления myData, цикл for await в addSubscribers() автоматически получит новое значение.
     */
    func start() async {
       await manager.addData()
    }
    
}

struct AsyncPublisherBootcamp: View {
    
    @StateObject var vm = AsyncPublisherBootcampViewModel()
    
    var body: some View {
        ScrollView {
            VStack {
                ForEach(vm.dataArrey, id: \.self) {
                    Text($0)
                        .font(.headline)
                }
            }
        }
        .task {
            await vm.start()
        }
    }
}

#Preview {
    AsyncPublisherBootcamp()
}
