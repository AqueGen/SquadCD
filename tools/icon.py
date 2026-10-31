"""SquadCD project icon: 400x400 PNG for CurseForge, 64x64 TGA for the game.

400 exactly, because CurseForge's logo cropper opens on a fixed 400x400
selection pinned to the top left: a larger image comes out cropped unless the
author drags the handles.
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

S = 512
OUT_SIZE = 400
BG = (24, 27, 34)
BG_EDGE = (44, 49, 60)
TEAL = (38, 214, 196)
DIM = (62, 68, 82)

ROWS = [84, 158, 232, 306, 380]
ICONS_X = (288, 362)
READY = [(1, 1), (1, 0), (0, 0), (1, 1), (0, 1)]

img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([0, 0, S - 1, S - 1], radius=96, fill=BG, outline=BG_EDGE, width=4)


def ready_icons(draw, fill):
    for y, states in zip(ROWS, READY):
        for x, on in zip(ICONS_X, states):
            if on:
                draw.rounded_rectangle([x, y, x + 48, y + 48], radius=10, fill=fill)


glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ready_icons(ImageDraw.Draw(glow), TEAL + (110,))
img.alpha_composite(glow.filter(ImageFilter.GaussianBlur(14)))

d = ImageDraw.Draw(img)
for y, states in zip(ROWS, READY):
    d.rounded_rectangle([76, y, 262, y + 48], radius=24, fill=DIM)
    for x, on in zip(ICONS_X, states):
        d.rounded_rectangle([x, y, x + 48, y + 48], radius=10, fill=TEAL if on else DIM)

here = Path(__file__).resolve().parent
# CurseForge's logo upload refused transparent corners and turned them black.
small = img.resize((OUT_SIZE, OUT_SIZE), Image.LANCZOS)
ground = Image.new("RGB", (OUT_SIZE, OUT_SIZE), BG)
ground.paste(small, (0, 0), small)
ground.save(here / "icon.png")
print(here / "icon.png")

game = here.parent / "Media" / "icon.tga"
game.parent.mkdir(exist_ok=True)
img.resize((64, 64), Image.LANCZOS).save(game)
print(game)
