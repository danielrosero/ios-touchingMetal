//
//  Model.swift
//  touchingMetal
//
//  Created by Daniel Rosero on 1/8/20.
//  Copyright © 2020 Daniel Rosero. All rights reserved.
//

import Foundation
import MetalKit

//This extension allows to create a MTLTexture attribute inside this Model class
//in order to be identified and used in the Renderer. This is to ease the loading in case of multiple models in the scene

extension Model : Texturable{
    
}

class Model {
    
    let mdlMeshes: [MDLMesh]
    let mtkMeshes: [MTKMesh]
    var texture: MTLTexture?
    var transform = Transform()
    let name: String
    
    //In order to create a model, you need to pass a name to use it as an identifier,
    //    a reference to the vertexDescriptor, the imagename with the extension of the texture,
    //the dictionary of MTKTextureLoader.Options
    
    init(name: String, vertexDescriptor: MDLVertexDescriptor, textureFile: String, textureLoaderOptions: [MTKTextureLoader.Option : Any]) {
        let assetUrl = Bundle.main.url(forResource: name, withExtension: "obj")
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        
        let asset = MDLAsset(url: assetUrl, vertexDescriptor: vertexDescriptor, bufferAllocator: allocator)
        
        let (mdlMeshes, mtkMeshes) = try! MTKMesh.newMeshes(asset: asset, device: Renderer.device)
        self.mdlMeshes = mdlMeshes
        self.mtkMeshes = mtkMeshes
        self.name = name
        texture = setTexture(device: Renderer.device, imageName: textureFile, textureLoaderOptions: textureLoaderOptions)
        
    }
    
    
    
}
