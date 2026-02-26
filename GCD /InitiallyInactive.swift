
//
//  InitiallyInactive.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 26.02.2026.
//

import UIKit

class InitiallyInactive: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue(
            label: "com.example.inactiveQueue",
            qos: .utility,
            attributes: [.concurrent, .initiallyInactive]
        )
        
        queue.async {
            print("Task 1")
        }
        
        queue.async {
            print("Task 2")
        }
        
        print("Before activate")
        
        queue.activate()
        
        print("After activate")
    }
}

/*
 🟢 DispatchQueue(... attributes: [.concurrent, .initiallyInactive])
    ◉ создаём очередь в неактивном состоянии
    ◉ задачи можно добавлять, но они НЕ выполняются сразу
    ◉ очередь “заморожена” до вызова activate()

 🟢 queue.async { }
    ◉ добавляем задачи в очередь
    ◉ они накапливаются, но не стартуют

 🟢 queue.activate()
    ◉ активирует очередь
    ◉ после вызова все добавленные задачи начинают выполняться
    ◉ activate() можно вызвать только один раз

 🔸 Для чего используется .initiallyInactive
    ◉ Отложенный старт группы задач
    ◉ Подготовка нескольких операций перед одновременным запуском
    ◉ Контроль момента начала выполнения
    ◉ Более управляемый запуск конкурентной работы

 ❗ Важно понимать
    ◉ Пока activate() не вызван — очередь полностью неактивна
    ◉ После активации работает как обычная очередь
    ◉ Можно использовать и с serial, и с concurrent очередями

 ❌ Частая ошибка
    ◉ Забыть вызвать activate() → задачи никогда не выполнятся

 🧠 Главное, что нужно запомнить
    ◉ .initiallyInactive = очередь создаётся в “спящем” состоянии
    ◉ Задачи можно добавлять заранее
    ◉ activate() запускает выполнение
    ◉ Даёт контроль над моментом старта работы
 */
