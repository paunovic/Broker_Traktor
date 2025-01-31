import glob
import zipfile
from pathlib import Path

files: set[str] = {
    "Broker_Traktor.toc",
    "traktor.lua",
    "TrackingApi.lua",
    "embeds.xml",
    "modules/**",
    "lib/**",
}

if __name__ == "__main__":
    for line in Path("Broker_Traktor.toc").read_text().splitlines():
        if line.startswith("## Version: "):
            version: str = line[11:].strip()
            break
    else:
        raise Exception("Version not found in Broker_Traktor.toc")

    version = f"v{version}"

    print(f"Building Broker_Traktor-{version}.zip...")

    with zipfile.ZipFile(
        f"build/Broker_Traktor_{version}.zip",
        "w",
        compression=zipfile.ZIP_DEFLATED,
        compresslevel=9,
    ) as zf:
        for file in files:
            if "*" not in file and "?" not in file:
                print(f"  - {file}")
                zf.write(file, f"Broker_Traktor/{file}")
            else:
                for f in glob.glob(file, recursive=True):
                    print(f"  - {f}")
                    zf.write(f, f"Broker_Traktor/{f}")

    print("Done.")
