import json
import logging
import os
import shutil
import subprocess
import tarfile
import tempfile
import urllib.request
import zipfile

from homecli import ARCHITECTURE, BIN_DIR, CACHE_DIR
from homecli.utils import get_latest_stable_nodejs_version, progress


def get_latest_release(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
        return data["tag_name"]


def download_with_progress(url, path, name=""):
    with urllib.request.urlopen(url) as response:
        total_size = int(response.info().get("Content-Length").strip())
        chunk_size = 1024 * 4
        with open(path, "wb") as f:
            while True:
                chunk = response.read(chunk_size)
                if not chunk:
                    break
                f.write(chunk)
                progress(f.tell(), total_size, name)


def install_neovim(overwrite=False):
    logging.info("Installing neovim...")
    # download the stable version of neovim
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/neovim/neovim/releases/download/stable/nvim.appimage"
    else:
        release_tag = get_latest_release("matsuu", "neovim-aarch64-appimage")
        url = f"https://github.com/matsuu/neovim-aarch64-appimage/releases/download/{release_tag}/nvim-{release_tag}.appimage"
    bin_file = os.path.join(BIN_DIR, "nvim")

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "nvim")
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    logging.info("Installing neovim done.")

    # install packer
    subprocess.run(
        os.path.join(CACHE_DIR, "miniconda", "bin", "git")
        + " clone --depth 1 https://github.com/wbthomason/packer.nvim "
        "~/.local/share/nvim/site/pack/packer/start/packer.nvim",
        shell=True,
    )
    # install plugins
    subprocess.run(
        os.path.join(BIN_DIR, "nvim")
        + " --appimage-extract-and-run --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSync'",
        shell=True,
    )

    # tree-sitter
    tree_sitter_list = [
        "toml",
        "fish",
        "json",
        "yaml",
        "lua",
        "python",
    ]

    subprocess.run(
        os.path.join(BIN_DIR, "nvim")
        + " --appimage-extract-and-run --headless -c 'TSInstall "
        + " ".join(tree_sitter_list)
        + "'"
        + " -c 'q'",
        shell=True,
    )

    # mason
    mason_list = [
        "bash-language-server",
        "black",
        "isort",
        "json-lsp",
        "lua-language-server",
        "yaml-language-server",
    ]
    subprocess.run(
        os.path.join(BIN_DIR, "nvim")
        + " --appimage-extract-and-run --headless -c 'MasonInstall "
        + " ".join(mason_list)
        + "'"
        + " -c 'q'",
        shell=True,
    )

    # LspInstall
    lsp_list = [
        "lua_ls",
        "pyright",
        "bashls",
        "jsonls",
        "yamlls",
    ]
    subprocess.run(
        os.path.join(BIN_DIR, "nvim")
        + " --appimage-extract-and-run --headless -c 'LspInstall "
        + " ".join(lsp_list)
        + "'"
        + " -c 'q'",
        shell=True,
    )


def install_tmux(overwrite=False):
    logging.info("Installing tmux...")
    bin_file = os.path.join(BIN_DIR, "tmux")
    release_tag = get_latest_release("nelsonenzo", "tmux-appimage")
    url = f"https://github.com/nelsonenzo/tmux-appimage/releases/download/{release_tag}/tmux.appimage"

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "tmux")
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    logging.info("Installing tmux done.")


def install_aliyunpan(overwrite=False):
    logging.info("Installing aliyunpan...")
    bin_file = os.path.join(BIN_DIR, "aliyunpan")
    release_tag = get_latest_release("tickstep", "aliyunpan")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://github.com/tickstep/aliyunpan/releases/download/{release_tag}/aliyunpan-{release_tag}-linux-amd64.zip"
    else:
        url = f"https://github.com/tickstep/aliyunpan/releases/download/{release_tag}/aliyunpan-{release_tag}-linux-arm64.zip"

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "aliyunpan")
            # unzip the file
            with tempfile.TemporaryDirectory() as tmpdir:
                with zipfile.ZipFile(tmp.name, "r") as zip_ref:
                    zip_ref.extractall(tmpdir)

                # copy the binary fileo
                shutil.copy(
                    os.path.join(
                        tmpdir, os.path.basename(url).replace(".zip", ""), "aliyunpan"
                    ),
                    bin_file,
                )
                os.chmod(bin_file, 0o755)
    logging.info("Installing aliyunpan done.")


