/*
 * Copyright (c) 2024 Tiny Tapeout LTD
 * SPDX-License-Identifier: Apache-2.0
 * Author: Uri Shaked


 - Modified by Pongsgon Vichitvejpaisal to 
  load 320x240 6-bit color image
 */


`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    localparam IMG_SIZE       = 320;
    localparam MUL_FACTOR     = 2;
    localparam DISPLAY_WIDTH  = 640;
    localparam DISPLAY_HEIGHT = 480;

    localparam SLIDE_FRAMES = 64;
    localparam FADE_FRAMES  = 128;
    localparam END_FRAME    = SLIDE_FRAMES + FADE_FRAMES;

    // =========================================================
    // VGA Signals
    // =========================================================

    wire hsync;
    wire vsync;
    wire video_active;
    wire [9:0] pix_x;
    wire [9:0] pix_y;

    wire [1:0] R, G, B;

    assign uo_out  = {hsync, B[0], G[0], R[0],
                      vsync, B[1], G[1], R[1]};

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused_ok = &{ena, ui_in[7:1], uio_in};

    hvsync_generator vga_sync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(video_active),
        .hpos(pix_x),
        .vpos(pix_y)
    );

    // =========================================================
    // Image Memories (RGB222)
    // =========================================================

    reg [5:0] img  [0:76799];
    reg [5:0] img2 [0:76799];

    initial begin
        $readmemh("../data/bg1_dithering.mem", img);
        $readmemh("../data/bg1.mem", img2);
    end

    // =========================================================
    // Animation Timer
    // =========================================================

    reg [7:0] frame_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            frame_count <= 0;
        else if (pix_x == 0 && pix_y == 0) begin
            if (frame_count < END_FRAME)
                frame_count <= frame_count + 1'b1;
        end
    end

    // =========================================================
    // Blur Function (5-point Average)
    // =========================================================

    function [5:0] blur_pixel;
        input integer x;
        input integer y;
        input integer radius;

        integer xl, xr, yu, yd;
        integer index;

        reg [5:0] c, l, r, u, d;
        reg [3:0] red_sum;
        reg [3:0] green_sum;
        reg [3:0] blue_sum;

        begin
            xl = (x >= radius) ? x - radius : 0;
            xr = (x + radius < IMG_SIZE)
                 ? x + radius : IMG_SIZE - 1;

            yu = (y >= radius) ? y - radius : 0;
            yd = (y + radius < 240)
                 ? y + radius : 239;

            index = y * IMG_SIZE + x;

            c = img[index];
            l = img[y * IMG_SIZE + xl];
            r = img[y * IMG_SIZE + xr];
            u = img[yu * IMG_SIZE + x];
            d = img[yd * IMG_SIZE + x];

            // Average RGB channels separately.
            red_sum =
                {2'b0, c[5:4]} +
                {2'b0, l[5:4]} +
                {2'b0, r[5:4]} +
                {2'b0, u[5:4]} +
                {2'b0, d[5:4]};

            green_sum =
                {2'b0, c[3:2]} +
                {2'b0, l[3:2]} +
                {2'b0, r[3:2]} +
                {2'b0, u[3:2]} +
                {2'b0, d[3:2]};

            blue_sum =
                {2'b0, c[1:0]} +
                {2'b0, l[1:0]} +
                {2'b0, r[1:0]} +
                {2'b0, u[1:0]} +
                {2'b0, d[1:0]};

            blur_pixel = {
                2'(red_sum / 5),
                2'(green_sum / 5),
                2'(blue_sum / 5)
            };
        end
    endfunction

    // =========================================================
    // Image Slide + Blur + Transition
    // =========================================================

    integer x, y;
    integer shift;
    integer x_img, x_img2;
    integer radius;
    integer fade_level;

    reg [5:0] pixel1;
    reg [5:0] pixel2;
    reg [5:0] next_color;

    reg valid1;
    reg valid2;

    reg [3:0] dither_threshold;

    always @(*) begin
        x = pix_x / MUL_FACTOR;
        y = pix_y / MUL_FACTOR;

        shift = 0;
        radius = 0;
        fade_level = 0;

        x_img = 0;
        x_img2 = 0;

        valid1 = 0;
        valid2 = 0;

        pixel1 = 0;
        pixel2 = 0;
        next_color = 0;

        // A simple spatial dither pattern (0 to 15).
        dither_threshold = {
            pix_x[1] ^ pix_y[1],
            pix_x[0] ^ pix_y[0],
            pix_y[1],
            pix_x[0]
        };

        if (frame_count < SLIDE_FRAMES) begin
            // Slide images in from opposite sides.
            shift = (SLIDE_FRAMES - frame_count) * 5;

            x_img  = x + shift;
            x_img2 = x - shift;

            if (x_img >= 0 && x_img < IMG_SIZE)
                valid1 = 1;

            if (x_img2 >= 0 && x_img2 < IMG_SIZE)
                valid2 = 1;

            if (y < 240) begin
                if (valid1)
                    pixel1 = img[y * IMG_SIZE + x_img];

                if (valid2)
                    pixel2 = img2[y * IMG_SIZE + x_img2];
            end

            if (valid1 && valid2)
                next_color = (dither_threshold < 8)
                             ? pixel2 : pixel1;
            else if (valid1)
                next_color = pixel1;
            else if (valid2)
                next_color = pixel2;

        end else if (frame_count < END_FRAME) begin
            // Gradually blur img while revealing img2.
            radius = 1 + ((frame_count - SLIDE_FRAMES) / 32);
            fade_level = (frame_count - SLIDE_FRAMES) / 8;

            if (x < IMG_SIZE && y < 240) begin
                pixel1 = blur_pixel(x, y, radius);
                pixel2 = img2[y * IMG_SIZE + x];

                next_color = (dither_threshold < fade_level)
                             ? pixel2 : pixel1;
            end

        end else begin
            // Show only img2 after the transition.
            if (x < IMG_SIZE && y < 240)
                next_color = img2[y * IMG_SIZE + x];
        end
    end

    // =========================================================
    // VGA Output Register
    // =========================================================

    reg [5:0] color;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            color <= 0;
        else
            color <= next_color;
    end

    assign R = video_active ? color[5:4] : 2'b00;
    assign G = video_active ? color[3:2] : 2'b00;
    assign B = video_active ? color[1:0] : 2'b00;

endmodule

`default_nettype wire
