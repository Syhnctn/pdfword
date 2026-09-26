from __future__ import annotations

from pathlib import Path
from typing import Iterable, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont

Color = Tuple[int, int, int]


ROOT = Path(__file__).resolve().parents[1]
OUT_BASE = ROOT / "marketing" / "playstore"
ICONS_DIR = OUT_BASE / "icons"
SCREENSHOTS_DIR = OUT_BASE / "screenshots"
FEATURE_DIR = OUT_BASE / "feature-graphic"


def ensure_dirs() -> None:
    for path in (ICONS_DIR, SCREENSHOTS_DIR, FEATURE_DIR):
        path.mkdir(parents=True, exist_ok=True)


def font_path_candidates(bold: bool) -> Iterable[Path]:
    if bold:
        names = [
            "segoeuib.ttf",
            "arialbd.ttf",
            "bahnschrift.ttf",
            "calibrib.ttf",
        ]
    else:
        names = [
            "segoeui.ttf",
            "arial.ttf",
            "bahnschrift.ttf",
            "calibri.ttf",
        ]
    for name in names:
        yield Path("C:/Windows/Fonts") / name


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    for candidate in font_path_candidates(bold):
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default()


def lerp(a: int, b: int, t: float) -> int:
    return int(a + (b - a) * t)


def vertical_gradient(size: Tuple[int, int], top: Color, bottom: Color) -> Image.Image:
    w, h = size
    image = Image.new("RGB", (w, h), top)
    draw = ImageDraw.Draw(image)
    for y in range(h):
        t = y / max(h - 1, 1)
        color = (lerp(top[0], bottom[0], t), lerp(top[1], bottom[1], t), lerp(top[2], bottom[2], t))
        draw.line([(0, y), (w, y)], fill=color)
    return image


