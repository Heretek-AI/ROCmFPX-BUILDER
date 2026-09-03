#!/usr/bin/env bash
# ==============================================================================
# run_yarn_1m.sh — High-Performance 1M Context Server for Qwen 3.8 27B with YaRN
# Scales 262K native context to 1,048,576 tokens using YaRN RoPE scaling.
# Engineered for AMD ROCm 7 / Strix Halo APU (Ryzen AI Max+ 395 / Radeon 8060S).
#
# Target model: Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf
#   arch = qwen35 (hybrid SSM + full-attention, M-RoPE, MTP head
#   nextn_predict_layers=1), native context_length = 262144.
#
# Refinement rationale (vs the naive launcher), grounded in build 244 (0fc9568):
#   * --override-kv uses qwen35.context_length — the old qwen2/qwen2vl/qwen3 keys
#     never matched the real arch, so n_ctx_train stayed 262144 and llama-server
#     silently capped the slot at it ("...exceeds the training context...capping").
#   * TurboQuant KV (q8_0 K / turbo4 V) — the upstream-validated long-context
#     recipe for this model family.
#   * MTP speculative decode: disabled by default for 1M context serving.
#     Speculative draft boundary mismatches (spec-boundary-mismatch) trigger
#     prompt-cache cold fallbacks (target-draft-restore-rejected), completely
#     erasing slot KV cache and wiping checkpoints, forcing multi-minute
#     prefill re-evaluations. Enable explicitly with --mtp if desired.
#   * RAM context checkpoints: 128 checkpoints @ 32 GiB (spaced every 2,048
#     tokens).
#     CRITICAL FOR HYBRID RECURRENT (qwen35): SSM layers cannot arbitrarily shift
#     KV cells. Checkpoints are the ONLY mechanism for context reuse. Dense 2K
#     checkpoints ensure any branching prompt or multi-turn chat rolls back in
#     ~0.2s and re-evaluates at most 2K tokens (~5s), avoiding full prompt cache
#     drops ("forcing full prompt re-processing due to lack of cache data").
#   * Physical micro-batch (ubatch) set to 2048 to match logical batch for peak
#     ROCm compute throughput during long-context prompt ingestion.
#   * Strix Halo env (HSA_OVERRIDE_GFX_VERSION, unified memory) + -dev ROCm0.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 1. Strix Halo environment (mirrors q38rocm/setup_env.sh)
# ------------------------------------------------------------------------------
export HSA_OVERRIDE_GFX_VERSION="${HSA_OVERRIDE_GFX_VERSION:-11.5.1}"   # gfx1151 ISA — Radeon 8060S only
export GGML_HIP_ENABLE_UNIFIED_MEMORY="${GGML_HIP_ENABLE_UNIFIED_MEMORY:-1}"
export ROCM_FLUSH_ACCEPT="${ROCM_FLUSH_ACCEPT:-1}"
export AMD_VULKAN_ICD="${AMD_VULKAN_ICD:-RADV}"
export RADV_PERFTEST="${RADV_PERFTEST:-gpl,sam,nggc}"

# ------------------------------------------------------------------------------
# 2. Defaults & Workload Profile Selection
# ------------------------------------------------------------------------------
DEVICE="${DEVICE:-auto}"               # auto = prefer Vulkan0 (RADV Wave64 34-36 tok/s), fallback ROCm0
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8800}"
MODEL_PATH="${MODEL_PATH:-}"
MMPROJ_PATH="${MMPROJ_PATH:-}"
NO_MMPROJ="${NO_MMPROJ:-1}"            # 1 = text-only inference (prevents CLIP unsupported op warnings)
NGL="${NGL:-99}"
NP="${NP:-1}"
PROFILE="${PROFILE:-1m}"

