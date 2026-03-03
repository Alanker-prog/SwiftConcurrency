//
//  StrongSelfExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class StrongSelfExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global().async { [weak self] in
            
            guard let self = self else { return }
            
            print("Work started")
            sleep(1)
            
            DispatchQueue.main.async {
                self.view.backgroundColor = .red
            }
        }
    }
    
    deinit {
        print("StrongSelfExample deinit")
    }
}

/*
 🟢 strong self pattern

    ◉ Используется в замыканиях
    ◉ Предотвращает retain cycle
    ◉ Гарантирует, что self не исчезнет во время выполнения

────────────────────────────────────────────

 🔥 Что происходит в примере

    1️⃣ Замыкание захватывает [weak self]
    2️⃣ self может стать nil
    3️⃣ guard let self = self
       создаёт временную strong ссылку

    Это и есть strong self pattern.

────────────────────────────────────────────

 🧠 Почему просто [weak self] недостаточно

    Если писать так:

        [weak self] in
        self?.doSomething()

    self может стать nil
    между строками кода.

    guard создаёт безопасную strong ссылку
    на время выполнения блока.

────────────────────────────────────────────

 🟢 weak vs unowned

    weak:
        ◉ Не увеличивает счётчик ссылок
        ◉ Может стать nil
        ◉ Тип всегда Optional

    unowned:
        ◉ Не увеличивает счётчик ссылок
        ◉ НЕ может стать nil
        ◉ Если объект удалён → crash

────────────────────────────────────────────

 🔥 Когда использовать

    weak:
        ◉ В async коде
        ◉ Когда объект может быть освобождён

    unowned:
        ◉ Когда гарантировано,
          что объект жив дольше
        ◉ Например parent → child связь

────────────────────────────────────────────

 🟡 Почему это важно в многопоточности

    ◉ Async код живёт дольше,
      чем ViewController
    ◉ Без weak self возникает retain cycle
    ◉ Или обновление UI после удаления экрана

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ Замыкания захватывают self strongly
    ◉ Используем [weak self] в async коде
    ◉ strong self pattern делает код безопасным
    ◉ unowned может привести к crash
 */
