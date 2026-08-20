# ROCmFPX Automated Builds

<a href="https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest" title="Download the latest release">
  <img src="https://img.shields.io/github/v/release/Heretek-AI/ROCmFPX-BUILDER?logo=github&logoColor=white" alt="GitHub release (latest by date)" />
</a>
<a href="https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest" title="View latest release date">
  <img src="https://img.shields.io/github/release-date/Heretek-AI/ROCmFPX-BUILDER?logo=github&logoColor=white" alt="Latest release date" />
</a>
<a href="LICENSE" title="View license">
  <img src="https://img.shields.io/github/license/Heretek-AI/ROCmFPX-BUILDER?logo=opensourceinitiative&logoColor=white&cacheBust=1" alt="License" />
</a>
<a href="https://github.com/ROCm/ROCm" title="Powered by ROCm 7.0">
  <img src="https://img.shields.io/badge/ROCm-7.0-blue?logo=amd&logoColor=white" alt="ROCm 7.0" />
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

---

We provide automated nightly and on-demand builds of [**ROCmFPX** (`ciru-ai/ROCmFPX`)](https://github.com/ciru-ai/ROCmFPX) with **AMD ROCm™ 7** acceleration based on [TheRock](https://github.com/ROCm/TheRock).

ROCmFPX is Ciru's inference framework featuring specialized low-bit quantization formats (**ROCmFP2**, **ROCmFP3**, **ROCmFP4**, **ROCmFP6**, **ROCmFP7 DualView**, **ROCmFP8**), specialized HIP kernels, PromptForge serving runtimes, and fast inference on AMD hardware.

> [!IMPORTANT]  
> **All builds include ROCm™ 7 built-in** — complete runtime libraries and BLAS kernels are bundled directly into the archives. No separate ROCm™ driver/SDK installation is required on Windows or Linux!

---

## 🎯 Supported Devices

This build pipeline targets all major AMD GPU architectures:
- **gfx1151** (STX Halo APU) — Ryzen AI MAX+ Pro 395, Radeon 8060S
- **gfx1150** (STX Point APU) — Ryzen AI 300 Series
- **gfx120X** (RDNA4 GPUs) — AMD Radeon RX 9070 XT / 9070 / 9060 XT / 9060
- **gfx110X** (RDNA3 GPUs) — AMD Radeon dGPUs: PRO W7900/W7800/W7700/W7600, RX 7900 XTX/XT/GRE, RX 7800 XT, RX 7700 XT, RX 7600 XT; iGPUs: Radeon 780M/760M/740M
- **gfx103X** (RDNA2 GPUs) — AMD Radeon dGPUs: RX 6950 XT, 6900 XT, 6800 XT/6800, RX 6700 XT, RX 6600 XT, RX 6500 XT
- **gfx90a** (CDNA2 GPUs) — AMD Instinct MI210 / MI250
- **gfx908** (CDNA1 GPUs) — AMD Instinct MI100

---

## 🚀 Automated Builds

Our automated GitHub Actions workflow creates nightly builds for:
- **Windows** and **Ubuntu Linux**
- **7 GPU Target Families**: `gfx1151`, `gfx1150`, `gfx120X`, `gfx110X`, `gfx103X`, `gfx90a`, `gfx908`
- **ROCm™ 7 Built-in**: Full runtime libraries and BLAS support

| GPU Target | Target Architecture | Ubuntu (x64) | Windows (x64) |
|---|---|---|---|
| **gfx1151** | Strix Halo (Ryzen AI MAX+ 395) | [![Download Ubuntu gfx1151](https://img.shields.io/badge/Download-Ubuntu%20gfx1151-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx1151](https://img.shields.io/badge/Download-Windows%20gfx1151-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx1150** | Strix Point (Ryzen AI 300) | [![Download Ubuntu gfx1150](https://img.shields.io/badge/Download-Ubuntu%20gfx1150-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx1150](https://img.shields.io/badge/Download-Windows%20gfx1150-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx120X** | RDNA4 (RX 9070 XT / 9070) | [![Download Ubuntu gfx120X](https://img.shields.io/badge/Download-Ubuntu%20gfx120X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx120X](https://img.shields.io/badge/Download-Windows%20gfx120X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx110X** | RDNA3 (RX 7900 XTX / 7800 XT / 780M) | [![Download Ubuntu gfx110X](https://img.shields.io/badge/Download-Ubuntu%20gfx110X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx110X](https://img.shields.io/badge/Download-Windows%20gfx110X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx103X** | RDNA2 (RX 6800 XT / 6700 XT) | [![Download Ubuntu gfx103X](https://img.shields.io/badge/Download-Ubuntu%20gfx103X-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx103X](https://img.shields.io/badge/Download-Windows%20gfx103X-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx90a** | CDNA2 (Instinct MI210 / MI250) | [![Download Ubuntu gfx90a](https://img.shields.io/badge/Download-Ubuntu%20gfx90a-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx90a](https://img.shields.io/badge/Download-Windows%20gfx90a-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |
| **gfx908** | CDNA1 (Instinct MI100) | [![Download Ubuntu gfx908](https://img.shields.io/badge/Download-Ubuntu%20gfx908-blue)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) | [![Download Windows gfx908](https://img.shields.io/badge/Download-Windows%20gfx908-green)](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest) |

> **Linux (gfx1150/gfx1151 APU):** If you experience OOM despite free VRAM, add `ttm.pages_limit=12582912` (48 GB) to your kernel command line (e.g. GRUB), run `sudo update-grub`, then reboot.

---

## ⚡ ROCmFPX Format Family

ROCmFPX provides native support for ultra-low-bit formats:

| Format | Block BPW | Description |
|---|---:|---|
| **`Q2_0_ROCMFPX`** | 2.50 | S40 2.5-bpw format with frozen codebook and HIP MMQ/MMVQ paths |
| **`Q3_0_ROCMFPX`** | 3.50 | 3.5-bpw format with scale search and packed execution paths |
| **`Q4_0_ROCMFP4` / `FAST`** | 4.50 / 4.25 | Original ROCmFP4 formats with HIP regression coverage |
| **`Q6_0_ROCMFPX`** | 6.50 | Strix quality recipes and tuned GPU execution |
| **`Q7_0_ROCMFPX`** | 7.50 | Signed Q7 format and stored representation for DualView |
| **`Q8_0_ROCMFPX`** | 8.25 | Reference and cross-backend precision baseline |

Quantize any model using `llama-quantize`:
```bash
llama-quantize source-model-BF16.gguf output-model-FP7.gguf Q7_0_ROCMFPX
```

---

## 🧪 Quick Smoketest

1. **Download** the archive for your OS and GPU target from [Releases](https://github.com/Heretek-AI/ROCmFPX-BUILDER/releases/latest).
2. **Extract** the zip file to your preferred folder.
3. **Run `llama-server` or `llama-cli`**:

```bash
# General GGUF Model
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

## 🏗️ Repository Structure

- **`.github/workflows/build-rocmfpx.yml`**: Matrix CI/CD pipeline for building, bundling, and releasing Windows & Ubuntu binaries.
- **`.github/workflows/test-rocmfpx.yml`**: CI/CD testing workflow for smoke testing release artifacts.
- **`.github/actions/test-rocmfpx-build/`**: Composite action for executing automated validation tests.
- **`utils/gather_required_libs.py`**: Dependency resolution utility to discover and copy missing shared libraries.
- **`docs/manual_instructions.md`**: Step-by-step instructions for building locally on Windows and Ubuntu.

---

## 📋 Manual Build Instructions

For building locally from source, see **[docs/manual_instructions.md](docs/manual_instructions.md)**.

---

## 📄 License

This builder repository is licensed under the [MIT License](LICENSE).
ROCmFPX is developed by Ciru ([ciru-ai/ROCmFPX](https://github.com/ciru-ai/ROCmFPX)) under the MIT License.