# Scan CLI arguments early to discover --profile before setting defaults
ARGS=("$@")
for ((i = 0; i < ${#ARGS[@]}; i++)); do
    if [ "${ARGS[$i]}" = "--profile" ] && ((i + 1 < ${#ARGS[@]})); then
        PROFILE="${ARGS[$((i + 1))]}"
        break
    fi
done

case "${PROFILE}" in
    speed)
        # Maximum decode speed (30–36 tok/s) via Vulkan0 + MTP (K=4, p=0.0) on native RoPE
        CTX="${CTX:-131072}"
        ROPE_SCALING="${ROPE_SCALING:-none}"
        MTP="${MTP:-1}"
        SPEC_DRAFT_N_MAX="${SPEC_DRAFT_N_MAX:-4}"
        SPEC_DRAFT_P_MIN="${SPEC_DRAFT_P_MIN:-0.0}"
        STRICT_MTP="${STRICT_MTP:-0}"
        BATCH_SIZE="${BATCH_SIZE:-2048}"
        UBATCH_SIZE="${UBATCH_SIZE:-1024}"
        TEMP="${TEMP:-0}"
        CACHE_PROMPT="${CACHE_PROMPT:-1}"
        CHECKPOINT_EVERY="${CHECKPOINT_EVERY:-2048}"
        CTX_CHECKPOINTS="${CTX_CHECKPOINTS:-128}"
        ;;
    agent)
        # Deterministic coding agents: strict MTP verification (34.82 tok/s) with cache isolation
        CTX="${CTX:-65536}"
        ROPE_SCALING="${ROPE_SCALING:-none}"
        MTP="${MTP:-1}"
        SPEC_DRAFT_N_MAX="${SPEC_DRAFT_N_MAX:-4}"
        SPEC_DRAFT_P_MIN="${SPEC_DRAFT_P_MIN:-0.0}"
        STRICT_MTP="${STRICT_MTP:-1}"
        BATCH_SIZE="${BATCH_SIZE:-2048}"
        UBATCH_SIZE="${UBATCH_SIZE:-1024}"
        TEMP="${TEMP:-0}"
        CACHE_PROMPT="${CACHE_PROMPT:-0}"
        CHECKPOINT_EVERY="${CHECKPOINT_EVERY:-2048}"
        CTX_CHECKPOINTS="${CTX_CHECKPOINTS:-0}"
        ;;
    cache)
        # Multi-turn conversational chat with deep prompt caching and dense checkpoints (MTP off)
        CTX="${CTX:-131072}"
        ROPE_SCALING="${ROPE_SCALING:-none}"
        MTP="${MTP:-0}"
        BATCH_SIZE="${BATCH_SIZE:-2048}"
        UBATCH_SIZE="${UBATCH_SIZE:-2048}"
        TEMP="${TEMP:-0}"
        CACHE_PROMPT="${CACHE_PROMPT:-1}"
        CHECKPOINT_EVERY="${CHECKPOINT_EVERY:-2048}"
        CTX_CHECKPOINTS="${CTX_CHECKPOINTS:-128}"
        ;;
    1m|yarn|*)
        PROFILE="1m"
        CTX="${CTX:-1048576}"          # 1M context via YaRN 4x on 262K native base
        ROPE_SCALING="${ROPE_SCALING:-yarn}"
        ROPE_SCALE="${ROPE_SCALE:-4.0}"
        YARN_ORIG_CTX="${YARN_ORIG_CTX:-262144}"
        YARN_EXT_FACTOR="${YARN_EXT_FACTOR:--1}"
        YARN_ATTN_FACTOR="${YARN_ATTN_FACTOR:-1.0}"
        YARN_BETA_SLOW="${YARN_BETA_SLOW:-1}"
        YARN_BETA_FAST="${YARN_BETA_FAST:-32}"
        MTP="${MTP:-0}"
        SPEC_DRAFT_N_MAX="${SPEC_DRAFT_N_MAX:-4}"
        SPEC_DRAFT_P_MIN="${SPEC_DRAFT_P_MIN:-0.0}"
        STRICT_MTP="${STRICT_MTP:-1}"
        BATCH_SIZE="${BATCH_SIZE:-2048}"
        UBATCH_SIZE="${UBATCH_SIZE:-2048}"
        TEMP="${TEMP:-0}"
        CACHE_PROMPT="${CACHE_PROMPT:-1}"
        CHECKPOINT_EVERY="${CHECKPOINT_EVERY:-2048}"
        CTX_CHECKPOINTS="${CTX_CHECKPOINTS:-128}"
        ;;
esac

CACHE_TYPE_K="${CACHE_TYPE_K:-q8_0}"     # TurboQuant: Keys stay 8-bit (sharp attention routing)
CACHE_TYPE_V="${CACHE_TYPE_V:-turbo4}"   # TurboQuant: Values compressed to 4-bit
CACHE_TYPE_K_DRAFT="${CACHE_TYPE_K_DRAFT:-q8_0}"
CACHE_TYPE_V_DRAFT="${CACHE_TYPE_V_DRAFT:-turbo4}"
FLASH_ATTN="${FLASH_ATTN:-on}"
THREADS="${THREADS:-16}"
THREADS_BATCH="${THREADS_BATCH:-32}"
POLL="${POLL:-50}"
TOP_P="${TOP_P:-0.95}"
TOP_K="${TOP_K:-20}"
SPEC_DRAFT_N_MIN="${SPEC_DRAFT_N_MIN:-0}"
SPEC_DRAFT_P_SPLIT="${SPEC_DRAFT_P_SPLIT:-0.10}"
CACHE_RAM_MIB="${CACHE_RAM_MIB:-32768}"
SLOT_SAVE_PATH="${SLOT_SAVE_PATH:-${SCRIPT_DIR}/cache/slots}"
REASONING="${REASONING:-}"
REASONING_BUDGET="${REASONING_BUDGET:-}"
EXTRA_ARGS=()

# ------------------------------------------------------------------------------
# 3. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Usage: $(basename "$0") [options] [extra llama-server args...]

Launch Qwen 3.8 27B on AMD Strix Halo / Radeon 8060S with ROCmFP4 & TurboQuant.

Profiles:
  --profile speed            Maximum generation speed (30–36 tok/s via Vulkan0 + MTP K=4/p=0.0)
  --profile agent            Deterministic coding agents (34.82 tok/s strict MTP, cache isolated)
  --profile cache            Multi-turn conversation with deep prompt caching (MTP=0, dense checkpoints)
  --profile 1m               Full 1M context via YaRN 4x on 262K native base (default)

Options:
  -m, --model <path>         Path to Qwen 3.8 27B GGUF model file
  --mmproj <path>            Path to multimodal projector GGUF (optional, disabled by default)
  --auto-mmproj              Enable auto-detection of multimodal projector
  --device <dev>             Backend device: auto (default: Vulkan0 > ROCm0), Vulkan0, or ROCm0
  -p, --port <port>          Server port (default: 8800)
  -h, --host <host>          Server bind host (default: 0.0.0.0)
  -c, --ctx <size>           Context window size (profile default, or override)
  -ngl, --n-gpu-layers <n>   GPU offload layers (default: 99)
  -np, --parallel <n>        Parallel request slots (default: 1)
  --hip-device <n>           HIP_VISIBLE_DEVICES target (pins; else auto-detected to the 8060S)
  --cache-type-k <type>      KV cache Key quantization (default: q8_0)
  --cache-type-v <type>      KV cache Value quantization (default: turbo4)
  -b, --batch <size>         Logical batch size (default: 2048)
  -ub, --ubatch <size>       Physical/micro-batch size (default: 2048 or 1024)
  --mtp                      Enable MTP speculative decoding (K=4, p=0.0)
  --no-mtp                   Disable MTP speculative decoding
  --strict                   --spec-mtp-strict-qwen: greedy output matches no-spec
  --cache-ram <MiB>          Prompt-cache checkpoint RAM budget (default: 32768)
  --ctx-checkpoints <n>      Number of RAM context checkpoints (default: 128)
  --checkpoint-every <n>     Tokens between context checkpoints (default: 2048)
  --no-cache-prompt          Disable prompt caching / checkpoints
  --reasoning <on|off|auto>  Thinking mode (default: fork default)
  --reasoning-budget <n>     Thinking token budget (-1 = unlimited)
  --help                     Show this help message

Environment Variables:
  HSA_OVERRIDE_GFX_VERSION   ROCm gfx target (default: 11.5.1 — gfx1151, 8060S only)
  GGML_HIP_ENABLE_UNIFIED_MEMORY  Unified memory (default: 1)
  HIP_VISIBLE_DEVICES        HIP device index; auto-detected to the Radeon 8060S
                             when unset (--hip-device / setting it pins the choice)
  DEVICE, MODEL_PATH, MMPROJ_PATH, PORT, HOST, CTX  Launcher defaults

Example:
  $(basename "$0") -m /path/to/Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf --mmproj /path/to/mmproj-F16.gguf
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            exit 0
            ;;
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        -m|--model)
            MODEL_PATH="$2"
            shift 2
            ;;
        --mmproj)
            MMPROJ_PATH="$2"
            NO_MMPROJ=0
            shift 2
            ;;
        --auto-mmproj)
            NO_MMPROJ=0
            shift
            ;;
        --no-mmproj)
            NO_MMPROJ=1
            shift
            ;;
        --device)
            DEVICE="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -c|--ctx)
            CTX="$2"
            shift 2
            ;;
        -ngl|--n-gpu-layers)
            NGL="$2"
            shift 2
            ;;
        -np|--parallel)
            NP="$2"
            shift 2
            ;;
        --hip-device)
            export HIP_VISIBLE_DEVICES="$2"
            shift 2
            ;;
        --cache-type-k)
            CACHE_TYPE_K="$2"
            shift 2
            ;;
        --cache-type-v)
            CACHE_TYPE_V="$2"
            shift 2
            ;;
        -b|--batch)
            BATCH_SIZE="$2"
            shift 2
            ;;
        -ub|--ubatch)
            UBATCH_SIZE="$2"
            shift 2
            ;;
        --mtp)
            MTP=1
            shift
            ;;
        --no-mtp)
            MTP=0
            shift
            ;;
        --strict)
            STRICT_MTP=1
            shift
            ;;
        --cache-ram)
            CACHE_RAM_MIB="$2"
            shift 2
            ;;
        --ctx-checkpoints)
            CTX_CHECKPOINTS="$2"
            shift 2
            ;;
        --checkpoint-every)
            CHECKPOINT_EVERY="$2"
            shift 2
            ;;
        --no-cache-prompt)
            CACHE_PROMPT=0
            shift
            ;;
        --reasoning)
            REASONING="$2"
            shift 2
            ;;
        --reasoning-budget)
            REASONING_BUDGET="$2"
            shift 2
            ;;
        *)
            if [ -z "$MODEL_PATH" ] && [[ "$1" == *.gguf ]]; then
                MODEL_PATH="$1"
            else
                EXTRA_ARGS+=("$1")
            fi
            shift
            ;;
    esac
