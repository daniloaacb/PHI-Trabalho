# PHI-Trabalho
---
### Esquema do trabalho

Desenvolva um sistema digital medidor de tempo de reação que mede o tempo decorrido entre o acendimento de uma lâmpada e o apertar de um botão por uma pessoa. O medidor tem três entradas, uma entrada clk de clock, uma entrada rst de reset e um botão de entrada B. Tem três saídas, uma saída len de habilitação da lâmpada, uma saída rtempo de tempo de reação de dez bits e uma saída lento para indicar que o usuário não foi rápido o suficiente. Durante o reset, o medidor de tempo de reação espera por 10 segundos antes de acender a lâmpada fazendo len = 1. A seguir, o medidor de tempo de reação mede o intervalo de tempo decorrido em milissegundos até o usuário pressionar o botão B, fornecendo o tempo como um número binário de 12 bits na saída rtempo. Se o usuário não pressionar o botão dentro de 2 segundos, o medidor irá ativar a saída lento tornando-a 1 e colocando 2 segundos em rtempo. Assuma que a entrada de clock tem uma frequência de 2,5 kHz. O tempo de reação deve ser fornecido na saída rtempo em segundos.


### Componentes:
- temporizador_10s.vhd
- controle_lampada.vhd
- contador_tempo_reacao.vhd
- conversor_ms_para_s.vhd
- fsm_top.vhd (ou controle_reacao.vhd)

