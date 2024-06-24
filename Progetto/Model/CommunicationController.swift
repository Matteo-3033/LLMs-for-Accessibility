//
//  CommunicationController.swift
//  Progetto
//
//  Created by Matteo Manzoni on 14/06/24.
//

import Foundation

struct CommunicationController {
    private static let API_KEY = "sk-proj-pnOaxK5PclXhjPrOGqTRT3BlbkFJPGhGv4jHrFVccEsfoQAe"
    private static let SERVER_URL = "https://api.openai.com"
        // "https://develop.ewlab.di.unimi.it/descripix"
    
    private enum Endpoint: String {
        case predict = "/v1/chat/completions"   // "predict"
    }
    
    private enum RequestError: Error {
        case bodyEncodingError
    }
    
    private enum ResponseError: Error {
        case bodyDecodingError
        case statusError
    }
    
    private enum HttpMethod: String {
        case post = "POST"
        case delete = "DELETE"
        case get = "GET"
        case put = "PUT"
    }
    
    public func getDescription(text: String, imageBase64: String, onResult: @escaping (String?, Any?) -> Void) {
        print("getDescription")
        
        var request = URLRequest(url: getURL(endpoint: .predict))
        request.httpMethod = HttpMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            "Bearer \(CommunicationController.API_KEY)",
            forHTTPHeaderField: "Authorization"
        )
        
        let json: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": text
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": imageBase64
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        URLSession.shared.dataTask(with: request) { body, response, error in
            guard let body, error == nil else {
                onResult(nil, error)
                return
            }

            do {
                if let jsonResponse = try JSONSerialization.jsonObject(
                    with: body, options: []
                ) as? [String: Any] {
                    if let choices = jsonResponse["choices"] as? [[String: Any]], let choice = choices.first {
                        if let message = choice["message"] as? [String: Any] {
                            if let text = message["content"] as? String {
                                onResult(text, nil)
                            }
                        }
                    }
                } else {
                    onResult(nil, ResponseError.bodyDecodingError)
                }
            } catch let error {
                onResult(nil, error)
            }
        }.resume()
    }
    
    private func getURL(endpoint: Endpoint) -> URL {
        return URL(string: CommunicationController.SERVER_URL + "/" + endpoint.rawValue)!
    }
}
