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
        flags_out : out std_logic_vector(4 downto 0) -- [N, V, Z, H, C]
    );
end alu;

architecture behavior of alu is
    -- Sinais para cálculos aritméticos (9 bits para capturar Carry/Borrow)
    signal res_add  : unsigned(8 downto 0);
    signal res_addc : unsigned(8 downto 0);
    signal res_sub  : unsigned(8 downto 0);
    signal res_subc : unsigned(8 downto 0);
    
    -- Sinais para Half-Carry/Borrow (estouro do bit 3)
    signal h_add  : unsigned(4 downto 0);
    signal h_addc : unsigned(4 downto 0);
    signal h_sub  : unsigned(4 downto 0);
    signal h_subc : unsigned(4 downto 0);
    
    -- Sinal para o resultado final antes das flags
    signal res_final : std_logic_vector(7 downto 0);
    
    -- Extensão do carry de entrada para cálculos
    signal c_ext : unsigned(8 downto 0);
    signal h_ext : unsigned(4 downto 0);

begin
    -- Preparação dos sinais auxiliares (Concorrente)
    c_ext <= "00000000" & c_in;
    h_ext <= "0000" & c_in;

    -- Cálculos Aritméticos Prévios (Todos ocorrem em paralelo)
    res_add  <= unsigned('0' & a_in) + unsigned('0' & b_in);
    res_addc <= unsigned('0' & a_in) + unsigned('0' & b_in) + c_ext;
    res_sub  <= unsigned('0' & a_in) - unsigned('0' & b_in);
    res_subc <= unsigned('0' & a_in) - unsigned('0' & b_in) - c_ext;

    h_add  <= unsigned('0' & a_in(3 downto 0)) + unsigned('0' & b_in(3 downto 0));
    h_addc <= unsigned('0' & a_in(3 downto 0)) + unsigned('0' & b_in(3 downto 0)) + h_ext;
    h_sub  <= unsigned('0' & a_in(3 downto 0)) - unsigned('0' & b_in(3 downto 0));
    h_subc <= unsigned('0' & a_in(3 downto 0)) - unsigned('0' & b_in(3 downto 0)) - h_ext;

    -- Seleção do Resultado Final (Lógica Concorrente)
    with op_sel select
        res_final <= std_logic_vector(res_add(7 downto 0))  when "0000", -- ADD
                     std_logic_vector(res_addc(7 downto 0)) when "0001", -- ADDC
                     std_logic_vector(res_sub(7 downto 0))  when "0010", -- SUB
                     std_logic_vector(res_subc(7 downto 0)) when "0011", -- SUBC
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
                     (not a_in)                             when "1111", -- NOT
                     (others => '0')                        when others;

    r_out <= res_final;

    -- Atribuição das Flags (Exclusivamente Concorrente)

    -- N (Negative): Bit 7 do resultado
    flags_out(4) <= res_final(7);

    -- V (Overflow): Apenas para ADD, ADDC, SUB, SUBC
    flags_out(3) <= ((a_in(7) and b_in(7) and (not res_final(7))) or ((not a_in(7)) and (not b_in(7)) and res_final(7))) when (op_sel = "0000" or op_sel = "0001") else
                    ((a_in(7) and (not b_in(7)) and (not res_final(7))) or ((not a_in(7)) and b_in(7) and res_final(7))) when (op_sel = "0010" or op_sel = "0011") else
                    '0';

    -- Z (Zero): '1' se resultado for zero
    flags_out(2) <= '1' when res_final = "00000000" else '0';

    -- H (Half Carry/Borrow): Vai-um ou empréstimo do bit 3[cite: 1]
    flags_out(1) <= h_add(4)  when op_sel = "0000" else
                    h_addc(4) when op_sel = "0001" else
                    h_sub(4)  when op_sel = "0010" else
                    h_subc(4) when op_sel = "0011" else
                    '0';

    -- C (Carry/Borrow): Vai-um/empréstimo do MSB ou bit de rotação[cite: 1]
    flags_out(0) <= res_add(8)  when op_sel = "0000" else
                    res_addc(8) when op_sel = "0001" else
                    res_sub(8)  when op_sel = "0010" else
                    res_subc(8) when op_sel = "0011" else
                    a_in(7)     when (op_sel = "1000" or op_sel = "1010" or op_sel = "1100") else
                    a_in(0)     when (op_sel = "1001" or op_sel = "1011" or op_sel = "1101" or op_sel = "1110") else
                    '0';

end behavior;