//
//  DispatchSourceTimerExample.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 27.02.2026.
//

import UIKit

class DispatchSourceTimerExample: UIViewController {
    
    private var timer: DispatchSourceTimer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let queue = DispatchQueue.global(qos: .utility)
        
        timer = DispatchSource.makeTimerSource(queue: queue)
        
        timer?.schedule(deadline: .now(), repeating: 2)
        
        timer?.setEventHandler {
            print("Timer fired")
            print(Thread.current)
        }
        
        timer?.resume()
    }
    
    deinit {
        timer?.cancel()
    }
}

/*
 🟢 DispatchSource

    ◉ Это механизм отслеживания системных событий
    ◉ Работает через GCD
    ◉ Timer — лишь один из типов

────────────────────────────────────────────

 🟢 DispatchSourceTimer

    ◉ Низкоуровневый GCD-таймер
    ◉ Работает через DispatchQueue
    ◉ Более гибкий, чем обычный Timer

────────────────────────────────────────────

 🟢 Популярные типы DispatchSource

    ◉ DispatchSourceTimer
        Таймеры

    ◉ DispatchSourceRead / DispatchSourceWrite
        Работа с сокетами и потоками данных

    ◉ DispatchSourceFileSystemObject
        Отслеживание изменений файлов

    ◉ DispatchSourceSignal
        Обработка Unix сигналов

────────────────────────────────────────────

 🟡 Про сокеты и мессенджеры

    ◉ Популярные мессенджеры работают через сокеты
    ◉ Постоянное соединение с сервером
    ◉ Сервер может отправить данные в любой момент

    DispatchSourceRead:
        ◉ Отслеживает, когда в сокете появились данные
        ◉ Реагирует немедленно
        ◉ Работает эффективно без постоянного polling

    Это системный уровень работы с сетью.

────────────────────────────────────────────

 🟢 schedule(deadline:repeating:)

    ◉ deadline — когда стартовать
    ◉ repeating — интервал
    ◉ Можно указать leeway для оптимизации энергии

────────────────────────────────────────────

 🟢 resume()

    ◉ ОБЯЗАТЕЛЬНО вызвать
    ◉ DispatchSource создаётся в suspended состоянии

────────────────────────────────────────────

 ❗ Важно

    ◉ cancel() нужно вызывать перед уничтожением
    ◉ Нельзя вызвать resume() дважды → crash
    ◉ Это низкоуровневый API

────────────────────────────────────────────

 🔸 Отличие от Timer

    Timer:
    ◉ Работает через RunLoop
    ◉ Обычно main thread

    DispatchSource:
    ◉ Работает через GCD
    ◉ Может отслеживать таймеры, сокеты, файлы, сигналы
    ◉ Используется в более системных задачах

────────────────────────────────────────────

 🧠 Главное, что нужно запомнить

    ◉ DispatchSource — механизм событий
    ◉ Timer — лишь один из его типов
    ◉ Используется для таймеров, сокетов, файлов
    ◉ Это более низкоуровневый инструмент GCD
 
🔥 Пример использования в мессенджерах, постоянные соединения (WebSocket / TCP) работают через сокеты.
   На низком уровне такие вещи действительно могут использовать DispatchSourceRead.

   🔸 Но в iOS-приложениях обычно используют:
    ◉ URLSession
    ◉ Network framework
    ◉ WebSocket API
    ◉ Starscream и другие библиотеки

 А внутри них уже может использоваться DispatchSource.
 */
