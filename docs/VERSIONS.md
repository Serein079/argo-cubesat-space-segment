# File and version map

Original names and file bytes are retained. Directory names describe the source location, not a verified chronology of every edit.

| Repository directory | Original location | Role |
|---|---|---|
| `code/final/` | `Final Report Script/` | Primary final-report walkthrough; seven files |
| `code/final-development/` | `Final Report Code/` | Three alternative/development files; not a replacement for the final scripts |
| `code/draft/` | `Draft Report Code/` | Five early scripts; two explicitly PSS-copyrighted files stay in local archive |
| `code/integration-development/` | Two `Final*.m` files at the `SCTAcademic/` root | ARGO parameter/mode work recovered from the toolbox directory |
| `data/original/` | Two MAT files in `Draft Report Code/` | Historical saved outputs; not relabelled as final results |

## Final-script entry points

| File | Purpose | Main dependency / caveat |
|---|---|---|
| `FinalStructure.m` | 6U geometry and deployed panels | SCT CubeSat model and drawing functions |
| `FinalThermal.m` | 20-orbit single-node thermal response | SCT `RHSIsothermalCubeSat`, propagation, Sun and eclipse helpers |
| `FinalPower.m` | Six-orbit generation/load/energy history | SCT orbit/attitude/solar-array helpers |
| `FinalADCS.m` | Two-orbit-duration quaternion PID study | Local helper functions + MATLAB built-ins; simplified wheel physics |
| `FinalCDH.m` | Two-orbit Sydney visibility/link scenario | SCT link/coordinate helpers; centred pass is a scenario construction |
| `FinalCubeSatSimulation.m` | 2.5-orbit disturbance/attitude/basic-power study | SCT `RHSCubeSat`, RK4, plotting and animation; not complete subsystem integration |
| `ISSOrbit.m` | Local offline orbit helper | Legacy element ordering; avoid shadowing the SCT function unintentionally |

## Differences that must remain visible

- Final report orbit: 97.6°. Most `code/final/` scripts: 97.4°. The offline `ISSOrbit.m`: 97.6°.
- `FinalPower.m` uses a 60 Wh battery and 8/18/10/5 W charging/payload/downlink/eclipse loads. `FinalCubeSatSimulation.m` uses 60 Wh and a constant 8 W load with body-face solar areas. These are different EPS scenarios.
- `FinalCDH.m`: Sydney, 2.26 GHz, 2 W, QPSK, 1.2 Mbps, 10° elevation mask. `final-development/Comm.m`: high-latitude station, 90° orbit, 2.2 GHz, 1 W, BPSK, 0.5 Mbps, 5° mask, four orbits.
- Integration-development files retain a 40 Wh battery and a different operating schedule; they are not the 60 Wh final EPS model.
- `Final_BuildMissionData.m` declares `ARGO_BuildMissionData`; `FinalBuildMissionData.m` declares `BuildMissionData`; `FinalMissionMode.m` declares `MissionMode`. Original name/declaration mismatches are preserved. Do not assume they automatically replace course functions.
- `draft/ARGO_BuildMissionData.m` and `final/ISSOrbit.m` use `[a;e;i;RAAN;omega;nu]`; the local SCT `El2RV` documents `[a;i;RAAN;omega;e;M]`. These are incompatible conventions. The final orbit script uses the SCT ordering; the development builder has its own converter.

Do not add the entire repository recursively to the MATLAB path. Run one version at a time and check function resolution with `which ... -all`.
