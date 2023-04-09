import os
import platform

import typer

PLATFORM = platform.system()
ARCHITECTURE = platform.machine()

avaliable_archs = ["x86_64", "aarch64", "amd64", "arm64"]

if ARCHITECTURE not in avaliable_archs:
    typer.echo(f"Unsupported architecture: {ARCHITECTURE}", err=True)
    exit(1)

avaliable_platforms = ["Linux"]

if PLATFORM not in avaliable_platforms:
    typer.echo(f"Unsupported platform: {PLATFORM}", err=True)
    exit(1)


__app_name__ = "homecli"
CACHE_DIR = typer.get_app_dir(__app_name__)
BIN_DIR = os.path.join(CACHE_DIR, "bin")
os.makedirs(BIN_DIR, exist_ok=True)
from .install import install_all

# add install commands here
app = typer.Typer()
app.command("install")(install_all)


def main():
    app()
