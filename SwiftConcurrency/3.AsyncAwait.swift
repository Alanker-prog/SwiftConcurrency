//
//  3.AsyncAwait.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 16.10.2025.
//

import SwiftUI
import Combine

class AsyncAwaitBootcampViewModel: ObservableObject {
    
    @Published var dataArrey: [String] = []
    
    func addTitle1() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dataArrey.append("Title1 \(Thread.current.description)")
        }
    }
    
    func addTitle2() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        let title = "Title2 \(Thread.current.description)"
            DispatchQueue.main.async {
                self.dataArrey.append(title)
                
                let title3 = "Title3 \(Thread.current.description)"
                self.dataArrey.append(title3)
            }
           
            
        }
    }
    
    /*
     ✅ Этот урок проходной и главное что нужно понять из урока: Старый метод DispatchQueue мы в ручную вызывали и пеключались между главным и фоновыми потоками(примеры сверху).
     ✅ А более новый метод асинхронный async/await. Главное что нужно знать для обновления итерфейса экрана после слова await мы должны написать MainActor.run(body: { }) и уже в теле меинактора прописать обновление интерфейса, это нужно потому что await может выкинуть рандомно выполнение этого когда в фоновый поток(запрешенно обновлять интерфейс в фоновом потоке), он также возможно может выполнить код и главном потоке , но так как мы точно этого не знаем мы пишем MainActor.run(body: { }) что бы код точно отработал в главном потоке!
     
     ⚠️ Так же я умышленно оставил желтое предупреждение(если буду пресматривать урок буду знать в чем дело):
         ➡️ В Swift 6 (или в режиме совместимости со Swift 6), ты не можешь вызывать Thread.current внутри async функции. Причина — Thread.current основан на синхронном API, и его использование в асинхронных контекстах больше не безопасно или корректно.Это предупреждение в Swift 6 оно будет считаться ошибкой компиляции
         ➡️ Асинхронные функции (async) могут переключать потоки исполнения, особенно если используются такие штуки как Task.sleep. После await, код может продолжить выполняться уже на другом потоке, поэтому Thread.current становится неконсистентным или бесполезным — это больше не гарантированная информация.
     
     ✅ Безопасная(исправленная) версия кода:
     
     func addSomething() async {
         try? await Task.sleep(nanoseconds: 2_000_000_000)
         
         // Проверка потока (безопасно)
         let isMain = Thread.isMainThread
         let something = "Something (on main thread? \(isMain))"
         
         await MainActor.run {
             self.dataArrey.append(something)
         }
     }
     */
    func addSomething() async {
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        let samething = "Something : \(Thread.current.description)"
        await MainActor.run(body: {
            self.dataArrey.append(samething)
        })
    }
}

struct AsyncAwaitBootcamp: View {
    
    @StateObject var vm = AsyncAwaitBootcampViewModel()
    
    var body: some View {
        List {
            ForEach(vm.dataArrey, id: \.self) { data in
                Text(data)
            }
        }
        .onAppear {
            //vm.addTitle1()
            //vm.addTitle2()
            Task {
                await vm.addSomething()
            }
        }
    }
}

#Preview {
    AsyncAwaitBootcamp()
}
