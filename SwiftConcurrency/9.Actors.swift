//
//  9.Actors.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 24.10.2025.
//

import SwiftUI
import Combine

/*
✅ actor — это специальный тип (как class), который гарантирует потокобезопасность для данных внутри него.
 Swift автоматически следит за тем, чтобы обращение к свойствам и методам этого actor происходило только из одной задачи (task) за раз.👉 То есть: Если два потока попытаются одновременно изменить data, Swift гарантирует, что они будут выполняться по очереди, а не одновременно.
 
 ✅ private init(){ }
    ➡️ Конструктор закрыт (private), чтобы никто не мог создать другой экземпляр
    ➡️ Только MyActorDataManager.instance доступен извне.
 
 ✅ var data: [String] = []
    ➡️ Это обычный массив строк, хранящий данные.Так как он объявлен внутри actor, доступ к нему потокобезопасен — нельзя менять его с разных потоков одновременно без await.
 
 ✅ nonisolated let myRandomText = "ggggggggg"
    ➡️ Ключевое слово nonisolated говорит эта константа, доступная без await
    ⚠️ Обычно nonisolated используют для констант или чистых функций,если нужно избавиться от асинхронности
 
 ✅ func getRandomData() -> String?
    ➡️ Это изолированный метод актёра (по умолчанию все методы изолированы).Каждый вызов будет выполняться внутри акторной очереди, чтобы не было гонок данных.
 
 ✅ nonisolated func getSaveData() -> String
    ⚠️ Это метод, который не изолирован актором поэтому его можно вызвать без await и из любого потока
 */
actor MyActorDataManager {
    
    static let instance = MyActorDataManager()
    private init(){ }
    
    var data: [String] = []
    nonisolated let myRandomText = "ggggggggg"
    
    func getRandomData() -> String? {
        self.data.append(UUID().uuidString)
        print(Thread.current)
        return self.data.randomElement()
    }
    
   nonisolated func getSaveData() -> String {
        return "New Data"
    }

}

// ❌ Старый метод менее удобный, делает код потокобезопасным(до пявления actor)
class MyDataManager {
    
    static let instance = MyDataManager()
    private init(){ }
    
    var data: [String] = []
    private let lock = DispatchQueue(label: "com.MyApp.MyDataManager")
    
    func getRandomData(completionHandler: @escaping (_ title: String?) -> ()) {
        lock.async {
            self.data.append(UUID().uuidString)
            print(Thread.current)
            completionHandler(self.data.randomElement())
        }
    }
}
    


// ✅ Метод для актора
struct HomeView: View {
    
    let manager = MyActorDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.3, tolerance: nil, on: .main, in: .common, options: nil).autoconnect()
    
    var body: some View {
        ZStack {
            Color.gray.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onAppear(perform: {
            let newString = manager.getSaveData()
        })
        
        .onReceive(timer) { _ in
            Task {
                if let data = await manager.getRandomData() {
                    await MainActor.run(body: {
                        self.text = data })
                }
            }
        }
        
    }
}

// ✅ Старый способ для потокабезопасности
struct BrowseView: View {
    
    let manager = MyDataManager.instance
    @State private var text: String = ""
    let timer = Timer.publish(every: 0.3, tolerance: nil, on: .main, in: .common, options: nil).autoconnect()
    
    var body: some View {
        ZStack {
            Color.yellow.opacity(0.8).ignoresSafeArea()
            
            Text(text)
                .font(.headline)
        }
        .onReceive(timer) { _ in
            DispatchQueue.global(qos: .background).async {
                manager.getRandomData { title in
                    if let data = title {
                        DispatchQueue.main.async {
                            self.text = data
                       }
                    }
                }
            }
        }
    }
}

struct ActorsBootcamp: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "magnifyingglass")
                }
            
        }
        
    }
}

#Preview {
    ActorsBootcamp()
}
