#!/usr/bin/env bash
# Hill climb: run the eval, and if it fails, ask the agent to improve the skill, then repeat.
# AUTO_IMPROVE=1 enables the automatic skill edit. Default is report only.
set -uo pipefail

CASE_DIR="${1:?usage: loop.sh <case-dir> [max-iterations]}"
MAX="${2:-3}"
RUBRIC="${RUBRIC:-evals/rubric.example.json}"
AGENT="${AGENT:-opencode}"
AGENT_PROFILE="${AGENT_PROFILE:-}"
JUDGE_AGENT="${JUDGE_AGENT:-}"
MODEL="${MODEL:-}"
JUDGE_MODEL="${JUDGE_MODEL:-}"

for i in $(seq 1 "$MAX"); do
  echo "== iteration $i =="
  OUT="evals/runs/loop-$i-$(date +%H%M%S)"
  ARGS=(--case-dir "$CASE_DIR" --rubric "$RUBRIC" --out "$OUT" --agent "$AGENT")
  [ -n "$AGENT_PROFILE" ] && ARGS+=(--agent-profile "$AGENT_PROFILE")
  [ -n "$JUDGE_AGENT" ] && ARGS+=(--judge-agent "$JUDGE_AGENT")
  [ -n "$MODEL" ] && ARGS+=(--model "$MODEL")
  [ -n "$JUDGE_MODEL" ] && ARGS+=(--judge-model "$JUDGE_MODEL")
  python3 evals/harness.py "${ARGS[@]}"
  CODE=$?
  if [ "$CODE" -ne 0 ] && [ ! -f "$OUT/score.json" ]; then
    echo "harness failed (exit $CODE); not touching the skill"
    exit 1
  fi

  SCORE="$(python3 -c "import json,sys;print(json.load(open('$OUT/score.json'))['aggregate']['mean'])" 2>/dev/null || echo 0)"
  THRESHOLD="$(python3 -c "import json;print(json.load(open('$OUT/score.json'))['threshold'])" 2>/dev/null || echo 8.5)"
  echo "score: $SCORE (threshold $THRESHOLD)"
  if python3 -c "import sys;sys.exit(0 if float('$SCORE') >= float('$THRESHOLD') else 1)"; then
    echo "passed"
    exit 0
  fi

  if [ "${AUTO_IMPROVE:-0}" = "1" ]; then
    if [ -z "$MODEL" ]; then
      echo "MODEL not set; refusing to edit the skill with an unapproved default model"
      exit 1
    fi
    python3 evals/agent_runner.py \
      --agent "$AGENT" \
      ${AGENT_PROFILE:+--profile "$AGENT_PROFILE"} \
      --model "$MODEL" \
      --prompt "Read $OUT/score.json and the skill under skills/. Fix the failures by changing the skill or its supporting files. Do not weaken the rubric and do not change the judge. Stop after the edit."
    echo "review the diff before keeping the skill edit"
  else
    echo "below threshold; improve the skill and run again (set AUTO_IMPROVE=1 to let the agent edit it)"
    exit 1
  fi
done

echo "still below threshold after $MAX iterations"
exit 1
