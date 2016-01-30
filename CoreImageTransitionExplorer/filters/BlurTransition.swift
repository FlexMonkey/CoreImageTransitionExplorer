//
//  BlurTransition.swift
//  CoreImageTransitionExplorer
//
//  Created by Simon Gladman on 30/01/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import CoreImage

class BlurTransition: CIFilter
{
    static func register()
    {
        CIFilter.registerFilterName("BlurTransition",
            constructor: CustomFiltersVendor(),
            classAttributes: [
                kCIAttributeFilterCategories: ["CICategoryTransition"]
            ])
    }
    
    override var attributes: [String : AnyObject]
    {
        return [
            kCIAttributeFilterDisplayName: "Blur Transition",
            
            "inputImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputTargetImage": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "CIImage",
                kCIAttributeDisplayName: "Target Image",
                kCIAttributeType: kCIAttributeTypeImage],
            
            "inputTime": [kCIAttributeIdentity: 0,
                kCIAttributeClass: "NSNumber",
                kCIAttributeDefault: 0.5,
                kCIAttributeDisplayName: "Time",
                kCIAttributeMin: 0,
                kCIAttributeSliderMin: 0,
                kCIAttributeSliderMax: 1,
                kCIAttributeType: kCIAttributeTypeScalar]
        ]
    }
    
    override var outputImage: CIImage?
    {
        guard let inputImage = inputImage,
            inputTargetImage = inputTargetImage else
        {
            return nil
        }
        
        let time = inputTime.smootherStep()
        
        let blurredSource = inputImage
            .imageByApplyingFilter("CIGaussianBlur", withInputParameters: [kCIInputRadiusKey: time * maxBlur])
            .imageByCroppingToRect(inputImage.extent)
        
        let blurredTarget = inputTargetImage
            .imageByApplyingFilter("CIGaussianBlur", withInputParameters: [kCIInputRadiusKey: (1 - time) * maxBlur])
            .imageByCroppingToRect(inputTargetImage.extent)
        
        let finalImage = blurredSource
            .imageByApplyingFilter("CIDissolveTransition", withInputParameters: [
                kCIInputTargetImageKey: blurredTarget,
                kCIInputTimeKey: inputTime])
        
        return finalImage
    }
    
    var inputImage: CIImage?
    var inputTargetImage: CIImage?
    
    var inputTime: CGFloat = 0.5
    
    let maxBlur = CGFloat(100)
    
    let transitionFilter = CIFilter(name: "CIDissolveTransition")!
    let sourceBlurFilter = CIFilter(name: "CIGaussianBlur")!
    let targetBlurFilter = CIFilter(name: "CIGaussianBlur")
}

class CustomFiltersVendor: NSObject, CIFilterConstructor
{
    func filterWithName(name: String) -> CIFilter?
    {
        switch name
        {
        case "BlurTransition":
            return BlurTransition()
            
        default:
            return nil
        }
    }
}

extension CGFloat
{
    func saturate() -> CGFloat
    {
        return self < 0 ? 0 : self > 1 ? 1 : self
    }
    
    func smootherStep() -> CGFloat
    {
        let x = self.saturate()
        
        return ((x) * (x) * (x) * ((x) * ((x) * 6 - 15) + 10))
    }
}