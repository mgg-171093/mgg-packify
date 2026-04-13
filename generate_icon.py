"""Generate multi-resolution app_icon.ico from logo-mgg.png for Windows taskbar compatibility."""

import io
import struct
from pathlib import Path

from PIL import Image

SOURCE = Path("app/assets/branding/logo-mgg-packify-base-deep-orange-500.png")
OUTPUT = Path("app/windows/runner/resources/app_icon.ico")
SIZES = [(16, 16), (32, 32), (48, 48), (256, 256)]


def _make_png_frame(img: Image.Image, size: tuple[int, int]) -> bytes:
    resized = img.resize(size, Image.LANCZOS)
    buf = io.BytesIO()
    resized.save(buf, format="PNG")
    return buf.getvalue()


def main():
    print(f"Opening source: {SOURCE}")
    img = Image.open(SOURCE).convert("RGBA")
    print(f"Source size: {img.size}")

    print(f"Building ICO with sizes: {SIZES}")
    frames = [_make_png_frame(img, s) for s in SIZES]

    # Build ICO file manually (Pillow's ICO writer collapses multi-frame).
    # ICO format: 6-byte header + N * 16-byte directory entries + image data.
    num_images = len(frames)
    ico_header = struct.pack("<HHH", 0, 1, num_images)  # reserved, type=1, count

    dir_size = num_images * 16
    data_offset = 6 + dir_size
    offsets: list[int] = []
    off = data_offset
    for f in frames:
        offsets.append(off)
        off += len(f)

    directory = b""
    for s, f, o in zip(SIZES, frames, offsets):
        w = s[0] if s[0] < 256 else 0   # 0 means 256 in ICO spec
        h = s[1] if s[1] < 256 else 0
        directory += struct.pack("<BBBBHHII", w, h, 0, 0, 1, 32, len(f), o)

    with open(OUTPUT, "wb") as fp:
        fp.write(ico_header)
        fp.write(directory)
        for f in frames:
            fp.write(f)

    print(f"Saved: {OUTPUT}")

    # Verify — read ICO directory directly (Pillow only surfaces the largest frame).
    with open(OUTPUT, "rb") as fp:
        raw = fp.read(6 + num_images * 16)
    _, ico_type, count = struct.unpack_from("<HHH", raw, 0)
    assert ico_type == 1, f"Not an ICO file (type={ico_type})"
    reported_sizes: list[tuple[int, int]] = []
    for i in range(count):
        off = 6 + i * 16
        w, h = struct.unpack_from("<BB", raw, off)
        reported_sizes.append((w or 256, h or 256))

    print(f"ICO frames: {reported_sizes}")
    assert len(reported_sizes) == 4, f"Expected 4 frames, got {len(reported_sizes)}"
    print("OK ICO verification passed")


if __name__ == "__main__":
    main()
