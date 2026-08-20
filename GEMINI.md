# GEMINI.md - Development Guide for Google Gemini & Antigravity

This file provides instructions for Google Gemini / Antigravity CLI agents interacting with this repository.

---

## 📌 Repository Summary
`Heretek-AI/ROCmFPX-BUILDER` provides automated GitHub Actions CI/CD workflows producing portable, self-contained builds of **ROCmFPX** (`ciru-ai/ROCmFPX`) with built-in AMD ROCm™ 7 runtime libraries.

---

## 🏗️ Architecture Reference
- **CI Matrix**: Prepared in `prepare-matrix` step, parsing comma-separated targets into JSON for Windows (`windows-2022`) and Linux (`ubuntu-22.04`).
- **ROCm Download**: Dynamically parses TheRock multi-arch nightly index from `https://rocm.nightlies.amd.com/tarball-multi-arch/`.
- **Packaging**: DLLs and BLAS libraries are bundled into `build/bin` on Windows; `.so` files and BLAS libraries are copied on Linux with `patchelf --set-rpath '$ORIGIN'`.
- **Releases**: Auto-generates sequential `b####` tags and creates releases with GitHub CLI.

---

## 🧪 Verification Steps
1. Verify Python files with `python3 -m py_compile <file>`.
2. Check all workflow and template YAML files using Python `yaml.safe_load`.
3. Check `git status` before committing.
