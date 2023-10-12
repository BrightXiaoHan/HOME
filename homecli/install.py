import argparse
import json
import logging
import os
import shutil
import subprocess
import sys
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


try:
    import requests

    def download_with_progress(url, path, name=""):
        response = requests.get(
            url,
            stream=True,
            proxies={
                "http": os.environ.get("http_proxy", ""),
                "https": os.environ.get("https_proxy", ""),
            },
        )
        total_size = int(response.headers.get("Content-Length", 0))
        chunk_size = 1024 * 4
        with open(path, "wb") as f:
            for data in response.iter_content(chunk_size=chunk_size):
                f.write(data)
                progress(f.tell(), total_size, name)
        sys.stderr.write("\n")

except ImportError:

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
        sys.stderr.write("\n")


def install_neovim(overwrite=True):
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

    subprocess.run(
        os.path.join(BIN_DIR, "nvim")
        + " --appimage-extract-and-run --headless -c 'TSUpdateSync' -c 'q'",
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


def install_aliyunpan(overwrite=True):
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


def install_mamba(overwrite=True):
    logging.info("Installing mamba...")
    bin_file = os.path.join(BIN_DIR, "mamba")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://micro.mamba.pm/api/micromamba/linux-64/latest"
    else:
        url = f"https://micro.mamba.pm/api/micromamba/linux-aarch64/latest"

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "mamba")
            # unzip the file
            with tempfile.TemporaryDirectory() as tmpdir:
                # extract tar.bz2
                with tarfile.open(tmp.name, "r:bz2") as tar:
                    tar.extractall(tmpdir)

                # copy the binary file
                shutil.copy(
                    os.path.join(tmpdir, "bin", "micromamba"),
                    bin_file,
                )
                os.chmod(bin_file, 0o755)
    logging.info("Installing aliyunpan done.")


def install_conda():
    logging.info("Installing conda...")
    command = [
        "install",
        "-n",
        "base",
        "-c",
        "conda-forge",
        "-y",
        "conda",
        "fish",
        "ncurses",
        "fzf",
        "ripgrep",
        "make",
        "cmake",
        "git",
        "git-lfs",
        "conda-pack",
        "poetry",
        "tmux",
        "libcurl",
        "pipx",
        "compilers",
        "zlib",
        "nodejs",
    ]
    if ARCHITECTURE in ("x86_64", "amd64"):
        command.extend(
            [
                "starship",
                "zoxide",
            ]
        )
    else:
        command.extend([])

    env = os.environ.copy()
    env["PYTHONPATH"] = ""
    env["MAMBA_ROOT_PREFIX"] = os.path.join(CACHE_DIR, "miniconda")
    mamba_path = os.path.join(CACHE_DIR, "bin", "mamba")
    subprocess.run(
        [mamba_path, "create", "-n", "base"],
        check=True,
        env=env,
    )
    command = [mamba_path] + command

    logging.info("Installing conda packages...")
    subprocess.run(
        command,
        check=True,
        env=env,
    )
    
    env = os.environ.copy()
    env["PIPX_HOME"] = os.path.join(CACHE_DIR, "pipx")
    env["PIPX_BIN_DIR"] = os.path.join(CACHE_DIR, "bin")
    for package in ["rich-cli", "git+https://github.com/BrightXiaoHan/ssr-command-client.git@socks2http", "mycli", "mdformat"]:
        subprocess.run(
            [
                os.path.join(CACHE_DIR, "miniconda", "bin", "pipx"),
                "install",
                "--force",
                package,
            ],
            check=True,
            env=env,
        )
    logging.info("Installing other packages done.")


def install_nodejs():
    latest_version = get_latest_stable_nodejs_version()
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://nodejs.org/dist/{latest_version}/node-{latest_version}-linux-x64.tar.gz"
    else:
        url = f"https://nodejs.org/dist/{latest_version}/node-{latest_version}-linux-arm64.tar.gz"

    logging.info("Installing nodejs...")
    with tempfile.NamedTemporaryFile() as tmp:
        download_with_progress(url, tmp.name, "nodejs")
        with tarfile.open(tmp.name) as tar:
            tar.extractall(path=CACHE_DIR)

    # rename nodejs directory
    nodejs_dir = os.path.join(CACHE_DIR, url.split("/")[-1].replace(".tar.gz", ""))
    os.rename(nodejs_dir, os.path.join(CACHE_DIR, "nodejs"))

    logging.info("Installing nodejs done.")


def install_trzsz(overwrite=True):
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/trzsz/trzsz-go/releases/download/v1.1.4/trzsz_1.1.4_linux_x86_64.tar.gz"
    else:
        url = "https://github.com/trzsz/trzsz-go/releases/download/v1.1.4/trzsz_1.1.4_linux_aarch64.tar.gz"

    logging.info("Installing trzsz...")
    if not os.path.exists(os.path.join(CACHE_DIR, "bin", "trzsz")) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "trzsz")
            with tarfile.open(tmp.name) as tar:
                tar.extractall(path=CACHE_DIR)

        # move all files to CACHE_DIR/bin
        trzsz_dir = os.path.join(CACHE_DIR, url.split("/")[-1].replace(".tar.gz", ""))
        for f in os.listdir(trzsz_dir):
            if os.path.isfile(os.path.join(CACHE_DIR, "bin", f)):
                os.remove(os.path.join(CACHE_DIR, "bin", f))
            shutil.move(os.path.join(trzsz_dir, f), os.path.join(CACHE_DIR, "bin"))


def install_docker_compose(overwrite=True):
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-x86_64"
    else:
        url = "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-linux-aarch64"

    logging.info("Installing docker-compose...")
    if (
        not os.path.exists(os.path.join(CACHE_DIR, "bin", "docker-compose"))
        or overwrite
    ):
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "docker-compose")
            # move all files to CACHE_DIR/bin
            shutil.copy(tmp.name, os.path.join(CACHE_DIR, "bin", "docker-compose"))
            os.chmod(os.path.join(CACHE_DIR, "bin", "docker-compose"), 0o755)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-c",
        "--component",
        nargs="+",
        choices=[
            "all",
            "update",
            "trzsz",
            "aliyunpan",
            "neovim",
        ],
        default=["all"],
        help="component to install. all by default",
    )
    args = parser.parse_args()
    if "all" in args.component:
        components = [
            "docker_compose",
            "aliyunpan",
            "mamba",
            "conda",
            "neovim",
            "trzsz",
        ]
    elif "update" in args.component:
        components = [
            "docker_compose",
            "aliyunpan",
            "mamba",
            "neovim",
            "trzsz",
        ]
    else:
        components = args.component

    for component in components:
        func_name = f"install_{component}"
        globals()[func_name]()


if __name__ == "__main__":
    main()
