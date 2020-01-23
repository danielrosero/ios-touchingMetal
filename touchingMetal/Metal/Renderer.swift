//
//  Renderer.swift
//  touchingMetal
//
//  Created by Daniel Rosero on 1/8/20.
//  Copyright © 2020 Daniel Rosero. All rights reserved.
//

import Foundation
import MetalKit




class Renderer: NSObject {
    
    static var device: MTLDevice!
    static var library: MTLLibrary!
    let commandQueue: MTLCommandQueue
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    var pipelineState: MTLRenderPipelineState!
    var baseColorTexture:MTLTexture!
    var samplerState:MTLSamplerState!
    var vertexDescriptorReal:MTLVertexDescriptor!
    var vertexDescriptor:MDLVertexDescriptor!
    var computePipeLineState: MTLComputePipelineState!
    var kernelRandomFunction: MTLFunction!
    let depthStencilState: MTLDepthStencilState
    let camera = ArcballCamera()
    var uniforms = Uniforms()
    var timer: Float = 0
    
    var drawableTextureForKernel: MTLTexture?
    var enableTextureForKernel: Bool?
    
    //    The models what we are going to render in the scene
    let scan: Model
    let completeBody: Model
    
    //    ****
    
    //    iteration is used as a seed in the randomizer kernel
    var iteration = 0
    //    ****
    
//    //    ignore this, I was experimenting trying to change size of the drawableTextureForKernel on runtime.
//    var sizeOfComputedTexture: Int = 0
//    //    ****
//
    
    init(view: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue() else {
                fatalError("Unable to connect to GPU")
        }
        
        Renderer.device = device
        self.commandQueue = commandQueue
        Renderer.library = device.makeDefaultLibrary()
        
        vertexDescriptor = Renderer.buildVertexDescriptor()
        pipelineState = Renderer.createPipelineState(vertexDescriptor: vertexDescriptor)
        depthStencilState = Renderer.createDepthState()
        samplerState = Renderer.buildSamplerState(device: device)
        
        
        camera.target = [0, 0.8, 0]
        camera.distance = 3
        
        
        
        //       Create the MTLTextureLoader options that we need according to each model case. Some of them are flipped, and so on.
        
        
        let textureLoaderOptionsWithFlip: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true, .origin : MTKTextureLoader.Origin.bottomLeft]
        
        let textureLoaderOptionsWithoutFlip: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
        
        
        
        //        ****
        
        
        
        
//        Initializing the models, set their position, scale and do a rotation transformation
        
//        Scan model
        
        scan = Model(name: "face",vertexDescriptor: vertexDescriptor,textureFile: "face.jpg", textureLoaderOptions: textureLoaderOptionsWithFlip)
        scan.transform.position = [0, 1.7, 1.5]
        scan.transform.scale = 0.08
                scan.transform.rotation = vector_float3(radians(fromDegrees: 180),radians(fromDegrees: 180),0)
        
//        ****
        
//        Body model
        
        completeBody = Model(name: "completebody",vertexDescriptor: vertexDescriptor,textureFile: "bodyTexture.jpg", textureLoaderOptions: textureLoaderOptionsWithoutFlip)
        completeBody.transform.position = [0, 0.8, 1]
        completeBody.transform.scale = 0.08
        completeBody.transform.rotation = vector_float3(radians(fromDegrees: 180),radians(fromDegrees: 180),0)
        
        
//        ****
        
        
        view.depthStencilPixelFormat = .depth32Float
        
//        The kernel texture is not going to be used by default
        enableTextureForKernel=false
//        ****
        
        
        
        super.init()
        
        
        
        
        //    Creating drawableTextureForKernel for kernel
        
        let drawableTextureForKernelDescriptor = MTLTextureDescriptor()
        drawableTextureForKernelDescriptor.pixelFormat = .bgra8Unorm
        
        // Set the pixel dimensions of the texture
        drawableTextureForKernelDescriptor.width = 100
        drawableTextureForKernelDescriptor.height = 100
        
        drawableTextureForKernelDescriptor.usage = [.shaderRead, .shaderWrite]
        
        drawableTextureForKernel = Renderer.device.makeTexture(descriptor: drawableTextureForKernelDescriptor)
        
        
        
