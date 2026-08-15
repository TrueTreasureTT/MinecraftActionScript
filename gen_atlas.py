"""
Generates atlas.png: a 256x256 texture atlas, 16 tiles across x 16 tiles down,
each tile 16x16 px. Tile coordinates here MUST match Block.hx's TOP/BOTTOM/etc
arrays: e.g. grass top is tile (3,0), dirt is tile (2,0), stone is (4,0).

All patterns are hand-authored per-pixel, original designs (noise-dithered
flat colors with simple structural motifs -- grain lines, speckle, veins).
Nothing here is copied from any existing game's asset files.
"""
from PIL import Image
import random

TILE = 16
GRID = 16
ATLAS = TILE * GRID  # 256

random.seed(42)  # deterministic output

img = Image.new("RGBA", (ATLAS, ATLAS), (0, 0, 0, 0))
px = img.load()

def set_tile(tx, ty, painter):
    """painter(x,y) -> (r,g,b,a) for local tile coords 0..15"""
    ox, oy = tx * TILE, ty * TILE
    for y in range(TILE):
        for x in range(TILE):
            px[ox + x, oy + y] = painter(x, y)

def dither(base, variance, x, y, seed_offset=0):
    """Deterministic per-pixel noise for a hand-painted look."""
    random.seed((x * 31 + y * 17 + seed_offset) ^ 0x5bd1)
    r, g, b = base
    v = variance
    return (
        max(0, min(255, r + random.randint(-v, v))),
        max(0, min(255, g + random.randint(-v, v))),
        max(0, min(255, b + random.randint(-v, v))),
        255,
    )

# ---- (1,0) Grass side: dirt base with green fringe along top 4px ----
def grass_side(x, y):
    if y < 4:
        # green fringe, jagged bottom edge
        jag = (x % 3 == 0)
        if y == 3 and jag:
            return dither((118, 84, 53), 10, x, y, 1)  # dirt poking through
        return dither((91, 153, 61), 14, x, y, 1)
    return dither((118, 84, 53), 12, x, y, 2)
set_tile(1, 0, grass_side)

# ---- (2,0) Dirt: warm brown speckle ----
def dirt(x, y):
    return dither((118, 84, 53), 16, x, y, 3)
set_tile(2, 0, dirt)

# ---- (3,0) Grass top: green speckle with slightly lighter blades ----
def grass_top(x, y):
    base = (91, 153, 61)
    c = dither(base, 12, x, y, 4)
    random.seed((x * 13 + y * 41) ^ 0x33)
    if random.random() < 0.12:
        return (max(0, c[0]-10), min(255, c[1]+18), max(0, c[2]-10), 255)
    return c
set_tile(3, 0, grass_top)

# ---- (4,0) Stone: cool grey with darker fleck ----
def stone(x, y):
    base = (127, 127, 127)
    c = dither(base, 10, x, y, 5)
    random.seed((x * 7 + y * 23) ^ 0x77)
    if random.random() < 0.08:
        return (max(0, c[0]-25), max(0, c[1]-25), max(0, c[2]-25), 255)
    return c
set_tile(4, 0, stone)

# ---- (5,0) Cobblestone: stone base with darker mortar grid ----
def cobble(x, y):
    base = (122, 122, 122)
    on_seam = (x % 4 == 0) or (y % 4 == 0) or ((x + y) % 8 == 0)
    if on_seam:
        return dither((70, 70, 70), 8, x, y, 6)
    return dither(base, 14, x, y, 6)
set_tile(5, 0, cobble)

# ---- (6,0) Wood log side: vertical bark striping ----
def log_side(x, y):
    stripe = (x % 3 == 0)
    base = (90, 62, 38) if stripe else (110, 78, 48)
    return dither(base, 8, x, y, 7)
set_tile(6, 0, log_side)

# ---- (6,1) Wood log end: rings ----
def log_end(x, y):
    cx, cy = 7.5, 7.5
    d = ((x - cx) ** 2 + (y - cy) ** 2) ** 0.5
    ring = int(d) % 3 == 0
    base = (168, 130, 84) if not ring else (140, 104, 64)
    return dither(base, 8, x, y, 8)