def add_glow(base: Image.Image, center: Tuple[int, int], radius: int, color: Color, alpha: int = 120) -> None:
    glow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow)
    x, y = center
    draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(*color, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(radius // 2))
    base.alpha_composite(glow)


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def draw_brand_logo(base: Image.Image, x: int, y: int, size: int, accent: int = 0) -> None:
    tile = vertical_gradient((size, size), (74, 145, 255), (31, 93, 255)).convert("RGBA")
    mask = rounded_mask(size, int(size * 0.26))
    base.paste(tile, (x, y), mask)

    draw = ImageDraw.Draw(base)
    pad = int(size * 0.23)
    doc_x0 = x + pad
    doc_y0 = y + int(size * 0.2)
    doc_x1 = x + size - pad
    doc_y1 = y + size - int(size * 0.23)
    fold = int(size * 0.18)

    draw.rounded_rectangle((doc_x0, doc_y0, doc_x1, doc_y1), radius=int(size * 0.08), fill=(236, 243, 255, 255))
    draw.polygon(
        [
            (doc_x1 - fold, doc_y0),
            (doc_x1, doc_y0),
            (doc_x1, doc_y0 + fold),
        ],
        fill=(31, 93, 255, 255),
    )
    line_color = (31, 93, 255, 255)
    draw.rounded_rectangle(
        (doc_x0 + int(size * 0.07), doc_y0 + int(size * 0.26), doc_x1 - int(size * 0.18), doc_y0 + int(size * 0.31)),
        radius=4,
        fill=line_color,
    )
    draw.rounded_rectangle(
        (doc_x0 + int(size * 0.07), doc_y0 + int(size * 0.39), doc_x1 - int(size * 0.12), doc_y0 + int(size * 0.44)),
        radius=4,
        fill=line_color,
    )

    circle_r = int(size * 0.21)
    cx = x + size - int(size * 0.1)
    cy = y + size - int(size * 0.1)
    badge_color = (13, 29, 60, 255) if accent != 1 else (22, 38, 75, 255)
    draw.ellipse((cx - circle_r, cy - circle_r, cx + circle_r, cy + circle_r), fill=badge_color)
    arrow = (74, 145, 255, 255)
    if accent == 2:
        arrow = (30, 217, 161, 255)
    draw.line((cx - 11, cy, cx + 10, cy), fill=arrow, width=5)
    draw.line((cx + 3, cy - 7, cx + 10, cy), fill=arrow, width=5)
    draw.line((cx + 3, cy + 7, cx + 10, cy), fill=arrow, width=5)


def save_icon_variants() -> None:
    size = 512
    variants = [
        ("icon_primary_512.png", (5, 12, 28), (8, 24, 51), 0),
        ("icon_minimal_512.png", (9, 18, 40), (10, 35, 78), 1),
        ("icon_modern_512.png", (6, 16, 34), (7, 27, 60), 2),
    ]
    for filename, top, bottom, accent in variants:
        icon = vertical_gradient((size, size), top, bottom).convert("RGBA")
        add_glow(icon, (size // 2, size // 2), 170, (37, 99, 255), 90)
        draw_brand_logo(icon, 88, 88, 336, accent=accent)
        icon.convert("RGB").save(ICONS_DIR / filename, "PNG")

    # Adaptive icon files for Android usage.
    background = vertical_gradient((432, 432), (10, 30, 66), (8, 19, 38))
    background.save(ICONS_DIR / "adaptive_background_432.png", "PNG")

    foreground = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    add_glow(foreground, (216, 216), 130, (37, 99, 255), 115)
    draw_brand_logo(foreground, 86, 86, 260, accent=0)
    foreground.save(ICONS_DIR / "adaptive_foreground_432.png", "PNG")


def rounded_panel(draw: ImageDraw.ImageDraw, box: Tuple[int, int, int, int], fill: Tuple[int, int, int], border: Tuple[int, int, int], r: int = 26) -> None:
    draw.rounded_rectangle(box, radius=r, fill=fill, outline=border, width=2)


def draw_phone_shell(base: Image.Image, caption: str, subtitle: str) -> Tuple[int, int, int, int]:
    draw = ImageDraw.Draw(base)
    w, h = base.size
    title_font = get_font(66, bold=True)
    sub_font = get_font(34, bold=False)
    draw.text((90, 80), caption, font=title_font, fill=(244, 247, 255))
    draw.text((90, 168), subtitle, font=sub_font, fill=(152, 170, 207))

    phone_w, phone_h = 860, 1820
    x0 = (w - phone_w) // 2
    y0 = 370
    x1 = x0 + phone_w
    y1 = y0 + phone_h
    draw.rounded_rectangle((x0 - 4, y0 - 4, x1 + 4, y1 + 4), radius=78, fill=(11, 19, 35))
    draw.rounded_rectangle((x0, y0, x1, y1), radius=72, fill=(6, 14, 30))

    draw.rounded_rectangle((x0 + 300, y0 + 26, x0 + 560, y0 + 50), radius=12, fill=(18, 30, 56))
    draw.text((x0 + 60, y0 + 26), "9:41", font=get_font(26, bold=True), fill=(229, 235, 255))

    screen = (x0 + 30, y0 + 70, x1 - 30, y1 - 26)
    draw.rounded_rectangle(screen, radius=52, fill=(7, 18, 39))
    return screen


def draw_bottom_nav(draw: ImageDraw.ImageDraw, screen: Tuple[int, int, int, int], active: int) -> None:
    x0, y0, x1, y1 = screen
    nav_h = 112
    draw.rectangle((x0, y1 - nav_h, x1, y1), fill=(10, 22, 46))
    labels = ["Convert", "History", "Settings"]
    col_w = (x1 - x0) // 3
    for idx, label in enumerate(labels):
        cx = x0 + idx * col_w + col_w // 2
        color = (37, 99, 255) if idx == active else (138, 151, 179)
        draw.text((cx - 44, y1 - 48), label, font=get_font(22, bold=idx == active), fill=color)


def screenshot_login(path: Path) -> None:
    base = vertical_gradient((1080, 2400), (5, 11, 28), (8, 24, 51)).convert("RGBA")
    add_glow(base, (760, 300), 240, (37, 99, 255), 70)
    screen = draw_phone_shell(base, "Scan and Convert in Seconds", "AI powered PDF to Word experience")
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = screen

    draw_brand_logo(base, x0 + 255, y0 + 150, 250)
    draw.text((x0 + 125, y0 + 455), "PDF to Word Pro", font=get_font(64, bold=True), fill=(244, 247, 255))
    draw.text((x0 + 120, y0 + 535), "Convert scanned documents instantly", font=get_font(30), fill=(148, 165, 198))

    rounded_panel(draw, (x0 + 70, y0 + 690, x1 - 70, y0 + 800), (247, 249, 255), (247, 249, 255), r=28)
    draw.text((x0 + 200, y0 + 727), "Continue with Google", font=get_font(34, bold=True), fill=(23, 31, 54))

    rounded_panel(draw, (x0 + 70, y0 + 835, x1 - 70, y0 + 945), (247, 249, 255), (247, 249, 255), r=28)
    draw.text((x0 + 210, y0 + 872), "Continue with Apple", font=get_font(34, bold=True), fill=(23, 31, 54))

    rounded_panel(draw, (x0 + 70, y0 + 1010, x1 - 70, y0 + 1115), (7, 20, 43), (62, 82, 124), r=28)
    draw.text((x0 + 245, y0 + 1045), "Sign in with Email", font=get_font(33, bold=True), fill=(228, 235, 251))
    base.convert("RGB").save(path, "PNG")


def screenshot_convert(path: Path) -> None:
    base = vertical_gradient((1080, 2400), (5, 11, 28), (8, 24, 51)).convert("RGBA")
    add_glow(base, (260, 360), 200, (37, 99, 255), 70)
    screen = draw_phone_shell(base, "Upload PDF Files", "Track progress and convert with one tap")
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = screen

    draw_brand_logo(base, x0 + 40, y0 + 30, 86)
    draw.text((x0 + 145, y0 + 40), "PDF to Word Pro", font=get_font(36, bold=True), fill=(240, 245, 255))
    draw.text((x0 + 145, y0 + 82), "Converter Pro", font=get_font(24), fill=(138, 151, 179))

    rounded_panel(draw, (x0 + 36, y0 + 155, x1 - 36, y0 + 615), (14, 32, 66), (52, 79, 126), r=34)
    draw.text((x0 + 282, y0 + 338), "Upload PDF", font=get_font(54, bold=True), fill=(241, 246, 255))
    draw.text((x0 + 190, y0 + 412), "Tap to browse or drag files here", font=get_font(28), fill=(142, 161, 199))

    draw.text((x0 + 45, y0 + 660), "Selected Files", font=get_font(48, bold=True), fill=(242, 246, 255))
    rounded_panel(draw, (x0 + 36, y0 + 730, x1 - 36, y0 + 930), (15, 32, 61), (39, 63, 102), r=30)
    draw.text((x0 + 175, y0 + 792), "KUTAHYA_HALK_EGITIM...pdf", font=get_font(30, bold=True), fill=(238, 244, 255))
    draw.rectangle((x0 + 175, y0 + 850, x1 - 110, y0 + 864), fill=(52, 69, 95))
    draw.rectangle((x0 + 175, y0 + 850, x0 + 560, y0 + 864), fill=(37, 99, 255))

    rounded_panel(draw, (x0 + 36, y1 - 235, x1 - 36, y1 - 118), (37, 99, 255), (37, 99, 255), r=32)
    draw.text((x0 + 224, y1 - 196), "Convert to Word", font=get_font(44, bold=True), fill=(246, 250, 255))
    draw_bottom_nav(draw, screen, active=0)
    base.convert("RGB").save(path, "PNG")


def screenshot_processing(path: Path) -> None:
    base = vertical_gradient((1080, 2400), (6, 14, 34), (8, 26, 56)).convert("RGBA")
    add_glow(base, (760, 430), 220, (30, 217, 161), 55)
    screen = draw_phone_shell(base, "Live Job Tracking", "Queued to completed with status badges")
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = screen

    draw.text((x0 + 45, y0 + 42), "Conversion Queue", font=get_font(50, bold=True), fill=(244, 248, 255))
    cards = [
        ("Annual_Report_2023.pdf", "Processing", 68, (37, 99, 255)),
        ("Project_Specs_v2.pdf", "Ready", 100, (30, 217, 161)),
        ("Meeting_Notes.pdf", "Queued", 25, (138, 151, 179)),
    ]
    y = y0 + 130
    for name, status, pct, color in cards:
        rounded_panel(draw, (x0 + 34, y, x1 - 34, y + 200), (14, 30, 58), (34, 54, 92), r=30)
        draw.text((x0 + 68, y + 45), name, font=get_font(30, bold=True), fill=(238, 244, 255))
        draw.text((x1 - 210, y + 45), status, font=get_font(27, bold=True), fill=color)
        draw.rectangle((x0 + 68, y + 124, x1 - 88, y + 140), fill=(45, 62, 92))
        fill_w = int((x1 - 156) * pct / 100)
        draw.rectangle((x0 + 68, y + 124, x0 + 68 + fill_w, y + 140), fill=color)
        y += 224

    rounded_panel(draw, (x0 + 34, y1 - 345, x1 - 34, y1 - 140), (11, 26, 52), (33, 56, 94), r=30)
    draw.text((x0 + 65, y1 - 303), "Estimated completion: < 8 sec", font=get_font(32, bold=True), fill=(236, 243, 255))
    draw.text((x0 + 65, y1 - 255), "Auto-refresh enabled", font=get_font(27), fill=(129, 153, 196))
    draw_bottom_nav(draw, screen, active=0)
    base.convert("RGB").save(path, "PNG")


def screenshot_history(path: Path) -> None:
    base = vertical_gradient((1080, 2400), (5, 11, 28), (9, 28, 58)).convert("RGBA")
    add_glow(base, (300, 510), 220, (37, 99, 255), 60)
    screen = draw_phone_shell(base, "Access File History", "All converted files in one timeline")
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = screen

    draw.text((x0 + 44, y0 + 36), "History", font=get_font(64, bold=True), fill=(244, 248, 255))
    rounded_panel(draw, (x0 + 42, y0 + 132, x1 - 42, y0 + 218), (20, 35, 65), (34, 54, 90), r=22)
    draw.text((x0 + 76, y0 + 162), "Search converted files...", font=get_font(30), fill=(130, 149, 184))

    items = [
        ("Contract_Final_v2.docx", "10:42 AM  -  1.2 MB"),
        ("Resume_2024_Update.docx", "09:15 AM  -  450 KB"),
        ("Marketing_Brief_Q3.docx", "Yesterday  -  2.8 MB"),
        ("Invoice_TEMPLATE.docx", "Last week  -  156 KB"),
    ]
    y = y0 + 260
    for name, meta in items:
        rounded_panel(draw, (x0 + 42, y, x1 - 42, y + 170), (19, 34, 63), (34, 54, 90), r=28)
        draw.text((x0 + 86, y + 54), name, font=get_font(31, bold=True), fill=(236, 243, 255))
        draw.text((x0 + 86, y + 102), meta, font=get_font(25), fill=(137, 154, 188))
        y += 194

    draw.ellipse((x1 - 172, y1 - 280, x1 - 62, y1 - 170), fill=(37, 99, 255))
    draw.text((x1 - 134, y1 - 252), "+", font=get_font(56, bold=True), fill=(244, 247, 255))
    draw_bottom_nav(draw, screen, active=1)
    base.convert("RGB").save(path, "PNG")


def screenshot_settings(path: Path) -> None:
    base = vertical_gradient((1080, 2400), (4, 10, 26), (8, 24, 52)).convert("RGBA")
    add_glow(base, (760, 440), 220, (37, 99, 255), 70)
    screen = draw_phone_shell(base, "Control Your Preferences", "Manage account, quality and notifications")
    draw = ImageDraw.Draw(base)
    x0, y0, x1, y1 = screen

    draw.text((x0 + 44, y0 + 36), "Settings", font=get_font(64, bold=True), fill=(244, 248, 255))
    rounded_panel(draw, (x0 + 42, y0 + 128, x1 - 42, y0 + 360), (17, 33, 62), (32, 52, 88), r=30)
    draw.ellipse((x0 + 76, y0 + 168, x0 + 186, y0 + 278), fill=(230, 208, 170))
    draw.text((x0 + 218, y0 + 190), "Sarah Jenkins", font=get_font(36, bold=True), fill=(239, 245, 255))
    draw.text((x0 + 218, y0 + 236), "sarah.j@example.com", font=get_font(25), fill=(142, 160, 196))
    rounded_panel(draw, (x0 + 218, y0 + 280, x0 + 500, y0 + 340), (37, 99, 255), (37, 99, 255), r=30)
    draw.text((x0 + 260, y0 + 298), "Upgrade to Pro", font=get_font(24, bold=True), fill=(244, 248, 255))

    rows = [
        ("Dark Mode", True),
        ("High Quality Conversion", False),
        ("Push Notifications", True),
        ("Email Updates", False),
    ]
    y = y0 + 400
    for label, on in rows:
        rounded_panel(draw, (x0 + 42, y, x1 - 42, y + 118), (17, 33, 62), (32, 52, 88), r=24)
        draw.text((x0 + 80, y + 40), label, font=get_font(31, bold=True), fill=(238, 244, 255))
        toggle_x = x1 - 172
        track_color = (37, 99, 255) if on else (66, 84, 114)
        draw.rounded_rectangle((toggle_x, y + 38, toggle_x + 86, y + 80), radius=21, fill=track_color)
        knob_x = toggle_x + 58 if on else toggle_x + 28
        draw.ellipse((knob_x - 16, y + 43, knob_x + 16, y + 75), fill=(242, 246, 255))
        y += 138

    draw_bottom_nav(draw, screen, active=2)
    base.convert("RGB").save(path, "PNG")


def save_feature_graphic() -> None:
    image = vertical_gradient((1024, 500), (5, 12, 30), (8, 27, 58)).convert("RGBA")
    add_glow(image, (760, 170), 180, (37, 99, 255), 90)
    draw = ImageDraw.Draw(image)

    draw_brand_logo(image, 80, 98, 220, accent=0)
    draw.text((340, 120), "PDF to Word Pro", font=get_font(70, bold=True), fill=(244, 248, 255))
    draw.text((344, 206), "Scan. Convert. Edit.", font=get_font(40, bold=False), fill=(154, 173, 209))

    chips = ["Fast OCR", "Secure Downloads", "History Tracking"]
    x = 344
    for chip in chips:
        tw = draw.textbbox((0, 0), chip, font=get_font(28, bold=True))[2]
        w = tw + 54
        draw.rounded_rectangle((x, 282, x + w, 338), radius=20, fill=(17, 33, 62), outline=(42, 66, 108), width=2)
        draw.text((x + 26, 298), chip, font=get_font(28, bold=True), fill=(219, 230, 255))
        x += w + 16

    draw.rounded_rectangle((344, 366, 616, 432), radius=26, fill=(37, 99, 255))
    draw.text((386, 386), "Get Started", font=get_font(32, bold=True), fill=(245, 250, 255))

    image.convert("RGB").save(FEATURE_DIR / "feature_graphic_1024x500.png", "PNG")


def save_readme() -> None:
    text = """Play Store Marketing Assets

Icons (512x512):
- icon_primary_512.png
- icon_minimal_512.png
- icon_modern_512.png

Adaptive icon helpers:
- adaptive_background_432.png
- adaptive_foreground_432.png

Screenshots (1080x2400):
- screenshot_01_login.png
- screenshot_02_convert.png
- screenshot_03_processing.png
- screenshot_04_history.png
- screenshot_05_settings.png

Feature graphic:
- feature_graphic_1024x500.png
"""
    (OUT_BASE / "README.txt").write_text(text, encoding="utf-8")


def main() -> None:
    ensure_dirs()
    save_icon_variants()
    screenshot_login(SCREENSHOTS_DIR / "screenshot_01_login.png")
    screenshot_convert(SCREENSHOTS_DIR / "screenshot_02_convert.png")
    screenshot_processing(SCREENSHOTS_DIR / "screenshot_03_processing.png")
    screenshot_history(SCREENSHOTS_DIR / "screenshot_04_history.png")
    screenshot_settings(SCREENSHOTS_DIR / "screenshot_05_settings.png")
    save_feature_graphic()
    save_readme()
    print("Assets generated under:", OUT_BASE)


if __name__ == "__main__":
    main()
