#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 lightRipple(float2 position, half4 currentColor, float2 touchPos, float time, float2 size, half4 rippleColor) {
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
    float split = 8.0; 
    float intensityR = exp(-pow((distFromWave - split) / waveWidth, 2.0));
    float intensityG = exp(-pow(distFromWave / waveWidth, 2.0));
    float intensityB = exp(-pow((distFromWave + split) / waveWidth, 2.0));
    
    // Shiny specular highlight exactly at the crest
    float specular = exp(-pow(distFromWave / (waveWidth * 0.15), 2.0)) * 0.3;
    
    // Fade out as it expands
    float fade = 1.0 - time;
    
    // The base envelope for the ripple visibility
    float envelope = max(max(intensityR, intensityG), intensityB);
    float blendAlpha = envelope * fade * rippleColor.a * 1.5; // Reduced alpha boost
    
    // Only apply light to visible pixels to preserve shapes
    if (currentColor.a == 0.0) {
        return currentColor;
    }
    
    // Create the chromatic light
    half3 chromaticLight = half3(intensityR, intensityG, intensityB);
    
    // Tint it slightly with the requested ripple color to keep branding
    chromaticLight = mix(chromaticLight, rippleColor.rgb, 0.5);
    
    // Add specular highlight
    chromaticLight += half3(specular);
    chromaticLight = clamp(chromaticLight, 0.0h, 1.0h);
    
    // Blend the shiny chromatic ripple over the current color
    half3 newColor = mix(currentColor.rgb, chromaticLight, clamp(blendAlpha, 0.0, 1.0));
    
    return half4(newColor, currentColor.a);
}
