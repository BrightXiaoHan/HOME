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
    logging.info("Installing neovim...")
    # download the stable version of neovim
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://github.com/neovim/neovim/releases/download/stable/nvim.appimage"
    else:
        release_tag = get_latest_release("matsuu", "neovim-aarch64-appimage")
        url = f"https://github.com/matsuu/neovim-aarch64-appimage/releases/download/{release_tag}/nvim-{release_tag}-aarch64.appimage"
    bin_file = os.path.join(BIN_DIR, "nvim")

    if not os.path.exists(bin_file) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "nvim")
            shutil.copy(tmp.name, bin_file)
            os.chmod(bin_file, 0o755)
    logging.info("Installing neovim done.")

    if ARCHITECTURE not in ("x86_64", "amd64"):
        tmpfile = os.path.join(BIN_DIR, "nvim.appimage")
        shutil.copy(bin_file, tmpfile)
        # https://github.com/AppImage/AppImageKit/issues/965
        # https://github.com/AppImage/AppImageKit/issues/1056
        subprocess.run(
            [
                "sed",
                "-i",
                # r's|AI\x02|\x00\x00\x00|',
                r"0,/AI\x02/{s|AI\x02|\x00\x00\x00|}",
                tmpfile,
            ]
        )
        bin_file = tmpfile

    # install plugins. Run 3 times to make sure all plugins are installed
    # 1st time: install nvchad
    # 2nd time: install plugins
    # 3rd time: install dependencies
    for _ in range(3):
        # install plugins
        subprocess.run(
            [
                bin_file,
                "--appimage-extract-and-run",
                "--headless",
                '"+Lazy! sync"',
                "+qa",
            ],
        )

    subprocess.run(
        [
            bin_file,
            "--appimage-extract-and-run",
            "--headless",
            "-c",
            "TSInstallSync",
            "-c",
            "q",
        ],
    )

    # mason
    subprocess.run(
        [
            bin_file,
            "--appimage-extract-and-run",
            "--headless",
            "-c",
            "MasonInstallAll",
            "-c",
            "q",
        ]
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
        "compilers",
        "zlib",
        "nodejs",
        "gh",
        "jq",
        "lazygit",
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
    for package in [
        "rich-cli",
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


def install_docker_compose(overwrite=True):
    latest_version = get_latest_release("docker", "compose")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = f"https://github.com/docker/compose/releases/download/{latest_version}/docker-compose-linux-x86_64"
    else:
        url = f"https://github.com/docker/compose/releases/download/{latest_version}/docker-compose-linux-aarch64"

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


def install_zoxide(overwrite=True):
    latest_version = get_latest_release("ajeetdsouza", "zoxide")
    if ARCHITECTURE in ("x86_64", "amd64"):
        # url = f"https://github.com/ajeetdsouza/zoxide/releases/download/{latest_version}/zoxide-{latest_version}-x86_64-unknown-linux-musl.tar.gz"
        return
    else:
        url = f"https://github.com/ajeetdsouza/zoxide/releases/download/{latest_version}/zoxide-{latest_version[1:]}-aarch64-unknown-linux-musl.tar.gz"

    logging.info("Installing zoxide...")
    if not os.path.exists(os.path.join(CACHE_DIR, "bin", "zoxide")) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "zoxide")
            with tarfile.open(tmp.name) as tar:
                # extract zoxide
                tar.extract("zoxide", path=os.path.join(CACHE_DIR, "bin"))
        os.chmod(os.path.join(CACHE_DIR, "bin", "zoxide"), 0o755)


def install_starship(overwrite=True):
    latest_version = get_latest_release("starship", "starship")
    if ARCHITECTURE in ("x86_64", "amd64"):
        # url = f"https://github.com/starship/starship/releases/download/{latest_version}/starship-x86_64-unknown-linux-musl.tar.gz"
        return
    else:
        url = f"https://github.com/starship/starship/releases/download/{latest_version}/starship-aarch64-unknown-linux-musl.tar.gz"

    logging.info("Installing starship...")
    if not os.path.exists(os.path.join(CACHE_DIR, "bin", "starship")) or overwrite:
        with tempfile.NamedTemporaryFile() as tmp:
            download_with_progress(url, tmp.name, "starship")
            with tarfile.open(tmp.name) as tar:
                tar.extractall(path=os.path.join(CACHE_DIR, "bin"))
        os.chmod(os.path.join(CACHE_DIR, "bin", "starship"), 0o755)


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
            "frp",
            "docker_compose",
            "aliyunpan",
            "mamba",
            "starship",
            "zoxide",
            "conda",
            "neovim",
            "trzsz",
        ]
    elif "update" in args.component:
        components = [
            "frp",
            "docker_compose",
            "aliyunpan",
            "mamba",
            "starship",
            "zoxide",
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
