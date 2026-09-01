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
    
    // EARLY EXIT OPTIMIZATION: If the pixel is completely outside the wave, skip all math!
    // waveWidth * 1.5 ensures we don't clip the outer chromatic aberration split
    if (abs(distFromWave) > waveWidth * 1.5) {
        return currentColor;
    }
    
    // Chromatic aberration split (offsetting the wave crest for R, G, B)
    float split = 3.0; 
    // Use fast hardware smoothstep instead of exp for better performance
    float valR = abs(distFromWave - split) / waveWidth;
    float intensityR = smoothstep(1.0, 0.0, valR);
    
    float valG = abs(distFromWave) / waveWidth;
    float intensityG = smoothstep(1.0, 0.0, valG);
    
    float valB = abs(distFromWave + split) / waveWidth;
    float intensityB = smoothstep(1.0, 0.0, valB);
    
    // Subtle specular highlight exactly at the crest
    float valS = abs(distFromWave) / (waveWidth * 0.15);
    float specular = smoothstep(1.0, 0.0, valS) * 0.15;
    
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
    
    // Proper premultiplied alpha blending (Source-Over)
    // chromaticLight is our unpremultiplied source color, blendAlpha is source alpha
    float3 sourceRGB = chromaticLight * blendAlpha;
    
    // currentF is our destination (already premultiplied)
    float3 newColor = sourceRGB + currentF.rgb * (1.0 - blendAlpha);
    float newAlpha = blendAlpha + currentF.a * (1.0 - blendAlpha);
    
    // CRITICAL: SwiftUI expects valid premultiplied alpha. 
    // If any RGB component exceeds Alpha, it causes a yellow error box or crash.
    newColor = clamp(newColor, 0.0, newAlpha);
    
    return half4(newColor.r, newColor.g, newColor.b, newAlpha);
}
