import sys
import re

registers = {
    '$zero': 0, '$at': 1, '$v0': 2, '$v1': 3,
    '$a0': 4, '$a1': 5, '$a2': 6, '$a3': 7,
    '$t0': 8, '$t1': 9, '$t2': 10, '$t3': 11, '$t4': 12, '$t5': 13, '$t6': 14, '$t7': 15,
    '$s0': 16, '$s1': 17, '$s2': 18, '$s3': 19, '$s4': 20, '$s5': 21, '$s6': 22, '$s7': 23,
    '$t8': 24, '$t9': 25, '$k0': 26, '$k1': 27,
    '$gp': 28, '$sp': 29, '$fp': 30, '$ra': 31,
    '$0': 0, '$2': 2, '$3': 3, '$4': 4, '$5': 5, '$7': 7, '$8': 8, '$9': 9
}

r_type = {'add': 0x20, 'sub': 0x22, 'and': 0x24, 'or': 0x25, 'slt': 0x2A, 'mult': 0x18, 'mflo': 0x12, 'mfhi': 0x10}
i_type = {'lw': 0x23, 'sw': 0x2B, 'beq': 0x04, 'addi': 0x08}
j_type = {'j': 0x02}

def get_reg(v):
    if v in registers: return registers[v]
    if v.startswith('$'): return int(v[1:])
    return int(v)

def assemble(asm_file, exe_file):
    with open(asm_file, 'r') as f:
        content = f.read()
        
    content = content.replace('−', '-')
    lines = content.split('\n')
        
    labels = {}
    instructions = []
    

    pc = 0
    for line in lines:
        line = line.split('#')[0].strip()
        if not line or line.startswith('.end'): continue
        if line.startswith('.org'):
            target_addr = int(line.split()[1], 0) // 4
            while pc < target_addr:
                instructions.append((pc, 'add $zero, $zero, $zero')) # nop
                pc += 1
            continue
        elif ':' in line:
            label, rest = line.split(':', 1)
            labels[label.strip()] = pc
            if rest.strip() and not rest.strip().startswith('.end'):
                instructions.append((pc, rest.strip()))
                pc += 1
        else:
            instructions.append((pc, line.strip()))
            pc += 1
            
    
    machine_code = []
    for pc, inst in instructions:
        parts = [p.strip() for p in re.split(r'[\s,]+', inst) if p.strip()]
        op = parts[0]
        
        if op in r_type:
            if op == 'mult':
                # mult rs, rt -> rd=0, shamt=0
                rs = get_reg(parts[1])
                rt = get_reg(parts[2])
                rd = 0
            elif op in ['mflo', 'mfhi']:
                # mflo rd -> rs=0, rt=0, shamt=0
                rd = get_reg(parts[1])
                rs = 0
                rt = 0
            else:
                # op rd, rs, rt
                rd = get_reg(parts[1])
                rs = get_reg(parts[2])
                rt = get_reg(parts[3])
            code = (0 << 26) | (rs << 21) | (rt << 16) | (rd << 11) | (0 << 6) | r_type[op]
        elif op in i_type:
            if op == 'beq':
                rs = get_reg(parts[1])
                rt = get_reg(parts[2])
                target = parts[3]
                if target in labels:
                    imm = labels[target] - (pc + 1)
                else:
                    imm = int(target)
                code = (i_type[op] << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
            elif op in ['lw', 'sw']:
                # op rt, imm(rs)
                rt = get_reg(parts[1])
                match = re.match(r'(-?\d+)\((.*?)\)', parts[2])
                imm = int(match.group(1))
                rs = get_reg(match.group(2))
                code = (i_type[op] << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
            elif op == 'addi':
                rt = get_reg(parts[1])
                rs = get_reg(parts[2])
                imm = int(parts[3])
                code = (i_type[op] << 26) | (rs << 21) | (rt << 16) | (imm & 0xFFFF)
        elif op in j_type:
            target = labels[parts[1]]
            code = (j_type[op] << 26) | (target & 0x3FFFFFF)
        else:
            print(f"Unknown op: {op}")
            sys.exit(1)
            
        machine_code.append(f"{code:08x}")
        
    with open(exe_file, 'w') as f:
        for c in machine_code:
            f.write(c + '\n')
            
    print(f"Compiled {len(machine_code)} instructions to {exe_file}")

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python assembler.py <input.asm> <output.exe>")
        sys.exit(1)
    assemble(sys.argv[1], sys.argv[2])