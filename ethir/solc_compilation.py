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

    # --- ^ case ---
    if raw_version.startswith("^"):
        base_version = semantic_version.Version(re.sub(r"[^\d.]", "", raw_version))

        # ^x.y.z -> >=x.y.z <(major+1).0.0
        upper_bound = f"<{base_version.major+1}.0.0"
        
        spec_str = f">={base_version},{upper_bound}"
        spec = semantic_version.SimpleSpec(spec_str)

        compatible = [v for v in available_versions if v in spec]
        if not compatible:
            raise ValueError(f"No compatible versions found for {raw_version}")
        return str(max(compatible))

    # --- >= case ---
    elif raw_version.startswith(">="):
        base_version = semantic_version.Version(re.sub(r"[^\d.]", "", raw_version))

        # For major >=1, stay within the same major version
        same_major = [v for v in available_versions 
                      if v.major == base_version.major and v >= base_version]
        if not same_major:
            raise ValueError(f"No compatible versions found for {raw_version}")
        return str(max(same_major))
        
    # --- Other cases ---
    else:
        try:
            spec = semantic_version.SimpleSpec(raw_version)
            compatible = [v for v in available_versions if v in spec]
            if not compatible:
                raise ValueError(f"No compatible versions found for {raw_version}")
            return str(max(compatible))
        except ValueError:
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
