//
//  1.DoCatcheThyThrows.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 14.10.2025.
//

import SwiftUI
import Combine



class DoCatcheThyThrowsDataManager {
    
    // состояние для проверки через (if isActive { )
    let isActive: Bool = true
    
    func getTitle() -> (title:String?, error: Error?) {
        if isActive {
            return ("New Text!", nil)
        } else {
            return (nil, URLError(.badServerResponse))
        }
    }
    
    /*
     🟢 -> Result<String, Error>
         ◉ <String, Error>  это кортеж с стрингой и ошибкой
     */
    func getTitleTwo() -> Result<String, Error> {
        if isActive {
            return .success("New Text!")
        } else {
            return .failure(URLError(.badServerResponse))
        }
    }
    
    /*
     ✅ throws -> String
        ◉ throws говорит что эта функция может выбросить ошибку
        ◉ throws говорит компилятору и вызывающему коду, что внутри функции може произойти ошибка, и её нужно будет обработать через try, (try? или try!)
     */
    func getTitleThree() throws -> String {
       if isActive {
           return "New Text!"
        } else {
            throw URLError(.badServerResponse)
        }
    }
    
    func getTitleFour() throws -> String {
        if isActive {
            return "Final Text!"
        } else {
            throw URLError(.badServerResponse)
        }
    }
}

class DoCatcheThyThrowsViewModel: ObservableObject {
    
    @Published var text: String = "Starting text..."
    let manager = DoCatcheThyThrowsDataManager()
    
    func fetchTitle() {
        
        /*
    let result = manager.getTitleTwo()
        
    switch result {
    case .success(let success):
        self.text = success
    case .failure(let error):
        self.text = error.localizedDescription
        }
      */ // getTitleTwo()
        
        /*
         ◉ Функции с throws обрабатывается через оператор -> do {
         ◉ Нужно написать docatch и нажать энтер, раскроется конструкция try/catch
         
         
         ◉ try        вызывает функцию, которая может выбросить ошибку
         ◉ try?       возвращает nil при ошибке
         ◉ try!       вызывает crash при ошибке
         ◉ do-catch   позволяет обработать ошибку
         
         ⚠️ В блоке do { может быть несколько операций (try)
         ❌ И если хоть в одном try случится ошибка остальные вызовы(операции try)  не смогут отработать
         🟢 Но мы можем сделать параметр try?(не обязательным)
            ◉ При ошибки в try?,он просто вернет nil. В этом случае даже если в опциональном try? будет ошибка, остальные try смогут отработать штатно
         */
        do {
         let newTitle = try? manager.getTitleThree()
            if let newTitle = newTitle {
                self.text = newTitle
            }
            
            let finalTitle = try manager.getTitleFour()
            self.text = finalTitle
        } catch {
            self.text = error.localizedDescription
        }
    }
}

struct DoCatcheThyThrowsBootcamp: View {
    
    @StateObject var vm = DoCatcheThyThrowsViewModel()
    
    var body: some View {
        Text(vm.text)
            .frame(width: 300, height: 300)
            .background(.blue)
            .onTapGesture {
                vm.fetchTitle()
            }
    }
}

#Preview {
    DoCatcheThyThrowsBootcamp()
}
