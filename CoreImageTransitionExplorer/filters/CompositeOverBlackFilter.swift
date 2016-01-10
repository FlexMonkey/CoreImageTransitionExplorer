//
//  CompositeOverBlackFilter.swift
//  CoreImageTransitionExplorer
//
//  Created by Simon Gladman on 10/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit
import CoreImage

class CompositeOverBlackFilter: CIFilter
{
    let black: CIFilter
    let composite: CIFilter
    let crop: CIFilter
    
    var inputImage : CIImage?
    
    override init()
    {
        black = CIFilter(name: "CIConstantColorGenerator",
            withInputParameters: [kCIInputColorKey: CIColor(color: UIColor.blackColor())])!
        
        composite = CIFilter(name: "CISourceAtopCompositing",
            withInputParameters: [kCIInputBackgroundImageKey: black.outputImage!])!
        
        crop = CIFilter(name: "CICrop",
            withInputParameters: ["inputRectangle" : CIVector(CGRect: ViewController.rect1024x1024)])!
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var outputImage: CIImage!
    {
        guard let inputImage = inputImage else
        {
            return nil
        }
        
        composite.setValue(inputImage, forKey: kCIInputImageKey)
        crop.setValue(composite.outputImage, forKey: kCIInputImageKey)
        
        return crop.outputImage
    }
}
