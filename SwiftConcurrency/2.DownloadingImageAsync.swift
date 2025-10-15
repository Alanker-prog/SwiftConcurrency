//
//  2.DownloadingImageAsync.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 15.10.2025.
//

import SwiftUI
import Combine

class DownloadingImageAsyncImageLoader {
    
    let url = URL(string: "https://api.ai-cats.net/v1/cat")!
    
    func handleResponse(data: Data?, response: URLResponse?) -> UIImage? {
        guard
            let data = data,
            let image = UIImage(data: data),
            let response = response as? HTTPURLResponse,
            response.statusCode >= 200 && response.statusCode < 300 else {
            return nil
        }
        return image
    }
    
    func downloadWithEscaping(completionHandler: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            let image = self?.handleResponse(data: data, response: response)
            completionHandler(image, error)
        }
        .resume()
    }
    
    func downloadingWithCombine() -> AnyPublisher<UIImage?, Error> {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(handleResponse)
            .mapError( { $0 })
            .eraseToAnyPublisher()
    }
    
    /*
     ✴️ Эта функция загружает изображение по URL с использованием Swift Concurrency (async/await) и возвращает UIImage?. Если что-то пойдёт не так — она выбросит ошибку.
     
     ✅ func downloadWithAsync() async throws -> UIImage?
          ➡️ async: функция асинхронная пишем ключевое слово async ( должна вызываться с await.)
          ➡️ throws: функция может выбросить ошибку (throw).
          ➡️ -> UIImage?: возвращает опциональное изображение (UIImage?).
     
     ✅ do { ... } catch { throw error }
          ➡️ Блок do пробует выполнить сетевой запрос.
          ➡️ Если ошибка — она попадает в catch и повторно выбрасывается (throw error).
          ⚠️ (На самом деле catch здесь необязателен — try await и так прокинет ошибку наружу, но это может быть заготовка под обработку ошибок.)
     
     ✅ let (data, responce) = try await URLSession.shared.data(from: url, delegate: nil)
          ➡️ Здесь происходит асинхронный сетевой запрос.
          ➡️ try await означает: "подожди, пока результат придёт, и выбрось ошибку, если что-то пошло не так".
          ➡️ URLSession.shared.data(from:) возвращает кортеж (Data, URLResponse) — содержимое и ответ от сервера.
     
     ✅ return handleResponse(data: data, response: responce)
          ➡️ Вызывается метод handleResponse(...) — он проверяет:есть ли данные,валидный ли HTTP статус и может ли быть создано изображение (UIImage(data:))
          ➡️Если всё ок — вернёт UIImage, иначе — nil.
     */
    func downloadWithAsync() async throws -> UIImage? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url, delegate: nil)
            return handleResponse(data: data, response: response)
        } catch  {
            throw error
        }
    }
    
}

class DownloadingImageAsyncViewModel: ObservableObject {
    
    @Published var image: UIImage? = nil
    let loader = DownloadingImageAsyncImageLoader()
    var cancelables = Set<AnyCancellable>()
    
    /*
     
    ✴️ Что делает функция в целом (человеческими словами) -> "Асинхронно загрузи изображение из интернета и, если получилось — обнови переменную image в главном потоке."
     
     ✅ func fetchImage() async {
         ➡️ Это асинхронная функция, которая не выбрасывает ошибок (throws нет) и не возвращает значение (-> нет).
         ➡️ Она может вызываться только из async контекста (например, внутри Task или другой async-функции) ->
         ⚠️Task {
             await viewModel.fetchImage()
           }
     
     ✅ let image = try? await loader.downloadWithAsync()
         ➡️ Вызывается асинхронная функция downloadWithAsync(), которая загружает изображение.
         ➡️ try? означает: если произойдёт ошибка (например, нет интернета) — image станет nil, и ошибка не будет выброшена. Это безопасный способ "пробовать" загрузку без обязательной обработки ошибок.
         ➡️ await - ждет ответа от loader.downloadWithAsync() и далее пробует загрузить полуенные данные в let image = try?
         ➡️ let image здесь будет типа UIImage?, либо nil, если: произошла ошибка (например, нет сети) или сервер вернул плохой ответ

     ✅ await MainActor.run { self.image = image }
         ➡️ await ждет ответа от let image если данные полученны переводит волученные данные в MainActor(главный поток)
         ➡️ MainActor.run возврвщает и запускает этот код в главном потоке, потому что обновление UI должно происходить в главном потоке!
         ➡️ Внутри тела мы присваиваем self.image = image(с полученными данными)
         ➡️ self.image — это @Published var image: Image? в ObservableObject, и я привязываю ниже vm.image.
     
     */
    func fetchImage() async {
        let image = try? await loader.downloadWithAsync()
        await MainActor.run {
            self.image = image
        }
        
        //WithEscaping
        /*
        loader.downloadWithEscaping { [weak self] image, error in
            DispatchQueue.main.async {
                self?.image = image
            }
        }*/
        //WithCombine
        /*loader.downloadingWithCombine()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                
            } receiveValue: { [weak self] image in
                    self?.image = image
            }
            .store(in: &cancelables)*/
    }
}


struct DownloadingImageAsyncBootcamp: View {
    
    @StateObject var vm = DownloadingImageAsyncViewModel()
    
    var body: some View {
        ZStack {
            if let image = vm.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            }
        }
        .onAppear {
            Task {
              await vm.fetchImage()
            }
        }
    }
}

#Preview {
    DownloadingImageAsyncBootcamp()
}
