--[[
--------------------------------------------------------------------------------
LUXART VEHICLE CONTROL V3 (LVC - OX STACK) - CONFIGURAÇÃO E AUDITORIA DE TECLAS
--------------------------------------------------------------------------------
DOCUMENTAÇÃO E AUDITORIA COMPLETA DE CONTROLES DO LVC:

1. GIROFLEX / LUZES DE EMERGÊNCIA:
   - Tecla: Q (Controle Nativo GTA V INPUT_VEH_RADIO_WHEEL / 85)
   - Função: Liga e desliga as luzes de emergência (Giroflex).
   - Observação: É necessário ligar o Giroflex (Q) para atuar as sirenes contínuas (1, 2, 3).

2. SIRENES CONTÍNUA POR TOM (MANTER LIGADA):
   - Teclas: 1, 2, 3, 4, 5, 6, 7, 8, 9, 0 (Comandos _lvc_siren_1 até 10)
   - Função:
     * Com o Giroflex LIGADO (Q), pressione '1' para ativar o 1º Tom (Wail) em modo CONTÍNUO.
     * Pressione '2' para mudar para o 2º Tom (Yelp) em modo CONTÍNUO.
     * Pressione '3' para mudar para o 3º Tom (Phaser) em modo CONTÍNUO.
     * Pressione a mesma tecla novamente para desligar a sirene contínua.

3. SIRENE TEMPORÁRIA / TROCA RÁPIDA:
   - Tecla: R (Controle Nativo GTA V INPUT_SPECIAL_ABILITY_SECONDARY / 19)
   - Função: Toca sirene de forma temporária/manual ou altera rápida de tom.

4. BUZINA DE EMERGÊNCIA (AIRHORN):
   - Tecla: E (Controle Nativo GTA V INPUT_VEH_HORN / 86)
   - Função: Toca a buzina forte de emergência (Airhorn) enquanto a tecla for mantida pressionada.

5. SIRENE AUXILIAR (POWERCALL):
   - Tecla: Seta para Cima (Controle Nativo GTA V INPUT_CELLPHONE_UP / 172)
   - Função: Liga/desliga o tom auxiliar simultâneo de emergência.

6. MENU CONTEXTUAL DE CONFIGURAÇÕES:
   - Tecla: O (open_menu_key)
   - Função: Abre a interface visual ox_lib para personalizar volumes, HUD e perfis por veículo.

7. TRAVAMENTO DO PAINEL LVC:
   - Comando / Tecla: /lvc lock (lockout_default_hotkey)
   - Função: Bloqueia a alteração acidental de sirenes durante a pilotagem.
--------------------------------------------------------------------------------
]]

--------------------1. IDENTIFICAÇÃO DA COMUNIDADE-------------------
community_id = 'qbox'

--------------------2. ATALHOS DE TECLAS E MENU--------------------
-- Tecla para abrir o menu do ox_lib (Ex: 'O', 'F5', 'L')
open_menu_key = 'O'

-- Tecla para trancar/destrancar o painel do LVC (Vazio = apenas via comando /lvc lock)
lockout_default_hotkey = ''

-- Ativar registro automático das teclas numéricas 1 a 0 para sirenes contínuas
main_siren_set_register_keys_set_defaults = true

--------------------3. COMPORTAMENTO DAS SIRENES--------------------
-- Chaves mestre de configuração
main_siren_settings_masterswitch = true
park_kill_masterswitch = true
airhorn_interrupt_masterswitch = true
reset_to_standby_masterswitch = true
custom_manual_tones_master_switch = true
custom_aux_tones_master_switch = true

-- Configurações padrão de fábrica
park_kill_default = false         -- Desligar sirene automaticamente ao sair da viatura
airhorn_interrupt_default = true  -- Pausar sirene temporariamente ao usar buzina (E)
reset_to_standby_default = true   -- Voltar ao 1º tom ao desligar a sirene

--------------------4. CONFIGURAÇÃO DE HUD E VISIBILIDADE-----------
hud_first_default = true          -- Exibir o HUD visual ao entrar no veículo de emergência

--------------------5. SINAIS DE SETA E ALERTA----------------------
hazard_key = 202                  -- Tecla de pisca-alerta (Backspace)
left_signal_key = 84              -- Setas para esquerda
right_signal_key = 83             -- Setas para direita
hazard_hold_duration = 750        -- Tempo em milissegundos pressionado para ligar o pisca-alerta

--------------------6. VOLUMES E EFEITOS SONOROS (SFX)-------------
button_sfx_scheme_choices = { 'SSP2000', 'SSP3000', 'Cencom', 'ST300' }
default_sfx_scheme_name = 'SSP2000'
default_on_volume = 0.5
default_off_volume = 0.7
default_upgrade_volume = 0.5
default_downgrade_volume = 0.7
default_hazards_volume = 0.09
default_lock_volume = 0.25
default_lock_reminder_volume = 0.2
default_reminder_volume = 0.09

--------------------7. SUPORTE A PLUGINS----------------------------
plugins_installed = false