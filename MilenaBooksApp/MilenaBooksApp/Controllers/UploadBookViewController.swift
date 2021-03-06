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
import SwiftValidator
import MobileCoreServices

class UploadBookViewController: UIViewController, ValidationDelegate, UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet var uploadBookView: UploadBookView!
    var book: Book?
    private var isAnEdit = false
    private let validator = Validator()
    private let webClient = WebClient()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        registerRules()
        
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
            uploadBookView.authorTextField.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            uploadBookView.titleTextField.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            uploadBookView.priceTextField.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            uploadBookView.ratingTextField.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            uploadBookView.coverImageUrlTextField.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            uploadBookView.descriptionTextView.layer.borderColor = #colorLiteral(red: 0.7540688515, green: 0.7540867925, blue: 0.7540771365, alpha: 1)
            
            btn.showLoading()
            validator.validate(self)
        } else {
            print("currently uploading...")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditUploadToDetailsSegue" {
            if let destination = segue.destination as? BookDetailsViewController {
                destination.book = self.book
            }
        }
    }
}

extension UploadBookViewController {
    @IBAction func selectImageButtonClicked(_ sender: ActivityButtonView) {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary;
            imagePicker.allowsEditing = false
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        var image: UIImage?
        if let editedImage = info[.editedImage] as? UIImage {
            image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            image = originalImage
        }
        uploadBookView.displayCoverImageView.showLoading()
        picker.dismiss(animated: true, completion: nil)
        
        uploadCoverImage(image: image!, to: ApiEndPoints.Books.postBookCover.fullUrl)
    }
}

// Validation of input for book stuff
extension UploadBookViewController {
    private func registerRules(){
        // Title validation
        validator.registerField(uploadBookView.titleTextField, rules: [
            RequiredRule(),
            MinLengthRule(length: 1),
            BookValidationRules.EmptySpacesRule()
            ])
        
        // Author validation
        validator.registerField(uploadBookView.authorTextField, rules: [
            RequiredRule(),
            MinLengthRule(length: 1),
            BookValidationRules.EmptySpacesRule()
            ])
        
        // Price validation
        validator.registerField(uploadBookView.priceTextField, rules: [
            RequiredRule(), MinLengthRule(length: 1),
            FloatRule(),
            BookValidationRules.EmptySpacesRule()
            ])
        
        // Rating validation
        validator.registerField(uploadBookView.ratingTextField, rules: [
            RequiredRule(),
            MinLengthRule(length: 1),
            BookValidationRules.EmptySpacesRule(),
            BookValidationRules.NumberRule()
            ])
    }
    
    func validationSuccessful() {
        let id = book?.id
        let title = uploadBookView.titleTextField.text!
        let author = uploadBookView.authorTextField.text!
        let price = Double(uploadBookView.priceTextField.text!)!
        let rating = Int(uploadBookView.ratingTextField.text!)!
        let url = uploadBookView.coverImageUrlTextField.text!.isEmpty ? "https://marketplace.canva.com/MAB___U-clw/1/0/thumbnail_large/canva-yellow-lemon-children-book-cover-MAB___U-clw.jpg" : uploadBookView.coverImageUrlTextField.text
        let desc = uploadBookView.descriptionTextView.text
        
        book = Book(id: id, title: title, price: price, author: author, rating: rating, coverImageUrl: url, description: desc)
        
        if isAnEdit {
            addOrUpdate(book!, to: ApiEndPoints.Books.edit(book: book!).fullUrl, with: .put)
        } else {
            addOrUpdate(book!, to: ApiEndPoints.Books.post.fullUrl, with: .post)
        }
    }
    
    func validationFailed(_ errors: [(Validatable, ValidationError)]) {
        if let btn = (uploadBookView.uploadButton as? ActivityButtonView), btn.isUploading {
            btn.hideLoading()
        }
        
        for (field, error) in errors {
            if let field = field as? UITextField {
                field.layer.borderColor = UIColor.red.cgColor
                field.layer.borderWidth = 1.0
            }
            //            error.errorLabel?.text = error.errorMessage // works if you added labels
            //            error.errorLabel?.isHidden = false
            print(error.errorMessage)
        }
    }
}

// Calls to APIs
extension UploadBookViewController {
    private func addOrUpdate(_ book: Book, to urlString: String, with method: HTTPMethod) {
        webClient.addOrUpdateBook(book, to: urlString, with: method) { book, error in
            
            (self.uploadBookView.uploadButton as? ActivityButtonView)?.hideLoading()
            
            if let book = book, self.isAnEdit, let navController = self.navigationController {
                let indexOfPrevBookDetailsVC = navController.viewControllers.endIndex - 2
                
                if let bookDetailsVC = navController.viewControllers[indexOfPrevBookDetailsVC] as? BookDetailsViewController {
                    bookDetailsVC.book = book
                    bookDetailsVC.isEditted = self.isAnEdit
                }
                
                let _ = navController.viewControllers.popLast()
            } else if let book = book {
                self.book = book
                self.performSegue(withIdentifier: "EditUploadToDetailsSegue", sender: self.uploadBookView.uploadButton)
                
                //remove self from navigation controller after segued to book details view
                let selfIndex = (self.navigationController!.viewControllers.endIndex - 2)
                self.navigationController?.viewControllers.remove(at: selfIndex)
            }
            
            if let error = error {
                print(error)
            }
        }
    }
    
    private func uploadCoverImage(image: UIImage, to url: String){
        webClient.uploadCoverImage(image, to: url) { result, error in
            if error == nil {
                self.uploadBookView.displayCoverImageView.removeBorder()
                self.uploadBookView.displayCoverImageView.image = image
                self.uploadBookView.coverImageUrlTextField.text = result!
                self.uploadBookView.coverImageUrlTextField.isEnabled = false
            } else {
                print(error!)
            }
            
            self.uploadBookView.displayCoverImageView.hideLoading()
        }
    }
}
