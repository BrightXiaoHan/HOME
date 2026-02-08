import argparse
import gzip
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
from homecli.utils import progress


def get_latest_release_info(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    with urllib.request.urlopen(url) as response:
        return json.loads(response.read())


def get_latest_release(owner, repo):
    return get_latest_release_info(owner, repo)["tag_name"]


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


def _asset_tokens(name):
    for suffix in (".tar.gz", ".gz"):
        if name.endswith(suffix):
            name = name[: -len(suffix)]
            break
    return name.split("-")


def _select_mihomo_asset(assets):
    candidates = []
    for asset in assets:
        name = asset.get("name", "")
        if not name.startswith("mihomo-"):
            continue
        if not (name.endswith(".gz") or name.endswith(".tar.gz")):
            continue
        tokens = _asset_tokens(name)
        if "linux" not in tokens:
            continue
        candidates.append((asset, tokens))

    if not candidates:
        return None

    def score_candidate(tokens):
        penalty = 0
        if "go120" in tokens:
            penalty -= 1
        if "compatible" in tokens:
            penalty -= 1

        if ARCHITECTURE in ("x86_64", "amd64"):
            if "amd64" not in tokens:
                return None
            if "v1" in tokens:
                return 30 + penalty
            if "v2" in tokens:
                return 20 + penalty
            if "v3" in tokens:
                return 10 + penalty
            return 0 + penalty

        if ARCHITECTURE in ("aarch64", "arm64"):
            if "arm64" not in tokens and "aarch64" not in tokens:
                return None
            score = 0
            if "arm64" in tokens:
                score += 2
            if "v8" in tokens:
                score += 1
            return score + penalty

        return None

    best_asset = None
    best_score = None
    for asset, tokens in candidates:
        score = score_candidate(tokens)
        if score is None:
            continue
        if best_score is None or score > best_score:
            best_score = score
            best_asset = asset

    return best_asset


def _extract_mihomo_archive(archive_path, archive_name, dest_path):
    if archive_name.endswith(".tar.gz"):
        with tarfile.open(archive_path, "r:gz") as tar:
            member = None
            for entry in tar.getmembers():
                if entry.isfile() and os.path.basename(entry.name) == "mihomo":
                    member = entry
                    break
            if member is None:
                for entry in tar.getmembers():
                    if entry.isfile():
                        member = entry
                        break
            if member is None:
                raise RuntimeError("mihomo archive has no files")
            with tempfile.TemporaryDirectory() as tmpdir:
                tar.extract(member, tmpdir)
                src_path = os.path.join(tmpdir, member.name)
                shutil.copy(src_path, dest_path)
        return

    if archive_name.endswith(".gz"):
        with gzip.open(archive_path, "rb") as src, open(dest_path, "wb") as dst:
            shutil.copyfileobj(src, dst)
        return

    shutil.copy(archive_path, dest_path)


def _is_musl():
    try:
        result = subprocess.run(
            ["ldd", "--version"],
            check=False,
            capture_output=True,
            text=True,
        )
    except FileNotFoundError:
        return False

    output = (result.stdout or "") + (result.stderr or "")
    return "musl" in output.lower()


def _mihoro_target_triple():
    arch = ARCHITECTURE
    if arch == "amd64":
        arch = "x86_64"
    elif arch == "arm64":
        arch = "aarch64"

    libc = "musl" if _is_musl() else "gnu"
    return f"{arch}-unknown-linux-{libc}"


def _select_mihoro_asset(assets, target):
    for asset in assets:
        name = asset.get("name", "")
        if not name.startswith("mihoro-"):
            continue
        if not name.endswith(".tar.gz"):
            continue
        if target in name:
            return asset

    for asset in assets:
        name = asset.get("name", "")
        if not name.startswith("mihoro-"):
            continue
        if not name.endswith(".zip"):
            continue
        if target in name:
            return asset

    return None


def _extract_mihoro_archive(archive_path, archive_name, dest_path):
    if archive_name.endswith(".tar.gz"):
        with tarfile.open(archive_path, "r:gz") as tar:
            member = None
            for entry in tar.getmembers():
                if entry.isfile() and os.path.basename(entry.name) == "mihoro":
                    member = entry
                    break
            if member is None:
                for entry in tar.getmembers():
                    if entry.isfile():
                        member = entry
                        break
            if member is None:
                raise RuntimeError("mihoro archive has no files")
            with tempfile.TemporaryDirectory() as tmpdir:
                tar.extract(member, tmpdir)
                src_path = os.path.join(tmpdir, member.name)
                shutil.copy(src_path, dest_path)
        return

    if archive_name.endswith(".zip"):
        with zipfile.ZipFile(archive_path) as archive:
            member = None
            for entry in archive.infolist():
                if entry.is_dir():
                    continue
                if os.path.basename(entry.filename) == "mihoro":
                    member = entry
                    break
            if member is None:
                for entry in archive.infolist():
                    if not entry.is_dir():
                        member = entry
                        break
            if member is None:
                raise RuntimeError("mihoro archive has no files")
            with tempfile.TemporaryDirectory() as tmpdir:
                archive.extract(member, tmpdir)
                src_path = os.path.join(tmpdir, member.filename)
                shutil.copy(src_path, dest_path)
        return

    shutil.copy(archive_path, dest_path)


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

    # Ensure expected Mason directory exists for post-install validation.
    data_home = os.environ.get("XDG_DATA_HOME", os.path.join(CACHE_DIR, "data"))
    mason_bin_dir = os.path.join(data_home, "nvim", "mason", "bin")
    os.makedirs(mason_bin_dir, exist_ok=True)


def install_mamba(overwrite=True):
    logging.info("Installing mamba...")
    bin_file = os.path.join(BIN_DIR, "mamba")
    micromamba_file = os.path.join(BIN_DIR, "micromamba")
    if ARCHITECTURE in ("x86_64", "amd64"):
        url = "https://micro.mamba.pm/api/micromamba/linux-64/latest"
    else:
        url = "https://micro.mamba.pm/api/micromamba/linux-aarch64/latest"

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

    # Ensure micromamba is available as a command for shell hooks/tests.
    if overwrite or not os.path.exists(micromamba_file):
        try:
            if os.path.exists(micromamba_file):
                os.remove(micromamba_file)
            os.symlink("mamba", micromamba_file)
        except OSError:
            shutil.copy(bin_file, micromamba_file)
            os.chmod(micromamba_file, 0o755)
    logging.info("Installing micromamba done.")


def install_conda():
    logging.info("Installing conda...")
    command = [
        "install",
        "-n",
        "base",
        "-c",
        "conda-forge",
        "-y",
        "python=3.13.*",
        "fish",
        "ncurses",
        "fzf",
        "ripgrep",
        "make",
        "ninja",
        "cmake",
        "git",
        "git-lfs",
        "tmux=3.5a",
        "libcurl",
        "libgit2",
        "uv",
        "compilers",
        "zlib",
        "nodejs",
        "jq",
        "zoxide",
        "starship",
        "nvim",
        "lua-language-server",
        "stylua",
        "prettier",
        "pyright",
        "ruff",
        "typescript-language-server",
        "conda-pack",
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
    env["UV_TOOL_DIR"] = os.path.join(CACHE_DIR, "uv", "tool")
    env["UV_TOOL_BIN_DIR"] = os.path.join(CACHE_DIR, "bin")
    env["UV_PYTHON_INSTALL_DIR"] = os.path.join(CACHE_DIR, "uv", "python")
    env["UV_PYTHON_PREFERENCE"] = "only-system"

    for package in [
        "kimi-cli",
        "huggingface-cli",
        "modelscope",
    ]:
        subprocess.run(
            [
                os.path.join(CACHE_DIR, "miniconda", "bin", "uv"),
                "tool",
                "install",
                "--force",
                "--python-preference",
                "only-managed",
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


def install_mihomo(overwrite=True):
    logging.info("Installing mihomo...")
    bin_file = os.path.join(BIN_DIR, "mihomo")
    if os.path.exists(bin_file) and not overwrite:
        return

    release_info = get_latest_release_info("MetaCubeX", "mihomo")
    asset = _select_mihomo_asset(release_info.get("assets", []))
    if not asset:
        raise RuntimeError("Unable to find a suitable mihomo release asset")

    url = asset["browser_download_url"]
    archive_name = asset["name"]

    with tempfile.NamedTemporaryFile() as tmp:
        download_with_progress(url, tmp.name, "mihomo")
        tmp.flush()
        _extract_mihomo_archive(tmp.name, archive_name, bin_file)

    os.chmod(bin_file, 0o755)
    logging.info("Installing mihomo done.")


def install_mihoro(overwrite=True):
    logging.info("Installing mihoro...")
    bin_file = os.path.join(BIN_DIR, "mihoro")
    if os.path.exists(bin_file) and not overwrite:
        return

    release_info = get_latest_release_info("spencerwooo", "mihoro")
    target = _mihoro_target_triple()
    asset = _select_mihoro_asset(release_info.get("assets", []), target)
    if not asset:
        raise RuntimeError(f"Unable to find a suitable mihoro release asset for {target}")

    url = asset["browser_download_url"]
    archive_name = asset["name"]

    with tempfile.NamedTemporaryFile() as tmp:
        download_with_progress(url, tmp.name, "mihoro")
        tmp.flush()
        _extract_mihoro_archive(tmp.name, archive_name, bin_file)

    os.chmod(bin_file, 0o755)
    logging.info("Installing mihoro done.")


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
            "mihomo",
            "mihoro",
        ],
        default=["all"],
        help="component to install. all by default",
    )
    args = parser.parse_args()
    if "all" in args.component:
        components = [
            "frp",
            "trzsz",
            "mihomo",
            "mihoro",
            "mamba",
            "conda",
            "neovim",
        ]
    elif "update" in args.component:
        components = [
            "frp",
            "trzsz",
            "mihomo",
            "mihoro",
        ]
    else:
        components = args.component

    for component in components:
        func_name = f"install_{component}"
        globals()[func_name]()


if __name__ == "__main__":
    main()
