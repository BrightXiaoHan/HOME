import json
import lzma
import os
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
import zipfile

import typer

from . import ARCHITECTURE, BIN_DIR, CACHE_DIR


def get_latest_release(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
        return data["tag_name"]


def download_with_progress(url, path):
    with urllib.request.urlopen(url) as response:
        total_size = int(response.info().get("Content-Length").strip())
        chunk_size = 1024 * 4
        with open(path, "wb") as f, typer.progressbar(
            length=total_size, label="Downloading"
        ) as progress:
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                f.write(chunk)
                progress.update(len(chunk))


def install_neovim(overwrite=False):
    typer.echo("Installing neovim...")
    # download the stable version of neovim
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/neovim/neovim/releases/download/stable/nvim.appimage"
    else:
        release_tag = get_latest_release("matsuu", "neovim-aarch64-appimage")
        url = f"https://github.com/matsuu/neovim-aarch64-appimage/releases/download/{release_tag}/nvim-{release_tag}.aarch64.appimage"
    bin_file = os.path.join(BIN_DIR, "nvim")

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name)
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    typer.echo("Installing neovim done.")


def install_tmux(overwrite=False):
    typer.echo("Installing tmux...")
    bin_file = os.path.join(BIN_DIR, "tmux")
    release_tag = get_latest_release("nelsonenzo", "tmux-appimage")
    url = f"https://github.com/nelsonenzo/tmux-appimage/releases/download/{release_tag}/tmux.appimage"

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name)
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    typer.echo("Installing tmux done.")


def install_aliyunpan(overwrite=False):
    typer.echo("Installing aliyunpan...")
    bin_file = os.path.join(BIN_DIR, "aliyunpan")
    release_tag = get_latest_release("tickstep", "aliyunpan")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://github.com/tickstep/aliyunpan/releases/download/{release_tag}/aliyunpan-{release_tag}-linux-amd64.zip"
    else:
        url = f"https://github.com/tickstep/aliyunpan/releases/download/{release_tag}/aliyunpan-{release_tag}-linux-arm64.zip"

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name)
            # unzip the file
            with tempfile.TemporaryDirectory() as tmpdir:
                with zipfile.ZipFile(tmp.name, "r") as zip_ref:
                    zip_ref.extractall(tmpdir)

                # copy the binary fileo
                shutil.copy(os.path.join(tmpdir, os.path.basename(url).replace(".zip", ""), "aliyunpan"), bin_file)
                os.chmod(bin_file, 0o755)
    typer.echo("Installing aliyunpan done.")


def install_oh_my_posh(overwrite=False):
    typer.echo("Installing oh-my-posh...")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64"
    else:
        url = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64"

    bin_file = os.path.join(BIN_DIR, "oh-my-posh")

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name)
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    typer.echo("Installing oh-my-posh done.")


def install_nodejs():
    typer.echo("Installing nodejs...")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://nodejs.org/dist/v18.15.0/node-v18.15.0-linux-x64.tar.xz"
    else:
        url = "https://nodejs.org/dist/v18.15.0/node-v18.15.0-linux-arm64.tar.xz"

    target_dir = os.path.join(CACHE_DIR, "nodejs")

    if subprocess.check_call(["which", "node"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) == 0:
        cache_file = os.path.join(CACHE_DIR, os.path.basename(url))
        if not os.path.exists(cache_file):
            with tempfile.NamedTemporaryFile() as tmp:
                download_with_progress(url, tmp.name)
                shutil.copy(tmp.name, cache_file)
        with lzma.open(cache_file, "r") as f:
            with tarfile.open(fileobj=f) as tar:
                tar.extractall(path=target_dir)

    typer.echo("Installing nodejs done.")


def install_conda():
    typer.echo("Installing conda...")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    else:
        url = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-aarch64.sh"

    if subprocess.check_call(["which", "conda"]) != 0:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name)
            os.chmod(tmp.name, 0o755)
            subprocess.run(
                [tmp.name, "-b", "-p", os.path.join(CACHE_DIR, "miniconda")], check=True
            )

    typer.echo("Installing conda done.")

    # conda install fish shell
    typer.echo("Installing fish shell...")
    subprocess.run(["conda", "install", "-y", "fish"], check=True)
    typer.echo("Installing fish shell done.")


def install_all():
    install_neovim()
    install_tmux()
    install_aliyunpan()
    install_nodejs()
    install_oh_my_posh()
    install_conda()
