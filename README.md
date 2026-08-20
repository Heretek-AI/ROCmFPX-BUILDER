# ROCmFPX Automated Builds (AMD ROCm™ 7)

<div align="center">

<a href="https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest" title="Download the latest release">
  <img src="https://img.shields.io/github/v/release/Heretek-AI/ROCmFPX-BUILDER?logo=github&logoColor=white" alt="GitHub release (latest by date)" />
</a>
<a href="https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest" title="View latest release date">
  <img src="https://img.shields.io/github/release-date/Heretek-AI/ROCmFPX-BUILDER?logo=github&logoColor=white" alt="Latest release date" />
</a>
<a href="LICENSE" title="View license">
  <img src="https://img.shields.io/github/license/Heretek-AI/ROCmFPX-BUILDER?logo=opensourceinitiative&logoColor=white&cacheBust=1" alt="License" />
</a>
<a href="https://github.com/ROCm/ROCm" title="Powered by AMD ROCm 7.0">
  <img src="https://img.shields.io/badge/ROCm-7.0-blue?logo=amd&logoColor=white" alt="AMD ROCm 7.0" />
</a>
<a href="https://github.com/ciru-ai/ROCmFPX" title="Powered by ROCmFPX">
  <img src="https://img.shields.io/badge/⚡Powered%20by-ROCmFPX-blue?logo=amd&logoColor=white" alt="Powered by ROCmFPX" />
</a>
<a href="#-supported-devices" title="Platform support">
  <img src="https://img.shields.io/badge/OS-Windows%20%7C%20Ubuntu-0078D6?logo=windows&logoColor=white" alt="Platform: Windows | Ubuntu" />
</a>
<a href="#-supported-devices" title="GPU targets">
  <img src="https://img.shields.io/badge/GPU-gfx1151%20%7C%20gfx1150%20%7C%20gfx120X%20%7C%20gfx110X%20%7C%20gfx103X%20%7C%20gfx90a%20%7C%20gfx908-00B04F?logo=amd&logoColor=white" alt="GPU Targets" />
</a>

<p align="center">
  <b>High-performance automated nightly and on-demand builds of <a href="https://github.com/ciru-ai/ROCmFPX">ROCmFPX</a> with built-in AMD ROCm™ 7 runtime libraries for Windows & Ubuntu.</b>
</p>

</div>

---

## ⚡ What is ROCmFPX?

