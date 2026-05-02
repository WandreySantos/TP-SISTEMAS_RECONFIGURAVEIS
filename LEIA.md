1. Preparação da PastaColoque o arquivo alu.vhd em uma pasta que não tenha espaços ou acentos no nome do caminho (ex: C:\Projetos\ULA em vez de C:\Usuários\André\Trabalho Escola). O Quartus 9.1 é antigo e dá erro com nomes de pastas brasileiros.

2. Criando o Projeto (New Project Wizard)Nome do Projeto: Deve ser exatamente alu (igual ao nome da entity no código).  Arquivos: Quando chegar na tela de adicionar arquivos, selecione o alu.vhd.  Família de Chips: No Quartus 9.1, se você não achar o Cyclone IV, pode selecionar o Cyclone II (é o mais comum para essa versão).

3. CompilaçãoClique no botão de Play (Start Compilation) na barra de ferramentas.  Atenção: Se der erro de "Top-level design entity is undefined", clique com o botão direito no arquivo alu.vhd na aba de arquivos e selecione Set as Top-Level Entity.

4. Simulação (Onde a maioria trava)Para o Waveform funcionar no Quartus 9.1, siga esta ordem exata:

Criar o arquivo: File > New > Vector Waveform File.  Importar Sinais: No painel esquerdo, clique com o botão direito > Insert Node or Bus > Node Finder > Filtro: Pins: all > Clique em List > Clique no botão >> para passar tudo para a direita > OK.

Configurar o Tempo: Vá em Edit > End Time e coloque 1 us ou 100 ns.

Colocar Valores: Clique no sinal a_in, e use os ícones no topo (como o 'C' para contar ou o '1'/'0' fixo) para dar valores.  Dica: Clique com o botão direito no sinal > Radix > Unsigned Decimal para facilitar a vida.

Gerar Netlist (Obrigatório): Vá em Processing > Generate Functional Simulation Netlist. Sem isso, o simulador não abre.

Rodar: Vá em Simulator Tool (no menu Assignments ou Tools) > Selecione Functional > Clique em Start.
