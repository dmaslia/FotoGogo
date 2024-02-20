//
//  ContentView.swift
//  FotoGogo
//
//  Created by Daniel Maslia on 1/5/24.
//

import SwiftUI
import Photos
import Vision

enum PhotoLoadingError: Error {
    case failedToRetrieveImage(String)
}


struct PhotoView: View {
    let assets: [PHAsset]
    @State private var featureprints: [VNFeaturePrintObservation] = []
    @State private var progress: Float = 0.0
    @State private var image: CIImage?
    @State private var fileNames: [String: Int] = [:]
    @State private var counts: Set<Int> = []
    @State private var curr_idx: Int = 0
    @State private var distance: Float?
    
    init(assets: [PHAsset]){
        self.assets = assets
    }
    
    
    var body: some View {
        VStack {
            ProgressView(value: progress)
            Text("Progress: \(String(format: "%.1f", progress * 100))%")
        }
        .padding()
        .onAppear {
            Task {
                await loadFeatureprints()
                print("done")
            }
        }
    }

    func loadFeatureprints() async -> Void {
        await withTaskGroup(of: VNFeaturePrintObservation?.self) { taskGroup in
            for asset in assets {
                taskGroup.addTask {
                    if let featureprint = await FotoAsset(asset: asset).getFeatureprint(){
                        return featureprint
                    } else {
                        return nil
                    }
                }
                for await featureprint in taskGroup {
                    if let featureprint = featureprint {
                        featureprints.append(featureprint)
                        let processed_val = Float(featureprints.count) / Float(assets.count)
                        DispatchQueue.main.async { progress = processed_val }
                    }
                }
            }
        }
    }
    
    



        
        
        
//        asset1 = FotoAsset(asset: asset1) {
//            asset2 = FotoAsset(asset: asset2) {
//                guard let asset1 = asset1, let asset2 = asset2 else {
//                    print("Error: Asset not initialized.")
//                    return
//                }
//                FotoAsset.computeFeaturePrintDistance(asset1: asset1, asset2: asset2) { returned_distance in
//                    if let returned_distance = returned_distance {
//                        asset1.getFeatureprint(completion: { featurePrint in
//                            if let featurePrint = featurePrint {
//                                print("ASSET 1 COUNT: \(featurePrint.data)")
//                            }
//                        })
//
//                        asset2.getFeatureprint(completion: { featurePrint in
//                            if let featurePrint = featurePrint {
//                                print("ASSET 2 COUNT: \(featurePrint.data)")
//                            }
//                        })
//                        print("DISTANCE: \(returned_distance)")
//                        distance = returned_distance
//                    } else {
//                        print("Distance could not be calculated.")
//                    }
//                }
//            }
//        }
    }
    
    func deleteAssets(assets: [PHAsset]){
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSArray)
        } completionHandler: { (success, error) in
            if success {
                print("Great success")
            } else {
                if let error = error {
                    print("Error deleting asset: \(error)")
                }
            }
        }
        
    }
    
//    private func fetchImageData(asset: PHAsset) {
//        let requestOptions: PHImageRequestOptions = {
//            let options = PHImageRequestOptions()
//            options.isNetworkAccessAllowed = true
//            return options
//        }()
//
//        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions) { (imageData, returned_data, orientation, info) in
//            if let imageData = imageData {
//                if let image = UIImage(data: imageData) {
//                    DispatchQueue.main.async {
//                        self.image = image
//                    }
//                }
//                if let infoDict = info {
//                    print("Additional Info:")
//                    for (key, value) in infoDict {
//                        print("\(key): \(value)")
//                    }
//                }
//            }
//            if let imageUrl = info?["PHImageFileURLKey"] as? URL {
//                print("Image URL: \(imageUrl)")
//            }
//        }
//    }    private func fetchImageData(asset: PHAsset) {
//        let requestOptions: PHImageRequestOptions = {
//            let options = PHImageRequestOptions()
//            options.isNetworkAccessAllowed = true
//            return options
//        }()
//
//        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: requestOptions) { (imageData, returned_data, orientation, info) in
//            if let imageData = imageData {
//                if let image = UIImage(data: imageData) {
//                    DispatchQueue.main.async {
//                        self.image = image
//                    }
//                }
//                if let infoDict = info {
//                    print("Additional Info:")
//                    for (key, value) in infoDict {
//                        print("\(key): \(value)")
//                    }
//                }
//            }
//            if let imageUrl = info?["PHImageFileURLKey"] as? URL {
//                print("Image URL: \(imageUrl)")
//            }
//        }
//    }

struct ContentView: View {
    @State private var selectedAssets: [PHAsset] = []
    var num: Int = 1000
    
    var body: some View {
        NavigationView {
            VStack {
                if selectedAssets.count > 0 {
                    PhotoView(assets: selectedAssets)
                } else {
                    Text("No Photos On Device")
                }
                
            }
            .onAppear {
                getPhotos(numberOfPhotos: num)
            }
        }
        
    }
    
    func getPhotos(numberOfPhotos num: Int) {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let limit = true
        fetchResult.enumerateObjects { (asset, index, stop) in
            if index < num || !limit {
                selectedAssets.append(asset)
            } else {
                stop.pointee = true // Stop enumeration after reaching 20 assets
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
        
    }
}
