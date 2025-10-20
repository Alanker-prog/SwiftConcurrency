//
//  6.TaskGroup.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 19.10.2025.
//

import SwiftUI
import Combine



/*
 ✴️ fetchImagesWithTaskGroup() запускает параллельные загрузки 5 изображений.Используется TaskGroup, чтобы загрузки шли одновременно (а не последовательно).Все успешно загруженные изображения возвращаются в виде массива [UIImage].
 ❌ Хотя такой код маштабируется и можно загружать сразу массив данных с многими Api ,он не позволяет использовать в одной группе разные функции 
 */
class TaskGroupBootcampDataManager {
    /*
     ✅ Функция fetchImagesWithTaskGroup() скачивает 5 изображений параллельно с заданных URL и возвращает массив изображений ([UIImage]).
     
     ✅ return try await withThrowingTaskGroup(of: UIImage?.self) { group in
         ➡️ Создаётся асинхронная Task Group, в которую можно добавлять задачи, которые выполняются параллельно. Тип задачи — UIImage?(тип данных может быть любой,можно поменять тип в возврате функции и тогда поменяется на выбранный тип и в Task Group), также может вернуться nil, если что-то пошло не так.
     
     ⚠️ var images: [UIImage] = []
     ⚠️ images.reserveCapacity(urlString.count) -
         ➡️ Создаём массив images и резервируем в нём место под 5 изображений, чтобы избежать перераспределения памяти при добавлении.
     
     ✅ for urlString in urlString {
            group.addTask {
                try? await self.fetchImage(urlString: urlString)
            }
        }
         ➡️ Для каждого URL добавляется отдельная асинхронная задача в группу, которая вызывает функцию fetchImage.
         ➡️ try? — опциональный try нужен для того что если в одном URL будет ошибка остальные отработают штатно,в URL с ошибкой  вернётся nil, и задача не "уронит" группу.
         ➡️ В Task Group все 5 задач запускаются параллельно.
     
      ✅  for try await image in group {
              if let image = image {
                  images.append(image)
              }
          }
        ➡️ Ждём, пока каждая задача завершится.Если изображение не nil, добавляем его в массив images.
     
      ✅ return images - После завершения всех задач возвращается массив полученных изображений.


     */
    func fetchImagesWithTaskGroup() async throws -> [UIImage] {
        let urlString = [
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300",
            "https://picsum.photos/300"
        ]
        return try await withThrowingTaskGroup(of: UIImage?.self) { group in
            var images: [UIImage] = []
            images.reserveCapacity(urlString.count)
        
            for urlString in urlString {
                group.addTask {
                    try? await self.fetchImage(urlString: urlString)
                }
            }
            
            for try await image in group {
                if let image = image {
                    images.append(image)
                }
            }
            
            return images
        }
    }
    
    /*
     ✅ private func fetchImage(urlString: String) async throws -> UIImage
        ➡️ Это вспомогательная функция, которая скачивает изображение по URL.
     
     ✅ guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        ➡️ Создает URL и проверяет, правильный ли URL. Если нет — выбрасывает ошибку.
     
     ✅ let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
        ➡️ Пробует асинхронно загрузить данные с сервера по заданному URL.
        ➡️ (data, _) - responce мы игнорируем нижним подчеркиваением
     
     ✅ if let image = UIImage(data: data) {
              return image
         } else {
              throw URLError(.badURL)
         }
         ➡️ Пытается превратить полученные данные UIImage(data: data) в изображение image. Если не получилось — снова ошибка.
     
     */
    private func fetchImage(urlString: String) async throws -> UIImage {
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        do {
        let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            if let image = UIImage(data: data) {
                return image
            } else {
                throw URLError(.badURL)
            }
        } catch  {
            throw error
        }
    }
    
}

class TaskGroupBootcampViewModel: ObservableObject {
    
    @Published var images: [UIImage] = []
    let manager = TaskGroupBootcampDataManager()
    
    func getImages() async {
        if let images = try? await manager.fetchImagesWithTaskGroup() {
            self.images.append(contentsOf: images)
        }
        
    }
}

struct TaskGroupBootcamp: View {
    
    @StateObject private var vm = TaskGroupBootcampViewModel()
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns) {
                    ForEach(vm.images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }
                }
            }
            .navigationTitle("Task Group")
            .task {
                await vm.getImages()
            }
        }
    }
}
#Preview {
    TaskGroupBootcamp()
}
