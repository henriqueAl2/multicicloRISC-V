# Processador RISC-V Multiciclo (`multicicloRISC-V`)

Implementação em **VHDL** de um processador **RISC-V (RV32I) multiciclo**, organizado de forma modular entre pacote de definições, parte operativa (*datapath*), unidade de controle e *testbenches* de verificação.

---

## Sumário

* [Visão Geral](#visão-geral)
* [Estrutura do Repositório](#estrutura-do-repositório)
* [Instruções Suportadas](#instruções-suportadas)
* [Módulos Principais](#módulos-principais)
* [Simulação e Testes](#simulação-e-testes)
* [Pontos de Atenção para Integração](#pontos-de-atenção-para-integração)

---

## Visão Geral

O projeto realiza a arquitetura RISC-V multiciclo em VHDL, compartilhando recursos como a memória de dados/instruções e a ULA ao longo das etapas de execução controladas por uma máquina de estados finitos (FSM).

---

## Estrutura do Repositório

```text
multicicloRISC-V/
├── README.md
├── work-obj93.cf
├── packages/
│   └── pkg.vhdl
├── rtl/
│   ├── control/
│   │   ├── controle.vhdl
│   │   ├── controle_ULA.vhdl
│   │   ├── ula_control.vhd
│   │   └── fsm_control.vhd
│   └── datapath/
│       ├── XREGS.vhdl
│       ├── genImm32.vhdl
│       ├── memoria.vhdl
│       ├── reg_en.vhdl
│       ├── ula.vhdl
│       ├── ulaRV_vhd
│       ├── aux_regs.vhd
│       ├── genImm32.vhd
│       ├── muxes.vhd
│       └── xregs.vhd
└── tb/
    ├── riscv_testbench.vhdl
    ├── tb_ulaRV.vhd
    ├── tb_fsm.vhd
    ├── tb_riscv_top.vhd
    └── tb_xregs.vhd
```

---

## Instruções Suportadas

### Núcleo Básico (RV32I)

* **Memória e Imediatos altos:** `LW`, `SW`, `LUI`, `AUIPC`
* **Aritmética e Lógica:** `ADD`, `ADDi`, `SUB`, `AND`, `OR`, `XOR`, `SLT`
* **Desvios e Saltos:** `BEQ`, `BNE`, `JAL`, `JALR`

### Extensões — Grupos Comp e Shift

| Grupo | Instrução | Descrição |
| :--- | :--- | :--- |
| **Comp** | `SLTi` | `X[rd] = (X[rs1] < imm32) ? 1 : 0` (com sinal) |
| **Comp** | `SLTU` | `X[rd] = (X[rs1] <u X[rs2]) ? 1 : 0` (sem sinal) |
| **Comp** | `SLTIU` | `X[rd] = (X[rs1] <u imm32) ? 1 : 0` (imediato estendido com sinal, comparação sem sinal) |
| **Shift** | `SLL` | `X[rd] = X[rs1] << X[rs2][4:0]` (deslocamento lógico à esquerda) |
| **Shift** | `SRL` | `X[rd] = X[rs1] >>u X[rs2][4:0]` (deslocamento lógico à direita) |
| **Shift** | `SRA` | `X[rd] = X[rs1] >> X[rs2][4:0]` (deslocamento aritmético à direita) |

---

## Módulos Principais

* **`packages/pkg.vhdl`**: define constantes globais (`WORD_WIDTH = 32`, `REG_ADDR_W = 5`, `MEM_DEPTH = 256`), *opcodes* (`OP_R_TYPE`, `OP_I_ALU`, `OP_LOAD`, `OP_STORE`, `OP_BRANCH`, `OP_JAL`, `OP_JALR`, `OP_LUI`), códigos da ULA (`ALU_ADD` até `ALU_SNE`) e declarações de componentes.
* **`rtl/control/controle.vhdl` (`controle`)**: FSM multiciclo com estados como `S_FETCH`, `S_DECODE`, `S_MEM_ADDR`, `S_MEM_READ`, `S_MEM_WB`, `S_MEM_WRITE`, `S_R_EXEC`, `S_I_EXEC`, `S_ALU_WB`, `S_BRANCH`, `S_JAL`, `S_JALR_CALC`, `S_JALR_WB`, `S_LUI` e `S_AUIPC`.
* **`rtl/control/ula_control.vhd` / `controle_ULA.vhdl` (`controle_ula`)**: traduz `alu_op_ctrl`, `funct3` e `funct7_bit` (`instr(30)`) para o sinal `alu_ctrl` da ULA.
* **`rtl/datapath/XREGS.vhdl` (`XREGS`)**: banco de 32 registradores de 32 bits com leitura combinacional (`ro1`, `ro2`), escrita síncrona (`wren`) e `x0` fixo em zero.
* **`rtl/datapath/genImm32.vhdl` (`genImm32`)**: gera e estende para 32 bits (`signed`) os imediatos conforme o formato da instrução.
* **`rtl/datapath/ulaRV_vhd` / `ula.vhdl` (`ulaRV`)**: executa as operações selecionadas (`Z`, `cond`, `zero`).

---

## Simulação e Testes

A simulação pode ser feita no **GHDL**, **ModelSim** ou **EDA Playground** compilando primeiro o pacote `pkg.vhdl` na biblioteca `work`:

```sh
ghdl -a --std=08 packages/pkg.vhdl
ghdl -a --std=08 rtl/datapath/XREGS.vhdl rtl/datapath/genImm32.vhdl rtl/datapath/memoria.vhdl rtl/datapath/reg_en.vhdl rtl/datapath/ula.vhdl
ghdl -a --std=08 rtl/control/controle.vhdl rtl/control/ula_control.vhd
ghdl -a --std=08 tb/tb_ulaRV.vhd
ghdl -e --std=08 tb_ulaRV
ghdl -r --std=08 tb_ulaRV
```

---

## Pontos de Atenção para Integração

1. **Padronização de extensões de arquivo**: o repositório contém arquivos `.vhdl`, `.vhd` e arquivos de rascunho/vazios; garanta que o script de compilação aponte exatamente para os arquivos ativos escolhidos pelo grupo.
2. **Conversão de tipos no *datapath***: `genImm32` retorna `signed(31 downto 0)`, enquanto as entradas da ULA usam `std_logic_vector` — utilize `std_logic_vector(imm32)` na interligação dos multiplexadores.
3. **Casos de teste em `Teste_multiciclo.asm`**: no bloco `# GRUPO SHIFT`, `sll t5, t2, a0` com `t2 = 0xFF000000` e `a0 = 4` produz `0xF0000000` (enquanto o comentário original do arquivo indica `0x0FF00000`).
