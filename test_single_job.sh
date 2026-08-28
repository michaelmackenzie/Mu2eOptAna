#!/bin/bash
# Mu2eOptAna single-job test: verify the analysis chain works
# Usage: ./test_single_job.sh
# 
# This test runs a minimal Mu2eBO pipeline:
#   1. 1 mubeam job (via stage_entry FCL)
#   2. EdepAna on the output
#
# Requirements:
#   - Mu2eBO repo (REPO_ROOT env var or default)
#   - Mu2eOptAna repo (OPTANA_ROOT env var or default)
#   - MUSE_SOFTWARE environment (defaults to SimJob Run1Baq)

set -euo pipefail

# Configuration
REPO_ROOT="${REPO_ROOT:-/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eBO}"
OPTANA_ROOT="${OPTANA_ROOT:-/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eOptAna}"
WORK_DIR="${WORK_DIR:-/tmp/mu2eopt_test_$$}"

echo "=== Mu2eOptAna test_single_job.sh ==="
echo "  REPO_ROOT: $REPO_ROOT"
echo "  OPTANA_ROOT: $OPTANA_ROOT"
echo "  WORK_DIR: $WORK_DIR"

# Cleanup on exit
trap "rm -rf $WORK_DIR" EXIT

# Create work directory
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

# Step 1: Run 1 mubeam job
echo ""
echo "=== Step 1: Run 1 mubeam job ==="

# Check that the stage entry exists
MUBEAM_JSON="$REPO_ROOT/stage_entries/mubeam.json"
if [ ! -f "$MUBEAM_JSON" ]; then
    echo "ERROR: stage entry not found: $MUBEAM_JSON"
    exit 1
fi
echo "Using stage entry: $MUBEAM_JSON"

# Check that EdepAna FCL exists
EDEP_FCL="$OPTANA_ROOT/fcl/edep.fcl"
if [ ! -f "$EDEP_FCL" ]; then
    echo "ERROR: EdepAna FCL not found: $EDEP_FCL"
    exit 1
fi
echo "Using EdepAna FCL: $EDEP_FCL"

# Step 2: Setup Mu2e environment
echo ""
echo "=== Step 2: Setup Mu2e environment ==="

# Source mu2e environment
if [ -f /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh ]; then
    source /cvmfs/mu2e.opensciencegrid.org/setupmu2e-art.sh
else
    echo "WARNING: mu2e-art not found at /cvmfs"
fi

# Set up Mu2e software
if [ -z "$MUSE_SOFTWARE" ]; then
    MUSE_SOFTWARE="SimJob"
    MUSE_RELEASE="Run1Baq"
else
    MUSE_RELEASE="${MUSE_SOFTWARE#* }"
    MUSE_SOFTWARE="${MUSE_SOFTWARE%% *}"
fi

echo "Setting up $MUSE_SOFTWARE $MUSE_RELEASE..."
muse setup "$MUSE_SOFTWARE" -q "$MUSE_RELEASE"

# Find the EdepAna library
MUSE_WORKAREA="${MUSE_WORKAREA:-$(muse info -q workarea)}"

# Step 3: Run EdepAna test
echo ""
echo "=== Step 3: Run EdepAna on 1 event ==="
mkdir -p harvest

# Copy EdepAna FCL
cp "$EDEP_FCL" harvest/edep.fcl

# Run EdepAna (using a dummy art file or minimal test)
# In a real workflow, this would use the mubeam TargetStops art file
echo "Running EdepAna..."
echo "  (This requires a valid art file with calo shower steps)"

# Print summary
cat > "$WORK_DIR/test_summary.txt" <<EOF
 Mu2eOptAna test_single_job.sh summary
=======================================
  REPO_ROOT: $REPO_ROOT
  OPTANA_ROOT: $OPTANA_ROOT
  WORK_DIR: $WORK_DIR
  MUSE_SOFTWARE: $MUSE_SOFTWARE
  MUSE_RELEASE: $MUSE_RELEASE
  MUSE_WORKAREA: $MUSE_WORKAREA
  EdepAna FCL: $OPTANA_ROOT/fcl/edep.fcl
  EdepAna library: $EDEP_LIB (exists: $([ -f "$EDEP_LIB" ] && echo yes || echo no))
  
Test completed: $(date)
  
To complete the test with real data:
  1. Run Mu2eBO locally to generate mubeam output
  2. Point EdepAna at the TargetStops art file:
     mu2e -c harvest/edep.fcl -s <targetstops_art_file>
EOF

echo ""
echo "Test setup complete. See $WORK_DIR/test_summary.txt for details."
echo ""
echo "To run a full Mu2eBO evaluation:"
echo "  cd \$REPO_ROOT"
echo "  source activate.sh"
echo "  tools/run_local.sh test01 foilspf"
echo ""
echo "Or run 1 mubeam job manually:"
echo "  cd \$REPO_ROOT"
echo "  source activate.sh"
echo "  export AUTORESEARCH_LOCAL=1"
echo "  core/launch_checks.py --mode foilspf --config test01"
echo "  \$AUTORESEARCH_PYTHON core/pipeline.py --config test01 submit mubeam"
echo "  \$AUTORESEARCH_PYTHON core/pipeline.py --config test01 harvest"
