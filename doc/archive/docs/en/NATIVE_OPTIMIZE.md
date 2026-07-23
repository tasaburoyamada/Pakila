# Native Optimization: AVX-512 Auto-Generation

Pakila and LeanTensor leverage Lean 4's metaprogramming capabilities to achieve physical performance limits.

## #compile_native Macro
We have implemented custom macros that generate optimized C code directly from the mathematical definitions of tensor operations (like MatMul).
- **SIMD Utilization**: Targets the Intel AVX-512 instruction set, processing 512-bit registers (zmm) in a single pass.
- **FMA Path**: Automatically applies Fused Multiply-Add instructions (`_mm512_fmadd_pd`) to execute dot products in a single cycle.

## Universal Fallback
While we pursue maximum speed, we do not sacrifice compatibility.
- **Dynamic Detection**: Checks CPUID at runtime and automatically switches to generic C kernels if AVX-512 is unavailable.
- **Dual Safety**: Even if native execution fails, pure Lean mathematical code acts as the ultimate fail-safe.

## Lake Integration
The generated native code is automatically compiled and linked by the Lake build process. Users can obtain high-performance binaries simply by running `lake build`, without needing any special external tools.
