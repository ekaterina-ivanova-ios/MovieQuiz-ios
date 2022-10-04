//
//  AlertModel.swift
//  MovieQuiz
//
//  Created by Екатерина Иванова on 04.10.2022.
//

import Foundation

struct AlertModel {
    var title: String
    var message: String
    var buttonText: String
    var completion: () -> Void
}
