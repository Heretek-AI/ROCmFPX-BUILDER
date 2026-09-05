# AI Agent Guidelines for ROCmFPX-BUILDER

This document provides context, architecture rules, and development standards for AI coding agents (such as Google Antigravity, Claude Code, Cursor, Copilot, etc.) working on this repository.

---

## 🎯 Repository Purpose & Architecture

**`Heretek-AI/ROCmFPX-BUILDER`** is an automated CI/CD build pipeline repository for:
1. [**ROCmFPX Upstream** (`charlie12345/ROCmFPX`)](https://github.com/charlie12345/ROCmFPX): Canonical, actively maintained upstream ROCm acceleration stack for `llama.cpp`.
2. [**Ciru-AI ROCmFPX** (`ciru-ai/ROCmFPX`)](https://github.com/ciru-ai/ROCmFPX): Ciru's specialized research fork featuring low-bit quantization formats (ROCmFP2..FP8, DualView Q7/Q8, PromptForge, Kairic Edge).
3. [**q38rocm** (`julianmb/q38rocm`)](https://github.com/julianmb/q38rocm): Dedicated Qwen 3.8 27B deployment stack on Strix Halo APU (`gfx1151`).
4. [**kingjones30 ROCmFPX** (`kingjones30/ROCmFPX`)](https://github.com/kingjones30/ROCmFPX): Fork adding 7 extended model architectures (Mellum, Instella, Ling-3.0/bailing-hybrid, Muse-Glimmer, Qwen4Exp, ZAYA, Cohere2MoE) with ROCmFP4/FP8.

All builds produce standalone, portable binary releases with built-in AMD ROCm™ 7 runtime libraries for Windows and Ubuntu Linux.

### Key Architecture Components:
1. **GitHub Actions Workflow (`.github/workflows/build-rocmfpx.yml`)**:
   - **Multi-Target Matrix**: Compiles for `gfx1151`, `gfx1150`, `gfx120X`, `gfx110X`, `gfx103X`, `gfx90a`, and `gfx908`.
   - **TheRock ROCm Toolchain**: Downloads nightly multi-arch tarballs from `https://rocm.nightlies.amd.com/tarball-multi-arch/`.
   - **Windows Builder (`windows-2022`)**: Pinned to Visual Studio 2022 (MSVC 14.4x) to avoid `<cmath>` constexpr collision with ROCm Clang in newer MSVC toolchains.
   - **Ubuntu Builder (`ubuntu-22.04`)**: Streams tarball directly to `/opt/rocm`, compiles using Clang HIP compiler, bundles ROCm `.so` dependencies, and sets portable RPATH (`$ORIGIN`) via `patchelf`.
   - **Automated Release**: Computes sequential `b####` tags and uploads `.zip` archives.
2. **Testing Action & Workflow (`.github/actions/test-rocmfpx-build`, `.github/workflows/test-rocmfpx.yml`)**:
   - Downloads artifacts and runs smoke tests with lightweight GGUF models.
3. **Utility Scripts (`utils/gather_required_libs.py`)**:
   - Discovers and copies missing dynamic libraries by inspecting runtime loader output.

---

## 📋 Code & Contribution Standards

When making changes to this codebase, follow these rules:

1. **Simplicity First**: Keep workflows and scripts minimal and declarative. Avoid introducing unnecessary dependencies or convoluted abstractions.
2. **Concise Code Comments**:
   - Keep comments brief (1-2 lines).
   - Explain *why* something non-obvious is done (e.g. MSVC version pin, target mapping), not *what* standard syntax does.
   - Use standard ASCII characters (avoid unicode arrows or em-dashes).
3. **Workflow Invariants**:
   - Target mapping must always map generic identifiers to their concrete hardware targets:
     - `gfx120X` -> `gfx1200;gfx1201`
     - `gfx110X` -> `gfx1100;gfx1101;gfx1102;gfx1103`
     - `gfx103X` -> `gfx1030;gfx1031;gfx1032;gfx1034`
     - `gfx1151` -> `gfx1151`
     - `gfx1150` -> `gfx1150`
   - ROCmFPX CMake builds require `-DGGML_HIP_FORCE_MMQ=ON` to enable the optimized low-bit MMQ/MMVQ paths.
4. **Verification**:
   - Always run `python3 -m py_compile` on Python files.
   - Validate YAML syntax on `.github/workflows/*.yml` before committing.

---

## 🛠️ Quick Commands

```bash
# Validate python utilities
python3 -m py_compile utils/gather_required_libs.py

# Check git status
git status

# Inspect GitHub Actions run history
gh run list --limit 10
```