done

# ------------------------------------------------------------------------------
# 4. Resolve Binary Path
# ------------------------------------------------------------------------------
LLAMA_SERVER_BIN="${LLAMA_SERVER_BIN:-}"
if [ -z "$LLAMA_SERVER_BIN" ]; then
    if [ -x "/home/linuxbrew/.linuxbrew/opt/q38rocm/bin/llama-server" ]; then
        LLAMA_SERVER_BIN="/home/linuxbrew/.linuxbrew/opt/q38rocm/bin/llama-server"
    elif [ -x "/home/linuxbrew/.linuxbrew/opt/rocmfpx/bin/llama-server" ]; then
        LLAMA_SERVER_BIN="/home/linuxbrew/.linuxbrew/opt/rocmfpx/bin/llama-server"
    elif [ -x "/home/linuxbrew/.linuxbrew/opt/ciru-rocmfpx/bin/llama-server" ]; then
        LLAMA_SERVER_BIN="/home/linuxbrew/.linuxbrew/opt/ciru-rocmfpx/bin/llama-server"
    elif command -v llama-server >/dev/null 2>&1; then
        LLAMA_SERVER_BIN="$(command -v llama-server)"
    elif [ -x "${SCRIPT_DIR}/../build/bin/llama-server" ]; then
        LLAMA_SERVER_BIN="${SCRIPT_DIR}/../build/bin/llama-server"
    fi
