#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 lightRipple(float2 position, half4 currentColor, float2 touchPos, float time, float2 size, half4 rippleColor) {
    // Convert to float for safer math on A-series GPUs
    float4 currentF = float4(currentColor);
    float4 rippleF = float4(rippleColor);
    
    // Distance from the exact touch point
    float distance = length(position - touchPos);
    
    // The maximum distance the wave needs to travel is roughly the diagonal of the view
    float maxDist = length(size);
    
    // The current radius of the expanding wave based on the animation progress (time from 0 to 1)
    float waveRadius = time * maxDist * 1.5;
    
    // The thickness of the ripple ring
    float waveWidth = maxDist * 0.3;
    if (waveWidth < 30.0) waveWidth = 30.0;
    
    // Calculate how far the current pixel is from the wave crest
    float distFromWave = distance - waveRadius;
    
    // Chromatic aberration split (offsetting the wave crest for R, G, B)
    float split = 3.0; 
    float valR = (distFromWave - split) / waveWidth;
    float intensityR = exp(-(valR * valR));
    
    float valG = distFromWave / waveWidth;
    float intensityG = exp(-(valG * valG));
    
    float valB = (distFromWave + split) / waveWidth;
    float intensityB = exp(-(valB * valB));
    
    // Subtle specular highlight exactly at the crest
    float valS = distFromWave / (waveWidth * 0.15);
    float specular = exp(-(valS * valS)) * 0.15;
    
    // Fade out as it expands
    float fade = 1.0 - time;
    
    // The base envelope for the ripple visibility
    float envelope = max(max(intensityR, intensityG), intensityB);
    float blendAlpha = envelope * fade * rippleF.a * 0.8;
    
    // Only apply light to visible pixels to preserve shapes
    if (currentF.a == 0.0) {
        return currentColor;
    }
    
    // Create the chromatic light
    float3 chromaticLight = float3(intensityR, intensityG, intensityB);
    
    // Tint it slightly with the requested ripple color to keep branding
    chromaticLight = mix(chromaticLight, rippleF.rgb, 0.5);
    
    // Add specular highlight
    chromaticLight += float3(specular);
    chromaticLight = clamp(chromaticLight, 0.0, 1.0);
    
    // Blend the shiny chromatic ripple over the current color
    float3 newColor = mix(currentF.rgb, chromaticLight, clamp(blendAlpha, 0.0, 1.0));
    
    // Increase alpha so the ripple is visible even on transparent backgrounds
    float newAlpha = clamp(currentF.a + blendAlpha, 0.0, 1.0);
    
    return half4(newColor.r, newColor.g, newColor.b, newAlpha);
}