set_tile(6, 1, log_end)

# ---- (7,0) Leaves: dense green speckle, some transparency-suggestive dark flecks ----
def leaves(x, y):
    base = (63, 122, 46)
    c = dither(base, 20, x, y, 9)
    random.seed((x * 19 + y * 5) ^ 0x99)
    if random.random() < 0.15:
        return (max(0,c[0]-20), max(0,c[1]-20), max(0,c[2]-20), 255)
    return c
set_tile(7, 0, leaves)

# ---- (8,0) Sand: pale tan speckle ----
def sand(x, y):
    return dither((219, 205, 154), 10, x, y, 10)
set_tile(8, 0, sand)

# ---- (9,0) Water: blue with horizontal wave bands, semi-transparent ----
def water(x, y):
    base = (48, 100, 191)
    band = (y % 4 in (0, 1))
    c = dither(base if band else (58, 112, 201), 8, x, y, 11)
    return (c[0], c[1], c[2], 200)  # alpha 200 for translucency
set_tile(9, 0, water)

# ---- (10,0) Wood planks: horizontal boards ----
def planks(x, y):
    board = y // 4
    seam = (y % 4 == 0)
    base = (161, 120, 76) if board % 2 == 0 else (171, 130, 84)
    if seam:
        return dither((120, 88, 54), 6, x, y, 12)
    return dither(base, 8, x, y, 12)
set_tile(10, 0, planks)

# ---- (11,0) Bedrock: dark grey, heavy noise, chunky blotches ----
def bedrock(x, y):
    base = (60, 60, 64)
    c = dither(base, 24, x, y, 13)
    return c
set_tile(11, 0, bedrock)

# ---- (12,0) Coal ore: stone base with black speckle clusters ----
def coal_ore(x, y):
    base = (127, 127, 127)
    c = dither(base, 10, x, y, 14)
    # cluster centers for ore flecks (deterministic small set of blobs)
    clusters = [(4, 4), (11, 6), (7, 11)]
    for cxp, cyp in clusters:
        if (x - cxp) ** 2 + (y - cyp) ** 2 <= 2.6:
            return dither((25, 25, 27), 6, x, y, 114)
    return c
set_tile(12, 0, coal_ore)

# ---- (13,0) Iron ore: stone base with tan/rust speckle clusters ----
def iron_ore(x, y):
    base = (127, 127, 127)
    c = dither(base, 10, x, y, 15)
    clusters = [(5, 3), (10, 5), (6, 10), (12, 12)]
    for cxp, cyp in clusters:
        if (x - cxp) ** 2 + (y - cyp) ** 2 <= 2.0:
            return dither((196, 148, 110), 12, x, y, 115)
    return c
set_tile(13, 0, iron_ore)

# ---- (14,0) Gold ore: stone base with yellow speckle clusters ----
def gold_ore(x, y):
    base = (127, 127, 127)
    c = dither(base, 10, x, y, 16)
    clusters = [(4, 5), (10, 4), (8, 11), (12, 9)]
    for cxp, cyp in clusters:
        if (x - cxp) ** 2 + (y - cyp) ** 2 <= 2.0:
            return dither((232, 202, 87), 10, x, y, 116)
    return c
set_tile(14, 0, gold_ore)

# ---- (15,0) Diamond ore: stone base with cyan speckle clusters ----
def diamond_ore(x, y):
    base = (127, 127, 127)
    c = dither(base, 10, x, y, 17)
    clusters = [(5, 4), (11, 6), (7, 12)]
    for cxp, cyp in clusters:
        if (x - cxp) ** 2 + (y - cyp) ** 2 <= 2.2:
            return dither((110, 224, 220), 10, x, y, 117)
    return c
set_tile(15, 0, diamond_ore)

