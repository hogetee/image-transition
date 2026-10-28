# Image transition

A Verilog VGA image transition project using the Tiny Tapeout interface.

The design displays two 320 × 240 RGB222 images, scaled by 2 to a
640 × 480 VGA output. The animation slides the images in from opposite
sides for 64 frames, then uses a five-point blur and spatial dithering to
reveal the second image over 128 frames. The second image remains visible
after the transition. Reset restarts the animation.

## Try it online

[Open Image transition in VGA Playground](https://vga-playground.com/?repo=https://github.com/hogetee/image-transition)

The project configuration in `info.yaml` selects `tt_um_vga_example` and its
two Verilog source files. The required sample image memories are included.

## Project files

- `src/Img_vgaPlayground.v` — top module, image memories, animation, and RGB output.
- `src/hsync_generator.v` — VGA synchronization and pixel coordinates.
- `data/bg1_dithering.mem` and `data/bg1.mem` — the two sample image memories.
- `info.yaml` — Tiny Tapeout project configuration and output pin mapping.
- `test/Makefile` and `test/tb.v` — Icarus Verilog / Cocotb simulation setup.
- `test/test.py` — VGA synchronization checks and captured PNG frames.

## Run the simulation

Install Icarus Verilog (`iverilog` and `vvp`), Make, and Python 3.11 or later.
Then, from the repository root:

```sh
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r test/requirements.txt
cd test
make
```

The Makefile enables SystemVerilog syntax (`-g2012`) for the sized casts in
the transition RTL. Run the simulation from `test/`, so the RTL's
`../data/` image paths resolve correctly.

The tests capture the first three frames into `test/output/frame0.png`
through `frame2.png` and check VGA synchronization. These early frames show
the start of the slide; the full transition takes 192 frames. Optional PNG
reference comparisons are skipped when `test/reference/` has no reference
frames. Captured frames and simulator output are ignored by Git.

## Image format and credits

Each image memory contains 76,800 hexadecimal RGB222 values for a
320 × 240 image. To use your own images, replace the contents of the two
`.mem` files while keeping their names and format.

The sample image files and supporting templates come from
[pongsagon/teach_hw](https://github.com/pongsagon/teach_hw). See
[UPSTREAM.md](UPSTREAM.md) for the exact source revision and [LICENSE](LICENSE)
for the upstream Apache-2.0 license. Existing RTL credits are retained.
