//
//  ViewController.swift
//  CoreImageTransitionExplorer
//
//  Created by Simon Gladman on 10/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController
{
    let manager = PHImageManager.defaultManager()
    lazy var requestOptions: PHImageRequestOptions =
    {
        [unowned self] in
        
        let requestOptions = PHImageRequestOptions()
        
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
        requestOptions.resizeMode = PHImageRequestOptionsResizeMode.Exact
        requestOptions.networkAccessAllowed = true
        
        requestOptions.progressHandler = {
            (value: Double, _: NSError?, _ : UnsafeMutablePointer<ObjCBool>, _ : [NSObject : AnyObject]?) in
            dispatch_async(dispatch_get_main_queue())
            {
                self.progressBar.setProgress(Float(value), animated: true)
            }
        }

        return requestOptions
    }()
  
    let imageView = ImageView()
    
    let progressBar = UIProgressView(progressViewStyle: .Bar)
    
    let transitionSegmentedControl = UISegmentedControl(items: ["CIDissolveTransition", "CIBarsSwipeTransition",
        "CIModTransition", "CISwipeTransition",
        "CICopyMachineTransition", "CIFlashTransition"])
    
    var transitionTime = 0.0
    let transitionStep = 0.005
    
    var assets = ViewController.getAllAssets()
    
    var imageOne: CIImage?
    var imageTwo: CIImage?
    var imageOneIsTransitionTarget: Bool = false
    
    let returnImageSize = CGSize(width: 1024, height: 1024)
    let rect1024x1024 = CGRect(x: 0, y: 0, width: 1024, height: 1024)
    
    var randomAssetIndex: Int
    {
        return Int(arc4random_uniform(UInt32(assets.count - 1)))
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.blackColor()
        imageView.backgroundColor = UIColor.blackColor()
        
        view.addSubview(imageView)
        
        // ---
        
        view.addSubview(progressBar)
        
        // ---
        
        transitionSegmentedControl.selectedSegmentIndex = 0
        view.addSubview(transitionSegmentedControl)
        
        // ---

        manager.requestImageForAsset(assets[randomAssetIndex],
            targetSize: returnImageSize,
            contentMode: PHImageContentMode.AspectFit,
            options: requestOptions,
            resultHandler: imageRequestResultHandler)
        
        manager.requestImageForAsset(assets[randomAssetIndex],
            targetSize: returnImageSize,
            contentMode: PHImageContentMode.AspectFit,
            options: requestOptions,
            resultHandler: imageRequestResultHandler)

        let displayLink = CADisplayLink(target: self, selector: Selector("step"))
        displayLink.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    func step()
    {
        guard let imageOne = imageOne, imageTwo = imageTwo else
        {
            return
        }
  
        let transformFilterOne = CIFilter(name: "CIAffineTransform",
            withInputParameters: [kCIInputImageKey: imageOne,
                kCIInputTransformKey: ViewController.centerImageTransform(imageOne)])!
        
  
        let transformFilterTwo = CIFilter(name: "CIAffineTransform",
            withInputParameters: [kCIInputImageKey: imageTwo,
                kCIInputTransformKey: ViewController.centerImageTransform(imageTwo)])!
        
        // ---
        
        let source = imageOneIsTransitionTarget ? transformFilterOne.outputImage! : transformFilterTwo.outputImage!
        let target = imageOneIsTransitionTarget ? transformFilterTwo.outputImage! : transformFilterOne.outputImage!
    
        let transitionName = transitionSegmentedControl.titleForSegmentAtIndex(transitionSegmentedControl.selectedSegmentIndex)!
        
        let transition = CIFilter(name: transitionName,
            withInputParameters: [kCIInputImageKey: source,
                kCIInputTargetImageKey: target,
                kCIInputTimeKey: transitionTime])!

        if transition.inputKeys.contains(kCIInputExtentKey)
        {
            transition.setValue(CIVector(CGRect: rect1024x1024),
                forKey: kCIInputExtentKey)
        }
        
        if transition.inputKeys.contains(kCIInputCenterKey)
        {
            transition.setValue(CIVector(x: returnImageSize.width / 2, y: returnImageSize.height / 2),
                forKey: kCIInputCenterKey)
        }
      
        let finalImage = self.imageView.ciContext.createCGImage(transition.outputImage!,
            fromRect: rect1024x1024)
        
        imageView.image = CIImage(CGImage: finalImage)
        
        transitionTime += transitionStep
        
        if transitionTime > 1
        {
            transitionTime = 0
                    
            if imageOneIsTransitionTarget
            {
                self.imageOne = nil
            }
            else
            {
                self.imageTwo = nil
            }
            
            manager.requestImageForAsset(assets[randomAssetIndex],
                targetSize: returnImageSize,
                contentMode: PHImageContentMode.AspectFit,
                options: requestOptions,
                resultHandler: imageRequestResultHandler)
                    
        }
    }
    
    /// Returns an NSValue containing an affine transform to center an CIImage within
    /// a square bounding box
    static func centerImageTransform(image: CIImage) -> NSValue
    {
        let transform: NSValue
            
        if image.extent.width > image.extent.height
        {
            let dy = image.extent.width / 2 - image.extent.height / 2
            transform = NSValue(CGAffineTransform: CGAffineTransformMakeTranslation(0, dy))
        }
            else
        {
            let dx = image.extent.height / 2 - image.extent.width / 2
            transform = NSValue(CGAffineTransform: CGAffineTransformMakeTranslation(dx, 0))
        }

        return transform
    }
    
    /// Returns an array of all Image assets for collection type Moment
    static func getAllAssets() -> [PHAsset]
    {
        var assets = [PHAsset]()
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %i", PHAssetMediaType.Image.rawValue)
        
        
        let assetCollections = PHAssetCollection.fetchAssetCollectionsWithType(PHAssetCollectionType.Moment,
            subtype: PHAssetCollectionSubtype.AlbumRegular,
            options: nil)
        
        for index in 0 ..< assetCollections.count
        {
            let assetCollection = assetCollections[index] as? PHAssetCollection
            
            let assetsInCollection = PHAsset.fetchAssetsInAssetCollection(assetCollection!, options: fetchOptions)
            
            let range = NSIndexSet(indexesInRange: NSRange(0 ..< assetsInCollection.count))
            
            if let assetsArray = assetsInCollection.objectsAtIndexes(range) as? [PHAsset]
            {
                assets.appendContentsOf(assetsArray)
            }
        }
        
        return assets
    }
    
    func imageRequestResultHandler(image: UIImage?, properties: [NSObject: AnyObject]?)
    {
        guard let image = image else
        {
            return;
        }
     
        let imageResult = CIImage(image: image)?.imageByApplyingOrientation(imageOrientationToTiffOrientation(image.imageOrientation))
        
        if imageOneIsTransitionTarget
        {
            imageOne = imageResult
        }
        else
        {
            imageTwo = imageResult
        }
        
        progressBar.progress = 0
        
        imageOneIsTransitionTarget = !imageOneIsTransitionTarget
    }


    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds.insetBy(dx: 50, dy: 50)
        
        transitionSegmentedControl.frame = CGRect(x: 0,
            y: view.frame.height - transitionSegmentedControl.intrinsicContentSize().height,
            width: view.frame.width,
            height: transitionSegmentedControl.intrinsicContentSize().height)
        
        progressBar.frame = CGRect(x: 0,
            y: topLayoutGuide.length,
            width: view.frame.width,
            height: progressBar.intrinsicContentSize().height).insetBy(dx: 10, dy: 0)
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return UIStatusBarStyle.LightContent
    }

}


func imageOrientationToTiffOrientation(value: UIImageOrientation) -> Int32
{
    switch (value)
    {
    case UIImageOrientation.Up:
        return 1
    case UIImageOrientation.Down:
        return 3
    case UIImageOrientation.Left:
        return 8
    case UIImageOrientation.Right:
        return 6
    case UIImageOrientation.UpMirrored:
        return 2
    case UIImageOrientation.DownMirrored:
        return 4
    case UIImageOrientation.LeftMirrored:
        return 5
    case UIImageOrientation.RightMirrored:
        return 7
    }
}
