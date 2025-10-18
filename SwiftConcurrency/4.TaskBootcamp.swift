//
//  4.TaskBootcamp.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 16.10.2025.
//

import SwiftUI
import Combine

class TaskBootcampViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    /*
     ✴️ func fetchImage() async - Это асинхронная функция с URL запросом
     
     ✅ try? await Task.sleep(nanoseconds: 5_000_000_000)  - Задержка в 5 секунд
     
     ✅ await MainActor.run - Переводит в основной поток(обновление экрана запрещенно в фоновых потоках)
          ➡️ self.image = UIImage(data: data) - Получение данных(data) с URL адреса и дабавление их в image что загрузит полученное изображенние иобновит экран пользователя! Поэтому вызваем эту строку кода в теле MainActor.run
          ➡️ print("Image returned succsessfully") - Печатает что изображенние успешно вернулось
     */
    func fetchImage() async {
        try? await Task.sleep(nanoseconds: 5_000_000_000) 
        do {
            guard let url = URL(string: "https://picsum.photos/200") else { return }
            let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            await MainActor.run {
                self.image = UIImage(data: data)
                print("Image returned succsessfully")
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

// ✅ MARK: Экран ссылка с переходом на экран с фото
struct TaskBootcampHomeView: View {
    var body: some View {
        ZStack {
            NavigationStack {
                NavigationLink("CLICK ME!") {
                    TaskBootcamp()
                }
            }
        }
        
    }
}

struct TaskBootcamp: View {
    
    @StateObject var vm = TaskBootcampViewModel()
    //@State private var fetchImageTask: Task<(), Never>? = nil
    
    var body: some View {
        VStack(spacing: 40) {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
        }
        /*
         ⚠️ Раньше при вызове Task приходилось создавать приватную переменную для хранения fetchImageTask и вручную вызывать методы .onAppear и .onDisappear(это нужно для того, если допустим пользователь открыл преложение зашел на экран и потом быстро перешел на другой экран, .onDisappear.cancle()  прерывает вызовы и функции с экрана который пользователь уже покинул) что бы они не выполнялись и не нагружали приложение
         
         ✅ .task  - И в этом современном мадификаторе уже под капотом в автоматическом режиме работают методы .onAppear и .onDisappear и  об этом почти не нужно думать?!
         ❌ Но если у вас есть много функций с длительными задачами и вы собераетесь их отменить(cancle()), Apple советует проверять это через модификатор try Task.checkCancellation() действительно ли отменена задача
         */
        .task {
            await vm.fetchImage()
        }
    }
}
       
// ✅ MARK: Это Task приоритеты:
            /*
            Task(priority: .high) {
               await Task.yield()
                    print("high Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }
            
            Task(priority: .userInitiated) {
                    print("userInitiated Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }
            
            Task(priority: .medium) {
                    print("medium Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }
            
            Task(priority: .low) {
                    print("low Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }
            
            Task(priority: .utility) {
                    print("utility Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }
            
            Task(priority: .background) {
                    print("background Task | isMainThread: \(Thread.isMainThread) | priority: \(Task.currentPriority)")
                }*/



#Preview {
    TaskBootcampHomeView()
}
