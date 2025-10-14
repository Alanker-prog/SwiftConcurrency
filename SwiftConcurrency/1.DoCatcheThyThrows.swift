//
//  1.DoCatcheThyThrows.swift
//  SwiftConcurrency
//
//  Created by Алан Парастаев on 14.10.2025.
//

import SwiftUI
import Combine


/*
 ✅ -> Result<String, Error> - Возврат через Result успех или ошибка
 
 ✅ throws -> String - Обозначает, что функция может выбросить ошибку
    ➡️ throws говорит компилятору и вызывающему коду, что внутри функции може произойти ошибка, и её нужно будет обработать с помощью try, try? или try!.
 
 ⚠️ Функции с throws обрабатывается через оператор -> do { (нужно написать docatch и нажать энтер и раскроется конструкция try и catch)
 
 ❌ В блоке do { может быть несколько операторов try. И если хоть в одном try случится ошибка остальные try не смогут отработать, но мы можем сделать параметр try?(не обязательным) и если в этом try? будет ошибка он просто вернет nil. В этом случае даже если в опциональном try? будет ошибка, остальные try смогут отработать штатно
 
 ✅ try - Используется для вызова такой функции( блок try пытается получить значение, если его нет функция преходит в блок catch)
 
 ✅ catch - Обрабатывает ошибку, если она произошла( блок catch обробатывает и отображает ошибку, если значения не было полученно)
 */
class DoCatcheThyThrowsDataManager {
    
    let isActive: Bool = true
    
    func getTitle() -> (title:String?, error: Error?) {
        if isActive {
            return ("New Text!", nil)
        } else {
            return (nil, URLError(.badServerResponse))
        }
    }
    
    func getTitleTwo() -> Result<String, Error> {
        if isActive {
            return .success("New Text!")
        } else {
            return .failure(URLError(.badServerResponse))
        }
    }
    
    func getTitleThree() throws -> String {
//        if isActive {
//            return "New Text!"
//        } else {
            throw URLError(.badServerResponse)
        }
  //  }
    
    func getTitleThreeFour() throws -> String {
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
        /*let returnedValue = manager.getTitle()
        if let newTitle = returnedValue.title {
            self.text = newTitle
        } else if let error = returnedValue.error {
            self.text = error.localizedDescription
        }*/
        /*let result = manager.getTitleTwo()
        
        switch result {
        case .success(let success):
            self.text = success
        case .failure(let error):
            self.text = error.localizedDescription
        }*/
        
        do {
         let newTitle = try? manager.getTitleThree()
            if let newTitle = newTitle {
                self.text = newTitle
            }
            
            let finalTitle = try manager.getTitleThreeFour()
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
