#!/bin/bash
# Mu2eOptAna standalone test: full workflow test using Mu2eBO tools
# 
# This script creates a minimal mode_spec that defines a custom workflow:
#   - mubeam stage: runs MuBeamResampler FCL, outputs TargetStops art files
#   - harvest: runs EdepAna on TargetStops, counts muon stops, computes metrics
#
# Usage: ./test_standalone.sh [config-name]
# Example: ./test_standalone.sh test01

set -euo pipefail

CONFIG="${1:-standalone_test_$(date +%m%d_%H%M%S)}"
REPO_ROOT="${REPO_ROOT:-/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eBO}"
OPTANA_ROOT="${OPTANA_ROOT:-/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eOptAna}"

echo "=== Mu2eOptAna standalone test ==="
echo "  Config: $CONFIG"
echo "  REPO_ROOT: $REPO_ROOT"
echo "  OPTANA_ROOT: $OPTANA_ROOT"

# Verify required paths
[ -f "$OPTANA_ROOT/fcl/edep.fcl" ] || { echo "ERROR: EdepAna FCL not found"; exit 1; }
[ -f "$REPO_ROOT/stage_entries/mubeam.json" ] || { echo "ERROR: Mu2eBO stage entries not found"; exit 1; }

# Create temporary mode spec
WORK_DIR=$(mktemp -d)
trap "rm -rf $WORK_DIR" EXIT

MODE_SPEC_DIR="$WORK_DIR/mode_specs"
STAGE_ENTRIES_DIR="$WORK_DIR/stage_entries"
mkdir -p "$MODE_SPEC_DIR" "$STAGE_ENTRIES_DIR"

# Create mode spec with custom workflow
cat > "$MODE_SPEC_DIR/edep_test.json" <<EOF
{
  "name": "edep_test",
  "note": "Standalone test of EdepAna with simple mubeam workflow",
  "software": {
    "musing": "\${ARTIFACT}/SimJob/Run1Baq",
    "grid_tarball": "\${ARTIFACT}/Mu2eBO/Code.tar.bz2"
  },
  "run": {
    "stages": ["mubeam"],
    "stage_defs": {
      "mubeam": {
        "desc_fmt": "EdepTest_MuBeam_{cfg}",
        "output_glob": "sim.*.TargetStops.*.art",
        "entry": "stage_entries/mubeam.json",
        "njobs": 1,
        "events_per_job": 10
      }
    }
  },
  "jobs_per_stage": {},
  "presubmit_after": {},
  "stage_tuning": {},
  "knobs": [
    {
      "name": "extra_rOut_up",
      "min": 0.95,
      "max": 1.05,
      "fmt": "{:.3f}"
    }
  ],
  "int_dims": [],
  "leaderboard": {
    "file": "leaderboard_edep_test.tsv",
    "columns": ["sob", "calo_per_pot", "alpha", "obj"],
    "obs_noise": [0.01, 0.05],
    "metrics": {
      "sob": ["s_over_sqrt_b"],
      "calo_per_pot": ["calo_per_pot"]
    }
  },
  "preflight": {
    "dumps_gdml": false,
    "verifies_foil_gdml": false,
    "preserves_gdml": false,
    "checks_managed_overlap": false,
    "require_zero_overlaps": false
  },
  "geom": {
    "template": " foilspf_template",
    "knobs": ["extra_rOut_up"],
    "per_index": 1
  },
  "harvest": {
    "extractors": [
      {
        "name": "edepana",
        "type": "mu2e_module",
        "stage": "mubeam",
        "fcl": "Mu2eOptAna/fcl/edep.fcl",
        "output": "nts.edep.root",
        "parse_pattern": "EdepAna summary:\\s*Saw\\s+([\\d.eE+-]+)\\s+events",
        "parse_field": "ce_seen",
        "parse_type": "int"
      },
      {
        "name": "muminus_count",
        "type": "event_count",
        "stage": "mubeam",
        "count_filter": "TargetStops",
        "parse_field": "muminus_stops"
      }
    ],
    "derived": {
      "s_over_sqrt_b": "sqrt(ce_seen * muminus_stops)",
      "calo_per_pot": "muminus_stops / (count_files('mubeam') * events_per_job('mubeam'))"
    },
    "summary_fields": ["ce_seen", "muminus_stops", "s_over_sqrt_b", "calo_per_pot"]
  }
}
EOF

# Copy mubeam stage entry
cp "$REPO_ROOT/stage_entries/mubeam.json" "$STAGE_ENTRIES_DIR/mubeam.json"

echo ""
echo "=== Setup complete ==="
echo "  Mode spec: $MODE_SPEC_DIR/edep_test.json"
echo "  Stage entries: $STAGE_ENTRIES_DIR/mubeam.json"
echo ""
echo "To run this test with Mu2eBO tools:"
echo ""
echo "  cd $REPO_ROOT"
echo "  source activate.sh"
echo "  export AUTORESEARCH_DATA_ROOT=/tmp/edep_test_$$"
echo "  export AUTORESEARCH_BACKING=/exp/mu2e/app/users/oksuzian"
echo "  python3 -m graph.run --mode edep_test --config-name $CONFIG"
echo ""
echo "This will:"
echo "  1. Submit 1 mubeam job (10 events)"
echo "  2. Harvest runs EdepAna on TargetStops art files"
echo "  3. Counts muon stops"
echo "  4. Computes metrics: s_over_sqrt_b, calo_per_pot"
echo ""
echo "Or run manually with:"
echo "  cd \$REPO_ROOT"
echo "  source activate.sh"
echo "  export AUTORESEARCH_DATA_ROOT=/tmp/edep_test_$$"
echo "  export AUTORESEARCH_MODE=edep_test"
echo "  python3 core/launch_checks.py --mode edep_test --config $CONFIG"
echo "  python3 core/pipeline.py --config $CONFIG submit mubeam"
echo "  python3 core/pipeline.py --config $CONFIG harvest"
