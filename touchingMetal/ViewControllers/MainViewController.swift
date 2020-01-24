//
//  ViewController.swift
//  touchingMetal
//
//  Created by Daniel Rosero on 1/8/20.
//  Copyright © 2020 Daniel Rosero. All rights reserved.
//

import UIKit
import Metal
import simd
import MetalKit




class MainViewController: UIViewController {
    
    var device: MTLDevice!
    var metalView: MTKView!
    var renderer: Renderer!
    
    @IBOutlet weak var textureSizeSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        device = MTLCreateSystemDefaultDevice()
        
        metalView = MTKView(frame: view.frame)
        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0.87, green: 0.88, blue: 0.85, alpha: 1.0)
        
        
        renderer = Renderer(view: metalView)
        metalView.delegate=renderer
        
        //        Adding the created MTKView as a subView to the UIViewController
        self.view.addSubview(metalView)
        //        ****
        
        //        Sending the MTKView to the back
        self.view.sendSubviewToBack(metalView)
        //        ****
        
        
        
    }
    
    //    Handling Pan Gestures in order to rotate camera
    
    @IBAction func handlePan(_ recognizer: UIPanGestureRecognizer){
        
        guard recognizer.view != nil else{
            return
        }
        
        let translation = recognizer.translation(in: view)
        
        let delta = SIMD2(Float(-1*translation.x),
                          Float(-1*translation.y))
        
        renderer?.camera.rotate(delta: delta)
        
        recognizer.setTranslation(.zero, in: view)
        
    }
    
    //    ****
    
    
    //    Handling Pinch Gestures in order to zoom camera
    
    @IBAction func handlePinch(_ sender: UIPinchGestureRecognizer) {
        
        guard sender.view != nil else{
            return
        }
        
        renderer?.camera.zoom(delta: Float(sender.velocity))
        
    }
    
    //    ****
    
    
    //    Handling switch in UIViewController action in order to
    //    change fragmentTexture flag in Renderer
    
    @IBAction func handleSwitch(_ sender: UISwitch) {
        
        
        
        
        if(sender.isOn){
            
//            //        Unhide the slider
//
//            textureSizeSlider.isHidden=false
//
//
//            //        ****
            
            
            renderer.enableTextureForKernel = true
        }else{
            
//            //        Hide the slider
//
//            textureSizeSlider.isHidden=true
//
//            //        ****
            
            renderer.enableTextureForKernel=false
        }
        
        
    }
    
    //    ****
    
    
    
    @IBAction func handleSlider(_ sender: UISlider) {
        
//        renderer.sizeOfComputedTexture=Int(sender.value)
        
    }
    
    
}

