//
//  ViewController.swift
//  FlowerEncyclopedia-CoreML
//
//  Created by Dayton on 13/12/20.
//

import UIKit
import Vision
import CoreML
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    let picker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
           
            guard let ciImage = CIImage(image: pickedImage) else {
            fatalError("Can't convert to CIImage")
            }
            
            
            detect(image: ciImage)
            
            
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
  

    @IBAction func cameraBtnPressed(_ sender: UIBarButtonItem) {
        
        present(picker, animated: true, completion: nil)
    }
    
    func requestInfo(flowerName:String){
        
        let parameters : [String:String] = [
        "format" : "json",
        "action" : "query",
        "prop" : "extracts|pageimages",
        "exintro" : "",
        "explaintext" : "",
        "titles" : flowerName,
        "indexpageids" : "",
        "redirects" : "1",
        "pithumbsize" : "500",
        ]

        
        
        AF.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.value != nil {
                print(response)
                
                let flowerJSON : JSON = JSON(response.value!)
                
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                
                let flowerDescription = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                
                self.imageView.sd_setImage(with: URL(string: flowerImageURL))
                self.label.text = flowerDescription
            }
        }
    }
    
    func detect(image:CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier(configuration: MLModelConfiguration.init()).model) else {
            fatalError("Cannot import Model")
        }
       
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classification = request.results?.first as? VNClassificationObservation else{
                fatalError("Could not classify image")
            }
            
            self.navigationItem.title = classification.identifier.capitalized
            self.requestInfo(flowerName: classification.identifier)
            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        }catch{
            print(error)
        }
    }
}