        //    ****
        
        
        self.setupComputePipeline()
        
    }
    
    
    
    
    static func buildVertexDescriptor() -> MDLVertexDescriptor {
        
        let vertexDescriptor = MDLVertexDescriptor()
        
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: MemoryLayout<SIMD3<Float>>.stride,
                                                            bufferIndex: 0)
        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                            format: .float2,
                                                            offset:  MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride,
                                                            bufferIndex: 0)
        
        
        let valor = MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD3<Float>>.stride + MemoryLayout<SIMD2<Float>>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: valor)
        
        
        //        _____________________ THIS IS THE SAME AS ON TOP, but using .size instead of stride.
        
        //
        //        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
        //                                                            format: .float3,
        //                                                            offset: 0,
        //                                                            bufferIndex: 0)
        //        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
        //                                                            format: .float3,
        //                                                            offset: MemoryLayout<Float>.size * 3,
        //                                                            bufferIndex: 0)
        //        vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
        //                                                            format: .float2,
        //                                                            offset: MemoryLayout<Float>.size * 6,
        //                                                            bufferIndex: 0)
        //        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
        
        
        
        return vertexDescriptor
    }
    
    private func setupComputePipeline() {
        // Create Pipeline State for RayGenereration from Camera
        self.kernelRandomFunction = Renderer.library.makeFunction(name: "kernel_randomizer_allcolors")
        do    { try computePipeLineState = Renderer.device.makeComputePipelineState(function: kernelRandomFunction)}
        catch { fatalError("ShadeImage computePipelineState failed")}
    }
    
    static func createPipelineState(vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
        let vertexFunction = Renderer.library.makeFunction(name: "vertex_main")
        let fragmentFunction = Renderer.library.makeFunction(name: "fragment_main")
        
        
        
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        
        
        
        let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
        pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
        
        
        
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        return try! device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        
        
    }
    
    
    
    
    
    
    static func createDepthState() -> MTLDepthStencilState {
        let depthDescriptor = MTLDepthStencilDescriptor()
        depthDescriptor.depthCompareFunction = .less
        depthDescriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: depthDescriptor)!
    }
    
    static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.normalizedCoordinates = true
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.mipFilter = .linear
        return device.makeSamplerState(descriptor: samplerDescriptor)!
    }
    
}



extension Renderer: MTKViewDelegate {
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        camera.aspect = Float(view.bounds.width / view.bounds.height)
    }
    
    
    
    func draw(in view: MTKView) {
        //    autoreleasepool{ // added this
        guard let commandBuffer = self.commandQueue.makeCommandBuffer(),
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor else {
                return
        }
        
        timer += 0.05
        

        
        var viewTransform = Transform()
        viewTransform.position.y = 1.0
        viewTransform.position.z = -2.0
        
        
        //    Trying Kernel computing part
        
        let commandEncoderCompute = commandBuffer.makeComputeCommandEncoder()
        
        
        commandEncoderCompute?.label = "Iteration: \(self.iteration)"
        
        
        commandEncoderCompute!.setBytes(&self.iteration,  length: MemoryLayout<Int>.size, index: 21)
        commandEncoderCompute!.setTexture(drawableTextureForKernel, index: 0)
        
        
        self.iteration += 1
        
        
        self.dispatchPipelineState(using: commandEncoderCompute!)
        
        commandEncoderCompute?.endEncoding()
        
        
        
        //    ****
        
        
        let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)!
        commandEncoder.setRenderPipelineState(pipelineState)
        
        
        
        
        
        uniforms.viewMatrix = camera.viewMatrix
        uniforms.projectionMatrix = camera.projectionMatrix
        
        commandEncoder.setDepthStencilState(depthStencilState)
        
        uniforms.modelMatrix = scan.transform.matrix
        
        
        
        
        
        
        //    ------------------------------------------
        
        
        let models = [scan,completeBody]
        
        for model in models {
            
            
            uniforms.modelMatrix = model.transform.matrix
            
            
            
            commandEncoder.setVertexBytes(&uniforms,
                                          length: MemoryLayout<Uniforms>.stride,
                                          index: 21)
            
     
            
            if(enableTextureForKernel! == false){

                commandEncoder.setFragmentTexture(model.texture, index: 0)
            }else{

                commandEncoder.setFragmentTexture(drawableTextureForKernel, index: 0)
            }
            
            
            
            
            
            
            commandEncoder.setFragmentSamplerState(samplerState, index: 0)
            
            
            
            for mtkMesh in model.mtkMeshes {
                for vertexBuffer in mtkMesh.vertexBuffers {
                    
                    commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)

                    
                    for submesh in mtkMesh.submeshes {
                      
                        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                                             indexCount: submesh.indexCount,
                                                             indexType: submesh.indexType,
                                                             indexBuffer: submesh.indexBuffer.buffer,
                                                             indexBufferOffset: submesh.indexBuffer.offset)
                        
                        
                        
                        

                    }
                }
            }
        }
        
        commandEncoder.endEncoding()
        
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        
        
        
        
    }
    
}

extension Renderer {
    fileprivate func dispatchPipelineState(using commandEncoder: MTLComputeCommandEncoder) {
        let w = computePipeLineState.threadExecutionWidth
        let h = computePipeLineState.maxTotalThreadsPerThreadgroup / w
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        
        let threadgroupsPerGrid =  MTLSize(width:  (drawableTextureForKernel!.width + w - 1) / w,
                                           height: (drawableTextureForKernel!.height + h - 1) / h,
                                           depth: 1)
        
        commandEncoder.setComputePipelineState(computePipeLineState)
        commandEncoder.dispatchThreadgroups(threadgroupsPerGrid,
                                            threadsPerThreadgroup: threadsPerThreadgroup)
    }
    
}
