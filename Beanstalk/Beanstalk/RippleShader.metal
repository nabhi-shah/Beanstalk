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
    
    // Intensity of the ripple effect using a Gaussian falloff
    float intensity = exp(-pow(distFromWave / waveWidth, 2.0));
    
    // Fade out as it expands
    float fade = 1.0 - time;
    
    // Calculate the blend alpha combining the ripple intensity and the requested color's alpha
    float blendAlpha = intensity * fade * rippleColor.a;
    
    // Only apply light to visible pixels to preserve shapes
    if (currentColor.a == 0.0) {
        return currentColor;
    }
    
    // Blend the ripple color over the current color
    half3 newColor = mix(currentColor.rgb, rippleColor.rgb, blendAlpha);
    
    return half4(newColor, currentColor.a);
}
