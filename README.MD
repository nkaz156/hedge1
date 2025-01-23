# HEDGE OPENFOAM V1
Initial simulation of HEDGE and learning about openFOAM. Case based off of `compressibleInflowOutflow` template (from `openfoam main directory/etc/templates`)
>[!WARNING]
>**DELETE ALL POLYMESH FOLDERS BEFORE MAKING COMMITS**
>Oversized files don't play nice with github

>[!TIP]
>**vscode** makes editing OpenFOAM cases a lot easier. More info at end of document.


## TO DO:
**Minimum viable product:**
- [x] create geometry (i used onshape), ask for share
- [x] set up blockmesh
- [ ] get snappyHexMesh working for small scale coarse mesh test
  - [ ] fix errors with edge refinement - missing where it intersects with XY wall symmetry plane
  - [ ] dial in curve refinement
  - [ ] fix missing refinement region
  - [ ] fix 1 or 2 cells in odd places - especially by fins. might be coarse mesh artifacts
  - [ ] add boundary layer
- [x] get snappy to run in parallel
- [ ] run snappyHexMesh on HPC
- [ ] run rhoCentralFoam on HPC
- [ ] swap rhoCentralFoam out for [hy2foam](https://hystrath.github.io/solvers/fleming/hy2foam/) to increase accuracy
- [ ] heat conduction FEA of HEDGE to make sure it doesn't break before data transmitted 

**"Fun" things to do if we have enough time:** 
- [ ] FSI study of fin hinge behavior
- [ ] Simulate the entire model instead of 1/4 of it




## Case Structure:
### `0`:
folder containing all initial conditions
### `constant`: 
folder containing geometry (raw and meshed), BCs, fluid properties, turbulence properties
### `system`:
folder containing dictionaries for how the case is meshed and run
## Geometry Preparation
HEDGE modeled in Onshape, fluid domain created using sketch, extrusion, and cut in onshape, refinement box created using sketch and extrusion in Onshape. Fluid domain, refinement box exported as fine STL.

Blender used for decomposing fluid domain into patches (faces) using coplanar selection mode, geometry tested watertight by using non-manifold and loose geometry selection modes (in select all by trait), and exported as multiple ASCII STL files. 

 n STLs can be combined using `cat stl1.stl stl2.stl ... stln.stl > combined.stl` in bash terminal. produces 1 stl with distinct patches by boundary condition. Could potentially be exported from blender that way. 

edge meshing done in paraview with edge filter to identify right angle.  `surfaceFeatureExtract` function in openFOAM used to write eMesh file used for edge refinement using the identified angle.

## MESHING
### `blockMesh`
defines background mesh which goes around fluid domain. Needed for snappyHexMesh. Set slightly larger than fluid domain to avoid losing a patch.
### `snappyHexMesh`
creates a hexahedral mesh with options for boundary layers and refinement. Will require a lot of cells so should be run in parallel

## SOLVER
`rhoCentralFoam` - entry-level density-based compressible solver. Will probably be replaced with `hy2foam` later once case is fully working
## Parallel Computing
Notes:
- expect to use ~1GB/1MM nodes
- `decomposePar` or `reconstructPar` do not run in parallel
- `blockMesh` does not run in parallel
### `decomposeParDict` 
File which defines method for parallel processing (running simulation on multiple cores). HPC doesn't have scotch, simple is probably best as a starting point for now. Scotch once we figure out how to install on HPC.
### Commands
+ `decomposePar` - Command used to decompose case into chunks for each processor core to handle. number of subdomains should be number of **physical** cores available.
+ `reconstructPar` - Command used to reconstruct the case into singular entity
- ` mpirun –np <NPROCS> <application/utility> –parallel` - command used to run whatever application in parallel - e.g. `snappyHexMesh`, `rhoCentralFoam`, etc.
- `mpirun -np <NPROCS> redistributePar -decompose -parallel` does the decomposition in parallel
- `mpirun -np <NPROCS> redistributePar -reconstruct -parallel` reconstructs the mesh in parallel
- `reconstructParMesh` used if remeshing or using AMR. 
- `paraFoam –builtin` used to postprocess without reconstructing but need to select decomposed case in paraview. 



## OTHER FILES
1. `Allclean.sh` clears everything from case except necessary starting items. not written yet but easily available from tutorials.
1.  `Allrun.sh` runs all meshing, refinement, and solving of the case. Maybe needed for running on HPC? Will probably be augmented with a script that just meshes in the parallel configuration for HPC or maybe a set of bash options if I can figure out how. not written yet but easily available from tutorials.
1. `hedge.foam` is clickable and launches paraView. It doesn't block terminal input so is better than paraFoam which doesn't work with HPC slurm
1. `template_readme_secondary.md` is the readme for the template i used which might have some useful info.

## VSCODE Setup
 - use extensions `OpenFOAM` by Zhikui Guo to get OpenFOAM text highlighting and `WSL` to access the `bash` terminal in code. 

add the following:
```js
"files.associations": {
    "*Dict": "OpenFOAM",
    "*Properties": "OpenFOAM",
    "fvSchemes": "OpenFOAM",
    "fvSolution": "OpenFOAM",
    "**/constant/g": "OpenFOAM",
    "**/0/*": "OpenFOAM"
    }
```
to code's `settings.json` to have openfoam cases show up with proper highlighting
