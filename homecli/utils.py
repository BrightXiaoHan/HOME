import datetime
import json
import os
import sys
import urllib.request

PRINT_PROGRESS = os.environ.get("PRINT_PROGRESS", "true").lower() == "true"


def progress(count, total, suffix=""):
    bar_len = 60
    filled_len = int(round(bar_len * count / float(total)))
    percents = round(100.0 * count / float(total), 1)
    bar = "=" * filled_len + "-" * (bar_len - filled_len)
    if PRINT_PROGRESS:
        sys.stderr.write("[%s] %s%s ...%s\r" % (bar, percents, "%", suffix))
        sys.stderr.flush()


def get_latest_stable_nodejs_version():
    url = "https://nodejs.org/dist/index.json"
    try:
        with urllib.request.urlopen(url) as response:
            data = response.read().decode("utf-8")
            versions = json.loads(data)
            stable_versions = [
                version for version in versions if "lts" in version and version["lts"]
            ]
            dates = [
                datetime.datetime.strptime(version["date"], "%Y-%m-%d")
                for version in stable_versions
            ]
            latest_stable_version = stable_versions[dates.index(max(dates))]["version"]
            return latest_stable_version
    except urllib.error.URLError as e:
        raise RuntimeError(
            f"Failed to retrieve the latest stable version of Node.js: {e}"
        )


if __name__ == "__main__":
    latest_stable_version = get_latest_stable_nodejs_version()
    if latest_stable_version:
        print(f"The latest stable version of Node.js is {latest_stable_version}")
    else:
        print("Failed to retrieve the latest stable version of Node.js")
