//
//  SendableExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

struct User: Sendable {
    let id: Int
    let name: String
}

class SendableExample: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = User(id: 1, name: "Alan")
        
        Task.detached {
            print(user.name)
        }
    }
}

/*
 🟢 Что такое Sendable

    ◉ Sendable — это протокол,
      который гарантирует безопасную передачу данных
      между потоками (конкурентными контекстами).

    ◉ Используется в Swift Concurrency.

────────────────────────────────────────────

 🔥 Зачем он нужен

    Когда данные передаются:
        ◉ между Task
        ◉ между actor
        ◉ через Task.detached

    Swift должен быть уверен,
    что не возникнет Data Race.

────────────────────────────────────────────

 🧠 Что делает Sendable

    ◉ Гарантирует,
      что тип потокобезопасен.

    Обычно безопасны:
        ◉ struct с immutable свойствами (let)
        ◉ enum
        ◉ value types

────────────────────────────────────────────

 🔴 Что НЕ безопасно

    class с mutable свойствами:

        class User {
            var name: String
        }

    Такой тип может вызвать Data Race,
    если используется между потоками.

────────────────────────────────────────────

 🟡 Почему Task.detached требует Sendable

    Task.detached:
        ◉ Не наследует actor-контекст
        ◉ Работает полностью независимо
        ◉ Поэтому требует Sendable данные

────────────────────────────────────────────

 🟢 Автоматическое соответствие

    struct с let-свойствами
    автоматически считается Sendable.

    Но class — нет.

────────────────────────────────────────────

 🛡 Связь с Actor

    actor:
        ◉ Защищает mutable состояние

    Sendable:
        ◉ Гарантирует безопасную передачу данных

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ Sendable = безопасность передачи данных
    ◉ Нужен для concurrent кода
    ◉ Value types обычно безопасны
    ◉ Class с mutable состоянием — риск Data Race
 */
