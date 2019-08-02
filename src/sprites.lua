local font_data = {
    minfilter = "linear",
    magfilter = "linear",
    is_premult = true,
    {
        filename = "sprites/Untitled.png",
        x1 = 0, y1 = 0, x2 = 8, y2 = 8,
        s1 = 0.0078125, t1 = 0.859375, s2 = 0.0703125, t2 = 0.984375,
        width = 8, height = 8,
    },
}

return am._init_fonts(font_data, "sprites.png")