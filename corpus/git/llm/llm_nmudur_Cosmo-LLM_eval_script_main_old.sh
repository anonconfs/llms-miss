#!/bin/bash
# You would need to mount A. this script, 
# B. copy only the patch and the ini files that the LLM generated / modified to a new eval experiment folder (so you don't overwrite the LM generated artifacts during eval). Like eval/0521_...
# C. And do the following before running this script:
# mkdir -p /class/mounted/quantities # for the output of presave_script
# mkdir -p /class/mounted/output # for the output of ./class
# mkdir -p /class/mounted/quantities/rewards # for the output of compute_rewards.py
# mkdir -p /class/mounted/quantities/model_specific_tests # for the output of model_specific_tests.py
# D. Add the testing module too

echo "All milestones should ideally be 1 (Negation of Exit Code)"
echo "==== STAGE 1: Compile Code ====" 2>&1 | tee /class/mounted/eval_milestones.txt # This will overwrite if the file already existed.
if [ -f /class/mounted/model.patch ]; then
  milestone0=1
  echo "Milestone 0 [Patch exists]: $milestone0" 2>&1 | tee -a /class/mounted/eval_milestones.txt # Patch file exists?

else
  milestone0=0
  echo "Milestone 0 [Patch exists]: $milestone0" 2>&1 | tee -a /class/mounted/eval_milestones.txt
  exit
fi

git apply --reject /class/mounted/model.patch
make clean && make
milestone1=$(( ! $? )) # TODO: need to check if this fails when the code is not compilable
echo "Milestone 1 [Code compiles]: $milestone1" 2>&1 | tee -a /class/mounted/eval_milestones.txt # Code Compiles?

echo -e "\n\n==== STAGE 2: Compute Observables ====" 2>&1 | tee -a /class/mounted/eval_milestones.txt
/class/testing/compute_observables.sh param_base
milestone2=$(( ! $? )) # Works as expected
echo "Milestone 2 [Observables can be computed using either C or Classy]: $milestone2" 2>&1 | tee -a /class/mounted/eval_milestones.txt # Can Compute Observables?

# Stage 2: Run model-specific test for param_base.ini
CTXF=/class/mounted/problem_context.yaml
st2_type=$(python - <<PY 
import yaml, sys
with open("${CTXF}") as f:
    print(yaml.safe_load(f)["stage2"]["type"])
PY
)
if [ "$st2_type" == "artifact-based" ]; then
    python /class/testing/run_model_specific_tests.py --param=param_base --do_target_fdbk=True 
    python /class/testing/eval_utils.py --stage="model_specific" --out_file="/class/mounted/eval_milestones.txt"
elif [ "$st2_type" == "visual" ]; then
    echo "Stage 2 is visual, PLEASE IMPLEMENT."
elif [ "$st2_type" == "none" ]; then
    echo "Stage 2 is none, skipping model-specific tests."
else
    echo "ERROR: Unknown stage2 type '$st2_type'. Expected 'artifact-based', 'visual', or 'none'." >&2
    exit 1
fi

# Stage 3: 
st3_type=$(python - <<PY 
import yaml, sys
with open("${CTXF}") as f:
    print(yaml.safe_load(f)["stage3"]["type"])
PY
)

if [ "$st3_type" == "exploration" ]; then
  echo -e "\n\n==== STAGE 3: Compute Rewards and Parameter Exploration ====" 2>&1 | tee -a /class/mounted/eval_milestones.txt
  param_files=$(find /class/mounted/ -maxdepth 1 -type f -name "*.json")
  echo "$param_files" > /class/mounted/explored_params_list.txt
  cat /class/mounted/explored_params_list.txt

  processed_count=0
  error_count=0

  # Use null delimiters for safety with filenames
  echo "$param_files" | while IFS= read -r f
  do
    # Check if find actually returned something
    if [[ -n "$f" ]]; then
      processed_count=$((processed_count + 1))
      fname=$(basename "$f" .json) # Extract base name

      echo "---------------------"
      echo "Processing param file [$processed_count]: $f"
      echo "Extracted name: $fname"
      
      echo ">>> Attempting action on '$fname'..."
      if [[ "$fname" == "param_base" ]]; then
        echo ">>> Skipping param_base"
      else
        echo ">>> Running compute_observables for '$fname'..."
        /class/testing/compute_observables.sh $fname
      fi
      if [ $? -ne 0 ]; then
        echo "ERROR: compute_observables failed for '$fname'. Continuing to next file." >&2
        error_count=$((error_count + 1))
        continue
      else
        python /class/testing/compute_rewards.py --param="$fname"
        python /class/testing/eval_utils.py --stage="rewards" --param="$fname" --out_file="/class/mounted/eval_milestones.txt"
      fi
    fi # End check for non-empty filename
  done # End while loop
elif [ "$st3_type" == "minimization" ]; then
  echo -e "\n\n==== STAGE 3: Minimize Parameters with respect to data for the model ====" 2>&1 | tee -a /class/mounted/eval_milestones.txt
  cd /class
  python -m testing.fitting.minimize --min_config_path=/class/mounted/param_ini_config.json --param_base_path=/class/mounted/param_base.json 2>&1 | tee -a /class/mounted/eval_milestones.txt
  /class/testing/compute_observables.sh "param_best-fit"
  seq -s= 51 | tr -d '[:digit:]'
  echo "REWARDS for param_base and param_best-fit"
  seq -s= 51 | tr -d '[:digit:]'
  python /class/testing/compute_rewards.py --param="param_base"
  python /class/testing/eval_utils.py --stage="rewards" --param="param_base" --out_file="/class/mounted/eval_milestones.txt"
  python /class/testing/compute_rewards.py --param="param_best-fit"
  python /class/testing/eval_utils.py --stage="rewards" --param="param_best-fit" --out_file="/class/mounted/eval_milestones.txt"
fi

echo "Finished processing."
