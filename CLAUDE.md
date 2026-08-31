# CLAUDE.md - Development Guide for Claude Code

This file contains quick reference instructions for Anthropic's Claude Code / Claude CLI when working in this repository.

---

## 📌 Project Overview
- **Repository**: `Heretek-AI/ROCmFPX-BUILDER` is an automated CI/CD pipeline repository for pre-compiling and packaging standalone, portable binaries with embedded AMD ROCm 7 runtime libraries for:
1. **ROCmFPX (Upstream)** (`charlie12345/ROCmFPX`): The canonical upstream engine.
2. **Ciru-AI ROCmFPX** (`ciru-ai/ROCmFPX`): Specialized research fork (DualView, PromptForge, Kairic Edge).
3. **q38rocm** (`julianmb/q38rocm`): Dedicated Qwen 3.8 27B Strix Halo engine.
- **Upstream Target**: [https://github.com/ciru-ai/ROCmFPX](https://github.com/ciru-ai/ROCmFPX)

---

## 🛠️ Key Files
- `.github/workflows/build-rocmfpx.yml`: Main build, library bundling, and release workflow.
- `.github/workflows/test-rocmfpx.yml`: Standalone test dispatch workflow.
- `.github/actions/test-rocmfpx-build/action.yml`: Smoke test composite action.
- `utils/gather_required_libs.py`: Missing shared library gatherer.
- `docs/manual_instructions.md`: Step-by-step local compilation guide.
- `README.md`: User-facing documentation, hardware tables, and release links.
- `AGENTS.md`: Detailed agent architecture guide.

---

## 🧪 Validation Commands
```bash
# Validate Python scripts
python3 -m py_compile utils/gather_required_libs.py

# Validate YAML syntax
python3 -c "import yaml, glob; [yaml.safe_load(open(f)) for f in glob.glob('.github/**/*.yml', recursive=True)]"

# Check GitHub Actions status
gh workflow list
```

---

## 📝 Conventions
- Keep inline comments concise and focused on rationale.
- Maintain target mapping consistency (`gfx1151`, `gfx1150`, `gfx120X`, `gfx110X`, `gfx103X`, `gfx90a`, `gfx908`).
- For any CMake changes, ensure `-DGGML_HIP_FORCE_MMQ=ON` is preserved for ROCmFPX low-bit execution.