fi

if [ -z "$LLAMA_SERVER_BIN" ] || [ ! -x "$LLAMA_SERVER_BIN" ]; then
    echo "❌ [ERROR] llama-server executable not found!" >&2
    echo "Please install q38rocm or rocmfpx via Homebrew: brew install Heretek-AI/tap/q38rocm" >&2
    echo "Or ensure llama-server is available in PATH." >&2
    exit 1
fi

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 4b. Backend Device Auto-Detection (Vulkan0 vs ROCm0)
#     On AMD Strix Halo, Mesa RADV Wave64 cooperative matrix (Vulkan0) achieves
#     34–36 tok/s with MTP, while ROCm0 reaches ~28 tok/s.
# ------------------------------------------------------------------------------
AVAILABLE_DEVICES="$("${LLAMA_SERVER_BIN}" --list-devices 2>/dev/null || true)"

detect_rocm_8060s() {
    "${LLAMA_SERVER_BIN}" --list-devices 2>/dev/null \
        | sed -nE 's/^[[:space:]]*ROCm([0-9]+):.*8060S.*/\1/p' | head -1
}

if [ "$DEVICE" = "auto" ]; then
    if echo "$AVAILABLE_DEVICES" | grep -q "Vulkan0"; then
        DEVICE="Vulkan0"
        DEVICE_MODE="auto-detected Mesa RADV Wave64 (Vulkan0)"
    elif echo "$AVAILABLE_DEVICES" | grep -q "ROCm0"; then
        DEVICE="ROCm0"
        DEVICE_MODE="auto-detected ROCm0"
    else
        DEVICE="ROCm0"
        DEVICE_MODE="default ROCm0"
    fi
