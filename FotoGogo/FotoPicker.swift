//
//  FotoPicker.swift
//  FotoGogo
//
//  Created by Daniel Maslia on 1/10/24.
//

import PhotosUI
import SwiftUI

struct FotoPicker: View {
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageData: [Data] = []
    @State private var selectedPHAssets: [PHAsset] = []
    @State private var reading: String = ""
    @State private var distance: Float = Float()
    
    func getDistance(phAsset1: PHAsset, phAsset2: PHAsset) async
    {
        let asset1 = FotoAsset(asset: phAsset1)
        let asset2 = FotoAsset(asset: phAsset2)
        await FotoAsset.computeFeaturePrintDistance(asset1: asset1, asset2: asset2) { out_distance in
            if let out_distance = out_distance {
                distance = out_distance
            }
        }
        
//        asset1.getFeatureprint() { featureprint1 in
//            if let featureprint1 = featureprint1 {
//                asset2.getFeatureprint() { featureprint2 in
//                    if let featureprint2 = featureprint2 {
//                        var dist = Float()
//                        do {
//                            try featureprint1.computeDistance(&dist, to: featureprint2)
//                            if dist < 12 {
//                                reading = "DUPLICATES"
//                            } else {
//                                reading = "NOT DUPLICATES"
//                            }
//                            distance = dist
//                        } catch {
//                            print("Error computing distance: \(error)")
//                        }
//                    }
//                }
//            }
//        }
    }

    var body: some View {
        PhotosPicker(
            selection: $selectedItems,
            matching: .images,
            photoLibrary: .shared()) {
                Text("Select 2 photos")
            }
            .onChange(of: selectedItems) { newItems in
                selectedImageData = []
                selectedPHAssets = []
                guard newItems.count == 2 else {return}
                for newItem in newItems {
                    Task {
                        if let localID = newItem.itemIdentifier {
                            let result = PHAsset.fetchAssets(withLocalIdentifiers: [localID], options: nil)
                            if let asset = result.firstObject {
                                selectedPHAssets.append(asset)
                            }
                            // Retrieve selected asset in the form of Data
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                selectedImageData.append(data)
                            }
                            if selectedPHAssets.count == 2 {
                                await getDistance(phAsset1: selectedPHAssets[0], phAsset2: selectedPHAssets[1])
                            }
                        }
                        
                    }
                }
                
            }
        HStack {
            ForEach(selectedImageData, id: \.self) { imageData in
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
                }
            }
        }
        
        Text("PHOTO IDENTIFICATION: \(reading)")
        Text("DISTANCE: \(distance)")
    }
}

struct FotoPicker_Previews: PreviewProvider {
    static var previews: some View {
        FotoPicker()
    }
}
