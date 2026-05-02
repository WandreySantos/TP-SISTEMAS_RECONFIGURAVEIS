library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity alu is
    port (
        a_in      : in  std_logic_vector(7 downto 0);
        b_in      : in  std_logic_vector(7 downto 0);
        c_in      : in  std_logic;
        op_sel    : in  std_logic_vector(3 downto 0);
        r_out     : out std_logic_vector(7 downto 0);
        flags_out : out std_logic_vector(4 downto 0)
    );
end alu;

architecture behavior of alu is
    -- Sinais para cálculos aritméticos de 9 bits (para pegar o Carry Out)
    signal res_arith : unsigned(8 downto 0);
    signal carry_ext : unsigned(8 downto 0);
    
    -- Sinais para Half-Carry (estouro do bit 3 para o 4)
    signal h_arith   : unsigned(4 downto 0);
    
    -- Sinal para o resultado final da ULA
    signal res_final : std_logic_vector(7 downto 0);
begin

    -- Extensão do carry de entrada para cálculos de 9 bits
    carry_ext <= "00000000" & c_in;

    -- Lógica Aritmética Concorrente (Cálculo simultâneo)
    res_arith <= (unsigned('0' & a_in) + unsigned('0' & b_in))             when op_sel = "0000" else -- ADD
                 (unsigned('0' & a_in) + unsigned('0' & b_in) + carry_ext) when op_sel = "0001" else -- ADDC
                 (unsigned('0' & a_in) - unsigned('0' & b_in))             when op_sel = "0010" else -- SUB
                 (unsigned('0' & a_in) - unsigned('0' & b_in) - carry_ext) when op_sel = "0011" else -- SUBC
                 (others => '0');

    -- Lógica do Half-Carry (H)[cite: 1]
    h_arith <= (unsigned('0' & a_in(3 downto 0)) + unsigned('0' & b_in(3 downto 0)))             when op_sel = "0000" else
               (unsigned('0' & a_in(3 downto 0)) + unsigned('0' & b_in(3 downto 0)) + carry_ext(4 downto 0)) when op_sel = "0001" else
               (unsigned('0' & a_in(3 downto 0)) - unsigned('0' & b_in(3 downto 0)))             when op_sel = "0010" else
               (unsigned('0' & a_in(3 downto 0)) - unsigned('0' & b_in(3 downto 0)) - carry_ext(4 downto 0)) when op_sel = "0011" else
               (others => '0');

    -- Seletor Principal do Resultado (Apenas lógica concorrente)[cite: 1]
    with op_sel select
        res_final <= std_logic_vector(res_arith(7 downto 0)) when "0000" | "0001" | "0010" | "0011",
                     (a_in and b_in)                        when "0100", -- AND
                     (a_in or b_in)                         when "0101", -- OR
                     (a_in xor b_in)                        when "0110", -- XOR
                     b_in                                   when "0111", -- PASS B
                     (a_in(6 downto 0) & c_in)              when "1000", -- RLC
                     (c_in & a_in(7 downto 1))              when "1001", -- RRC
                     (a_in(6 downto 0) & a_in(7))           when "1010", -- RL
                     (a_in(0) & a_in(7 downto 1))           when "1011", -- RR
                     (a_in(6 downto 0) & '0')               when "1100", -- SLL
                     ('0' & a_in(7 downto 1))               when "1101", -- SRL
                     (a_in(7) & a_in(7 downto 1))           when "1110", -- SRA
                     not a_in                               when "1111", -- NOT A
                     (others => '0')                        when others;

    r_out <= res_final;

    -- =====================
    -- ATRIBUIÇÃO DAS FLAGS (CONCORRENTE)[cite: 1]
    -- =====================

    -- Bit 4: Negative (N) - Baseado no MSB do resultado[cite: 1]
    flags_out(4) <= res_final(7);

    -- Bit 3: Overflow (V) - Lógica de estouro de sinal para soma e subtração[cite: 1]
    flags_out(3) <= (a_in(7) and b_in(7) and (not res_final(7))) or ((not a_in(7)) and (not b_in(7)) and res_final(7)) 
                    when (op_sel = "0000" or op_sel = "0001") else
                    (a_in(7) and (not b_in(7)) and (not res_final(7))) or ((not a_in(7)) and b_in(7) and res_final(7))
                    when (op_sel = "0010" or op_sel = "0011") else '0';

    -- Bit 2: Zero (Z)[cite: 1]
    flags_out(2) <= '1' when res_final = "00000000" else '0';

    -- Bit 1: Half-Carry (H) - Carry saindo do bit 3[cite: 1]
    flags_out(1) <= h_arith(4);

    -- Bit 0: Carry (C) - Carry out aritmético ou bit deslocado[cite: 1]
    flags_out(0) <= res_arith(8) when (op_sel = "0000" or op_sel = "0001" or op_sel = "0010" or op_sel = "0011") else
                    a_in(7)      when (op_sel = "1000" or op_sel = "1010" or op_sel = "1100") else
                    a_in(0)      when (op_sel = "1001" or op_sel = "1011" or op_sel = "1101" or op_sel = "1110") else
                    '0';

end behavior;