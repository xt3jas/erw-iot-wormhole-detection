# ERW-IoT wormhole detection — classroom MVP

This project demonstrates a wormhole route check in a synthetic RPL-like IoT
network. MATLAB generates and analyzes 100 seeded events; a LabVIEW VI launches
the MATLAB run and displays its alarm result. The topology image on the VI is a
static illustration. No live network packets are captured.

- [Project instructions](ERW-IoT/README.md)
- [LabVIEW presentation VI](ERW-IoT/labview/ERW-IoT%20MATLAB%20Batch.vi)
- [MATLAB launch script](ERW-IoT/run_matlab_demo.sh)
- [Primary project slides](<source_materials/Downloads/ERW-IoT Wormhole Detection System-2 (1).pdf>)

On the original Mac, the saved VI's command uses a compatibility link to this
folder. On another computer, change its **MATLAB demo command** control to the
local path of `ERW-IoT/run_matlab_demo.sh` before running the VI.

The reference paper is [Hassan et al., *Computer Networks* 276 (2026),
111968](https://doi.org/10.1016/j.comnet.2025.111968). Its PDF is not included
in this public repository. The original class reports are also kept locally
because they contain student registration details.