else
    DEVICE_MODE="user-pinned ${DEVICE}"
fi

if [ "$DEVICE" = "ROCm0" ]; then
    if [ -z "${HIP_VISIBLE_DEVICES+x}" ]; then
        ROCM_APU_INDEX="$(detect_rocm_8060s)"
        if [ -n "$ROCM_APU_INDEX" ]; then
            export HIP_VISIBLE_DEVICES="${ROCM_APU_INDEX}"
            DEVICE_MODE="${DEVICE_MODE} (HIP_VISIBLE_DEVICES=${ROCM_APU_INDEX})"
        else
            echo "⚠️  [WARN] Could not auto-detect the Radeon 8060S in '${LLAMA_SERVER_BIN} --list-devices'." >&2
            echo "   Defaulting HIP_VISIBLE_DEVICES=0. HSA_OVERRIDE_GFX_VERSION=11.5.1 (gfx1151) only matches the 8060S." >&2
            export HIP_VISIBLE_DEVICES=0
            DEVICE_MODE="${DEVICE_MODE} (HIP_VISIBLE_DEVICES=0 fallback)"
        fi
    else
        DEVICE_MODE="${DEVICE_MODE} (HIP_VISIBLE_DEVICES pinned=${HIP_VISIBLE_DEVICES})"
    fi
fi

# ------------------------------------------------------------------------------
# 5. Resolve Model Path
# ------------------------------------------------------------------------------
CANDIDATE_MODELS=(
    "${MODEL_PATH}"
    "/home/ronin/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf"
    "/home/ronin/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-FAST.gguf"
    "${HOME}/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf"
    "${HOME}/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-FAST.gguf"
    "${HOME}/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf"
    "${HOME}/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/Qwen3.8-27B-ROCmFP4-FAST.gguf"
    "${SCRIPT_DIR}/../models/Qwen3.8-27B-ROCmFP4-STRIX_LEAN.gguf"
    "${SCRIPT_DIR}/../models/Qwen3.8-27B-ROCmFP4-FAST.gguf"
)

