//
//  CommunicationController.swift
//  Progetto
//
//  Created by Matteo Manzoni on 14/06/24.
//

import Foundation

struct CommunicationController {
    private static let SERVER_URL = "https://develop.ewlab.di.unimi.it/descripix"
    
    private enum Endpoint: String {
        case predict = "predict"
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
        
        let json = [
            "text": text,
            "image": imageBase64
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
                ) as? [String: Any],
                   let generatedText = jsonResponse["generated_text"] as? String {
                    onResult(generatedText, nil)
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
