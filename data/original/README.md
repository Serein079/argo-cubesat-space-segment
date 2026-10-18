# Preserved historical results

| File | Original location | Status |
|---|---|---|
| `ARGO_CommsCDH_AssignmentFull_Results.mat` | `Draft Report Code/` | Unchanged historical binary result |
| `ARGO_CommsCDH_Simple_Results.mat` | `Draft Report Code/` | Unchanged historical binary result |

These files are not certified as the source of the final-report plots. Their exact generating revision is unverified. `code/final-development/Comm.m` saves a file with the first name, but its presence does not prove it produced this copy.

To inspect without overwriting, load into a separate structure in MATLAB:

```matlab
whos('-file', 'ARGO_CommsCDH_AssignmentFull_Results.mat')
historical = load('ARGO_CommsCDH_AssignmentFull_Results.mat');
```

Run simulations in an ignored `runs/` directory. File sizes and hashes are recorded in `provenance/original-files.json`.
