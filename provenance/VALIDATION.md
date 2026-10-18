# Validation status

Prepared on 2026-10-17.

| Check | Outcome |
|---|---|
| Entire original source directory | 4,700 files, 433,227,561 bytes: all before/after SHA-256 values and sizes identical |
| Published original MATLAB files | 17/17 match source bytes |
| Published historical MAT files | 2/2 match source bytes |
| Local original archive | 35 files match source bytes |
| Extracted report images | 8 images recorded with source PDF hash, page and embedded-image name |
| Documentation links | Relative file/image links checked locally |
| MATLAB rerun | Not completed: local R2025b batch launcher exited status 1 without diagnostic output |
| Report-to-script numerical equivalence | Not established; original ADCS figure/initial-condition discrepancy documented |

## What was actually done

The source directory was read, inventoried and hashed before and after preparation. Original files were copied byte for byte. PDF text was read for the assessment mapping and report figures were extracted without redrawing. New Markdown explains versions, evidence, dependencies and interview talking points. Arithmetic checks were performed independently for the displayed thermal/power equations and data-budget assumptions.

Five selected final scripts were copied to a workspace scratch directory for a MATLAB batch check. The MATLAB launcher failed before script-level diagnostics were produced. No simulation pass result or new numerical dataset is claimed. The originals and their stored results were not overwritten.

The full source inventories and archive-copy confirmation are in the separate local archive. Public source-copy and image hashes are in this directory. `tools/verify_integrity.py` rechecks the public copies without modifying them.

This validation record describes the preserved project snapshot before publication. Repository publication is a separate delivery step and does not change the simulation-validation status. No assignment resubmission or grade claim is implied.
