//
//  RetainCycleARC.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 23.02.2026.
//

import SwiftUI
import Combine
import Foundation

// MARK: - Теория: Retain Cycle и захват self

/*
 🔴 Retain Cycle возникает, когда:
 объект A сильно удерживает объект B,
 а объект B сильно удерживает объект A.

 Классический пример — stored closure:

 final class ViewModel {

     var closure: (() -> Void)?

     func setup() {
         closure = {
             print(self.name) // self захватывается strongly
         }
     }
 }

 ViewModel → closure (strong)
 closure → self (strong)
 = retain cycle
*/

/*
 🔶 Временное сильное удержание (без цикла)

 Если self используется внутри Task или DispatchQueue,
 объект будет жить до завершения блока.

 Это НЕ retain cycle, но продление жизни объекта.
*/

/*
 🟢 Когда нужен [weak self]

 - Когда closure хранится в свойстве (stored closure)
 - Когда используется Timer
 - Когда self хранит cancellable (Combine)
 - Когда Task может жить дольше объекта
*/

/*
 🟢 После [weak self]:

 self становится optional (self?),
 потому что объект может быть освобождён.
*/

/*
 🟢 [unowned self]

 Используется, если вы на 100% уверены,
 что self будет жить дольше closure.

 Если объект освобождён → crash.
*/

// MARK: - 1️⃣ GCD — загрузка изображения

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

/*
 📌 Почему [weak self]?

 DispatchQueue может выполниться позже,
 чем деинициализируется контроллер.

 Это не retain cycle,
 а продление жизни объекта.
*/

// MARK: - 2️⃣ Combine

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
 🔴 Возможный retain cycle:

 self → cancellable
 cancellable → closure
 closure → self
*/

// MARK: - 3️⃣ async / await

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

/*
 📌 Task может жить дольше объекта.
 Это не retain cycle,
 но продление жизни.
*/

// MARK: - 4️⃣ Timer

final class TimerExample {

    private var timer: Timer?
    private var counter = 0

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1,
                                     repeats: true) { [weak self] _ in
            self?.counter += 1
            print("Timer:", self?.counter ?? 0)
        }
    }

    deinit {
        timer?.invalidate()
    }
}

/*
 📌 Retain cycle:

 self → timer
 timer → closure
 closure → self
*/

// MARK: - 5️⃣ UIAction / UIButton

final class VCButton: UIViewController {

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

/*
 Возможен retain cycle,
 если closure захватывает self strongly.
 Использование [weak self] безопаснее.
*/
