#!/usr/bin/env bash
# ==============================================================================
# run_yarn_1m.sh — High-Performance 1M Context Server for Qwen 3.8 27B with YaRN
# Scales 262K native context to 1,048,576 tokens using YaRN RoPE scaling & Q4_0 KV.
# Engineered for AMD ROCm 7 / Strix Halo APU & RDNA/CDNA Accelerators.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ------------------------------------------------------------------------------
# 1. Defaults & Configuration
# ------------------------------------------------------------------------------
HIP_DEVICE="${HIP_VISIBLE_DEVICES:-1}"
HOST="${HOST:-0.0.0.0}"
PORT="${PORT:-8800}"
MODEL_PATH="${MODEL_PATH:-}"
MMPROJ_PATH="${MMPROJ_PATH:-}"
NGL="${NGL:-99}"
NP="${NP:-1}"
CTX="${CTX:-1048576}" # 1M context (1,048,576 tokens)
ROPE_SCALING="${ROPE_SCALING:-yarn}"
ROPE_SCALE="${ROPE_SCALE:-4.0}"
YARN_ORIG_CTX="${YARN_ORIG_CTX:-262144}" # 256K native base context
YARN_EXT_FACTOR="${YARN_EXT_FACTOR:--1}"
YARN_ATTN_FACTOR="${YARN_ATTN_FACTOR:-1.0}"
YARN_BETA_SLOW="${YARN_BETA_SLOW:-1}"
YARN_BETA_FAST="${YARN_BETA_FAST:-32}"
CACHE_TYPE_K="${CACHE_TYPE_K:-q4_0}"
CACHE_TYPE_V="${CACHE_TYPE_V:-q4_0}"
FLASH_ATTN="${FLASH_ATTN:-on}"
BATCH_SIZE="${BATCH_SIZE:-2048}"
UBATCH_SIZE="${UBATCH_SIZE:-512}"
EXTRA_ARGS=()

# ------------------------------------------------------------------------------
# 2. CLI Argument Parsing
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Usage: $(basename "$0") [options] [extra llama-server args...]

Launch Qwen 3.8 27B with 1M YaRN context extension on AMD ROCm / Strix Halo.

Options:
  -m, --model <path>         Path to Qwen 3.8 27B GGUF model file
  --mmproj <path>            Path to multimodal projector GGUF (optional)
  -p, --port <port>          Server port (default: 8800)
  -h, --host <host>          Server bind host (default: 0.0.0.0)
  -c, --ctx <size>           Context window size (default: 1048576 for 1M)
  -ngl, --n-gpu-layers <n>   GPU offload layers (default: 99)
  -np, --parallel <n>        Parallel request slots (default: 1)
  --hip-device <n>           HIP_VISIBLE_DEVICES target (default: 1)
  --cache-type-k <type>      KV cache Key quantization (default: q4_0)
  --cache-type-v <type>      KV cache Value quantization (default: q4_0)
  -b, --batch <size>         Batch size (default: 2048)
  -ub, --ubatch <size>       Micro-batch size (default: 512)
  --help                     Show this help message

Environment Variables:
  HIP_VISIBLE_DEVICES        GPU device index (default: 1)
  MODEL_PATH                 Default model path
  MMPROJ_PATH                Default mmproj path
  PORT, HOST, CTX            Server network & context configuration

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
        -m|--model)
            MODEL_PATH="$2"
            shift 2
            ;;
        --mmproj)
            MMPROJ_PATH="$2"
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
            HIP_DEVICE="$2"
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
# 3. Resolve Binary Path
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
# 4. Resolve Model Path
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
# 5. Resolve Multimodal Projector (mmproj) Path (Optional)
# ------------------------------------------------------------------------------
CANDIDATE_MMPROJ=(
    "${MMPROJ_PATH}"
    "/home/ronin/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
    "${HOME}/Projects/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
    "${HOME}/models/Qwen-3.8-27B-ROCmFP4-FAST-GGUF/mmproj-F16.gguf"
    "$(dirname "${RESOLVED_MODEL}")/mmproj-F16.gguf"
    "${SCRIPT_DIR}/../models/mmproj-F16.gguf"
)

RESOLVED_MMPROJ=""
for candidate in "${CANDIDATE_MMPROJ[@]}"; do
    if [ -n "$candidate" ] && [ -f "$candidate" ]; then
        RESOLVED_MMPROJ="$candidate"
        break
    fi
done

# ------------------------------------------------------------------------------
# 6. Assemble Command & Launch
# ------------------------------------------------------------------------------
export HIP_VISIBLE_DEVICES="${HIP_DEVICE}"

echo "================================================================================"
echo " 🚀 Launching Qwen 3.8 27B YaRN 1M Context Server"
echo "================================================================================"
echo " Engine Binary     : ${LLAMA_SERVER_BIN}"
echo " HIP Device Target : HIP_VISIBLE_DEVICES=${HIP_VISIBLE_DEVICES}"
echo " Model             : ${RESOLVED_MODEL}"
[ -n "$RESOLVED_MMPROJ" ] && echo " MMProj            : ${RESOLVED_MMPROJ}"
echo " Host / Port       : ${HOST}:${PORT}"
echo " Context Size      : ${CTX} tokens (1M via YaRN 4x on 262K native base)"
echo " RoPE Parameters   : scaling=${ROPE_SCALING} scale=${ROPE_SCALE} orig_ctx=${YARN_ORIG_CTX}"
echo " KV Cache Format   : Key=${CACHE_TYPE_K}, Value=${CACHE_TYPE_V}"
echo " Batch / MicroBatch: ${BATCH_SIZE} / ${UBATCH_SIZE}"
echo "================================================================================"

CMD=(
    "${LLAMA_SERVER_BIN}"
    "--host" "${HOST}"
    "--port" "${PORT}"
    "-m" "${RESOLVED_MODEL}"
    "-ngl" "${NGL}"
    "-fit" "off"
    "-np" "${NP}"
    "-c" "${CTX}"
    "--override-kv" "qwen2.context_length=int:${CTX},qwen2vl.context_length=int:${CTX},qwen3.context_length=int:${CTX}"
    "--rope-scaling" "${ROPE_SCALING}"
    "--rope-scale" "${ROPE_SCALE}"
    "--yarn-orig-ctx" "${YARN_ORIG_CTX}"
    "--yarn-ext-factor" "${YARN_EXT_FACTOR}"
    "--yarn-attn-factor" "${YARN_ATTN_FACTOR}"
    "--yarn-beta-slow" "${YARN_BETA_SLOW}"
    "--yarn-beta-fast" "${YARN_BETA_FAST}"
    "--cache-type-k" "${CACHE_TYPE_K}"
    "--cache-type-v" "${CACHE_TYPE_V}"
    "-fa" "${FLASH_ATTN}"
    "-b" "${BATCH_SIZE}"
    "-ub" "${UBATCH_SIZE}"
)

if [ -n "$RESOLVED_MMPROJ" ]; then
    CMD+=("--mmproj" "${RESOLVED_MMPROJ}" "--image-min-tokens" "1024")
fi

if [ ${#EXTRA_ARGS[@]} -gt 0 ]; then
    CMD+=("${EXTRA_ARGS[@]}")
fi

exec "${CMD[@]}"
