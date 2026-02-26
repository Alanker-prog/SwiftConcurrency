//
//  ConcurrentPerform.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 26.02.2026.
//

import UIKit

class ConcurrentPerform: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue.global(qos: .utility)
        queue.async {
            DispatchQueue.concurrentPerform(iterations: 1000) { index in
                print(index)
                print(Thread.current)
            }
        }
        
    }
}

/*
 🟢 let queue = DispatchQueue.global(qos: .utility)
    queue.async
    ◉ создаём async глобальную очередь, чтобы перевести работу в фоновый поток
    ◉ main thread остаётся свободным (UI не блокируется)

 Внутри вызывается
 🟢 DispatchQueue.concurrentPerform(iterations: 1000)
    ◉ Блок выполняется 1000 раз параллельно
    ◉ Итерации распределяются по нескольким потокам
    ◉ Порядок выполнения НЕ гарантирован

 🔸 Для чего используется concurrentPerform
    ◉ Обработка больших массивов
    ◉ Параллельные вычисления
    ◉ CPU-интенсивные задачи
    ◉ Разделение одной задачи на части

 ❌ Не использовать на Main Thread
    ◉ Метод синхронный (sync)
    ◉ Блокирует текущий поток до завершения всех итераций
    ◉ При вызове на main → заморозит UI

 ⚠️ Важно
    ◉ Требует потокобезопасной работы с данными (возможны race condition)

 🧠 Главное, что нужно запомнить
    ◉ concurrentPerform = параллельный цикл
    ◉ Синхронный метод
    ◉ Блокирует текущий поток
    ◉ Не блокирует UI, если вызван не с main
    ◉ Работает на уровне потоков (GCD)

 🟡 Связь concurrentPerform и Task / TaskGroup
    ◉ DispatchQueue.concurrentPerform — старый (GCD) способ параллельного выполнения
    ◉ Swift Concurrency (Task, TaskGroup) — современный async способ
    ◉ Task не блокирует поток и управляется системой
 */
