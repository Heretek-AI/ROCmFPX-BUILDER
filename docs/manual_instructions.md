# 🔧 Manual Build Instructions for ROCmFPX + ROCm

> **⚠️ Important Notice**
> 
> These manual build instructions are provided for reference purposes and local development.
> 
> For the most reliable and automated build process, please refer to our [GitHub Actions build workflow](../.github/workflows/build-rocmfpx.yml).

---

## Operating Systems:
- [🪟 Windows Build Instructions](#windows-build-instructions)
- [🐧 Ubuntu Build Instructions](#ubuntu-build-instructions)
- [🎯 GPU Target Reference](#gpu-target-reference)
- [🧪 Testing & ROCmFPX Flags](#testing--rocmfpx-flags)

---

## 🪟 Windows Build Instructions

### Part 1: Install Required Software
Using Chocolatey (or install manually):
```powershell
choco install visualstudio2022buildtools -y --params "--add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.CMake.Project --add Microsoft.VisualStudio.Component.VC.ATL --add Microsoft.VisualStudio.Component.Windows11SDK.22621"
choco install cmake --version=3.31.0 -y
choco install ninja -y
choco install strawberryperl -y
choco install git -y
```

### Part 2: Obtain ROCm Nightly (TheRock)
1. Check the multi-arch tarball index at [https://rocm.nightlies.amd.com/tarball-multi-arch/](https://rocm.nightlies.amd.com/tarball-multi-arch/)
2. Download the Windows tarball for your target architecture (e.g., `therock-dist-windows-gfx1151-<version>.tar.gz` or `therock-dist-windows-gfx110X-all-<version>.tar.gz`).
3. Extract the contents to `C:\opt\rocm`:
   ```powershell
   New-Item -ItemType Directory -Force -Path "C:\opt\rocm"
   tar -xzf <filename>.tar.gz -C C:\opt\rocm --strip-components=1
   ```

### Part 3: Clone ROCmFPX
```powershell
git clone --depth 1 https://github.com/ciru-ai/ROCmFPX.git
cd ROCmFPX
```

### Part 4: Configure and Build
Open `x64 Native Tools Command Prompt for VS 2022`:
```cmd
set HIP_PATH=C:\opt\rocm
set HIP_PLATFORM=amd
set PATH=%HIP_PATH%\lib\llvm\bin;%HIP_PATH%\bin;%PATH%

mkdir build
cd build

cmake .. -G Ninja ^
  -DCMAKE_C_COMPILER="C:\opt\rocm\lib\llvm\bin\clang.exe" ^
  -DCMAKE_CXX_COMPILER="C:\opt\rocm\lib\llvm\bin\clang++.exe" ^
  -DCMAKE_CXX_FLAGS="-IC:\opt\rocm\include" ^
  -DCMAKE_CROSSCOMPILING=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DGPU_TARGETS="gfx1151" ^
  -DBUILD_SHARED_LIBS=ON ^
  -DLLAMA_BUILD_TESTS=OFF ^
  -DGGML_HIP=ON ^
  -DGGML_HIP_FORCE_MMQ=ON ^
  -DGGML_OPENMP=OFF ^
  -DGGML_CUDA_FORCE_CUBLAS=OFF ^
  -DGGML_RPC=ON ^
  -DGGML_HIP_ROCWMMA_FATTN=OFF ^
  -DLLAMA_BUILD_BORINGSSL=ON ^
  -DGGML_NATIVE=OFF ^
  -DGGML_STATIC=OFF ^
  -DCMAKE_SYSTEM_NAME=Windows

cmake --build . -j %NUMBER_OF_PROCESSORS%
```

### Part 5: Copy ROCm Runtime DLLs
Copy the required DLLs and kernel library folders into `build\bin`:
```powershell
$bin = "bin"
$rocmBin = "C:\opt\rocm\bin"
Copy-Item "$rocmBin\amdhip64_*.dll" $bin
Copy-Item "$rocmBin\rocm_kpack.dll" $bin
Copy-Item "$rocmBin\amd_comgr*.dll" $bin
Copy-Item "$rocmBin\libhipblas.dll" $bin
Copy-Item "$rocmBin\rocblas.dll" $bin
Copy-Item "$rocmBin\rocsolver.dll" $bin
Copy-Item "$rocmBin\hipblaslt.dll" $bin
Copy-Item "$rocmBin\origami.dll" $bin
Copy-Item "$rocmBin\rocblas\library" "$bin\rocblas\library" -Recurse -Force
Copy-Item "$rocmBin\hipblaslt\library" "$bin\hipblaslt\library" -Recurse -Force
```

---

## 🐧 Ubuntu Build Instructions

### Part 1: Install Required Software
```bash
sudo apt update
sudo apt install -y build-essential cmake ninja-build git curl patchelf
```

### Part 2: Obtain ROCm Nightly (TheRock)
Download and extract ROCm directly to `/opt/rocm`:
```bash
# E.g. For Strix Halo (gfx1151) or RDNA3 (gfx110X-all)
sudo mkdir -p /opt/rocm
curl -sL "https://rocm.nightlies.amd.com/tarball-multi-arch/therock-dist-linux-gfx1151-latest.tar.gz" | sudo tar --use-compress-program=gzip -xf - -C /opt/rocm --strip-components=1
```

Set up ROCm environment variables:
```bash
export HIP_PATH=/opt/rocm
export ROCM_PATH=/opt/rocm
export HIP_PLATFORM=amd
export HIP_CLANG_PATH=/opt/rocm/llvm/bin
export HIP_INCLUDE_PATH=/opt/rocm/include
export HIP_LIB_PATH=/opt/rocm/lib
export PATH=/opt/rocm/bin:/opt/rocm/llvm/bin:$PATH
export LD_LIBRARY_PATH=/opt/rocm/lib:/opt/rocm/lib64:/opt/rocm/llvm/lib:${LD_LIBRARY_PATH:-}
```

### Part 3: Clone ROCmFPX
```bash
git clone --depth 1 https://github.com/ciru-ai/ROCmFPX.git
cd ROCmFPX
```

### Part 4: Configure and Build
```bash
mkdir build
cd build

cmake .. -G Ninja \
  -DCMAKE_C_COMPILER=/opt/rocm/llvm/bin/clang \
  -DCMAKE_CXX_COMPILER=/opt/rocm/llvm/bin/clang++ \
  -DCMAKE_CXX_FLAGS="-I/opt/rocm/include" \
  -DCMAKE_CROSSCOMPILING=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DGPU_TARGETS="gfx1151" \
  -DBUILD_SHARED_LIBS=ON \
  -DLLAMA_BUILD_TESTS=OFF \
  -DGGML_HIP=ON \
  -DGGML_HIP_FORCE_MMQ=ON \
  -DGGML_OPENMP=OFF \
  -DGGML_CUDA_FORCE_CUBLAS=OFF \
  -DGGML_RPC=ON \
  -DGGML_HIP_ROCWMMA_FATTN=OFF \
  -DLLAMA_BUILD_BORINGSSL=ON \
  -DGGML_NATIVE=OFF \
  -DGGML_STATIC=OFF \
  -DCMAKE_SYSTEM_NAME=Linux

cmake --build . -j $(nproc)
```

### Part 5: Copy ROCm Runtime Libraries & Patch RPATH
```bash
cd bin

# Copy BLAS kernel folders
mkdir -p rocblas hipblaslt
cp -r /opt/rocm/lib/rocblas/library rocblas/
cp -r /opt/rocm/lib/hipblaslt/library hipblaslt/

# Copy required runtime libraries
cp -v /opt/rocm/lib/lib*.so* . 2>/dev/null || true
cp -v /opt/rocm/lib/rocm_sysdeps/lib/lib*.so* . 2>/dev/null || true
cp -v /opt/rocm/lib/llvm/lib/lib*.so* . 2>/dev/null || true

# Set portable RPATH ($ORIGIN)
for file in *.so* llama-*; do
  [ -f "$file" ] && [ ! -L "$file" ] && patchelf --set-rpath '$ORIGIN' "$file" 2>/dev/null || true
done
```

---

## 🎯 GPU Target Reference

Set `-DGPU_TARGETS` based on your hardware:

| Architecture Family | GPU Target Parameter | Target Devices |
|---|---|---|
| **Strix Halo (APU)** | `-DGPU_TARGETS="gfx1151"` | Ryzen AI MAX+ Pro 395, Radeon 8060S |
| **Strix Point (APU)** | `-DGPU_TARGETS="gfx1150"` | Ryzen AI 300 Series |
| **RDNA4** | `-DGPU_TARGETS="gfx1200;gfx1201"` | Radeon RX 9070 XT / 9070 / 9060 XT |
| **RDNA3** | `-DGPU_TARGETS="gfx1100;gfx1101;gfx1102;gfx1103"` | RX 7900 XTX/XT/GRE, 7800 XT, 7700 XT, 7600 XT, Radeon 780M |
| **RDNA2** | `-DGPU_TARGETS="gfx1030;gfx1031;gfx1032;gfx1034"` | RX 6950 XT, 6900 XT, 6800 XT, 6700 XT, 6600 XT |
| **CDNA2** | `-DGPU_TARGETS="gfx90a"` | AMD Instinct MI210 / MI250 |
| **CDNA1** | `-DGPU_TARGETS="gfx908"` | AMD Instinct MI100 |

---

## 🧪 Testing & ROCmFPX Flags

### Quantization with ROCmFPX formats:
```bash
./llama-quantize source-BF16.gguf output-FP2.gguf Q2_0_ROCMFPX
./llama-quantize source-BF16.gguf output-FP3.gguf Q3_0_ROCMFPX
./llama-quantize source-BF16.gguf output-FP4.gguf Q4_0_ROCMFP4
./llama-quantize source-BF16.gguf output-FP6.gguf Q6_0_ROCMFPX
./llama-quantize source-BF16.gguf output-FP7.gguf Q7_0_ROCMFPX
./llama-quantize source-BF16.gguf output-FP8.gguf Q8_0_ROCMFPX
```

### Running DualView Models:
```bash
export GGML_ROCM_GFX1151_Q7_Q8_VIEW=no-output
export GGML_HIP_ENABLE_UNIFIED_MEMORY=1

./llama-server -m Ornith1.0-35b-CIRU-DUALVIEW-FPX7+Q8-MTP.gguf -ngl 99
```
