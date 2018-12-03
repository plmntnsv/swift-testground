//
//  UploadBookViewController.swift
//  MilenaBooksApp
//
//  Created by Plamen on 27.11.18.
//  Copyright © 2018 Plamen. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper

class UploadBookViewController: UIViewController {
    
    @IBOutlet var uploadBookView: UploadBookView!
    
    var book: Book?
    private var isAnEdit = false
    
    // TODO: use SwiftValidator lib
    private var validBook: Bool {
        get {
            if (uploadBookView.titleTextField.text?.isEmpty)! {
                (uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                return false
            }
            
            if (uploadBookView.authorTextField.text?.isEmpty)! {
                (uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                return false
            }
            
            if (uploadBookView.priceTextField.text?.isEmpty)! || Double((uploadBookView.priceTextField.text)!) == nil {
                (uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                return false
            }
            
            if (uploadBookView.ratingTextField.text?.isEmpty)! || Int((uploadBookView.ratingTextField.text)!) == nil {
                (uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                return false
            }
            
            return true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let bookToEdit = book {
            isAnEdit = true
            
            uploadBookView.uploadButton.setTitle("Save", for: .normal)
            uploadBookView.uploadButton.backgroundColor = #colorLiteral(red: 0.4620226622, green: 0.8382837176, blue: 1, alpha: 1)
            uploadBookView.titleTextField.text = bookToEdit.title ?? "No title"
            uploadBookView.authorTextField.text = bookToEdit.author ?? "No author"
            uploadBookView.priceTextField.text = String((bookToEdit.price ?? 0.0)!)
            uploadBookView.ratingTextField.text = String((bookToEdit.rating ?? 0)!)
            uploadBookView.coverImageUrlTextField.text = bookToEdit.coverImageUrl
            uploadBookView.descriptionTextView.text = bookToEdit.description
        }
    }
    
    @IBAction func uploadBookBtnClicked(_ sender: Any) {
        if let btn = sender as? ActivityButtonView, !btn.isUploading {
                btn.showLoading()
                
                if validBook {
                    let id = book?.id
                    let title = uploadBookView.titleTextField.text!
                    let author = uploadBookView.authorTextField.text!
                    let price = Double(uploadBookView.priceTextField.text!)!
                    let rating = Int(uploadBookView.ratingTextField.text!)!
                    let url = uploadBookView.coverImageUrlTextField.text
                    let desc = uploadBookView.descriptionTextView.text
                    
                    book = Book(id: id, title: title, price: price, author: author, rating: rating, coverImageUrl: url, description: desc)
                    
                    if isAnEdit {
                        addOrUpdate(book!, to: ApiEndPoints.BookEndPoint.edit(book: book!).fullUrl, with: .put)
                    } else {
                        addOrUpdate(book!, to: ApiEndPoints.BookEndPoint.post.fullUrl, with: .post)
                    }
                    
                } else {
                    addOrUpdate(BookMockData.book, to: ApiEndPoints.BookEndPoint.post.fullUrl, with: .post)
                    print("invalid book")
                }
            } else {
                print("currently uploading")
            }
        }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditUploadToDetailsSegue" {
            if let destination = segue.destination as? BookDetailsViewController {
                destination.book = self.book
                destination.shouldRemovePreviousVC = true
            }
        }
    }
}

extension UploadBookViewController {
    private func addOrUpdate(_ book: Book, to urlString: String, with method: HTTPMethod) {
        Alamofire.request(urlString,
                          method: method,
                          parameters: book.toJSON(),
                          encoding: JSONEncoding.default)
            .responseObject { (response: DataResponse<Book>) in
                switch response.result {
                case .success:
                    (self.uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                    self.book = response.result.value
                    
                    if self.isAnEdit, let navController = self.navigationController {
                        let indexOfPrevBookDetailsVC = navController.viewControllers.endIndex - 2
                        
                        if let bookDetailsVC = navController.viewControllers[indexOfPrevBookDetailsVC] as? BookDetailsViewController {
                            bookDetailsVC.book = self.book
                            bookDetailsVC.isEditted = self.isAnEdit
                        }
                        
                        let _ = navController.viewControllers.popLast()
                    } else {
                        self.performSegue(withIdentifier: "EditUploadToDetailsSegue", sender: self.uploadBookView.uploadButton)
                    }
                case .failure(let error):
                    (self.uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
                    print(error)
                }
        }
    }
}
