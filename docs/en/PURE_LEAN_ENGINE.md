# 100% Pure Lean 4 Inference Engine

Pakila features a "Pure Engine" that completes all stages of inference within Lean 4.

## Eliminating External Dependencies
Previous versions utilized Rust's `candle` library, which has been completely deprecated for the following reasons:
1. **Build Uncertainty**: To prevent environment instability caused by Rust compiler versions or C++ shared library linking errors.
2. **Boundary Opacity**: To ensure mathematical proofs remain unbroken across the entire execution path by keeping memory management and bit manipulation under Lean's governance.

## Pure Components Implemented
- **GGUF Parser**: Directly parses headers, metadata, and tensor info from `ByteArray`.
- **Dequantizer**: Expands quantized bitstreams (such as Q4_0 4-bit) into Float arrays within pure Lean functions.
- **Base64**: Custom implementation for multimodal protocols, requiring no external commands.
- **System Info**: Directly reads from the `/proc` filesystem to monitor its own resource status.

## Bridge to Physical Acceleration
Pure Lean 4 code is safely "sublimated" into self-generated AVX-512 kernels at compile time. This maintains pure logic while achieving performance that surpasses native C++.
