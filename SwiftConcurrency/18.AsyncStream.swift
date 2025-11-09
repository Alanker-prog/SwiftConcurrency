//
//  18.AsyncStream.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 07.11.2025.
//

/*
 🧠 Коротко: зачем нужны AsyncStream и AsyncThrowingStream
 Когда ты используешь async/await, ты работаешь с операциями, которые возвращают одно значение в будущем.
 Например:
 let data = try await networkManager.loadData()

 Ты ждёшь один результат. ⚠️ Но бывают ситуации, когда нужно получать много значений постепенно — например:
 поток входящих сообщений в чате,данные с сенсора,нотификации из системы, обновления прогресса загрузки,или просто последовательные значения, приходящие с задержкой.
 Для этого и нужны асинхронные последовательности (AsyncSequence) — они позволяют await-ить новые значения по мере их появления. AsyncStream — это способ самостоятельно создать такую последовательность.

 🧩 Как устроен AsyncStream
 Определение
 struct AsyncStream<Element>: AsyncSequence

 Он создаёт поток (stream) значений типа Element.

 Ты задаёшь, как и когда эти значения будут поступать, с помощью closure, который принимает объект типа AsyncStream<Element>.Continuation.

✴️ Пример 1: простой поток чисел
 func makeNumberStream() -> AsyncStream<Int> {
     AsyncStream { continuation in
         for i in 1...5 {
             continuation.yield(i) // Отправляем значение в поток
         }
         continuation.finish() // Говорим, что поток закончен
     }
 }


 А использовать его можно так:

 Task {
     for await number in makeNumberStream() {
         print("Получено: \(number)")
     }
 }

 🔹 Этот код выведет:

 Получено: 1
 Получено: 2
 Получено: 3
 Получено: 4
 Получено: 5

✴️ Пример 2: с задержкой (асинхронные данные)
 func delayedStream() -> AsyncStream<Int> {
     AsyncStream { continuation in
         for i in 1...5 {
             DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                 continuation.yield(i)
                 if i == 5 {
                     continuation.finish()
                 }
             }
         }
     }
 }


 А потом:

 Task {
     for await value in delayedStream() {
         print("Пришло: \(value)")
     }
 }


 Теперь значения будут приходить каждую секунду.

 ⚠️ Что такое Continuation

 Continuation — это объект, который управляет потоком изнутри. У него есть 3 основных метода:

 Метод    Что делает
 yield(_:)    Отправляет новое значение подписчику
 finish()    Завершает поток
 yield(with:)    Позволяет передать результат Result<Element, Error> (удобно для AsyncThrowingStream)
 💥 AsyncThrowingStream

 Аналогичен AsyncStream, но может выбрасывать ошибки (через throw).

 Определение:

 struct AsyncThrowingStream<Element, Failure: Error>: AsyncSequence


 Используется, когда значения могут поступать вместе с ошибками, например при работе с сетью.

 Пример: поток данных, где может быть ошибка
 enum DataError: Error {
     case networkFailed
 }

 func getDataStream() -> AsyncThrowingStream<Int, Error> {
     AsyncThrowingStream { continuation in
         for i in 1...5 {
             DispatchQueue.global().asyncAfter(deadline: .now() + Double(i)) {
                 if i == 3 {
                     continuation.finish(throwing: DataError.networkFailed)
                 } else {
                     continuation.yield(i)
                 }
             }
         }
     }
 }


 А использование:

 Task {
     do {
         for try await value in getDataStream() {
             print("Значение: \(value)")
         }
     } catch {
         print("Ошибка: \(error)")
     }
 }


 Результат:

 Значение: 1
 Значение: 2
 Ошибка: networkFailed

 ✴️ Сравнение с Combine ✴️
 Combine:           Swift Concurrency:
 🟡 Publisher   ➡️  🟢 AsyncSequence
 🟡 .sink       ➡️  🟢 for await
 🟡 .send()     ➡️  🟢 yield()
 🟡 .completion ➡️  🟢 finish()

 ‼️ То есть AsyncStream — это своего рода аналог Combine Publisher, но в новом синтаксисе async/await.

 🧩 Назначение
    🟢 AsyncStream<T>                  Поток значений типа T, указываем пердаваемый тип данных
    🟢 AsyncThrowingStream<T, Error>   То же самое, но может завершиться ошибкой
    🟢 yield()                         Отправить значение
    🟢 finish()                        Завершить поток
    🟢 for await ... in                Асинхронно получать значения по мере их поступления
 
 ✅ Когда использовать:
 🔴 Используй AsyncStream, если:
 🟡 нужно подписаться на callback API и превратить его в async поток
 🟡 нужно создавать собственные события (таймер, сенсоры, нотификации, WebSocket)
 🟡 нужно упростить старые делегаты в асинхронный стиль

 🔴 Используй AsyncThrowingStream, если:
 🟡 источники данных могут завершиться с ошибкой
 🟡 данные поступают из ненадёжного источника (сеть, Bluetooth, файловая система и т.д.)
 */
import SwiftUI
import Combine

class AsyncStreamDataManager {
    
    func getFakeDataStream() -> AsyncStream<Int> {
        let items = [1,2,3,4,5,6,7,8,9,10]
        return AsyncStream { continuation in
            for item in items {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(item)) {
                    continuation.yield(item)
                    if item == items.last {
                        continuation.finish()
                    }
                }
            }
        }
    }
}

@MainActor
    final class AsyncStreamViewModel: ObservableObject {
        
        let manager = AsyncStreamDataManager()
        @Published private(set) var currentNumber: Int = 0
        
        
        func onViewAppear() {
            Task {
                for await value in manager.getFakeDataStream() {
                    currentNumber = value
                }
                //        manager.getFakeData() { [weak self]  value in
                //            self?.currentNumber = value
            }
        }
        
        
    }

struct AsyncStreamBootcamp: View {
    
    @StateObject var vm = AsyncStreamViewModel()
    
    var body: some View {
        Text("\(vm.currentNumber)")
            .onAppear {
            vm.onViewAppear()
        }
    }
}

#Preview {
    AsyncStreamBootcamp()
}