RESOLVED_MODEL=""
for candidate in "${CANDIDATE_MODELS[@]}"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        RESOLVED_MODEL="$candidate"
        break
    fi
done

if [ -z "$RESOLVED_MODEL" ]; then
    if [ -n "$MODEL_PATH" ]; then
        echo "❌ [ERROR] Specified model file not found at: $MODEL_PATH" >&2
    else
        echo "❌ [ERROR] No Qwen 3.8 27B model GGUF found in candidate search paths." >&2
        echo "Please specify the model path via -m /path/to/model.gguf or set MODEL_PATH." >&2
    fi
    exit 1
fi

# ------------------------------------------------------------------------------
# 6. Resolve Multimodal Projector (mmproj) Path (Optional)
#    NOTE: the HF repo ships no mmproj (text-only model); if a local
#    mmproj-F16.gguf is found it is attached, but disable with --no-mmproj.
# ------------------------------------------------------------------------------
RESOLVED_MMPROJ=""
if [ "${NO_MMPROJ}" != "1" ]; then
    CANDIDATE_MMPROJ=(
        "${MMPROJ_PATH}"
        "/home/ronin/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
        "${HOME}/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
        "${HOME}/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
        "$(dirname "${RESOLVED_MODEL}")/mmproj-F16.gguf"
        "${SCRIPT_DIR}/../models/mmproj-F16.gguf"
    )

    for candidate in "${CANDIDATE_MMPROJ[@]}"; do
        if [ -n "$candidate" ] && [ -f "$candidate" ]; then
            RESOLVED_MMPROJ="$candidate"
            break
        fi
    done
fi

# ------------------------------------------------------------------------------
# 7. Assemble Command & Launch
# ------------------------------------------------------------------------------
echo "================================================================================"
echo " 🚀 Starting Qwen 3.8 27B Server on AMD Strix Halo"
echo "================================================================================"
echo " Profile           : ${PROFILE}"
echo " Engine Binary     : ${LLAMA_SERVER_BIN}"
echo " Device Backend    : ${DEVICE} (${DEVICE_MODE})"
echo " Model             : ${RESOLVED_MODEL}"
[ -n "$RESOLVED_MMPROJ" ] && echo " MMProj            : ${RESOLVED_MMPROJ}" || echo " MMProj            : none (text-only)"
echo " Host / Port       : ${HOST}:${PORT}"
if [ "${ROPE_SCALING}" = "yarn" ]; then
    echo " Context Size      : ${CTX} tokens (YaRN ${ROPE_SCALE}x on ${YARN_ORIG_CTX} native base)"
    echo " RoPE Parameters   : scaling=${ROPE_SCALING} scale=${ROPE_SCALE} orig_ctx=${YARN_ORIG_CTX}"
else
    echo " Context Size      : ${CTX} tokens (native RoPE, no frequency dilation)"
fi
echo " KV Cache Format   : Key=${CACHE_TYPE_K}, Value=${CACHE_TYPE_V} (draft: ${CACHE_TYPE_K_DRAFT}/${CACHE_TYPE_V_DRAFT})"
echo " Speculative       : $([ "${MTP}" = "1" ] && printf 'MTP draft-mtp n_max=%s p_min=%s%s' "${SPEC_DRAFT_N_MAX}" "${SPEC_DRAFT_P_MIN}" "$([ "${STRICT_MTP}" = "1" ] && printf ' (strict)' || printf '')" || printf 'disabled')"
echo " Prompt Cache      : $([ "${CACHE_PROMPT}" = "1" ] && printf '%s checkpoints @ %s MiB (every %s tok)' "${CTX_CHECKPOINTS}" "${CACHE_RAM_MIB}" "${CHECKPOINT_EVERY}" || printf 'disabled')"
echo " Batching          : logical=${BATCH_SIZE}, physical=${UBATCH_SIZE}, threads=${THREADS}/${THREADS_BATCH}"
echo "================================================================================"

