import re
import subprocess
import sys
from pathlib import Path
import semantic_version


def get_available_versions():
    """
    Returns the list of installable versions via solc-select.
    """
    result = subprocess.run(["solc-select", "versions"],
                            capture_output=True, text=True, check=True)
    versions = []
    for line in result.stdout.splitlines():
        line = line.strip().lstrip("v")
        try:
            versions.append(semantic_version.Version(line))
        except ValueError:
            pass
    return sorted(versions)


def get_solc_version(contract_path: str) -> str:
    """
    Extracts the pragma solidity version/range and selects the newest compatible version.
    """
    with open(contract_path, "r") as f:
        content = f.read()

    match = re.search(r"pragma\s+solidity\s+([^;]+);", content)
    if not match:
        raise ValueError("pragma solidity directive not found")

    raw_version = match.group(1).strip()
    print(f" Detected pragma: {raw_version}")
    
    available_versions = get_available_versions()

    # The pragma uses the npm semver ranges (^x.y.z, >=a <b, x.y.z...). For
    # 0.x versions ^0.4.24 means >=0.4.24 <0.5.0 (not <1.0.0), which NpmSpec
    # implements
    try:
        spec = semantic_version.NpmSpec(raw_version)
    except ValueError:
        spec = None

    if spec is not None:
        compatible = [v for v in available_versions if v in spec]
        if not compatible:
            raise ValueError(f"No compatible versions found for {raw_version}")
        return str(max(compatible))

    # If the range is not recognized, treat it as a fixed version
    cleaned = re.sub(r"[^\d.]", "", raw_version)
    parts = cleaned.split(".")
    while len(parts) < 3:
        parts.append("0")
    version = ".".join(parts[:3])
    return version


def set_solc_version(version: str):
    """
    Activates the selected version via solc-select.
    """
    try:
        subprocess.run(["solc-select", "install", version], check=True)
    except subprocess.CalledProcessError:
        print(f"Could not install {version}, it might already be installed.")

    subprocess.run(["solc-select", "use", version], check=True)
    print(f"Using solc {version}")


def select_and_set_solc_version(contract_path: str):
    """
    Selects and activates the correct solc version based on a contract.
    Returns the minor version.
    """
    version = get_solc_version(contract_path)
    set_solc_version(version)

    return version.split(".")[1]


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python compile_contract.py <path_to_contract.sol>")
        sys.exit(1)

    contract_path = sys.argv[1]
    if not Path(contract_path).exists():
        print(f"File {contract_path} does not exist.")
        sys.exit(1)

    compiled_json = compile_contract(contract_path)
    print("\n Compilation result:")
    print(compiled_json)
