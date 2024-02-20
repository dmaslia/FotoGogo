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
