# Mu2e optimization analysis

Code to evaluate optimization metrics for the Mu2eBO Bayesian optimization loop.
Contains the `EdepAna` analyzer module and analysis macros used by `Mu2eBO`
to compute the primary figure of merit (`s_over_sqrt_b`) and diagnostics.

## Building
```bash
mu2einit
muse backing SimJob Run1Baq
git clone https://github.com/michaelmackenzie/Mu2eOptAna.git
git clone https://github.com/Mu2e/Mu2eBO.git --branch extract-ana-generalize
# on build02
muse build --mu2eCompactPrint --mu2ePyWrap --mu2eCBD -j4 
```

Make a tarball:
```bash
muse tarball
```

## Running a Single-Job Test

Run the test script to verify `EdepAna` can execute:

```bash
# Set REPO_ROOT to your Mu2eBO checkout
export REPO_ROOT=/path/to/Mu2eBO
cd Mu2eOptAna
./test_single_job.sh
```

This test:
1. Sets up the Mu2e environment (SimJob Run1Baq)
2. Runs 1 mubeam job (produces TargetStops art + nts.mubeam.root)
3. Runs `EdepAna` on the mubeam output
4. Verifies the output ROOT file with histograms

**Requirements:**
- `MUSE_SOFTWARE` environment variable (defaults to `SimJob Run1Baq`)
- Mu2eBO repo at `REPO_ROOT` (defaults to `/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eBO`)
- Mu2eOptAna repo at `OPTANA_ROOT` (defaults to `/exp/mu2e/app/users/mmackenz/mu2eopt/Mu2eOptAna`)

## EdepAna Module

The `EdepAna` analyzer (src/EdepAna_module.cc) evaluates energy deposition:
- Total calorimeter energy per event
- Tracker energy at front of tracker
- Primary particle properties (PDG, energy, start position)
- DIO reweighting using the Szafron 2016 spectrum

## Analysis Macros

- `scripts/rough_run1a_sensitivity.C` — Primary `s_over_sqrt_b` metric extractor
- `scripts/rough_sensitivity.C` — Generic signal-vs-background sensitivity
- `scripts/double_edep.C` — Pileup energy deposit model