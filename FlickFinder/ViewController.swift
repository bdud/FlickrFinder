//
//  ViewController.swift
//  FlickFinder
//
//  Created by Bill Dawson on 9/18/15.
//  Copyright © 2015 Bill Dawson. All rights reserved.
//

import UIKit

let API_ENDPOINT = NSURL(string: "https://api.flickr.com/services/rest")!
let API_KEY = "6d8d83bb9efc878a046ecf37682018de"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let SEARCH_METHOD = "flickr.photos.search"


class ViewController: UIViewController {
    let baseQueryComponents = [
        "api_key": API_KEY,
        "method": SEARCH_METHOD,
        "extras": EXTRAS,
        "nojsoncallback": NO_JSON_CALLBACK,
        "format": DATA_FORMAT
    ]


    // MARK: Outlets

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var defaultLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!

    // MARK: Overrides

    // MARK: Actions

    @IBAction func searchByPhraseTouch(sender: AnyObject) {

        guard let url = buildSearchByPhraseUrl(phraseTextField.text) else {
            print("Problem creating url")
            return
        }

        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithURL(url) { (data, response, error) in

            guard let photosArray = self.getPhotosArrayFromTaskResult(data, response: response, error: error) else {
                print("Did not get photos from result")
                return
            }

            self.presentRandomPhoto(photosArray)
        }

        task.resume()

    }


    @IBAction func searchByLocationTouch(sender: AnyObject) {
        guard let url = buildSearchByLocationUrl(latitudeTextField.text, lon: longitudeTextField.text) else {
            print("Problem creating url")
            return
        }

        let session = NSURLSession.sharedSession()

        let task = session.dataTaskWithURL(url) { (data, response, error) in

            guard let photosArray = self.getPhotosArrayFromTaskResult(data, response: response, error: error) else {
                print("Did not get photos from result")
                return
            }

            self.presentRandomPhoto(photosArray)
        }
        
        task.resume()

    }

    // MARK: Private Methods

    private func presentRandomPhoto(photosArray: [[String: AnyObject]]) {
        let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
        let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
        let photoTitle = photoDictionary["title"] as? String /* non-fatal */

        guard let photoUrl = photoDictionary["url_m"] as? String else {
            print("Could not find 'url_m' data for photo")
            return
        }

        if let imageData = NSData(contentsOfURL: NSURL(string: photoUrl)!) {
            dispatch_async(dispatch_get_main_queue(), {
                self.photoImageView.image = UIImage(data: imageData)
                self.photoTitleLabel.text = photoTitle ?? "(Untitled)"
            })
        }

    }

    private func getPhotosArrayFromTaskResult(data: NSData?, response: NSURLResponse?, error: NSError?) -> [[String: AnyObject]]? {
        guard (error == nil) else {
            print("There was an error")
            return nil
        }

        guard let data = data else {
            print("No data returned")
            return nil
        }

        let parsedResult: AnyObject!
        do {
            try parsedResult = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        }
        catch {
            print("Could not parse data as JSON: \(data)")
            return nil
        }

        guard let status = parsedResult["stat"] as? String where status == "ok" else {
            print("Flickr returned an error in data: \(parsedResult)")
            return nil
        }

        guard let resultDictionary = parsedResult["photos"] as? NSDictionary,
            photosArray = resultDictionary["photo"] as? [[String: AnyObject]] else {
                print("Could not get photos array from parsed result: \(parsedResult)")
                return nil
        }

        return photosArray

    }

    private func buildSearchByPhraseUrl(phrase: String?) -> NSURL? {
        guard let phrase = phrase else {
            print("Empty/nil phrase")
            return nil
        }

        guard let urlc = createUrlComponents() else {
            print("Problem creating URL components")
            return nil;
        }

        var queryComponents = baseQueryComponents
        queryComponents["text"] = phrase;

        urlc.queryItems = buildQueryItems(queryComponents)

        return urlc.URL
    }

    private func buildSearchByLocationUrl(lat: String?, lon: String?) -> NSURL? {
        guard let lat = lat else {
            print("Empty/nil latitude")
            return nil
        }

        guard let lon = lon else {
            print("Empty/nil longitude")
            return nil
        }

        guard let urlc = createUrlComponents() else {
            print("Problem creating URL components")
            return nil;
        }

        var queryComponents = baseQueryComponents
        queryComponents["lat"] = lat;
        queryComponents["lon"] = lon;

        urlc.queryItems = buildQueryItems(queryComponents)

        return urlc.URL
    }

    private func buildQueryItems(components: [String: String]) -> [NSURLQueryItem] {
        let keys = Array(components.keys)
        return keys.map { (key) -> NSURLQueryItem in
            let value: String = components[key]!
            return NSURLQueryItem(name: key, value: value)
        }
    }

    private func createUrlComponents() -> NSURLComponents? {
        return NSURLComponents(URL: API_ENDPOINT, resolvingAgainstBaseURL: false)
    }
}

