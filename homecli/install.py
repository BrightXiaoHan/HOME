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

from homecli import ARCHITECTURE, BIN_DIR, CACHE_DIR
from homecli.utils import progress


def get_latest_release(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    with urllib.request.urlopen(url) as response:
        data = json.loads(response.read())
        return data["tag_name"]


try:
    import requests

    def download_with_progress(url, path, name=""):
        sys.stderr.write("Downloading {}...\n".format(name))
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
        sys.stderr.write("Donwload {} done.\n".format(name))

except ImportError:

    def download_with_progress(url, path, name=""):
        sys.stderr.write("Downloading {}...\n".format(name))
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
        sys.stderr.write("Donwload {} done.\n".format(name))


def install_neovim(overwrite=True):
    bin_file = os.path.join(CACHE_DIR, "miniconda", "bin", "nvim")
    logging.info("Installing neovim...")
    # install plugins. Run 3 times to make sure all plugins are installed
    # 1st time: install nvchad
    # 2nd time: install plugins
    # 3rd time: install dependencies
    for _ in range(3):
        # install plugins
        subprocess.run(
            [
                bin_file,
                "--headless",
                '"+Lazy! sync"',
                "+qa",
            ],
        )

    subprocess.run(
        f'{bin_file} --headless "+TSInstallSync! c cpp fish python bash markdown cmake dockerfile yaml lua" +qa',
        shell=True,
    )

    # mason
    subprocess.run(
        f'{bin_file} --headless "+MasonInstall lua-language-server stylua '
        'prettier clangd clang-format pyright black isort autoflake debugpy" +qa',
        shell=True,
    )


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
        "python=3.11",
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
        "uv",
        "ruff",
        "compilers",
        "zlib",
        "nodejs",
        "gh",
        "jq",
        "zoxide",
        "starship",
        "nvim",
    ]
    if ARCHITECTURE in ("x86_64", "amd64"):
        command.extend(
            [
                "docker-compose",
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
    for package in [
        "git+https://github.com/BrightXiaoHan/ssr-command-client.git@master",
    ]:
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


def install_trzsz(overwrite=True):
    latest_version = get_latest_release("trzsz", "trzsz-go")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://github.com/trzsz/trzsz-go/releases/download/{latest_version}/trzsz_{latest_version[1:]}_linux_x86_64.tar.gz"
    else:
        url = f"https://github.com/trzsz/trzsz-go/releases/download/{latest_version}/trzsz_{latest_version[1:]}_linux_aarch64.tar.gz"

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


def install_frp(overwrite=True):
    latest_version = get_latest_release("fatedier", "frp")

    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://github.com/fatedier/frp/releases/download/{latest_version}/frp_{latest_version[1:]}_linux_amd64.tar.gz"
    else:
        url = f"https://github.com/fatedier/frp/releases/download/{latest_version}/frp_{latest_version[1:]}_linux_arm64.tar.gz"

    logging.info("Installing frp...")
    if not os.path.exists(os.path.join(CACHE_DIR, "bin", "frpc")) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "frp")
            with tarfile.open(tmp.name) as tar:
                tar.extractall(path=CACHE_DIR)

        # move all files to CACHE_DIR/bin
        frp_dir = os.path.join(CACHE_DIR, url.split("/")[-1].replace(".tar.gz", ""))
        for f in ["frpc", "frps"]:
            if os.path.isfile(os.path.join(CACHE_DIR, "bin", f)):
                os.remove(os.path.join(CACHE_DIR, "bin", f))
            shutil.move(os.path.join(frp_dir, f), os.path.join(CACHE_DIR, "bin"))


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
            "frp",
        ],
        default=["all"],
        help="component to install. all by default",
    )
    args = parser.parse_args()
    if "all" in args.component:
        components = [
            "frp",
            "trzsz",
            "mamba",
            "conda",
            "neovim",
        ]
    elif "update" in args.component:
        components = [
            "frp",
            "trzsz",
        ]
    else:
        components = args.component

    for component in components:
        func_name = f"install_{component}"
        globals()[func_name]()


if __name__ == "__main__":
    main()
