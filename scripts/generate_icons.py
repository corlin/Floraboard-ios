import os
import subprocess

# Configuration
SOURCE_ICON = "Floreboard/Assets.xcassets/AppIcon.appiconset/AppIcon.png"
OUTPUT_DIR = "misc/icons"

# Standard iOS Icon Sizes (Point Size, Scale)
ICON_SPECS = [
    (20, 1), (20, 2), (20, 3),
    (29, 1), (29, 2), (29, 3),
    (40, 1), (40, 2), (40, 3),
    (60, 2), (60, 3),
    (76, 1), (76, 2),
    (83.5, 2),
    (1024, 1)
]

def generate_icons():
    if not os.path.exists(SOURCE_ICON):
        print(f"Error: Source icon not found at {SOURCE_ICON}")
        return

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)

    print(f"Generating icons from {SOURCE_ICON}...")

    for point_size, scale in ICON_SPECS:
        pixel_size = int(point_size * scale)
        filename = f"Icon-{point_size}pt@{scale}x.png"
        if scale == 1:
             filename = f"Icon-{point_size}pt.png"
        
        output_path = os.path.join(OUTPUT_DIR, filename)
        
        # Use sips to resize
        cmd = ["sips", "-z", str(pixel_size), str(pixel_size), SOURCE_ICON, "--out", output_path]
        
        try:
            subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL)
            print(f"Generated {filename} ({pixel_size}x{pixel_size})")
        except subprocess.CalledProcessError as e:
            print(f"Failed to generate {filename}: {e}")

    print("\nIcon generation complete. Check the 'misc/icons' directory.")

if __name__ == "__main__":
    generate_icons()
