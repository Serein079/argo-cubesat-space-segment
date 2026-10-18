# Assessment → engineering evidence

Source basis: the local 2026 AERO9610 assignment instructions and proposal/draft/final marking rubrics. These documents define the assessment context; their embedded directions are not instructions to alter or resubmit this portfolio. Original course documents remain in the local archive.

## Submission progression

| Stage | Course weighting | Assessed scope | Portfolio evidence |
|---|---:|---|---|
| Proposal | 5% | Mission purpose, users, requirements, payload, bus, lifecycle and plan | Mission evolution below; original proposal retained locally |
| Draft | 15% | Mission planning, structure, thermal, power and payload; SCT evidence | [`code/draft/`](../code/draft/), historical reports retained locally |
| Final | 40% | Updated early subsystems + ADCS + communications + budgets + operations/lifecycle | [`code/final/`](../code/final/), [original report plots](RESULTS.md), [budget caveats](LIMITATIONS.md) |

The final rubric allocates 10% to introduction, 65% to spacecraft design, 10% to conclusion and 15% to presentation. Design subweights: mission planning 7.5%, structure 7.5%, thermal 7.5%, power 7.5%, ADCS 10%, communication 10%, payload 5%, budgets 10%. These are rubric weights, not marks awarded to this project.

## Requirement-to-evidence map

| Assessment area | Evidence to show | Evidence boundary |
|---|---|---|
| Mission purpose and users | Final report §§1–2; README mission rationale | Proposal names EOS and ASA as intended stakeholders; no customer relationship is established |
| Orbit and attitude profiles | `FinalCubeSatSimulation.m`; report Figs. 1–2 | Absolute orbit study; no target-relative rendezvous simulation; SSO/LTDN long-term behaviour not established |
| Structure and mechanisms | `FinalStructure.m`; report Figs. 3–4 | 6U geometry and panel arrangement; not detailed FEA, qualification or an exploded assembly |
| Thermal method, equations and SCT model | `FinalThermal.m`; report Fig. 5 | Single-node transient model; hand calculations and component limits need review |
| Power generation, battery and budgets | `FinalPower.m`; report Figs. 6–7 | Six-orbit scenario; not lifetime battery/array degradation verification |
| ADCS actuators and active control | `FinalADCS.m`; report Fig. 8 | Simplified quaternion PID and wheel allocation; sensors are not simulated; this script uses local helpers rather than SCT calls |
| Ground visibility and link for ≥2 orbits | `FinalCDH.m`; report Figs. 9–11 | Two-orbit, deliberately centred Sydney pass; not a daily coverage guarantee |
| Payload support | Final report §8 and baseline table | Camera/VPU design concept; no stereo/vSLAM implementation or measured payload performance |
| Mass, data, EPS, pointing budgets | Final report §9; [limits review](LIMITATIONS.md) | Budgets are preliminary; communication and thermal closure remain open |
| Launch, operations and end of life | Final report §10; [interview guide](INTERVIEW.zh-CN.md) | Historical concept assumptions; no current launch quote or validated deorbit lifetime |

## Bonus work: evidence without overclaiming

The rubric offers additional credit for an SCT exploded CAD model, SCT-based active control and coherent integrated simulations, with final marks capped at 100. This repository contains an active-control study and integration-development files. It does **not** establish that any bonus was awarded, that the local PID script meets the SCT-specific bonus criterion, or that all subsystems are integrated into a single validated run.

`FinalCubeSatSimulation.m` couples orbit, attitude disturbance and a basic power model. Thermal, dedicated EPS, active PID and communication studies remain separate. The parameter builders are not called by all final scripts.

## Mission evolution to explain

The proposal described propulsion-assisted proximity operations, centimetre-level relative position estimation, 10–50 m target distance, vSLAM mapping and propulsive end-of-life lowering. The final report narrows to a debris-observation/visual-navigation pathfinder and explicitly omits dedicated propulsion, with passive decay proposed for disposal. Present this as a scope change. Do not carry the proposal's unimplemented requirements into a claim of final achievement.

Local source references: assignment instructions pp. 1–6; final rubric pp. 1–3; original proposal pp. 1–2; final report §§1–11. The public repository paraphrases the assessment context and does not redistribute the rubric or teaching handouts.