def install_oh_my_posh(overwrite=False):
    logging.info("Installing oh-my-posh...")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64"
    else:
        url = "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-arm64"

    bin_file = os.path.join(BIN_DIR, "oh-my-posh")

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "oh-my-posh")
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    logging.info("Installing oh-my-posh done.")


def install_conda():
    logging.info("Installing conda...")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh"
    else:
        url = "https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-aarch64.sh"

    if subprocess.run(["which", "conda"]).returncode != 0:
        cache_file = os.path.join(CACHE_DIR, os.path.basename(url))
        if not os.path.exists(cache_file):
            with tempfile.NamedTemporaryFile() as tmp:
                download_with_progress(url, tmp.name, "conda")
                shutil.copy(tmp.name, cache_file)
                os.chmod(cache_file, 0o755)
        subprocess.run(
            [cache_file, "-b", "-p", os.path.join(CACHE_DIR, "miniconda")], check=True
        )
    logging.info("Installing conda done.")
    # conda install fish shell
    logging.info("Installing other packages...")
    subprocess.run(
        [
            os.path.join(CACHE_DIR, "miniconda", "bin", "conda"),
            "install",
            "-c",
            "conda-forge",
            "-y",
            "fish",
            "ncurses",
            "fzf",
            "ripgrep",
            "gcc",
            "gxx",
            "make",
            "cmake",
            "git",
            "conda-pack",
            "starship",
            "zoxide",
        ],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    logging.info("Installing other packages done.")


def install_nodejs():
    latest_version = get_latest_stable_nodejs_version()
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://nodejs.org/dist/{latest_version}/node-{latest_version}-linux-x64.tar.xz"
    else:
        url = f"https://nodejs.org/dist/{latest_version}/node-{latest_version}-linux-arm64.tar.xz"

    logging.info("Installing nodejs...")
    with tempfile.NamedTemporaryFile() as tmp:
        download_with_progress(url, tmp.name, "nodejs")
        with tarfile.open(tmp.name) as tar:
            tar.extractall(path=CACHE_DIR)

    # rename nodejs directory
    nodejs_dir = os.path.join(CACHE_DIR, url.split("/")[-1].replace(".tar.xz", ""))
    os.rename(nodejs_dir, os.path.join(CACHE_DIR, "nodejs"))

    logging.info("Installing nodejs done.")

def install_trzsz():
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/trzsz/trzsz-go/releases/download/v1.1.4/trzsz_1.1.4_linux_x86_64.tar.gz"
    else:
        url = "https://github.com/trzsz/trzsz-go/releases/download/v1.1.4/trzsz_1.1.4_linux_aarch64.tar.gz"

    logging.info("Installing trzsz...")
    with tempfile.NamedTemporaryFile() as tmp:
        download_with_progress(url, tmp.name, "trzsz")
        with tarfile.open(tmp.name) as tar:
            tar.extractall(path=CACHE_DIR)

    # move all files to CACHE_DIR/bin
    trzsz_dir = os.path.join(CACHE_DIR, url.split("/")[-1].replace(".tar.gz", ""))
    for f in os.listdir(trzsz_dir):
        shutil.move(os.path.join(trzsz_dir, f), os.path.join(CACHE_DIR, "bin"))


def main():
    install_tmux()
    install_aliyunpan()
    install_conda()
    install_neovim()
    install_nodejs()
    install_trzsz()


if __name__ == "__main__":
    main()
