


#include <metal_stdlib>
#import "../Common.h"
#import "../Resources/Libraries/Loki/loki_header.metal"

using namespace metal;

struct VertexIn {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
    float3 normal;
    float2 texCoords;
};


vertex VertexOut vertex_main(VertexIn in [[stage_in]],
                             constant Uniforms &uniforms [[buffer(21)]])
{
    VertexOut out;
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * float4(in.position, 1.0);
    out.texCoords = in.texCoords;
    
    return out;
}


fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]],
                              texture2d<float, access::sample> baseColorTexture [[texture(0)]],
                              sampler baseColorSampler [[sampler(0)]])
{
    float3 baseColor = baseColorTexture.sample(baseColorSampler, fragmentIn.texCoords).rgb;
    return float4(baseColor, 1);
}


fragment float4 fragment_normals(VertexOut in [[stage_in]]) {
    return float4(normalize(in.normal), 1);
}



/// Shade Image Based on a Random Number
kernel void kernel_randomizer_allcolors(texture2d<float, access::write> drawable   [[ texture(0) ]],
                              constant uint& iteration                   [[  buffer(21) ]],
                              const uint2 position [[thread_position_in_grid]]) {
    
    // Loki takes in (up to) 3 seeds, but must have at least one.
    // All you have to do is just pass in some random seeds, on initialization
    
    
    Loki rng = Loki(position.x + 1, position.y + 1,iteration + 1);
    
    // When using Loki, it's as simple as just calling rand()!
    float random_float = rng.rand();
    float random_float2 = rng.rand();
    float random_float3 = rng.rand();
    
    //    drawable.write(float4(float3(random_float),1), position);
    
    
    //    The float4 means (R,G,B,A)
    
    drawable.write(float4(float3(random_float3,random_float2,random_float),1), position);
    
    //    ****
}



