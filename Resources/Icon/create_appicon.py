#!/usr/bin/env python3

import os

from PIL import Image

basename = "OpenHaystackIcon"
imformat = "png"

export_folder = "../../OpenHaystack/OpenHaystack/Assets.xcassets/AppIcon.appiconset"
export_sizes = [16, 32, 64, 128, 256, 512, 1024]

with Image.open(f"{basename}.{imformat}") as im:
	for size in export_sizes:
		out = im.resize((size, size))
		outfile = os.path.join(export_folder, f"{size}.{imformat}")
		out.save(outfile)
