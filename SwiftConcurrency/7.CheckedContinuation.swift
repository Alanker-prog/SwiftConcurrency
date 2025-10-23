//
//  7.CheckedContinuation.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 20.10.2025.
//

import SwiftUI
import Combine

class CheckedContinuationBootcampNetworkManager {
    
    /*
     ✅ func getData(url: URL) async throws -> Data
        ➡️ Асинхронно загружает данные по URL, используя URLSession и async/await. Это стандартный способ загрузки данных в Swift 5.5+ с async/await.
        ➡️ Вызывается метод URLSession.shared.data(from:delegate:) – это встроенный асинхронный API.
        ➡️ Он возвращает кортеж (data, response).
        ➡️ Если загрузка прошла успешно, возвращает data.Если произошла ошибка – пробрасывает её дальше.
     */
    func getData(url: URL) async throws -> Data {
        do {
         let (data, _) = try await URLSession.shared.data(from: url, delegate: nil)
            return data
        } catch  {
            throw error
        }
    }
    
    /*
     ✴️ Этот способ нужен, если ты работаешь с API, которое ещё не поддерживает async/await.(По сути мы берем асинхроную функцию(обертку) в ее тело вставляем НЕ Асинхроный(старый) API метод dataTask. В теле асинхронные задачи останавливаются и нам нужно потом их снова перезапустить после того как НЕ Асинхроный код в теле выполнится. Запускаем асинхронный метод с помощью .resume()
     
     ✅ Использует withCheckedThrowingContinuation, чтобы обернуть старый callback API (URLSession.shared.dataTask) в новый метод async/await.
     
     ⚠️ return try await withCheckedThrowingContinuation - это замыкание(обертка).
        ➡️ { continuation in - Пишем в ручную
        ➡️ В тело замыкания мы добавляем старый НЕ Асинхронный метод .dataTask, когда загрузка завершена,срабатывает замыкание dataTask и оно возврашает картеж -> data, response, error in
     
     ✅ if let data = data { - Условия если данные полученны с замыкания dataTask
        ➡️ Если есть data → вызываем continuation.resume(returning: data).
        ➡️ Если есть error → вызываем continuation.resume(throwing: error).
        ➡️ Если ни того, ни другого — создаем и пробрасываем ошибку URLError(.badURL).
     
     ⚠️ .resume() обязательно вызывает продолжение выполнения асинхронного кода.
     */
    func getData2(url: URL) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared.dataTask(with: url) { data, response, error in
                if let data = data {
                    continuation.resume(returning: data)
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: URLError(.badURL))
                }
            }
            .resume()
        }
    }

    // Это пример старого стиля асинхронности – с callback(мы обернем ее в async функцию ниже)
    func getHeartImageFromDatabae(completionHandler: @escaping(_ image: UIImage) ->()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            completionHandler(UIImage(systemName: "heart.fill")!)
        }
    }
    
    /*
     ✴️ Оборачивает предыдущую функцию👆 с callback'ом в async-функцию с помощью withCheckedContinuation.
     
     ✅ await withCheckedContinuation - Использует withCheckedContinuation, чтобы обернуть функцию с callback.
     ✅ В замыкании вызывает старую версию(Не Асинхронную) функции getHeartImageFromDatabae.
     ✅ Когда получен image, вызывает continuation.resume(returning: image).
     */
    func getHeartImageFromDatabae() async -> UIImage {
        await withCheckedContinuation { continuation in
            getHeartImageFromDatabae { image in
                continuation.resume(returning: image)
            }
        }
    }
}

class CheckedContinuationBootcampViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    let networkManager = CheckedContinuationBootcampNetworkManager()
    
    /*
     ✴️ func getImage() async
        ➡️ Загружает изображение с интернета и сохраняет в image.
        ➡️ Это функция, которая показывает, как загрузить картинку асинхронно и отобразить в UI.
     
     ✅ Создает URL из строки "https://picsum.photos/300" (случайное изображение 300x300).

     ✅ Вызывает networkManager.getData2(url:), чтобы получить данные (через continuation).

     ✅ Если получилось создать UIImage(data:) из полученных данных:

     ✅ Переходит на главный поток (MainActor.run) и присваивает изображение свойству self.image.

     ✅Если произошла ошибка — выводит её в консоль.
     */
    func getImage() async {
        guard let url = URL(string: "https://picsum.photos/300") else { return }
        
        do {
            let data = try await networkManager.getData2(url: url)
            
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.image = image
                }
            }
        } catch  {
            print(error)
        }
    }
    
    // Получает иконку "сердце" асинхронно (через withCheckedContinuation).имитация загрузки "из базы данных".
    func getHeartImage() async {
        self.image = await networkManager.getHeartImageFromDatabae()
    }
}


struct CheckedContinuationBootcamp: View {
    
    @StateObject var vm = CheckedContinuationBootcampViewModel()
    
    var body: some View {
        ZStack {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
            }
        }
        .task {
            //await vm.getImage()
            await vm.getHeartImage()
        }
    }
}

#Preview {
    CheckedContinuationBootcamp()
}
