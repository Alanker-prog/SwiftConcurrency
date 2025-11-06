//
//  17.PhotoPicker.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 05.11.2025.
//

import SwiftUI
import Combine
import PhotosUI

/*
✅ Это модель данных (ViewModel) — класс, который хранит состояние выбора фотографий и управляет загрузкой картинок.Он помечен как @MainActor, чтобы всё происходило в главном потоке (UI-потоке), ведь мы работаем с интерфейсом.
 */
@MainActor
final class PhotoPickerViewModel: ObservableObject {
    /*
     🟢 imageSelection — выбранный элемент из галереи (PhotosPickerItem).
     🟢 Когда пользователь выбирает фото, срабатывает didSet — вызывается метод setImage(from:).
     🟢 selectedImage — готовое изображение (UIImage), которое потом показывается на экране.
     */
    @Published private(set) var selectedImage: UIImage? = nil
    @Published var imageSelection: PhotosPickerItem? = nil {
        didSet {
            setImage(from: imageSelection)
        }
    }
    /*
     🟢 imageSelections — массив выбранных элементов (несколько картинок).
     🟢 Когда пользователь выбирает фото, автоматически вызывается setImages(from:).
     🟢 selectedImages — массив готовых UIImage, которые можно показать в ScrollView.
     */
    @Published private(set) var selectedImages: [UIImage] = []
    @Published var imageSelections: [PhotosPickerItem] = [] {
        didSet {
            setImages(from: imageSelections)
        }
    }
    /*
     ⚙️🔻 setImage(from:) — загружает одно фото
     🟢 Проверяет, выбрано ли фото (guard let selection).
     🟢 Создаёт Task, чтобы загрузка выполнялась асинхронно.
     ⚠️ Вызывает selection.loadTransferable(type: Data.self) — система сама загружает данные изображения и Преобразует Data в UIImage, если данные(Data) не полученны выбрасывает внутреннюю ошибку!
     🟢 Сохраняет в selectedImage, чтобы потом показать в UI.
     */
    private func setImage(from selection: PhotosPickerItem?) {
        guard let selection else { return }
        
        Task {
            do {
                let data = try? await selection.loadTransferable(type: Data.self)
                
                guard let data, let uiImage = UIImage(data: data) else {
                    throw URLError(.badServerResponse)
                }
                selectedImage = uiImage
            } catch {
                print(error)
            }
        }
    }
    /*
     ⚙️🔻 setImages(from:) — Она вызывается, когда пользователь выбрал несколько фотографий через PhotosPicker.

     ⚠️ from selections: [PhotosPickerItem]
        ➡️ это массив выбранных элементов (не сами картинки, а ссылки на них из фотогалереи).Тип PhotosPickerItem — это объект, который позволяет асинхронно загрузить содержимое (например, изображение) с помощью метода .loadTransferable().
     
     🟢 Создаёт Task асинхронную задачу.
     
     🟢 var images: [UIImage] = []
        🟡 Создаём пустой массив images, куда будем добавлять все загруженные картинки.Тип — [UIImage]
     
     🟢for selection in selections {
         ...
     }
        🟡 Перебор всех выбранных элементов.Проходим по каждому выбранному элементу (тип PhotosPickerItem) в списке selections.Каждый элемент — это ссылка на одно изображение из галереи пользователя.
     
     🟢 if let data = try? await selection.loadTransferable(type: Data.self) {
        🟡 Загрузка данных из элемента 🔹 Здесь происходит самое важное:
        🟡 Метод .loadTransferable(type: Data.self) асинхронно загружает содержимое выбранного элемента в виде Data (сырых байтов изображения).
        🟡 await — потому что загрузка может занять время.try? — потому что операция может выбросить ошибку (если пользователь отменил, файл повреждён и т.д.). В случае неудачи просто вернётся nil.
        📘 После этой строки — если всё ок — у нас есть Data, содержащие байты изображения.
     
     🟢 if let uiImage = UIImage(data: data) {
           images.append(uiImage)
        }
        🟡 Преобразование Data в UIImage🔹 Здесь создаётся объект UIImage из полученных байтов.
        🟡 Если конвертация прошла успешно — добавляем готовое изображение в массив images.
     
     
     🟢 selectedImages = images
        🟡 Присваивание результата в @Published свойство
        🟡 После того, как все изображения загружены и добавлены в массив,мы сохраняем их в selectedImages.
        ✴️ Поскольку selectedImages помечено как @Published, SwiftUI автоматически обновит интерфейс, где этот массив используется (например, ForEach(viewModel.selectedImages)).
     */
    private func setImages(from selections: [PhotosPickerItem]) {
        
        Task {
            var images: [UIImage] = []
            for selection in selections {
                if let data = try? await selection.loadTransferable(type: Data.self) {
                    if let uiImage = UIImage(data: data) {
                        images.append(uiImage)
                    }
                }
            }
                selectedImages = images
        }
    }
}


    


struct PhotoPickerBootcamp: View {
    
   /*
    Инициализация модели Создаётся экземпляр ViewModel, который хранит состояние выбора фотографий.
    */
   @StateObject private var viewModel = PhotoPickerViewModel()
    
    var body: some View {
        VStack(spacing: 40) {
            //Отображение одного фото
            if let image = viewModel.selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)
                    .frame(width: 300, height: 300)
                    
                    
            }
            /*
             ✴️ Первый PhotosPicker — одиночный выбор  Кнопка вызывает системный выбор фото.
               🟢 При выборе фото значение imageSelection обновляется → срабатывает didSet в imageSelection и  → фото загружается.
               ⚠️ У matching: есть много модификаторов видео,файлы,мвассивы данных(но тут просто для примера используем обычное .images)
               🟢 Text("Open the photo picker") - это обычный label как у button(кнопки)
             */
            PhotosPicker(selection: $viewModel.imageSelection, matching: .images) {
                Text("Open the photo picker")
                    .foregroundStyle(.red)
            }
                //Отображение нескольких фото
                if !viewModel.selectedImages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(viewModel.selectedImages, id: \.self) { image in
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .cornerRadius(10)
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                }
                
        /*
         ✴️ Второй PhotosPicker — множественный выбор
          ❕Второй PhotosPicker - работает аналогично первому, только с массивом изображений
            🟢 Этот пикер позволяет выбрать несколько фото сразу. Связывается с imageSelections (массивом).
            🟢 После выбора вызывается функция setImages(from:selections: [PhotosPickerItem]), и все изображения загружаются.
         */
            PhotosPicker(selection: $viewModel.imageSelections, matching: .images) {
                Text("Open the photos picker")
                    .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    PhotoPickerBootcamp()
}
