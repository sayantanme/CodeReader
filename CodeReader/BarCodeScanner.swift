//
//  ViewController.swift
//  CodeReader
//
//  Created by Sayantan Chakraborty on 04/05/17.
//  Copyright © 2017 Sayantan Chakraborty. All rights reserved.
//

import UIKit
import AVFoundation
import CoreData

class BarCodeScanner: UIViewController,AVCaptureMetadataOutputObjectsDelegate {

    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var isActionAdd:Bool?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        view.backgroundColor = UIColor.black
        captureSession = AVCaptureSession()
        
        let videoCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        let videoInput: AVCaptureDeviceInput
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            print("Error with video capture")
            return
        }
        if (captureSession?.canAddInput(videoInput))! {
            captureSession?.addInput(videoInput)
        }else{
            failed()
            return
        }
        let metadataOutput = AVCaptureMetadataOutput()
        if (captureSession?.canAddOutput(metadataOutput))! {
            captureSession?.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        }else{
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        view.layer.addSublayer(previewLayer!)
        
        captureSession?.startRunning()
        
        // Initialize QR Code Frame to highlight the QR code
        qrCodeFrameView = UIView()
        
        if let qrCodeFrameView = qrCodeFrameView {
            qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
            qrCodeFrameView.layer.borderWidth = 2
            view.addSubview(qrCodeFrameView)
            view.bringSubview(toFront: qrCodeFrameView)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if captureSession?.isRunning == false {
            captureSession?.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession?.stopRunning()
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        captureSession?.stopRunning()
        if let metadataObject = metadataObjects.first {
            let readableObject = metadataObject as! AVMetadataMachineReadableCodeObject
            let barCodeObject = previewLayer?.transformedMetadataObject(for: metadataObject as! AVMetadataObject)
            qrCodeFrameView?.frame = (barCodeObject?.bounds)!
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: readableObject.stringValue)
        }
    }
    func found(code:String){
        print(code)
        
        
        if isActionAdd! {
            getProductData(code: code)
        }else{
            remove(code: code)
        }
        
    }
    
    func save(prod: Product){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let entity = NSEntityDescription.entity(forEntityName: "Products", in: managedContext)!
        let product = NSManagedObject(entity: entity, insertInto: managedContext)
        product.setValue(prod.code, forKeyPath: "code")
        product.setValue(prod.price, forKeyPath: "price")
        product.setValue(prod.productDescription, forKeyPath: "productDescription")
        product.setValue(prod.quantity, forKeyPath: "quantity")
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func remove(code: String){
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else{
            return
        }
        let managedContext =
            appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<Products> = Products.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "code == %@", code)
        let result = try? managedContext.fetch(fetchRequest)
        let resultData = result!
        for object in resultData {
            managedContext.delete(object)
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        self.dismiss(animated: true, completion: nil)
        
    }
    
    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    // MARK: - Bluemix Calls
    
    func getProductData(code: String){
        let url = URL(string: "https://autobillingsystem.mybluemix.net/getproductbycode/\(code)")
        
        let task = URLSession.shared.dataTask(with: url!) { (data, response, error) in
            guard error == nil else{
                print(error?.localizedDescription ?? "Error")
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! [String:AnyObject]
                print(json)
                if json.count > 0 {
                    let prod = Product()
                    prod.code = code
                    prod.productDescription = json["productname"] as? String
                    prod.price = json["price"] as? Double
                    prod.quantity = 1
                    
                    self.save(prod: prod)
                }
                //save(code: code)
                
            }catch let error as NSError{
                print(error)
            }
        }
        
        task.resume()
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

