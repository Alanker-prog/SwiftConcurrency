//
//  RetainСycleARC.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 23.02.2026.
//

import SwiftUI
import Combine

/*
 🟢 (Двойной closure) - Даже если self используется во вложенном closure, внешний тоже его захватывает.
 
 🟢 Даже если нет Retain cycle нужет [weak self]❕
 Представим: это UIViewController пользователь нажал "назад" и экран должен удалиться ,но загрузка ещё идёт
 ◉ Без[weak self] будет жить до завершения загрузки
 ◉ С [weak self] если экран удалился, блок не выполнится
 
 🟢 Ключевой момент
  ◉ DispatchQueue.async = временное удержание
  ◉ Timer / stored closure = возможный retain cycle
 
 🟢 После [weak self]
   ◉ .self становится опциональным self?, потому что объект может быть уже освобождён к моменту выполнения замыкания. ◉ Поэтому нужно безопасно его развернуть.
   ◉ Есть два варианта:
    1️⃣ guard let self = self else { return } - Если self nil → весь блок прекращается
    🔥 guard let self создаёт ллокальную strong ссылку и она живет до конца closure
    ‼️ НЕ ИСПОЛЬЗОВАТЬ guard С await если await длится 10 секунд — объект будет жить 10 секунд.
    👇 ИСПОЛЬЗУЕМ В С await MainActor.run ✅
 
    Task { [weak self] in
        let data = await service.fetch()
        await MainActor.run {
            self?.handle(data)
        }
    }
 
    2️⃣ self?.tick() - Если self nil → пропускается только конкретная строка
 
 🟢 [unowned self]
    ◉ Используется, когда вы гарантированно уверены, что self не будет уничтожен.
    ◉ Если объект будет освобождён — приложение упадёт (crash).🔴
 */

//MARK: 1️⃣ GCD — загрузка изображения с сети
final class ProfileViewController: UIViewController {

    private let imageView = UIImageView()

    func loadAvatar(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: url),
                  let image = UIImage(data: data) else { return }

            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image
            }
        }
    }
}
/*📌 Почему [weak self] GCD    ⚠ иногда    Блок может пережить объект
Контроллер может закрыться до завершения загрузки.Без weak фоновой блок удержит VC.

⚠ Подводный камень
Если сделать guard let self = self в первом блоке — контроллер будет жить до конца загрузки.*/

//MARK: 2️⃣ Combine
final class CombineExample {

    private var cancellables = Set<AnyCancellable>()
    @Published var value = 0

    func start() {
        Just(5)
            .delay(for: .seconds(1), scheduler: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] number in
                self?.value = number
                print("Combine:", number)
            }
            .store(in: &cancellables)
    }
}
/*
🔴 Combine почти всегда нужен [weak self] self хранит cancellable. Без weak — retain cycle.*/

//MARK: 3️⃣ async/await
final class AsyncExample {

    private var value = 0

    func start() {
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            await MainActor.run {
                self?.value = 20
                print("Async:", self?.value ?? 0)
            }
        }
    }
}
/*📌 Почему [weak self] Task может жить дольше объекта.✅ ИСПОЛЬЗУЕМ В С await MainActor.run ✅
 ⚠️ в 90% случаев люди пишут: Task { await loadData() } ,
 */


//MARK: 4️⃣ Timer
import Foundation

final class TimerExample {

    private var timer: Timer?
    private var counter = 0

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.counter += 1
            print("Timer:", self?.counter ?? 0)
        }
    }

    deinit {
        timer?.invalidate()
    }
}
/*📌 Почему [weak self]  Timer удерживает closure Если self хранит timer → цикл.*/

//MARK: 5️⃣ UIAction / кнопки
class VCButton: UIViewController {

    lazy var button: UIButton = {
        let button = UIButton()
        button.addAction(UIAction { [weak self] _ in
            self?.buttonTapped()
        }, for: .touchUpInside)
        return button
    }()

    func buttonTapped() {
        print("Button tapped")
    }
}
