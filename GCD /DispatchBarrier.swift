//
//  ThreadSafeArray.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import Foundation

final class ThreadSafeArray<Element> {
    
    private var storage: [Element] = []
    
    private let queue = DispatchQueue(
        label: "com.example.threadSafeArray",
        attributes: .concurrent
    )
    
    // MARK: - Read
    
    var values: [Element] {
        queue.sync {
            storage
        }
    }
    
    // MARK: - Write
    
    func append(_ element: Element) {
        queue.async(flags: .barrier) {
            self.storage.append(element)
        }
    }
    
    func removeAll() {
        queue.async(flags: .barrier) {
            self.storage.removeAll()
        }
    }
}
 
/*
 🟢 Архитектура thread-safe контейнера

    ◉ private storage — скрыто от внешнего доступа
    ◉ private concurrent очередь
    ◉ Чтение через sync
    ◉ Запись через async + barrier

────────────────────────────────────────────

 🟢 Почему чтение через sync

    queue.sync {
        storage
    }

    ◉ Получаем актуальное состояние немедленно
    ◉ Можно выполнять несколько чтений параллельно
    ◉ Не блокирует другие чтения

────────────────────────────────────────────

 🟢 Почему запись через async(flags: .barrier)

    ◉ barrier гарантирует эксклюзивный доступ
    ◉ Пока идёт запись — другие задачи не выполняются
    ◉ После завершения очередь продолжает обычную работу

    Это паттерн:
    multiple readers / single writer

────────────────────────────────────────────

 ❗ Важно

    ◉ Все обращения к storage должны идти только через queue
    ◉ Если обратиться к storage напрямую → race condition
    ◉ barrier работает только с кастомной concurrent очередью

────────────────────────────────────────────

 ⚠️ Почему запись async, а не sync

    ◉ async не блокирует вызывающий поток
    ◉ sync может привести к deadlock
    ◉ В большинстве случаев запись не требует немедленного результата

────────────────────────────────────────────

 🟡 Пример из жизни

    Представь:
    ◉ У нас есть кэш изображений
    ◉ Много потоков читают кэш
    ◉ Иногда добавляется новое изображение

    Решение:
    ◉ Чтение — параллельно
    ◉ Запись — строго по одной
    ◉ Производительность выше, чем при использовании serial очереди

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ concurrent очередь + barrier = безопасная запись
    ◉ sync для чтения
    ◉ async + barrier для записи
    ◉ Это классическая GCD-архитектура thread-safe контейнера
 */