CMD=(
    "${LLAMA_SERVER_BIN}"
    "-m" "${RESOLVED_MODEL}"
    "-dev" "${DEVICE}"
    "-ngl" "${NGL}"
    "-fa" "${FLASH_ATTN}"
    "-np" "${NP}"
    "-c" "${CTX}"
)

if [ "${ROPE_SCALING}" = "yarn" ]; then
    # qwen35 is the real arch key; without this the server caps the slot at the
    # model's native 262K training context (n_ctx_train is read from
    # {arch}.context_length, YaRN does not raise it).
    CMD+=(
        "--override-kv" "qwen35.context_length=int:${CTX}"
        "--rope-scaling" "${ROPE_SCALING}"
        "--rope-scale" "${ROPE_SCALE}"
        "--yarn-orig-ctx" "${YARN_ORIG_CTX}"
        "--yarn-ext-factor" "${YARN_EXT_FACTOR}"
        "--yarn-attn-factor" "${YARN_ATTN_FACTOR}"
        "--yarn-beta-slow" "${YARN_BETA_SLOW}"
        "--yarn-beta-fast" "${YARN_BETA_FAST}"
    )
fi

CMD+=(
    "-ctk" "${CACHE_TYPE_K}"
    "-ctv" "${CACHE_TYPE_V}"
    "-b" "${BATCH_SIZE}"
    "-ub" "${UBATCH_SIZE}"
    "-t" "${THREADS}"
    "-tb" "${THREADS_BATCH}"
    "--temp" "${TEMP}"
    "--top-p" "${TOP_P}"
    "--top-k" "${TOP_K}"
    "--no-context-shift"
    "-fit" "off"
    "--no-mmap"
    "--cont-batching"
    "--kv-unified"
    "--poll" "${POLL}"
    "--alias" "qwen38-27b"
    "--metrics"
    "--no-webui"
    "--host" "${HOST}"
    "--port" "${PORT}"
)

if [ "${CACHE_PROMPT}" = "1" ]; then
    mkdir -p "${SLOT_SAVE_PATH}"
    CMD+=(
        "--cache-prompt"
        "--cache-idle-slots"
        "--cache-ram" "${CACHE_RAM_MIB}"
        "--ctx-checkpoints" "${CTX_CHECKPOINTS}"
        "--checkpoint-every-n-tokens" "${CHECKPOINT_EVERY}"
        "--slot-save-path" "${SLOT_SAVE_PATH}"
    )
else
    CMD+=("--no-cache-prompt" "--ctx-checkpoints" "0" "--cache-ram" "0")
fi

if [ "${MTP}" = "1" ]; then
    CMD+=(
        "--spec-type" "draft-mtp"
        "--spec-draft-ngl" "all"
        "--spec-draft-n-max" "${SPEC_DRAFT_N_MAX}"
        "--spec-draft-n-min" "${SPEC_DRAFT_N_MIN}"
        "--spec-draft-p-min" "${SPEC_DRAFT_P_MIN}"
        "--spec-draft-p-split" "${SPEC_DRAFT_P_SPLIT}"
        "--no-spec-draft-backend-sampling"
        "--spec-draft-type-k" "${CACHE_TYPE_K_DRAFT}"
        "--spec-draft-type-v" "${CACHE_TYPE_V_DRAFT}"
        "--spec-draft-poll" "1"
        "--spec-draft-poll-batch" "1"
    )
    if [ "${STRICT_MTP}" = "1" ]; then
        CMD+=("--spec-mtp-strict-qwen")
    fi
fi

if [ -n "${REASONING}" ]; then
    CMD+=("--reasoning" "${REASONING}")
fi
if [ -n "${REASONING_BUDGET}" ]; then
    CMD+=("--reasoning-budget" "${REASONING_BUDGET}")
fi

if [ -n "$RESOLVED_MMPROJ" ]; then
    CMD+=("--mmproj" "${RESOLVED_MMPROJ}" "--image-min-tokens" "1024")
fi

if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    CMD+=("${EXTRA_ARGS[@]}")
fi

exec "${CMD[@]}"
