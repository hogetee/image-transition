# Simulation

From the repository root, create and activate a Python virtual environment,
then install the packages in `test/requirements.txt`. Install Icarus Verilog
and Make separately.

Run `make` from this directory. The Makefile compiles
`hsync_generator.v`, `Img_vgaPlayground.v`, and the `tb` wrapper, which
instantiates `tt_um_vga_example`. Image paths resolve to `../data/`.

The tests check VGA synchronization and save three early animation frames
under `output/`. The image memories can make initial Icarus compilation
slow; later runs reuse the compiled simulation.

PNG reference comparison is optional. With no `reference/frame*.png`
files, that test is skipped. To enable it, add independently checked
`reference/frame0.png` through `frame2.png`.
