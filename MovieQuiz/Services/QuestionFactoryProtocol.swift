//
//  QuestionFactoryProtocol.swift
//  MovieQuiz
//
//  Created by Екатерина Иванова on 04.10.2022.
//

import Foundation

protocol QuestionFactoryProtocol {
    //without delegate
    //func requestNextQuestion() -> QuizQuestion?
    //with delegate
    func requestNextQuestion()
} 