[**ROCmFPX** (`ciru-ai/ROCmFPX`)](https://github.com/ciru-ai/ROCmFPX) is Ciru's specialized high-performance AMD inference stack for low-bit quantization formats, mixed-precision execution, and GPU-accelerated runtime paths:
- **ROCmFP2** (2.50 bpw), **ROCmFP3** (3.50 bpw), **ROCmFP4 / FAST** (4.50 / 4.25 bpw), **ROCmFP6** (6.50 bpw), **ROCmFP7 DualView** (7.50 bpw), and **ROCmFP8** (8.25 bpw).
- **DualView Architecture**: Authoritative Q7 storage with zero-copy Q7-decode streaming and exact signed-Q8 prefill shadow for maximum throughput.
- **ActiveFPX PromptForge**: Prompt-specialized runtime featuring fused gate/up projections, merged QKV/Z projections, and shape-guarded routes on Strix Halo (`gfx1151`).
- **HIP/ROCm Acceleration**: Tailored MMQ and MMVQ execution paths tuned for AMD RDNA2, RDNA3, RDNA3.5, RDNA4, and CDNA architectures.

> [!IMPORTANT]  
> **⚡ Ready to Run — ROCm™ 7 Built-in**: All binaries include complete ROCm 7 runtime libraries, hipBLAS, rocBLAS, and hipBLASLt kernels. **No separate AMD ROCm™ SDK or driver installation is required on Windows or Linux!**

---

## 🎯 Supported AMD GPU Targets

| Target Code | GPU Architecture | Target Hardware / Devices |
|---|---|---|
| **`gfx1151`** | **Strix Halo APU** (RDNA3.5) | AMD Ryzen AI MAX+ Pro 395, Ryzen AI MAX 390, Radeon 8060S |
| **`gfx1150`** | **Strix Point APU** (RDNA3.5) | AMD Ryzen AI 9 HX 370, Ryzen AI 9 365, Radeon 890M / 880M |
| **`gfx120X`** | **RDNA4 dGPUs** | AMD Radeon RX 9070 XT, RX 9070 GRE, RX 9070, RX 9060 XT, RX 9060 |
| **`gfx110X`** | **RDNA3 dGPUs & iGPUs** | Radeon PRO W7900 / W7800 / W7700 / W7600, RX 7900 XTX / XT / GRE, RX 7800 XT, RX 7700 XT, RX 7600 XT, Radeon 780M / 760M |
| **`gfx103X`** | **RDNA2 dGPUs** | AMD Radeon RX 6950 XT, RX 6900 XT, RX 6800 XT / 6800, RX 6700 XT, RX 6600 XT, RX 6500 XT |
| **`gfx90a`** | **CDNA2 Accelerators** | AMD Instinct MI210, MI250, MI250X |
| **`gfx908`** | **CDNA1 Accelerators** | AMD Instinct MI100 |

---

## 🚀 Download Release Binaries

Automated GitHub Actions builds are published nightly and on every release:

| GPU Target | Architecture Family | Ubuntu Linux (x64) | Windows (x64) |
|---|---|---|---|
| **gfx1151** | Strix Halo (Ryzen AI MAX+ 395) | [![Download Ubuntu gfx1151](https://img.shields.io/badge/Download-Ubuntu%20gfx1151-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx1151](https://img.shields.io/badge/Download-Windows%20gfx1151-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx1150** | Strix Point (Ryzen AI 300) | [![Download Ubuntu gfx1150](https://img.shields.io/badge/Download-Ubuntu%20gfx1150-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx1150](https://img.shields.io/badge/Download-Windows%20gfx1150-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx120X** | RDNA4 (RX 9070 XT / 9070) | [![Download Ubuntu gfx120X](https://img.shields.io/badge/Download-Ubuntu%20gfx120X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx120X](https://img.shields.io/badge/Download-Windows%20gfx120X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx110X** | RDNA3 (RX 7900 XTX / 7800 XT / 780M) | [![Download Ubuntu gfx110X](https://img.shields.io/badge/Download-Ubuntu%20gfx110X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx110X](https://img.shields.io/badge/Download-Windows%20gfx110X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx103X** | RDNA2 (RX 6800 XT / 6700 XT) | [![Download Ubuntu gfx103X](https://img.shields.io/badge/Download-Ubuntu%20gfx103X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx103X](https://img.shields.io/badge/Download-Windows%20gfx103X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx90a** | CDNA2 (Instinct MI210 / MI250) | [![Download Ubuntu gfx90a](https://img.shields.io/badge/Download-Ubuntu%20gfx90a-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx90a](https://img.shields.io/badge/Download-Windows%20gfx90a-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx908** | CDNA1 (Instinct MI100) | [![Download Ubuntu gfx908](https://img.shields.io/badge/Download-Ubuntu%20gfx908-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx908](https://img.shields.io/badge/Download-Windows%20gfx908-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |

> **Linux (gfx1150/gfx1151 APU):** If you experience OOM errors despite free VRAM, add `ttm.pages_limit=12582912` (48 GB) to your kernel command line (e.g. GRUB), run `sudo update-grub`, and reboot.

---

## 📦 ROCmFPX Format Catalog

ROCmFPX introduces dedicated GGUF low-bit quantization formats optimized for ROCm MMQ/MMVQ kernels:

| Format | Block BPW | Implementation & Features |
|---|---:|---|
| **`Q2_0_ROCMFPX`** | 2.50 | S40 2.50-bpw format with frozen codebook and HIP MMQ/MMVQ dispatch |
| **`Q3_0_ROCMFPX`** | 3.50 | 3.50-bpw format with scale-search and packed execution paths |
| **`Q4_0_ROCMFP4` / `FAST`** | 4.50 / 4.25 | Original ROCmFP4 formats with regression coverage and serving stability |
| **`Q6_0_ROCMFPX`** | 6.50 | Strix quality recipes with optimized HIP/ROCm GPU execution |
| **`Q7_0_ROCMFPX`** | 7.50 | Signed Q7 format and stored representation for DualView |
| **`Q8_0_ROCMFPX`** | 8.25 | Reference precision and cross-backend baseline |

Quantize any model using `llama-quantize`:
```bash
llama-quantize source-model-BF16.gguf output-model-FP7.gguf Q7_0_ROCMFPX
```

---

## 🧪 Quick Smoketest & Usage

1. **Download** the zip archive matching your GPU from [Releases](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest).
2. **Extract** the archive to any directory.
3. **Run `llama-server` or `llama-cli`**:

```bash
# Start llama-server with all GPU layers offloaded
llama-server -m YOUR_MODEL.gguf -ngl 99
```

### Running DualView Models (e.g. Ornith 35B):
```bash
export GGML_ROCM_GFX1151_Q7_Q8_VIEW=no-output
export GGML_HIP_ENABLE_UNIFIED_MEMORY=1

./llama-server \
  -m Ornith1.0-35b-CIRU-DUALVIEW-FPX7+Q8-MTP.gguf \
  --host 127.0.0.1 --port 8080 \
  -dev ROCm0 -sm none -ngl 999 -fa on \
  -n 16384 -c 131072 -b 2048 -ub 512 -t 16 -tb 16 \
  -ctk f16 -ctv f16 --parallel 1 --metrics --mmap --no-repack
```

---

## 🏗️ Repository Overview

- **`.github/workflows/build-rocmfpx.yml`**: Multi-platform matrix build pipeline downloading TheRock ROCm toolchain and publishing release archives.
- **`.github/workflows/test-rocmfpx.yml`**: Standalone testing workflow for verifying release artifacts.
- **`.github/actions/test-rocmfpx-build/`**: Composite testing action for model inference and GPU offload validation.
- **`utils/gather_required_libs.py`**: Dynamic dependency discovery utility.
- **`docs/manual_instructions.md`**: Step-by-step local compilation guide.
- **`AGENTS.md`** / **`CLAUDE.md`** / **`GEMINI.md`**: Guidelines for AI coding agents.

---

## 📄 License

This builder pipeline is licensed under the [MIT License](LICENSE).  
ROCmFPX is developed by Ciru ([ciru-ai/ROCmFPX](https://github.com/ciru-ai/ROCmFPX)) under the MIT License.
Llama.cpp is developed by Georgi Gerganov and contributors under the MIT License.
