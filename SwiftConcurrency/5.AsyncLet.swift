//
//  5.AsyncLet.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 18.10.2025.
//

import SwiftUI

struct AsyncLetBootcamp: View {
    
    @State private var images: [UIImage] = []
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    let url = URL(string: "https://picsum.photos/300")!
    
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                    }
                }
            }
            .navigationTitle("Async Let!")
            /*
             ✴️ async let - Стоит использовать когда у вас 2-3 запроса(не подходит если у вас много запросов и большой запрос массив)
             ✅ async let fetchImage = fetchImage() - Добавляем через асинхронную функцию изображения в "fetchImage"
             ✅ let (image1, image2, image3, image4) = try await - Пробуем передать полученные данные в локальную пременную "image"
             ✅ self.images.append(contentsOf: [image1, image2, image3, image4]) - Если данные полученны добавляем их в наш приватный массив images: [UIImage]
             ⚠️ В это примере кода, где все вызовы добавляется в один массив через let все четыре изображения отобразятся одновреммено на экране у пользователя (так и должно бать!, а не как в примере ниже где изображения загружаются по очереди с задержкой)
             ❌ Также в такие примеры кода можно использовать и совмещать несколько различных функций 
             */
            .onAppear {
                Task {
                    do {
                        async let fetchImage1 = fetchImage()
                        async let fetchImage2 = fetchImage()
                        async let fetchImage3 = fetchImage()
                        async let fetchImage4 = fetchImage()
                        
                        let (image1, image2, image3, image4) = try await (fetchImage1, fetchImage2, fetchImage3, fetchImage4)
                        self.images.append(contentsOf: [image1, image2, image3, image4])

    // ✅ MARK: В примере ниже ижображения будут загружаться с небольшой задеркой по очереди(код выполняется с верху в низ, не очень хороший пример даже не знаю пока где это применить)
//                        let image1 = try await fetchImage()
//                        self.images.append(image1)
//                        
//                        let image2 = try await fetchImage()
//                        self.images.append(image2)
//                        
//                        let image3 = try await fetchImage()
//                        self.images.append(image3)
//                        
//                        let image4 = try await fetchImage()
//                        self.images.append(image4)
//                        
                    } catch {
                        
                    }
                }
            }
        }
    }
    
    func fetchImage() async throws -> UIImage {
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

#Preview {
    AsyncLetBootcamp()
}
