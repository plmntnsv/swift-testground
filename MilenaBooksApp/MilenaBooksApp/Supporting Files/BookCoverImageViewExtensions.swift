//
//  ImageViewExtensions.swift
//  MilenaBooksApp
//
//  Created by Plamen on 29.11.18.
//  Copyright © 2018 Plamen. All rights reserved.
//

import Foundation
import UIKit

extension BookCoverImageView {
    func downloadImageFromUrl(urlString: String, completion: @escaping (_ data: Data?) -> ()) {
        self.showLoading()
        
        DispatchQueue.global(qos: .background).async {
            if let url = URL(string: urlString), let urlContents = try? Data(contentsOf: url) {
                DispatchQueue.main.async {
                    completion(urlContents)
                    self.image = UIImage(data: urlContents)
                    self.hideLoading()
                    
                }
            } else {
                DispatchQueue.main.async {
                    completion(UIImage(named: "noimage")?.pngData())
                    self.image = UIImage(named: "noimage")
                    self.hideLoading()
                }
            }
        }
    }
}
