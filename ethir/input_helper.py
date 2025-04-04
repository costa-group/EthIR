import shlex
import subprocess
import os
import re
import logging
import json
import global_params_ethir
import six
import uuid
from typing import List, Dict, Tuple
from source_map import SourceMap
from utils import run_command, get_solc_executable, get_solidity_version_from_solc


class InputHelper:
    BYTECODE = 0
    SOLIDITY = 1
    STANDARD_JSON = 2
    STANDARD_JSON_OUTPUT = 3

    def __init__(self, input_type, **kwargs):
        self.input_type = input_type

        if input_type == InputHelper.BYTECODE:
            attr_defaults = {
                'source': None,
                'evm': False,
                'runtime': True,
                'solc_version': "v8",
                'opt_options': {},
                'tmp_path': global_params_ethir.tmp_path
            }
        elif input_type == InputHelper.SOLIDITY:
            attr_defaults = {
                'source': None,
                'evm': False,
                'runtime': True,
                'root_path': "",
                'compiled_contracts': [],
                'solc_version': "v8",
                'opt_options': {},
                'tmp_path': global_params_ethir.tmp_path
            }
        elif input_type == InputHelper.STANDARD_JSON:
            attr_defaults = {
                'source': None,
                'evm': False,
                'runtime': True,
                'root_path': "",
                'allow_paths': None,
                'compiled_contracts': [],
                'solc_version': "v8",
                'opt_options': {},
                'tmp_path': global_params_ethir.tmp_path
            }
        elif input_type == InputHelper.STANDARD_JSON_OUTPUT:
            attr_defaults = {
                'source': None,
                'evm': False,
                'runtime': True,
                'root_path': "",
                'compiled_contracts': [],
                'solc_version': "v8",
                'opt_options': {},
                'tmp_path': global_params_ethir.tmp_path, 
            }

        for (attr, default) in six.iteritems(attr_defaults):
            val = kwargs.get(attr, default)
            if val == None:
                raise Exception("'%s' attribute can't be None" % attr)
            else:
                setattr(self, attr, val)

        self.solc_version = self._get_solidity_version()

        self.init_compiled_contracts = []
        self.aux_path = "ethir_" + uuid.uuid4().hex
        os.mkdir(global_params_ethir.tmp_path + self.aux_path)

    def get_inputs(self):

        inputs = []
        if self.input_type == InputHelper.BYTECODE:
            with open(self.source, 'r') as f:
                bytecode = f.read()
            empty = self._prepare_disasm_file(self.source, bytecode)

            disasm_file = self._get_temporary_files(self.source)['disasm']
            if not empty:
                inputs.append({'disasm_file': disasm_file})
        else:
            self.solc_version = self._get_solidity_version()
            
            contracts = self._get_compiled_contracts()
            asm_json = self.asm_contracts

            if not self.runtime:
                contracts_init = self._get_compiled_contracts_init(contracts)

            empty = self._prepare_disasm_files_for_analysis(contracts)

            if not self.runtime:
                empty = self._prepare_disasm_files_for_analysis(contracts, contracts_init)

                for contract_init, _ in contracts_init:
                    if self.input_type == InputHelper.SOLIDITY:
                        # AQUI
                        source_map_init = SourceMap(contract_init, self.source, 'solidity', self.root_path,
                                                    self.solc_version)  # if self.solc_version != "v8" else None
                    else:
                        source_map_init = SourceMap(contract_init, self.source, 'standard json', self.root_path)

            else:
                source_map_init = None

            for contract, _ in contracts:
                c_source, cname = contract.split(':')
                c_source = re.sub(self.root_path, "", c_source)
                if self.input_type == InputHelper.SOLIDITY:
                    # AQUI
                    print(contract)
                    source_map = SourceMap(contract, self.source, 'solidity', self.root_path,
                                           self.solc_version)  # if self.solc_version != "v8" else None
                else:
                    source_map = SourceMap(contract, self.source, 'standard json', self.root_path)

                disasm_file = self._get_temporary_files(contract)['disasm']
                if not self.runtime:
                    disasm_file_init = self._get_temporary_files(contract)['disasm_init']
                else:
                    disasm_file_init = None
                if not empty[contract]:
                    inputs.append({
                        'contract': contract,
                        'source_map': source_map,
                        'source_map_init': source_map_init,
                        'source': self.source,
                        'c_source': c_source,
                        'c_name': cname,
                        'disasm_file': disasm_file,
                        'disasm_file_init': disasm_file_init,
                        'assembly': asm_json[contract]
                    })
        return inputs

    # Modified by Pablo Gordillo
    # Not remove tmp files (dissasamble files)
    def rm_tmp_files(self):
        # i = 0
        if self.input_type == InputHelper.BYTECODE:
            self._rm_tmp_files(self.source)
        else:
            self._rm_tmp_files_of_multiple_contracts(self.compiled_contracts)

    def get_aux_path(self):
        return self.aux_path

    def _get_compiled_contracts_init(self, runtime_contracts):
        contracts = self._compile_solidity_init()
        init_contracts = []
        for name_contract, evm in runtime_contracts:
            name_r, evm_r = contracts.pop(0)
            if name_contract != name_r:
                raise Exception("Something was wrong during the decompiled process...")
            else:
                pos = evm_r.find(evm)
                init_contracts.append((name_r, evm_r[:pos]))

        self.init_compiled_contracts = init_contracts
        return init_contracts

    def _get_compiled_contracts(self):
        if not self.compiled_contracts:
            if self.input_type == InputHelper.SOLIDITY:
                bin_runtime, asm_json = self._compile_solidity_runtime()
                self.compiled_contracts = bin_runtime
                self.asm_contracts = asm_json
            elif self.input_type == InputHelper.STANDARD_JSON:
                self.compiled_contracts = self._compile_standard_json()
            elif self.input_type == InputHelper.STANDARD_JSON_OUTPUT:
                self.compiled_contracts = self._compile_standard_json_output(self.source)

        return self.compiled_contracts

    def _compile_solidity_runtime(self):
        solc = get_solc_executable(self.solc_version)

        options = ""
        options = self._get_optimize_options()

        cmd = solc + " --bin-runtime --asm-json " + options + " %s" % self.source
        print(cmd)

        out = run_command(cmd)
        libs = re.findall(r"_+(.*?)_+", out)
        libs = set(libs)
        if libs and self.solc_version == "v4":
            return self._link_libraries(self.source, libs)
        else:
            return self._extract_bin_str(out), self._extract_asm_json(out)

    def _compile_solidity_init(self):

        solc = get_solc_executable(self.solc_version)

        options = ""

        options = self._get_optimize_options()

        cmd = solc + " --bin-runtime " + options + " %s" % self.source

        out = run_command(cmd)

        libs = re.findall(r"_+(.*?)_+", out)
        libs = set(libs)
        if libs:
            return self._link_libraries(self.source, libs)
        else:
            return self._extract_bin_str_init(out)

    def _compile_standard_json(self):
        FNULL = open(os.devnull, 'w')
        cmd = "cat %s" % self.source
        p1 = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=FNULL)

        solc = get_solc_executable(self.solc_version)

        # cmd = solc + " --allow-paths %s --standard-json" % self.allow_paths
        cmd = solc + " --standard-json %s" % self.source
        
        p2 = subprocess.Popen(shlex.split(cmd), stdin=p1.stdout, stdout=subprocess.PIPE, stderr=FNULL)
        p1.stdout.close()
        out = p2.communicate()[0]
        print(out)
        with open('standard_json_output', 'w') as of:
            of.write(out)

        prueba = self._compile_standard_json_output('standard_json_output')
        return prueba
    
    def _compile_standard_json_output(self, json_output_file):
        with open(json_output_file, 'r') as f:
            out = f.read()
        j = json.loads(out)
        contracts = []
        for source in j['sources']:
            for contract in j['contracts'][source]:
                cname = source + ":" + contract
                evm = j['contracts'][source][contract]['evm']['deployedBytecode']['object']
                contracts.append((cname, evm))
        return contracts

    def _removeSwarmHash(self, evm):
        evm_without_hash = re.sub(r"a165627a7a72305820\S{64}0029$", "", evm)
        return evm_without_hash

    def _extract_bin_str(self, s):
        # In v.4, we must be careful because "Binary of the runtime part:" is followed by a white space
        binary_regex = r"======= (.*?) =======\n(?:(?!Binary of the runtime part: *).*\n)*Binary of the runtime part: *\n(.*)\n"

        contracts = re.findall(binary_regex, s)

        contracts = [contract for contract in contracts if contract[1]]
        if not contracts:
            logging.critical("Solidity compilation failed")
            # print self.source
            if global_params_ethir.WEB:
                six.print_({"error": "Solidity compilation failed"})
            exit(1)
        return contracts

    def _match_assembly_json(self, s):
        """
        Matchs the json structure of the EVM assembly
        """
        contract_regex = r"======= (.*?) ======="
        i = 0
        text_lines = s.split('\n')
        contracts = []
        while i < len(text_lines):
            # First match the contract name
            contract_name_match = re.match(contract_regex, text_lines[i])
            if contract_name_match is not None:
                # Then match EVM assembly
                while i < len(text_lines) and not text_lines[i].startswith("EVM assembly:"):
                    i += 1

                    if re.match(contract_regex, text_lines[i]):
                        continue

                if i == len(text_lines):
                    continue

                initial_idx = i + 1

                if not text_lines[initial_idx].startswith("{"):
                    continue

                # Finally match all the enclosing lines in the json
                while i < len(text_lines) and not text_lines[i].startswith("}"):
                    i += 1

                if i == len(text_lines):
                    continue

                contract_json = '\n'.join(text_lines[initial_idx: i + 1])
                contracts.append([contract_name_match.group(1), contract_json])

            i += 1
        return contracts

    def _extract_asm_json(self, s):
        """
        Returns a dictionary with the assembly representation of each contract
        """
        if self.solc_version == "v8":
            # V8 appears the dict in a single line (unless pretty-json option is specified)
            asm_json_regex = r"======= (.*?) =======\n(?:(?!EVM assembly:).*\n)*EVM assembly:\n(.*)"
            contracts = re.findall(asm_json_regex, s)
        else:
            # V7 and before appears in multiple lines (similarly to pretty-json)
            contracts = self._match_assembly_json(s)

        contracts = {contract[0]: json.loads(contract[1]) for contract in contracts if contract[1]}
        if not contracts:
            logging.critical("ASM Json compilation failed")
            # print self.source
            if global_params_ethir.WEB:
                six.print_({"error": "ASM JSON compilation failed"})
            exit(1)
        return contracts

    def _extract_bin_str_init(self, s):
        binary_regex = r"======= (.*?) =======\n(?:(?!Binary:).*\n)*Binary:\n(.*)"
        contracts = re.findall(binary_regex, s)
        contracts = [contract for contract in contracts if contract[1]]
        if not contracts:
            logging.critical("Solidity compilation failed")
            if global_params_ethir.WEB:
                six.print_({"error": "Solidity compilation failed"})
            exit(1)
        return contracts

    def _link_libraries(self, filename, libs):
        option = ""
        for idx, lib in enumerate(libs):
            lib_address = "0x" + hex(idx + 1)[2:].zfill(40)
            option += " --libraries %s:%s" % (lib, lib_address)
        FNULL = open(os.devnull, 'w')

        solc = get_solc_executable(self.solc_version)

        cmd = solc + " --bin-runtime --asm-json %s" % filename

        p1 = subprocess.Popen(shlex.split(cmd), stdout=subprocess.PIPE, stderr=FNULL)

        cmd = solc + " --link%s" % option

        p2 = subprocess.Popen(shlex.split(cmd), stdin=p1.stdout, stdout=subprocess.PIPE, stderr=FNULL)
        p1.stdout.close()
        out = p2.communicate()[0].decode()
        return self._extract_bin_str(out), self._extract_asm_json(out)

    def _prepare_disasm_files_for_analysis(self, contracts, init_contracts=None):
        empty = {}
        if not init_contracts:
            for contract, bytecode in contracts:
                empty_c = self._prepare_disasm_file(contract, bytecode)
                empty[contract] = empty_c
        else:
            for contract, bytecode in init_contracts:
                empty_c = self._prepare_disasm_file(contract, bytecode, True)
                empty[contract] = empty_c
        return empty

    def _prepare_disasm_file(self, target, bytecode, init_contracts=False):
        self._write_evm_file(target, bytecode, init_contracts)
        empty = self._write_disasm_file(target, init_contracts)
        return empty

    def _get_temporary_files(self, target):
        return {
            "evm": global_params_ethir.tmp_path + self.aux_path + "/" + target.split(":")[-1] + ".evm",
            "disasm": global_params_ethir.tmp_path + self.aux_path + "/" + target.split(":")[-1] + ".evm.disasm",
            "evm_init": global_params_ethir.tmp_path + self.aux_path + "/" + target.split(":")[-1] + "_init.evm",
            "disasm_init": global_params_ethir.tmp_path + self.aux_path + "/" + target.split(":")[
                -1] + "_init.evm.disasm",
            "log": global_params_ethir.tmp_path + self.aux_path + "/" + target.split(":")[-1] + ".evm.disasm.log"
        }

    def _write_evm_file(self, target, bytecode, init_contracts):

        if init_contracts:
            evm_file = self._get_temporary_files(target)["evm_init"]
        else:
            evm_file = self._get_temporary_files(target)["evm"]

        with open(evm_file, 'w') as of:
            of.write(self._removeSwarmHash(bytecode))

    def _write_disasm_file(self, target, init_contracts):
        empty = False

        tmp_files = self._get_temporary_files(target)

        if init_contracts:
            evm_file = tmp_files["evm_init"]
            disasm_file = tmp_files["disasm_init"]
        else:
            evm_file = tmp_files["evm"]
            disasm_file = tmp_files["disasm"]

        disasm_out = ""
        try:

            if self.solc_version == "v4":
                disasm_p = subprocess.Popen(
                    ["evm", "disasm", evm_file], stdout=subprocess.PIPE)
            else:
                disasm_p = subprocess.Popen(
                    ["nohup", "evm1.12.0", "disasm", evm_file], stdout=subprocess.PIPE)

            disasm_out = disasm_p.communicate()[0].decode()

        except:
            logging.critical("Disassembly failed.")
            exit()

        if len(str(disasm_out).split()) > 1:
            with open(disasm_file, 'w') as of:
                of.write(disasm_out)
        else:
            empty = True
        return empty

    def _rm_tmp_files_of_multiple_contracts(self, contracts):
        if self.input_type in ['standard_json', 'standard_json_output']:
            self._rm_file('standard_json_output')
        for contract, _ in contracts:
            self._rm_tmp_files(contract)

        if self.init_compiled_contracts:
            for contract, _ in self.init_compiled_contracts:
                self._rm_tmp_files(contract, True)

    def _rm_tmp_files(self, target, init_contract=False):
        tmp_files = self._get_temporary_files(target)
        if not init_contract:
            if not self.evm:
                self._rm_file(tmp_files["evm"])
                self._rm_file(tmp_files["disasm"])
            self._rm_file(tmp_files["log"])

        else:
            if not self.evm:
                self._rm_file(tmp_files["evm_init"])
                self._rm_file(tmp_files["disasm_init"])

    def _rm_file(self, path):
        if os.path.isfile(path):
            os.unlink(path)

    def _get_solidity_version(self):
        f = open(self.source, "r")
        lines = f.readlines()
        pragma = [line for line in lines if not line.startswith("//") and "pragma solidity" in line]
        if pragma == []:
            return get_solidity_version_from_solc() #

        elif len(pragma) == 1:
            pragma_version = pragma[0].strip()
            id_p = pragma_version.find("^")
            if id_p != -1:
                elem = pragma_version[id_p + 1:]
                solc_v = elem.split(".")[1].strip()
            else:
                elem = pragma_version.split()[-1]
                solc_v = elem.split(".")[1].strip()
                if solc_v > "8":
                    solc_v = "8"

            return "v" + solc_v

        else:
            v = self._get_suitable_version(pragma)
            return v

    def get_solidity_version(self):
        return self.solc_version

    def _get_suitable_version(self, pragmas):
        v4 = len(list(filter(lambda x: x.find("0.4") != -1, pragmas)))
        v5 = len(list(filter(lambda x: x.find("0.5") != -1, pragmas)))
        v6 = len(list(filter(lambda x: x.find("0.6") != -1, pragmas)))
        v7 = len(list(filter(lambda x: x.find("0.7") != -1, pragmas)))
        v8 = len(list(filter(lambda x: x.find("0.8") != -1, pragmas)))
        m = max([v4, v5, v6, v7, v8])

        if m == v4:
            return "v4"
        elif m == v5:
            return "v5"
        elif m == v6:
            return "v6"
        elif m == v7:
            return "v7"
        elif m == v8:
            return "v8"
        else:
            return "Error"

    def _get_optimize_options(self):
        opt = ""
        compiler_opt = self.opt_options

        if (compiler_opt["no-yul"] or compiler_opt["runs"] != -1) and not compiler_opt["optimize"]:
            print("Flags --no-yul and --runs should go with the flag --optimize")
            exit()

        optimization = compiler_opt["optimize"]
        run = compiler_opt["runs"]
        yul = compiler_opt["no-yul"]
        viaIr = compiler_opt["via-ir"]

        if compiler_opt["optimize"] and run == -1:
            opt = "--optimize"
        elif run != -1:
            opt = "--optimize-runs=" + str(run)

        if viaIr:
            if opt.find("optimize") != -1:
                opt += " --via-ir"
            else:
                opt += " --optimize --via-ir"

        if yul and (self.solc_version != "v4" and self.solc_version != "v5"):
            opt += " --no-optimize-yul"

        if not yul and (self.solc_version == "v5"):
            opt += " --optimize-yul"

        return opt
