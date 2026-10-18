# Reproduction guide

## Status

This package preserves source evidence. It has **not passed a MATLAB simulation rerun**. MATLAB R2025b was found on the preparation machine, but batch startup exited with status 1 and no diagnostic output. The root cause was not established. Report values remain historical until a successful run is compared against them.

## Environment

- MATLAB supporting local functions in scripts and `yline`; the original exact release is not documented.
- An authorised Princeton Satellite Systems SCT installation for the five SCT-dependent final entry scripts.
- The course `MissionStarter` framework only for investigating integration-development work; it is not distributed here and is not needed for the self-contained PID script.

Do not use `addpath(genpath(repositoryRoot))`: historical function variants can shadow one another or SCT helpers. Do not run from `data/original/` or save over existing MAT files.

## Safest first demonstration: unchanged PID script

From the repository root in MATLAB, copy only the selected script to an ignored scratch directory and run the copy:

```matlab
repoRoot = pwd;
runDir = fullfile(repoRoot, 'runs', 'adcs');
if ~isfolder(runDir), mkdir(runDir); end
copyfile(fullfile(repoRoot, 'code', 'final', 'FinalADCS.m'), runDir);
cd(runDir);
clearvars -except repoRoot runDir;
FinalADCS;
% Inspect errHistDeg and t. Any saved output belongs in runDir.
cd(repoRoot);
```

Expected observable: a pointing-error plot with a 1° reference line. Whether it exactly matches the submitted figure is unverified. Local helpers are included in the original script.

## SCT-dependent subsystem example

Start a fresh MATLAB session; set up your own licensed SCT installation using its documented path setup. Check resolution before running:

```matlab
which CubeSatModel -all
which RHSIsothermalCubeSat -all
which El2RV -all
which DataRateGain -all
```

Then copy and run one final entry file, for example:

```matlab
repoRoot = pwd; % current folder must be the repository root
runDir = fullfile(repoRoot, 'runs', 'thermal');
if ~isfolder(runDir), mkdir(runDir); end
copyfile(fullfile(repoRoot, 'code', 'final', 'FinalThermal.m'), runDir);
cd(runDir);
clearvars -except repoRoot runDir;
FinalThermal;
cd(repoRoot);
```

Use the same pattern for `FinalPower.m`, `FinalStructure.m` or `FinalCDH.m`. `FinalCubeSatSimulation.m` opens visualisation and animation windows and is better inspected interactively. Copying just the chosen file also avoids adding the local `ISSOrbit.m` replacement to the execution path.

If a script errors due to a toolbox API or version mismatch, record it. The preservation snapshot should not be edited to make a test appear successful; use a separate future branch for repairs.

## Historical variants

`final-development/Comm.m` clears the workspace and writes `ARGO_CommsCDH_AssignmentFull_Results.mat` in its working directory. Run a copy in a scratch folder if investigating it. Do not point it at `data/original/`.

Parameter/mode files with filename/declaration mismatches are source evidence, not a supported one-command entry point. Their course-framework dependencies and version differences are documented in [VERSIONS.md](VERSIONS.md).

## Validate preservation

```bash
python3 tools/verify_integrity.py
```

The verifier checks file size and SHA-256 for the 19 copied original code/data files and SHA-256 for 8 extracted report images. It does not execute MATLAB, judge model accuracy or establish exact report reproduction. To compare directly with your local originals:

```bash
python3 tools/verify_integrity.py --source-root "/path/to/The Space Segment"
```
