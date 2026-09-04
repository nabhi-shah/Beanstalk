#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

[[ stitchable ]] half4 lightRipple(float2 position, half4 currentColor, float2 touchPos, float time, float2 size, half4 rippleColor) {
    // 1. Instant early exit: if ripple is inactive, pixel is transparent, or ripple has no alpha
    if (time >= 1.0f || time < 0.0f || currentColor.a <= 0.001h || rippleColor.a <= 0.001h) {
        return currentColor;
    }
    
    // 2. Precompute wave parameters in native FP16 on Apple Silicon (2x throughput vs FP32)
    half hTime = half(time);
    half fade = 1.0h - hTime;
    
    // Fast hardware distance calculations
    half distance = half(fast::distance(position, touchPos));
    half maxDist = half(fast::length(size));
    half waveRadius = hTime * maxDist * 1.3h;
    
    // Wave width and precomputed reciprocal for single-cycle multiplication (replaces 3 divisions)
    half waveWidth = max(maxDist * 0.22h, 24.0h);
    half invWaveWidth = 1.0h / waveWidth;
    
    half distFromWave = distance - waveRadius;
    
    // 3. Spatial bounding exit: if pixel is outside the wave crest envelope, skip all further math
    if (abs(distFromWave) > waveWidth * 1.2h) {
        return currentColor;
    }
    
    // 4. Subtle chromatic aberration split using fast smoothstep and reciprocal multiplication
    half split = 1.0h;
    half valR = abs(distFromWave - split) * invWaveWidth;
    half intensityR = smoothstep(1.0h, 0.0h, valR);
    
    half valG = abs(distFromWave) * invWaveWidth;
    half intensityG = smoothstep(1.0h, 0.0h, valG);
    
    half valB = abs(distFromWave + split) * invWaveWidth;
    half intensityB = smoothstep(1.0h, 0.0h, valB);
    
    // 5. Soft, subtle specular highlight at the wave crest
    half valS = abs(distFromWave) * (invWaveWidth * 6.6667h); // 1.0 / 0.15 = ~6.6667
    half specular = smoothstep(1.0h, 0.0h, valS) * 0.10h;
    
    // 6. Base envelope & early exit if imperceptible (balanced power for visible yet elegant ripple)
    half envelope = max(max(intensityR, intensityG), intensityB);
    half blendAlpha = envelope * fade * rippleColor.a * 0.6h;
    
    if (blendAlpha <= 0.001h) {
        return currentColor;
    }
    
    // 7. Chromatic light color tinting
    half3 chromaticLight = half3(intensityR, intensityG, intensityB);
    chromaticLight = mix(chromaticLight, rippleColor.rgb, 0.6h);
    chromaticLight += half3(specular);
    chromaticLight = clamp(chromaticLight, 0.0h, 1.0h);
    
    // 8. Blend the shiny chromatic ripple over the current color
    half3 newColor = mix(currentColor.rgb, chromaticLight, clamp(blendAlpha, 0.0h, 1.0h));
    half newAlpha = clamp(currentColor.a + blendAlpha, 0.0h, 1.0h);
    
    return half4(newColor, newAlpha);
}