# ---- (0,1) Gravel: grey with irregular light/dark pebble speckle (higher variance than stone, no seam pattern) ----
def gravel(x, y):
    base = (117, 113, 110)
    c = dither(base, 26, x, y, 18)
    random.seed((x * 11 + y * 29) ^ 0xAB)
    if random.random() < 0.1:
        return (max(0,c[0]-30), max(0,c[1]-30), max(0,c[2]-30), 255)
    return c
set_tile(0, 1, gravel)

# ---- (1,1) Glass: pale, mostly-uniform with a faint highlight streak, alpha well below 255 ----
def glass(x, y):
    base = (210, 228, 230)
    highlight = (x - y > 8 and x - y < 11)
    c = dither(base, 6, x, y, 19)
    if highlight:
        c = (min(255,c[0]+30), min(255,c[1]+30), min(255,c[2]+30), c[3])
    return (c[0], c[1], c[2], 70)
set_tile(1, 1, glass)

# ---- (2,1) Brick: red-brown with mortar lines, bricks offset every other row (running bond pattern) ----
def brick(x, y):
    row = y // 4
    offset = 4 if row % 2 == 1 else 0
    xm = (x + offset) % 16
    on_seam = (y % 4 == 0) or (xm % 8 == 0)
    if on_seam:
        return dither((178, 172, 160), 6, x, y, 20)
    return dither((146, 68, 55), 10, x, y, 20)
set_tile(2, 1, brick)

# ---- (3,1) Obsidian: very dark purple-black with subtle purple fleck ----
def obsidian(x, y):
    base = (24, 18, 30)
    c = dither(base, 10, x, y, 21)
    random.seed((x * 17 + y * 3) ^ 0xCD)
    if random.random() < 0.1:
        return (min(255,c[0]+18), c[1], min(255,c[2]+28), 255)
    return c
set_tile(3, 1, obsidian)

# ---- (4,1) Snow: white with slight blue-grey speckle ----
def snow(x, y):
    return dither((238, 240, 245), 8, x, y, 22)
set_tile(4, 1, snow)

# ---- (5,1) Ice: pale blue, translucent, faint diagonal crack streaks ----
def ice(x, y):
    base = (168, 202, 224)
    crack = ((x + y * 2) % 7 == 0)
    c = dither(base, 8, x, y, 23)
    if crack:
        c = (max(0,c[0]-15), max(0,c[1]-10), c[2], c[3])
    return (c[0], c[1], c[2], 190)
set_tile(5, 1, ice)

# ---- (7,1) Mossy cobblestone: cobblestone grid with green moss patches replacing some mortar/stone cells ----
def mossy_cobble(x, y):
    base = (122, 122, 122)
    on_seam = (x % 4 == 0) or (y % 4 == 0) or ((x + y) % 8 == 0)
    random.seed((x * 5 + y * 7) ^ 0xEE)
    mossy = random.random() < 0.35
    if on_seam:
        return dither((70, 70, 70), 8, x, y, 24)
    if mossy:
        return dither((80, 128, 62), 14, x, y, 24)
    return dither(base, 14, x, y, 24)
set_tile(7, 1, mossy_cobble)

# Fill any untouched tiles with magenta/black checker (visual "missing texture" marker)
def missing(x, y):
    return (255, 0, 255, 255) if (x // 4 + y // 4) % 2 == 0 else (0, 0, 0, 255)

used = {(1,0),(2,0),(3,0),(4,0),(5,0),(6,0),(6,1),(7,0),(8,0),(9,0),(10,0),(11,0),
        (12,0),(13,0),(14,0),(15,0),(0,1),(1,1),(2,1),(3,1),(4,1),(5,1),(7,1)}
for ty in range(GRID):
    for tx in range(GRID):
        if (tx, ty) not in used:
            corner = img.getpixel((tx*TILE, ty*TILE))
            if corner[3] == 0:  # still empty
                set_tile(tx, ty, missing)

img.save("/home/claude/haxe-pe/assets/images/atlas.png")
print("Saved atlas.png:", img.size)
