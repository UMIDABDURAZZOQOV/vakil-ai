"""One-off script: renders the Vakil AI "V" mark (same geometry as
lib/widgets/gradient_logo.dart) as a standalone PNG, for use as the
Telegram bot's profile picture. Run once with the backend venv active:
    python generate_bot_logo.py
Output: vakil_ai_bot_logo.png (512x512) in the project root.
"""

from PIL import Image, ImageDraw

SIZE = 512
NAVY_TOP = (10, 23, 48)
NAVY_BOTTOM = (22, 39, 74)
GOLD = (203, 163, 92)
EMERALD = (34, 197, 139)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_background(size):
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        color = lerp(NAVY_TOP, NAVY_BOTTOM, y / size)
        for x in range(size):
            px[x, y] = color
    return img


def make_gradient_diag(size):
    """Top-left (gold) to bottom-right (emerald) diagonal gradient."""
    img = Image.new("RGB", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size)
            px[x, y] = lerp(GOLD, EMERALD, min(max(t, 0), 1))
    return img


def draw_chevron(mask_draw, pts, width):
    mask_draw.line(pts, fill=255, width=width, joint="curve")
    r = width // 2
    for x, y in pts:
        mask_draw.ellipse([x - r, y - r, x + r, y + r], fill=255)


def main():
    bg = make_background(SIZE)
    gradient = make_gradient_diag(SIZE)

    # Logo occupies the centered 70% of the canvas so a circular crop
    # (Telegram avatars are round) doesn't clip the mark.
    inset = int(SIZE * 0.15)
    logo_size = SIZE - 2 * inset

    def pt(px_frac, py_frac):
        return (inset + px_frac * logo_size, inset + py_frac * logo_size)

    stroke_w = int(logo_size * 0.16)

    mask = Image.new("L", (SIZE, SIZE), 0)
    mdraw = ImageDraw.Draw(mask)
    back = [pt(0.10, 0.12), pt(0.5, 0.68), pt(0.90, 0.12)]
    draw_chevron(mdraw, back, stroke_w)
    back_layer = Image.composite(gradient, bg, mask)
    result = Image.blend(bg, back_layer, 0.45)

    mask2 = Image.new("L", (SIZE, SIZE), 0)
    mdraw2 = ImageDraw.Draw(mask2)
    front = [pt(0.06, 0.34), pt(0.5, 0.92), pt(0.94, 0.34)]
    draw_chevron(mdraw2, front, stroke_w)
    result = Image.composite(gradient, result, mask2)

    result.save("../vakil_ai_bot_logo.png")
    print("Saved vakil_ai_bot_logo.png")


if __name__ == "__main__":
    main()
