# scripts/generate_universal_icon.py
# Generates the official production-grade AeroSense Pro icon across all platforms:
# Android (all mipmap densities), Windows (.ico), Web Dashboard (favicon & logo), and Mobile Assets.

import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_master_icon(size=1024):
    # Render at 2x resolution (2048x2048) for supersampled anti-aliasing
    canvas_size = size * 2
    img = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    cx = canvas_size // 2
    cy = canvas_size // 2

    # 1. Background Squircle
    corner_radius = int(canvas_size * 0.22)
    squircle_margin = int(canvas_size * 0.04)
    x0, y0 = squircle_margin, squircle_margin
    x1, y1 = canvas_size - squircle_margin, canvas_size - squircle_margin

    # Ambient Background Gradient (Deep obsidian to rich navy)
    for i in range(y0, y1):
        progress = (i - y0) / (y1 - y0)
        r = int(7 + progress * 6)
        g = int(13 + progress * 10)
        b = int(30 + progress * 24)
        draw.line([(x0, i), (x1, i)], fill=(r, g, b, 255))

    # Mask to squircle rounded rectangle
    mask = Image.new("L", (canvas_size, canvas_size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([x0, y0, x1, y1], radius=corner_radius, fill=255)
    
    bg = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bg.paste(img, (0, 0), mask=mask)
    img = bg
    draw = ImageDraw.Draw(img)

    # Hairline Squircle Rim Border
    draw.rounded_rectangle(
        [x0, y0, x1, y1],
        radius=corner_radius,
        outline=(56, 189, 248, 65),
        width=int(canvas_size * 0.005)
    )

    # 2. Ambient Radial Air Glow in Center
    glow = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_r = int(canvas_size * 0.38)
    for r in range(glow_r, 0, -8):
        alpha = int((1.0 - (r / glow_r) ** 1.5) * 45)
        glow_draw.ellipse(
            [cx - r, cy - r, cx + r, cy + r],
            fill=(0, 242, 254, alpha)
        )
    img = Image.alpha_composite(img, glow)
    draw = ImageDraw.Draw(img)

    # 3. Protective Shield / Outer Aerodynamic Wings
    # Curved protective shield arcs representing home & city defense
    shield_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    shield_draw = ImageDraw.Draw(shield_layer)

    # Draw symmetric outer airflow shield wings
    shield_pts_left = [
        (cx - int(canvas_size * 0.05), cy - int(canvas_size * 0.34)),
        (cx - int(canvas_size * 0.28), cy - int(canvas_size * 0.26)),
        (cx - int(canvas_size * 0.38), cy - int(canvas_size * 0.08)),
        (cx - int(canvas_size * 0.35), cy + int(canvas_size * 0.16)),
        (cx - int(canvas_size * 0.20), cy + int(canvas_size * 0.34)),
        (cx, cy + int(canvas_size * 0.40)),
        (cx - int(canvas_size * 0.14), cy + int(canvas_size * 0.28)),
        (cx - int(canvas_size * 0.26), cy + int(canvas_size * 0.12)),
        (cx - int(canvas_size * 0.26), cy - int(canvas_size * 0.10)),
        (cx - int(canvas_size * 0.16), cy - int(canvas_size * 0.22)),
    ]
    # Mirror for right side
    shield_pts_right = [(canvas_size - x, y) for x, y in shield_pts_left]
    shield_pts_right.reverse()

    shield_draw.polygon(shield_pts_left, fill=(2, 132, 199, 140))
    shield_draw.polygon(shield_pts_right, fill=(6, 182, 212, 140))
    
    # Outer wing rim highlight
    shield_draw.line(shield_pts_left, fill=(0, 242, 254, 210), width=int(canvas_size * 0.008), joint="curve")
    shield_draw.line(shield_pts_right, fill=(52, 211, 153, 210), width=int(canvas_size * 0.008), joint="curve")

    img = Image.alpha_composite(img, shield_layer)
    draw = ImageDraw.Draw(img)

    # 4. Central 4-Blade Smart Relay Ventilation Impeller
    # Each blade curves outward symmetrically (0, 90, 180, 270 deg)
    blades_layer = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    b_draw = ImageDraw.Draw(blades_layer)

    blade_length = int(canvas_size * 0.24)
    blade_width = int(canvas_size * 0.09)

    colors = [
        ((0, 242, 254, 235), (56, 189, 248, 255)),   # Cyan (Exhaust)
        ((16, 185, 129, 235), (52, 211, 153, 255)),  # Emerald (Purifier)
        ((6, 182, 212, 235), (0, 242, 254, 255)),   # Aqua (HVAC)
        ((5, 150, 105, 235), (16, 185, 129, 255)),  # Mint (Damper)
    ]

    for i in range(4):
        angle_deg = i * 90 + 25
        base_angle = math.radians(angle_deg)
        tip_angle = math.radians(angle_deg + 42)

        # Build blade contour
        p0 = (cx, cy)
        p1 = (cx + int(blade_length * 0.5 * math.cos(base_angle - 0.2)),
              cy + int(blade_length * 0.5 * math.sin(base_angle - 0.2)))
        p2 = (cx + int(blade_length * math.cos(tip_angle)),
              cy + int(blade_length * math.sin(tip_angle)))
        p3 = (cx + int(blade_length * 0.65 * math.cos(tip_angle + 0.35)),
              cy + int(blade_length * 0.65 * math.sin(tip_angle + 0.35)))
        p4 = (cx + int(blade_length * 0.25 * math.cos(base_angle + 0.4)),
              cy + int(blade_length * 0.25 * math.sin(base_angle + 0.4)))

        blade_fill, blade_stroke = colors[i]
        b_draw.polygon([p0, p1, p2, p3, p4], fill=blade_fill)
        b_draw.line([p0, p1, p2, p3, p4, p0], fill=blade_stroke, width=int(canvas_size * 0.005), joint="curve")

    img = Image.alpha_composite(img, blades_layer)
    draw = ImageDraw.Draw(img)

    # 5. Central Living Seed / Clean Air Core
    core_r = int(canvas_size * 0.055)
    # Inner dark disc
    draw.ellipse([cx - core_r, cy - core_r, cx + core_r, cy + core_r], fill=(11, 19, 43, 255), outline=(255, 255, 255, 200), width=int(canvas_size * 0.006))
    # Glowing white/cyan focal dot
    dot_r = int(canvas_size * 0.024)
    draw.ellipse([cx - dot_r, cy - dot_r, cx + dot_r, cy + dot_r], fill=(0, 242, 254, 255))
    draw.ellipse([cx - int(dot_r * 0.5), cy - int(dot_r * 0.5), cx + int(dot_r * 0.5), cy + int(dot_r * 0.5)], fill=(255, 255, 255, 255))

    # Downscale from 2048 to target size with Lanczos filter for razor-sharp antialiasing
    final_icon = img.resize((size, size), Image.Resampling.LANCZOS)
    return final_icon

def export_all_icons():
    print("Rendering master 1024x1024 AeroSense Pro icon...")
    master = create_master_icon(1024)

    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    mobile_dir = os.path.join(base_dir, "mobile_app")
    web_dir = os.path.join(base_dir, "web_dashboard")

    # 1. Mobile App Master Assets
    master_png_path = os.path.join(mobile_dir, "assets", "images", "logo.png")
    os.makedirs(os.path.dirname(master_png_path), exist_ok=True)
    master.save(master_png_path, format="PNG")
    print(f"  [OK] Saved mobile asset: {master_png_path}")

    # 2. Web Dashboard Master & Favicon
    web_logo_path = os.path.join(web_dir, "logo.png")
    master.resize((512, 512), Image.Resampling.LANCZOS).save(web_logo_path, format="PNG")
    
    web_favicon_path = os.path.join(web_dir, "favicon.png")
    master.resize((64, 64), Image.Resampling.LANCZOS).save(web_favicon_path, format="PNG")
    print("  [OK] Saved web dashboard logo & favicon")

    # 3. Android Mipmap Densities
    android_res = os.path.join(mobile_dir, "android", "app", "src", "main", "res")
    mipmap_targets = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    for folder, dim in mipmap_targets.items():
        folder_path = os.path.join(android_res, folder)
        if os.path.exists(folder_path):
            target_path = os.path.join(folder_path, "ic_launcher.png")
            master.resize((dim, dim), Image.Resampling.LANCZOS).save(target_path, format="PNG")
            print(f"  [OK] Saved Android {folder} ({dim}x{dim})")

    # 4. Windows Desktop .ICO (Multi-resolution embedded)
    windows_ico_path = os.path.join(mobile_dir, "windows", "runner", "resources", "app_icon.ico")
    if os.path.exists(os.path.dirname(windows_ico_path)):
        master.save(
            windows_ico_path,
            format="ICO",
            sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
        )
        print(f"  [OK] Saved Windows multi-res .ico: {windows_ico_path}")

    print("\nAll platform icons generated and installed successfully!")

if __name__ == "__main__":
    export_all_icons()
