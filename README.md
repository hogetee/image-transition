# Image transition

A Verilog VGA image transition project using the Tiny Tapeout interface.

The design displays two 320 × 240 RGB222 images, scaled by 2 to a
640 × 480 VGA output. The animation slides the images in from opposite
sides for 64 frames, then uses a five-point blur and spatial dithering to
reveal the second image over 128 frames. The second image remains visible
after the transition. Reset restarts the animation.

## Project files

- `src/Img_vgaPlayground.v` — top module `tt_um_vga_example`, image memories,
  animation, and RGB output.
- `src/hsync_generator.v` — VGA synchronization and pixel coordinates.
- `info.yaml` — Tiny Tapeout project configuration and output pin mapping.
- `test/test.py` — Cocotb frame capture, synchronization checks, and reference
  image comparison.
- `test/requirements.txt` — Python test dependencies.

## Required image data

The RTL loads `../data/bg1_dithering.mem` and `../data/bg1.mem`, relative to
the simulator's working directory. Each image memory contains 76,800
six-bit pixels in RGB222 format, loaded with `$readmemh`.

These image data files are not included in this repository. Supply them at
the expected paths before simulating the image output.

## Simulation status

The supplied test captures three frames into `output/` and compares them
against PNG files in `reference/`, relative to its working directory.
Reference images and a simulator test runner are not included. Configure a
Cocotb-compatible simulator, provide the required assets, and install the
dependencies from `test/requirements.txt` to run it.

The original RTL and test files are preserved as supplied. Simulation has
not been verified for this upload.
