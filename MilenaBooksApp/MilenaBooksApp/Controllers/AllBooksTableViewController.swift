//
//  AllBooksTableViewController.swift
//  MilenaBooksApp
//
//  Created by Plamen on 23.11.18.
//  Copyright © 2018 Plamen. All rights reserved.
//

import UIKit
import Alamofire
import AlamofireObjectMapper

class AllBooksTableViewController: UITableViewController {
    private var allBooks = [Book]()
    private var booksFetched = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        getData()
    }

    private func getData() {
        Alamofire.request(ApiEndPoints.BookEndPoint.getAll.fullUrl)
            .validate(statusCode: 200..<300)
            .validate(contentType: ["application/json"])
            .responseArray { (response: DataResponse<[Book]>) in
                let booksArray = response.result.value
                
                if let booksArray = booksArray {
                    self.allBooks = booksArray
                }
                
                self.booksFetched = true;
                self.tableView.reloadData()
            }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BookSelectSegue", let indexPath = self.tableView.indexPathForSelectedRow {
            let selectedBook = allBooks[indexPath.row]
            if let destination = segue.destination as? BookDetailsViewController {
                destination.book = selectedBook
            }
        }
    }
}

extension AllBooksTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return booksFetched ? allBooks.count : 20
        //return BookMockData.books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell
        if booksFetched {
            
            cell = tableView.dequeueReusableCell(withIdentifier: "BookTableCell", for: indexPath)
            
            if let bookCell = cell as? BookTableViewCell {
                bookCell.bookTitleLabel.text = allBooks[indexPath.row].title ?? "No title."
                bookCell.bookAuthorLabel.text = allBooks[indexPath.row].author ?? "No author."
                
                if let img = allBooks[indexPath.row].coverImage {
                    bookCell.bookCoverImageView.image = UIImage(data: img)
                } else {
                    if let url = self.allBooks[indexPath.row].coverImageUrl {
                        bookCell.bookCoverImageView.downloadImageFromUrl(urlString: url) { data in
                            self.allBooks[indexPath.row].coverImage = data
                        }
                        
                    }
                }
            }
        } else {
            cell = tableView.dequeueReusableCell(withIdentifier: "LoadingBookCell", for: indexPath)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if booksFetched || allBooks.count > 0 {
            let cell = tableView.cellForRow(at: indexPath)
            performSegue(withIdentifier: "BookSelectSegue", sender: cell)
        }
    }
}
