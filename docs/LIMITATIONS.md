# Technical review and claim boundaries

This document adds review notes; it does not modify the submitted report, original scripts or result data. It is based on local code and report inspection, plus arithmetic checks, not a new mission simulation.

## 1. Implemented spacecraft studies versus mission concept

The delivered work includes subsystem models and an active-attitude-control study. It does not include camera data, feature tracking, stereo calibration, vSLAM, target-relative state estimation, closed-loop approach or collision avoidance. The proposal's proximity operations and propulsion are not demonstrated by the final code.

## 2. Shared configuration and orbit conventions

The scripts define parameters independently. Inclination, solar areas, load schedules, attitude assumptions, battery capacities and stations differ across versions. No final driver calls all subsystem scripts through one shared parameter definition. Some function filenames do not match declarations. The historical element-ordering mismatch is documented in [VERSIONS.md](VERSIONS.md).

The SSO label and a nominal 10:30 node time are design intentions; a short two-body simulation does not validate secular nodal precession or maintain a specified LTDN. Target accessibility and relative geometry require additional analysis.

## 3. Thermal arithmetic and model scope

The report's displayed eclipse equilibrium inputs give

```text
T = (5 / (5.67e-8 × 0.66 × 0.23))^(1/4) ≈ 155.2 K
```

rather than the reported 254.6 K. The displayed sunlit inputs give approximately 263.0 K, consistent with its approximate 263 K statement. This check concerns the displayed equilibrium equation; it is not a recalculation of the transient SCT trace. A finite eclipse does not necessarily reach equilibrium.

The original transient curve near 253.5–262 K does not by itself establish battery or electronics acceptability. A multi-node model, component operating/survival limits and consistent environmental heat terms would be needed. The scalar averages computed after `FinalThermal.m`'s integration are not the same as a validated component heat-flow model.

## 4. Power sizing and operational consistency

Using the report's displayed daylight load of 18 W and path efficiencies gives

```text
P_array = [5×(35.6/60)/0.65 + 18×(59/60)/0.85] / (59/60)
        ≈ 25.8 W
```

not its stated approximately 15 W. The final power simulation uses a scheduled load, not a constant 18 W throughout daylight, so this hand-calculation discrepancy does not by itself invalidate the plotted energy trend.

`FinalPower.m` defines a 30% DoD value but clamps battery energy only between zero and full capacity. It does not enforce a 70% state-of-charge floor. Its downlink mode is based on orbital phase and sunlight, without checking the communication model's contact windows. The 58.1 W area-based bound assumes all counted areas receive full normal irradiance; opposing surface normals make it an idealised upper bound, not a simultaneous achievable output.

## 5. Data volume and contact-time closure

The report assumes 15 orbits/day, 341 seconds of payload activity/orbit, 0.5 Mbps processed payload data and continuous 0.02 Mbps housekeeping. Decimal-unit arithmetic gives about 532.54 MB/day. At 1.2 Mbps, that needs about 59.17 minutes/day, before coding/protocol overhead and scheduling losses. 8 GB divided by that volume is about 15.02 days, before usable-capacity and reserve allowances.

`FinalCDH.m` constructs a pass centred at 11 minutes and examines two orbits. It does not establish daily aggregate contact. Moreover, the EPS downlink slot is at most 6% of an orbit, or 0.06 × 94.6 × 60 = 340.56 s per orbit. This is an upper bound before eclipse and visibility filtering. A common time history must reconcile data generation, contact, downlink and energy before claiming complete closure.

## 6. ADCS fidelity and provenance

The local quaternion PID script includes torque clipping and clamps stored wheel momentum. The clipped momentum does not constrain subsequent commanded wheel torque, and the body equation does not couple the stored wheel momentum back into the full spacecraft angular momentum. The model has no sensor noise, attitude estimator, momentum unloading or wheel-failure handling. The <1° goal is a requirement for a simplified simulated case, not a demonstrated hardware accuracy.

The report's initial plotted error and the current script initial attitude differ. Preserve the evidence as historical and investigate the exact generating revision before claiming numerical reproduction.

## 7. Historical output and lifecycle limits

The original MAT files are stored with draft-era code; their names alone do not prove that they generated the final report. No final MAT dataset was found in `Final Report Script/` or `Final Report Code/`.

Launch price and schedule statements in the submitted report are historical assumptions, not verified current quotes. Passive decay from 500 km requires a lifetime/disposal assessment; the repository does not demonstrate a particular disposal time or regulatory compliance. No new current pricing or compliance claim is made here.

## Follow-on development, separate from this preserved snapshot

A future branch could establish one configuration and element convention, replay report figures with logged software versions, couple modes/visibility/storage/energy, implement realistic wheel saturation, and correct hand calculations. These changes have intentionally not been applied to the original files in this package.
