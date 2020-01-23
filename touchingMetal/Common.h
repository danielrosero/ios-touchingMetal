//
//  Common.h
//  touchingMetal
//
//  Created by Daniel Rosero on 1/13/20.
//  Copyright © 2020 Daniel Rosero. All rights reserved.
//

#import <simd/simd.h>

#ifndef Common_h
#define Common_h

typedef struct {
  matrix_float4x4 modelMatrix;
  matrix_float4x4 viewMatrix;
  matrix_float4x4 projectionMatrix;
} Uniforms;

#endif /* Common_h */
