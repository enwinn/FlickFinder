//
//  ViewController.swift
//  flickfinder
//
//  Created by Eric Winn on 6/1/15.
//  Copyright (c) 2015 Eric N. Winn. All rights reserved.
//
// Flickr API: https://www.flickr.com/services/api/flickr.photos.search.html
// Example: https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=1b5af1cfc4eafebacd4603b96d0c9e40&text=Rainbow+Vomit&extras=url_m&format=json&nojsoncallback=1

import UIKit
import Foundation

// ATTRIB: - https://github.com/udacity/ios-networking/tree/step-2.9-testing-flick-finder/FlickFinder
extension String {
    func toDouble() -> Double? {
        return NSNumberFormatter().numberFromString(self)?.doubleValue
    }
}

// MARK: - constants
let BASE_URL = "https://api.flickr.com/services/rest/?"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "1b5af1cfc4eafebacd4603b96d0c9e40"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"


class ViewController: UIViewController, UITextFieldDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var searchPhraseTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var feedbackLabel: UILabel!
    
    // MARK: - Setup
    var tapRecognizer: UITapGestureRecognizer? = nil
    
    let flickFinderTextAttributes = [
        NSForegroundColorAttributeName : UIColor.blueColor(),
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchPhraseTextField.tag = 0
        searchPhraseTextField.delegate = self
        
        latitudeTextField.tag = 1
        latitudeTextField.delegate = self
        
        longitudeTextField.tag = 2
        longitudeTextField.delegate = self
    }

    // MARK: - Keyboard notification and text defaults
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        feedbackLabel.hidden = true
        
        setTextFieldDefaults(searchPhraseTextField, tag: 0, placeholder: "Enter Search Phrase", textAttributes: flickFinderTextAttributes)
        setTextFieldDefaults(latitudeTextField, tag: 1, placeholder: "Enter Latitude", textAttributes: flickFinderTextAttributes)
        setTextFieldDefaults(longitudeTextField, tag: 1, placeholder: "Enter Longitude", textAttributes: flickFinderTextAttributes)

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // ref: - http://stackoverflow.com/questions/25874975/cant-get-correct-value-of-keyboard-height-in-ios
    func keyboardWillShow(notification: NSNotification) {
        self.view.frame.origin.y = -getKeyboardHeight(notification)
        addKeyboardDismissRecognizer()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        // Just return origin to it's default since this should not be changing for this app
        self.view.frame.origin.y = 0.0
        removeKeyboardDismissRecognizer()
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.CGRectValue().height
    }

    // MARK: - textField functions
    func setTextFieldDefaults(textField: UITextField, tag: Int, placeholder: String, textAttributes: [NSObject: AnyObject]) -> Bool {
        textField.tag = tag
        textField.defaultTextAttributes = textAttributes
        textField.textColor = UIColor.blueColor()
        textField.clearButtonMode = .WhileEditing
        textField.placeholder = placeholder
        textField.minimumFontSize = 15.0
        textField.adjustsFontSizeToFitWidth = true
        return true
    }

    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField.text.isEmpty && textField.placeholder != nil {
            textField.placeholder = ""
        }
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text.isEmpty && textField.tag == 0 {
            textField.placeholder = "Enter Search Phrase"
        } else if textField.text.isEmpty && textField.tag == 1 {
            textField.placeholder = "Enter Latitude"
        } else if textField.text.isEmpty && textField.tag == 2 {
            textField.placeholder = "Enter Longitude"
        }
        textField.resignFirstResponder()
        return true
    }

    // MARK: - Actions
    @IBAction func searchByPhraseButton(sender: UIButton) {
        self.dismissAnyVisibleKeyboards()
        feedbackLabel.hidden = false
        if searchPhraseTextField.text.isEmpty {
            feedbackLabel.textColor = UIColor.redColor()
            feedbackLabel.text = "Search Phrase Cannot Be Empty! Try Again."
        } else {
            feedbackLabel.textColor = UIColor.greenColor()
            feedbackLabel.text = "Searching..."
            getImageFromFlickr(0, searchPhrase: searchPhraseTextField.text, latitude: "", longitude: "")
        }
    }
    
    @IBAction func searchByLatLongButton(sender: UIButton) {
        self.dismissAnyVisibleKeyboards()
        feedbackLabel.hidden = false
        if latitudeTextField.text.isEmpty || longitudeTextField.text.isEmpty {
            feedbackLabel.textColor = UIColor.redColor()
            feedbackLabel.text = "Lat/Lon Cannot Be Empty! Try Again."
        } else if !validLatitude() || !validLongitude() {
            feedbackLabel.textColor = UIColor.redColor()
            feedbackLabel.text = "Lat must be in [-90, 90] and Lon must be in [-180, 180]"
        } else {
            feedbackLabel.textColor = UIColor.greenColor()
            feedbackLabel.text = "Searching..."
            getImageFromFlickr(1, searchPhrase: "", latitude: latitudeTextField.text, longitude: longitudeTextField.text)
        }
    }
    
    func getImageFromFlickr(searchType: Int, searchPhrase: String, latitude: String, longitude: String) {
        var methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        var pageCount = 0
        
        switch searchType {
        case 0:
            if !searchPhrase.isEmpty {
                methodArguments["text"] = searchPhrase
                println("Search Type: Phrase")
            }
        case 1:
            if !(latitude.isEmpty || longitude.isEmpty) {
                methodArguments["lat"] = latitude
                methodArguments["lon"] = longitude
                println("Search Type: Lat-Lon")
            }
        default:
            feedbackLabel.textColor = UIColor.redColor()
            feedbackLabel.text = "Something broke. Call AAA!"
        }

        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + encodeParameters(params: methodArguments)
        let url = NSURL(string: urlString)!
        println("url: \(url)")
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            if let error = downloadError {
                self.feedbackLabel.textColor = UIColor.redColor()
                self.feedbackLabel.text = "Could not complete the request \(error)"
                println("Could not complete the request \(error)")
            } else {
                // Success! Parse the data
                var parsingError: NSError? = nil
                let parsedResult: AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments, error: &parsingError)
                
                if let photosDictionary = parsedResult.valueForKey("photos") as? NSDictionary {
                    if let totalPages = photosDictionary["pages"] as? Int {
                        pageCount = totalPages
                        println("totalPages: \(totalPages)")
                        // Flickr API limits result size to a max of 4000
                        // If per_page is not defined it defaults to 100 with a max allowed of 500
                        // If page is not set it defaults to Page 1
                        let pageLimit = min(totalPages, 40)
                        println("pageLimit: \(pageLimit)")
                        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                        println("randomPage: \(randomPage)")
//                        self.getImageFromFlickrBySearchWithPage(methodArguments, pageNumber: randomPage)
                    }
                    
                    if let photoArray = photosDictionary.valueForKey("photo") as? [[String: AnyObject]] {
                        if pageCount > 0 {
                            
                            // Grab a single, random image
                            let randomPhotoIndex = Int(arc4random_uniform(UInt32(photoArray.count)))
                            let photoDictionary = photoArray[randomPhotoIndex] as [String: AnyObject]
                            
                            // Get the image url and title
                            let photoTitle = photoDictionary["title"] as? String
                            if let imageUrlString = photoDictionary["url_m"] as? String {
                                let imageURL = NSURL(string: imageUrlString)
                                
                                // If an image exists at the url, set the image and title
                                if let imageData = NSData(contentsOfURL: imageURL!) {
                                    dispatch_async(dispatch_get_main_queue(), {
                                        self.imageView.image = UIImage(data: imageData)
                                        self.feedbackLabel.textColor = UIColor.blueColor()
                                        self.feedbackLabel.text = "\(photoTitle!)"
                                    })
                                } else {
                                    self.setLabelTraits(labelText: nil, debugText: "Image does not exist. imageURL", r: 1.0, g: 0.0, b: 0.0, a: 1, objName: "imageURL", obj: imageURL!)
                                }

                            } else {
                                self.setLabelTraits(labelText: nil, debugText: "No image URL string found!", r: 1.0, g: 0.0, b: 0.0, a: 1, objName: nil, obj: photoTitle!)
                            }
                        } else {
                            self.setLabelTraits(labelText: nil, debugText: "Got an empty page set! pageCount", r: 1.0, g: 0.0, b: 0.0, a: 1, objName: "pageCount", obj: pageCount)
                        }
                    } else {
                        self.setLabelTraits(labelText: nil, debugText: "Cant find key 'photo'. photosDictionary", r: 1.0, g: 0.0, b: 0.0, a: 1, objName: "photosDictionary", obj: photosDictionary)
                    }
                } else {
                    // Jarrod Parkes uses dispatch_async but it seemed to work without it. Hmmm?
                    self.setLabelTraits(labelText: nil, debugText: "Can't find key 'photos' in paresedResult -", r: 1.0, g: 0.0, b: 0.0, a: 1,objName: "parsedResult" ,obj: parsedResult)
                }
            }
        }
        
        // Resume (execute) the task
        task.resume()

    }
    
    // TODO: - Create a function to update the label wrapped by dispatch_async()
    func setLabelTraits(labelText: String?=nil, debugText: String, r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat, objName: String?=nil, obj: AnyObject?=nil) {
        dispatch_async(dispatch_get_main_queue(), {
            self.feedbackLabel.textColor = UIColor(red: r, green: g, blue: b, alpha: a)
            if let unwrappedLabelText = labelText {
                self.feedbackLabel.text = labelText
            } else {
                self.feedbackLabel.text = "No photo found! Try again."
            }
            
            if obj == nil {
                println(debugText)
            } else {
                println("\(debugText) \(objName): \(obj)")
            }
        })
    }
    
    // ATTRIB: - http://stackoverflow.com/a/27151324
    func encodeParameters(#params: [String: String]) -> String {
        var queryItems = map(params) { NSURLQueryItem(name:$0, value:$1)}
        var components = NSURLComponents()
        components.queryItems = queryItems
        return components.percentEncodedQuery ?? ""
    }
    
    // MARK: - Tap recognizer functions
    func addKeyboardDismissRecognizer() {
        println("Add the recognizer to dismiss the keyboard")
        if tapRecognizer == nil {
            tapRecognizer = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
            tapRecognizer!.numberOfTapsRequired = 1
            self.view.addGestureRecognizer(tapRecognizer!)
        }
    }
    
    func removeKeyboardDismissRecognizer() {
        println("Remove the recognizer to dismiss the keyboard")
        if tapRecognizer != nil {
            self.view.removeGestureRecognizer(tapRecognizer!)
            tapRecognizer = nil
        }
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        println("Tapped to dismiss keyboard")
        view.endEditing(true)
    }
    
    func validLatitude() -> Bool {
        // Valid range for latitude is -90...90
        println("Checking for legal latitude values")
        if let latitude: Double? = self.latitudeTextField.text.toDouble() {
            switch latitude! {
            case -90.0...90.0:
                return true
                default:
                return false
            }
        } else {
            return false
        }
    }
    
    func validLongitude() -> Bool {
        // Valid range for longitude is -180...180
        println("Checking for legal longitude values")
        if let longitude: Double? = self.longitudeTextField.text.toDouble() {
            switch longitude! {
            case -180.0...180.0:
                return true
            default:
                return false
            }
        } else {
            return false
        }
    }
}

// ATTRIB: - https://github.com/udacity/ios-networking/tree/step-2.8-making-random/FlickFinder
extension ViewController {
    func dismissAnyVisibleKeyboards() {
        if searchPhraseTextField.isFirstResponder() || latitudeTextField.isFirstResponder() || longitudeTextField.isFirstResponder() {
            self.view.endEditing(true)
        }
    }
}
