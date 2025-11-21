import re
import subprocess
import sys
from pathlib import Path
import semantic_version


def get_available_versions():
    """
    Devuelve la lista de versiones instalables con solc-select.
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
    Extrae la versión/rango del pragma solidity y elige la más nueva compatible.
    """
    with open(contract_path, "r") as f:
        content = f.read()

    match = re.search(r"pragma\s+solidity\s+([^;]+);", content)
    if not match:
        raise ValueError("No se encontró la directiva pragma solidity")

    raw_version = match.group(1).strip()
    print(f" Detectado pragma: {raw_version}")
    
    available_versions = get_available_versions()

    # --- Caso ^ ---
    if raw_version.startswith("^"):
        base_version = semantic_version.Version(re.sub(r"[^\d.]", "", raw_version))
        print(raw_version)
        # if base_version.major == 0:
        #     # ^0.x.y -> >=0.x.y <0.(minor+1).0
        #     upper_bound = f"<0.{base_version.minor+1}.0"
        # else:
        #     # ^x.y.z -> >=x.y.z <(major+1).0.0
        print(base_version.minor)
        upper_bound = f"<{base_version.major}.{base_version.minor+1}.0"
        
        spec_str = f">={base_version},{upper_bound}"
        spec = semantic_version.SimpleSpec(spec_str)

        compatible = [v for v in available_versions if v in spec]
        if not compatible:
            raise ValueError(f"No hay versiones compatibles con {raw_version}")
        return str(max(compatible))

    # --- Caso >= ---
    elif raw_version.startswith(">="):
        base_version = semantic_version.Version(re.sub(r"[^\d.]", "", raw_version))
        # if base_version.major == 0:
        #     # Caso especial para Solidity <1.0: quedarse en la misma rama 0.minor
        #     same_minor = [v for v in available_versions 
        #                   if v.major == 0 and v.minor == base_version.minor and v >= base_version]
        #     if not same_minor:
        #         raise ValueError(f"No hay versiones compatibles con {raw_version}")
        #     return str(max(same_minor))
        # else:
            # Para majors >=1 se podría permitir avanzar, pero mejor quedarse en el mismo major
        same_major = [v for v in available_versions 
                      if v.major == base_version.major and v >= base_version]
        if not same_major:
            raise ValueError(f"No hay versiones compatibles con {raw_version}")
        return str(max(same_major))
        
    # --- Otros casos ---
    else:
        try:
            spec = semantic_version.SimpleSpec(raw_version)
            compatible = [v for v in available_versions if v in spec]
            if not compatible:
                raise ValueError(f"No hay versiones compatibles con {raw_version}")
            return str(max(compatible))
        except ValueError:
            # Si no se reconoce el rango, lo tratamos como versión fija
            cleaned = re.sub(r"[^\d.]", "", raw_version)
            parts = cleaned.split(".")
            while len(parts) < 3:
                parts.append("0")
            version = ".".join(parts[:3])
            return version


def set_solc_version(version: str):
    """
    Activa la versión con solc-select.
    """
    try:
        subprocess.run(["solc-select", "install", version], check=True)
    except subprocess.CalledProcessError:
        print(f"No se pudo instalar {version}, puede que ya esté instalada.")

    subprocess.run(["solc-select", "use", version], check=True)
    print(f"Usando solc {version}")


def select_and_set_solc_version(contract_path: str):
    """
    Compila un contrato usando solc.
    Devuelve ABI y bytecode.
    """
    version = get_solc_version(contract_path)
    set_solc_version(version)


    print(version)
    return version.split(".")[1]
    # result = subprocess.run(
    #     ["solc", "--combined-json", "abi,bin", contract_path],
    #     capture_output=True, text=True, check=True
    # )

    # return result.stdout


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python compile_contract.py <ruta_al_contrato.sol>")
        sys.exit(1)

    contract_path = sys.argv[1]
    if not Path(contract_path).exists():
        print(f"El archivo {contract_path} no existe.")
        sys.exit(1)

    compiled_json = compile_contract(contract_path)
    print("\n Resultado de compilación:")
    print(compiled_json)
