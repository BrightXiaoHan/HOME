import logging
import os
import platform

__app_name__ = "homecli"
PLATFORM = platform.system()
ARCHITECTURE = platform.machine()

if os.getenv("HOMECLI_INSTALL_DIR"):
    CACHE_DIR = os.getenv("HOMECLI_INSTALL_DIR")
else:
    CACHE_DIR = os.path.join(os.path.expanduser("~"), "." + __app_name__)
BIN_DIR = os.path.join(CACHE_DIR, "bin")
os.makedirs(BIN_DIR, exist_ok=True)

avaliable_archs = ["x86_64", "aarch64", "amd64", "arm64"]

if ARCHITECTURE not in avaliable_archs:
    logging.error(f"Unsupported architecture: {ARCHITECTURE}")
    exit(1)

avaliable_platforms = ["Linux"]

if PLATFORM not in avaliable_platforms:
    logging.error(f"Unsupported platform: {PLATFORM}")
    exit(1)


from homecli.install import main as install
