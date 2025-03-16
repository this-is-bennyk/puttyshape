![putty_shape_banner](https://github.com/user-attachments/assets/e326085a-e9c0-48ec-b791-9ca1286e8b65)

<h1 align="center">PuttyShape</h1>

<p align="center">
  A set of SDF mesh generation tools for Godot 4.4+!
</p>

<p align="center">
  <a href="https://godotengine.org/download/" target="_blank" style="text-decoration:none"><img alt="Godot 4.4+" src="https://img.shields.io/badge/Godot-4.3+-%23478cbf?labelColor=CFC9C8&color=49A9B4" /></a>
</p>

## Table of Contents
- [About](#about)
- [Version](#version)
- [Installation](#installation)
- [License](#license)

## About

### What is Putty Shape?
The Putty Shape plugin is the culmination of multiple sources into one plugin that allows for complex mesh generation by using primitive shapes and mathematical operations.

### Why is Putty Shape?
I watched [this video by Carter Semrad](https://www.youtube.com/watch?v=QhvzmskRiCk) and became hyperfixated on using SDF functions to create cool visuals. I was also inspired by previous SDF plugins by [Zylann](https://github.com/Zylann/godot_sdf_blender), [Digvijaysinh](https://godotengine.org/asset-library/asset/2503) [Gohil](https://godotengine.org/asset-library/asset/2691), and [kubaxius](https://godotengine.org/asset-library/asset/2691). About 1 and a half weeks later, the Saturday before GDC 2025, I made this project.

### Features
- 3D Mesh Generation
  - Create static meshes in real-time by adding PuttyShape3Ds to a PuttyContainer3D
  - Over 30 shapes to use and over 20 operations to perform on them to create complex models
  - Save your creations from the mesh that's outputted to the PuttyContainer3D's mesh property as a model you can use in-game as-is or modify by exporting it from Godot

## Version
Putty Shape requires **at least Godot 4.4**.

## Installation
WIP

## License
This project is licensed under the [MIT License](https://github.com/this-is-bennyk/playnub/blob/main/LICENSE). 
This project utilizes Inigo Quilez's [SDF tutorials](https://iquilezles.org/articles/). Certain portions are licensed under the [MIT License](https://www.shadertoy.com/view/Xds3zN).
This project utilizes the surface nets algorithm based on Mikola Lysenko's [JavaScript implementation](https://github.com/mikolalysenko/mikolalysenko.github.com/blob/master/Isosurface/js/surfacenets.js). It is licensed under the [MIT License](https://github.com/mikolalysenko/mikolalysenko.github.com/blob/master/Isosurface/js/surfacenets.js).
This project utilize portions of the Mercury Demogroup's [hg_sdf file](https://mercury.sexy/hg_sdf/). It is licensed under the [MIT License](https://mercury.sexy/hg_sdf/).
