#!/usr/bin/env python3
"""
Generate a CRT shader from config.toml template.
Output path is based on config hash for debugging/history.
"""

import hashlib
import os
import sys
from pathlib import Path

# Python 3.11+ has tomllib built-in, fallback to tomli for older versions
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: Python 3.11+ required, or install tomli: pip install tomli")
        sys.exit(1)


def main():
    script_dir = Path(__file__).parent
    config_path = script_dir / "config.toml"
    template_path = script_dir / "templates" / "crt.template.glsl"
    output_dir = Path("/tmp/crt-term")

    # Read config
    if not config_path.exists():
        print(f"Error: {config_path} not found")
        sys.exit(1)

    with open(config_path, "rb") as f:
        config = tomllib.load(f)

    # Read template
    if not template_path.exists():
        print(f"Error: {template_path} not found")
        sys.exit(1)

    with open(template_path, "r") as f:
        template = f.read()

    # Flatten config for template substitution
    values = {
        # Color
        "phosphor_r": config["color"]["phosphor_r"],
        "phosphor_g": config["color"]["phosphor_g"],
        "phosphor_b": config["color"]["phosphor_b"],
        "monochrome": config["color"]["monochrome"],
        "saturation": config["color"]["saturation"],
        # Bloom
        "bloom_intensity": config["bloom"]["intensity"],
        "bloom_size": config["bloom"]["size"],
        # Screen
        "curvature": config["screen"]["curvature"],
        "vignette": config["screen"]["vignette"],
        # Scanlines
        "scanlines_intensity": config["scanlines"]["intensity"],
        "scanlines_size": config["scanlines"]["size"],
        # Noise
        "noise_static": config["noise"]["static"],
        "noise_flicker": config["noise"]["flicker"],
        "noise_jitter": config["noise"]["jitter"],
        "noise_hsync": config["noise"]["hsync"],
        # Chromatic
        "chromatic_aberration": config["chromatic"]["aberration"],
        # Levels
        "brightness": config["levels"]["brightness"],
        "contrast": config["levels"]["contrast"],
        "ambient": config["levels"]["ambient"],
    }

    # Generate shader
    shader = template.format(**values)

    # Hash the config content for unique filename
    config_str = str(sorted(values.items()))
    config_hash = hashlib.sha256(config_str.encode()).hexdigest()[:12]

    # Ensure output directory exists
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write shader
    output_path = output_dir / f"crt-{config_hash}.glsl"
    with open(output_path, "w") as f:
        f.write(shader)

    # Also create a symlink to latest for convenience
    latest_link = output_dir / "latest.glsl"
    if latest_link.is_symlink():
        latest_link.unlink()
    latest_link.symlink_to(output_path.name)

    # Print the path for run.sh to use
    print(output_path)


if __name__ == "__main__":
    main()
