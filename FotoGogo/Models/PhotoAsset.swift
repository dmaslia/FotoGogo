//
//  RandomPhoto.swift
//  FotoGogo
//
//  Created by Daniel Maslia on 1/7/24.
//
import UIKit
import Photos
import Foundation
import Vision


class FotoAsset {
    private var ciImage: CIImage?
    private var asset: PHAsset
    
    enum MyError: Error {
        case failedToCreateCIImage
        case noImageData
    }
    
    init(asset: PHAsset) {
        self.asset = asset
    }
    
    
    func getFeatureprint() async -> VNFeaturePrintObservation? {
        do {
            if let image = await FotoAsset(asset: asset).getImage() {
                let requestHandler = VNImageRequestHandler(ciImage: image)
                let request = VNGenerateImageFeaturePrintRequest()
                
                do {
                    try requestHandler.perform([request])
                    return request.results?.first as? VNFeaturePrintObservation
                } catch {
                    print("Vision error: \(error)")
                }
            }
        }

        return nil
    }
    
    func getImage() async -> CIImage? {
        let requestOptions: PHImageRequestOptions = {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            return options
        }()
        
        return try? await withCheckedThrowingContinuation { continuation in
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions) { (imageData, _, _, _) in
                if let imageData = imageData {
                    if let image = CIImage(data: imageData) {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: MyError.failedToCreateCIImage)
                    }
                } else {
                    continuation.resume(throwing: MyError.noImageData)
                }
            }
        }
    }
    
    
    static func computeFeaturePrintDistance(asset1: FotoAsset, asset2: FotoAsset, completion: @escaping (Float?) -> Void) async {
        if let observation1 = await asset1.getFeatureprint() {
            if let observation2 = await asset2.getFeatureprint() {
                
                var distance = Float(0)
                
                do {
                    try observation1.computeDistance(&distance, to: observation2)
                    completion(distance)
                } catch {
                    print("Error computing distance: \(error)")
                }
            }
        }
    }
}
    
    

