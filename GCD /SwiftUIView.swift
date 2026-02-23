//
//  SwiftUIView.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 18.02.2026.
//

import SwiftUI
import UIKit
 
class MyViewController: UIViewController {
    
    var button = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC 1"
        view.backgroundColor = UIColor.gray
        button.addTarget(self, action: #selector(pressAction), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        initButton()
        
    }
    
    @objc func pressAction() {
        let vc = MyViewControllerTwo()
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func initButton() {
        button.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        button.center = view.center
        button.setTitle("Press", for: .normal)
        button.backgroundColor = UIColor.red
        button.setTitleColor(UIColor.white, for: .normal)
        button.cornerConfiguration = .corners(radius: 10)
        view.addSubview(button)
    }
}
// 👇 Описание
/*
  ◉ Плохая практика! У contentsOf: Нет обработки ошибок, контроля статуса ответа, таймаута, кэширования, отмены запроса ❌ и САМОЕ ГЛАВНОЕ БЛОКИРУЕТ ПОТОК!
  ◉ Я создал этот пример так как мне нужно было потренить создать потоки в ручную
 */
// MARK: Загрузка данных через Data(contentsOf:) ❌ это sync(Синхронный метод)
/*class MyViewControllerTwo: UIViewController {
    
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC 2"
        view.backgroundColor = UIColor.white
        
        initImage()
        
        let imageURL = URL(string: "https://api.ai-cats.net/v1/cat")!
        
        DispatchQueue.global(qos: .utility).async {
            if let data = try? Data(contentsOf: imageURL),
               let image = UIImage(data: data) {
                
                DispatchQueue.main.async {
                    self.imageView.image = image
                }
            }
        }
    }
    
    func initImage() {
        imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        imageView.center = view.center
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }
} */


// MARK: Загрузка данных через URLSession ✅ это Async(Асинхронный метод)
class MyViewControllerTwo: UIViewController {
    
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "VC 2"
        view.backgroundColor = UIColor.white
        
        initImage()
        loadImage()
    }
    
    private func loadImage() {
        guard let url = URL(string: "https://api.ai-cats.net/v1/cat") else { return }
        /*
         🟢 URLSessionTask можно:
         ◉ Запускать (resume())
         ◉ Приостанавливать (suspend())
         ◉ Отменять (cancel())
         ◉ Это даёт контроль над жизненным циклом задачи.
         
         🟢 URLSession:
         ◉ Сам управляет потоками❕(🧠 Управление потоками — внутри системы.)
         ◉ Отправляет запрос автомат. в фоновом потоке,
         не нужно писать (DispatchQueue.global.async {) Глобальную очередь.)
         ◉ Получает ответ
         ◉ Выполняет completion handler в background thread
         ◉ И ты сам решаешь, когда перейти в main thread
         
         🟢 Когда создаешь задачу let task = URLSession.shared.dataTask(with: url)
          ◉ Она находится по умолчанию в состоянии .suspended(приостановлена).
          ◉ .resume() запускает задачу❕
         */
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard
                let self = self,
                error == nil,
                let httpResponse = response as? HTTPURLResponse,
                200..<300 ~= httpResponse.statusCode,
                let data = data,
                let image = UIImage(data: data)
            else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }
        .resume()
    }

    func initImage() {
        imageView.frame = CGRect(x: 0, y: 0, width: 300, height: 300)
        imageView.center = view.center
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
    }
}



let vc = MyViewController()
let navBar = UINavigationController(rootViewController: vc)


#Preview {
    UINavigationController(rootViewController: MyViewController())
}
