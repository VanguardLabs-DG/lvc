# lvc — Manual

Luxart Vehicle Control: controlador de sirenes, luzes e setas para veículos de emergência, com menu RageUI, HUD em NUI e perfis salvos por veículo no lado do cliente.

---

## Sumário

1. [Dependências](#dependências)
2. [Instalação](#instalação)
3. [Configuração](#configuração)
4. [Controles](#controles)
5. [Comandos](#comandos)
6. [Sirenes e perfis de veículo](#sirenes-e-perfis-de-veículo)
7. [Armazenamento (KVP)](#armazenamento-kvp)
8. [Plug-ins](#plug-ins)
9. [Entrypoints para outros recursos](#entrypoints-para-outros-recursos)
10. [Localização](#localização)
11. [Estrutura de arquivos](#estrutura-de-arquivos)

---

## Dependências

| Recurso | Obrigatório | Observação |
|---|---|---|
| `RageUI` | Sim | Declarado em `dependencies`. Todo o menu de configuração é construído com ele |

O recurso é standalone quanto a framework: não usa qb-core, ESX, inventário nem target.

---

## Instalação

1. Copie o recurso para `resources/` **com o nome de pasta exatamente `lvc`**. O `cl_lvc.lua` verifica `GetCurrentResourceName() == 'lvc'` e se recusa a funcionar com outro nome.
2. Adicione ao `server.cfg`, com o `RageUI` iniciado antes:
   ```
   ensure RageUI
   ensure lvc
   ```
3. **Conflito** — não rode junto com o `lux_vehcontrol`. O LVC detecta o recurso rodando, aborta a inicialização e imprime um erro no console.
4. Defina o `community_id` em `SETTINGS.lua` antes de subir em produção (ver abaixo).
5. Não há SQL nem itens de inventário a cadastrar.

---

## Configuração

Arquivo principal: `SETTINGS.lua`.

### Identidade e menu

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `community_id` | string | Sim | Prefixo dos dados salvos no cliente (KVP). Evita conflito entre servidores diferentes. Sem espaços. **Uma vez definido, não mude** — os jogadores perdem todos os perfis salvos. Se ficar vazio, o LVC não inicializa |
| `open_menu_key` | string | Sim | Tecla padrão do menu. Padrão: `'O'`. O jogador pode remapear em Configurações > Teclas > FiveM |

### Lockout

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `lockout_default_hotkey` | string | Sim | Tecla padrão do travamento de controles. Padrão: vazio (sem tecla; o jogador define a dele) |
| `locked_press_count` | number | Sim | Após quantas teclas pressionadas com o controlador travado o primeiro lembrete aparece |
| `reminder_rate` | number | Sim | De quantas em quantas teclas o lembrete se repete depois disso |

### HUD

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `hud_first_default` | bool | Sim | Estado inicial da HUD no primeiro uso. Depois disso, vale a preferência salva no KVP do jogador |

### Sirene principal

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `main_siren_settings_masterswitch` | bool | Sim | Libera o jogador a renomear tons e trocar o modo de cada tom (Cycle / Button) |
| `park_kill_masterswitch` | bool | Sim | Libera o jogador a alterar o park kill. Com `false`, o comportamento fica travado no default |
| `park_kill_default` | bool | Sim | Estado padrão do park kill (corta a sirene com o veículo estacionado) |
| `airhorn_interrupt_masterswitch` | bool | Sim | Libera o jogador a alterar a interrupção da sirene pela buzina |
| `airhorn_interrupt_default` | bool | Sim | Estado padrão da interrupção por buzina |
| `reset_to_standby_masterswitch` | bool | Sim | Libera o jogador a alterar o reset-to-standby |
| `reset_to_standby_default` | bool | Sim | Quando `true`, desligar a sirene volta ao tom padrão em vez de lembrar o último tom usado |

### Tons manuais, auxiliar e teclas numéricas

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `custom_manual_tones_master_switch` | bool | Sim | Libera o menu de escolha dos tons manuais primário e secundário |
| `custom_aux_tones_master_switch` | bool | Sim | Libera o menu de escolha do tom auxiliar (seta para cima) |
| `main_siren_set_register_keys_set_defaults` | bool | Sim | Quando `true`, registra as teclas 1–0 da linha numérica como atalhos diretos para os tons de sirene. Com `false`, os comandos continuam existindo mas nascem sem tecla |

### Setas e pisca-alerta

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `hazard_key` | number | Sim | Control id do pisca-alerta. Padrão: `202` (Backspace) |
| `left_signal_key` | number | Sim | Control id da seta esquerda. Padrão: `84` |
| `right_signal_key` | number | Sim | Control id da seta direita. Padrão: `83` |
| `hazard_hold_duration` | number (ms) | Sim | Tempo que a tecla do pisca-alerta precisa ficar pressionada para alternar. Padrão: `750` |

### Áudio

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `button_sfx_scheme_choices` | array | Sim | Esquemas de SFX disponíveis. Cada item precisa bater **exatamente** com um nome de pasta em `UI/sounds/`. Padrão: `SSP2000`, `SSP3000`, `Cencom`, `ST300` |
| `default_sfx_scheme_name` | string | Sim | Esquema usado por padrão |
| `default_on_volume` | number | Sim | Volume do som de ligar (0.0–1.0) |
| `default_off_volume` | number | Sim | Volume do som de desligar |
| `default_upgrade_volume` | number | Sim | Volume ao subir de tom |
| `default_downgrade_volume` | number | Sim | Volume ao descer de tom |
| `default_hazards_volume` | number | Sim | Volume do pisca-alerta |
| `default_lock_volume` | number | Sim | Volume do som de travar/destravar os controles |
| `default_lock_reminder_volume` | number | Sim | Volume do lembrete de controlador travado |
| `default_reminder_volume` | number | Sim | Volume do lembrete periódico de sirene ligada |

### Plug-ins

| Campo | Tipo | Obrigatório | Descrição |
|---|---|---|---|
| `plugins_installed` | bool | Sim | Habilita o menu de plug-ins. Ver [Plug-ins](#plug-ins) |

### Metadados do `fxmanifest.lua`

Três valores de comportamento ficam no manifesto, não no `SETTINGS.lua`:

| Campo | Descrição |
|---|---|
| `beta_checking` | Notifica sobre revisões beta e novas betas |
| `experimental` | Silencia o aviso de versão instável no console do servidor |
| `debug_mode` | Prints mais verbosos no console do cliente |

---

## Controles

Os controles só respondem se o jogador for **motorista de um veículo de classe 18 (emergência)** e o controlador não estiver travado.

| Control id | Tecla padrão | Descrição |
|---|---|---|
| 85 (`INPUT_VEH_RADIO_WHEEL`) | `Q` | Liga/desliga as luzes de emergência (master switch). Nada mais funciona com as luzes desligadas |
| 19 (`INPUT_CHARACTER_WHEEL`) | `Left Alt` | Liga/desliga a sirene principal |
| 172 (`INPUT_CELLPHONE_UP`) | `Seta para cima` | Liga/desliga o tom auxiliar (powercall) |
| 80 (`INPUT_VEH_CIN_CAM`) | `R` | Com a sirene ligada, avança para o próximo tom. Com a sirene desligada, toca o tom manual enquanto pressionado |
| 86 (`INPUT_VEH_HORN`) | `E` | Buzina / airhorn |
| — | `1` a `0` | Vão direto para o 1º até o 10º tom aprovado do veículo. Registrados por `main_siren_set_register_keys_set_defaults` |
| 84 (`left_signal_key`) | conforme binding do jogo | Seta esquerda |
| 83 (`right_signal_key`) | conforme binding do jogo | Seta direita |
| 202 (`hazard_key`) | `Backspace` (segurar) | Pisca-alerta. Precisa ficar pressionada por `hazard_hold_duration` |
| — | `O` | Abre o menu do LVC (`open_menu_key`) |
| — | nenhuma | Trava/destrava os controles. Sem tecla padrão; definida pelo jogador ou por `lockout_default_hotkey` |

Os controls 85, 19, 172, 80 e 86 são interceptados pelo LVC via `DisableControlAction`, então respondem à tecla que o jogador tiver mapeada para eles no GTA V. As teclas registradas via keybind (menu, lock e tons 1–0) podem ser remapeadas em Configurações > Teclas > FiveM.

---

## Comandos

| Comando | Permissão | Descrição |
|---|---|---|
| `/lvclock` | Todos | Trava e destrava os controles do LVC. Também é o comando ligado à tecla de lockout |
| `/lvcdebug` | Todos | Alterna o modo debug no cliente e força um refresh do perfil do veículo |
| `/lvcfactoryreset` | Todos | Apaga **todos** os dados salvos do LVC no cliente e volta às configurações de fábrica. Pede confirmação |
| `/lvcdumpkvp` | Todos | Imprime no console do cliente todos os KVPs salvos do LVC. Ferramenta de diagnóstico |

Os nomes de `/lvclock` e `/lvcdebug` vêm do arquivo de locale (`command.lock_command` e `command.debug_command`) e mudam se o locale for trocado.

Além desses, o recurso registra dinamicamente os comandos `_lvc_siren_1` até `_lvc_siren_13`, um por tom possível. Eles existem apenas para servir de alvo dos keybinds — não são feitos para serem digitados.

---

## Sirenes e perfis de veículo

Arquivo: `SIRENS.lua`.

### Catálogo de tons (`SIRENS`)

Lista fixa de 14 tons, cada um com `Name` (nome exibido no menu), `String` (o som do jogo) e `Ref`. Você pode renomear e trocar os sons, mas a ordem dos índices é o que o `SIREN_ASSIGNMENTS` referencia.

| ID | Nome padrão | ID | Nome padrão |
|---|---|---|---|
| 1 | Airhorn | 8 | CustomD |
| 2 | Wail | 9 | CustomE |
| 3 | Yelp | 10 | CustomF |
| 4 | Priority | 11 | Powercall |
| 5 | CustomA | 12 | Fire Horn |
| 6 | CustomB | 13 | Fire Yelp |
| 7 | CustomC | 14 | Fire Wail |

### Atribuição por veículo (`SIREN_ASSIGNMENTS`)

Define quais tons cada veículo pode usar, por `gameName`. A chave `DEFAULT` vale para qualquer veículo de emergência sem entrada própria.

```lua
SIREN_ASSIGNMENTS = {
    ['DEFAULT']  = { 1, 2, 3, 4 },
    ['FIRETRUK'] = { 12, 13, 14, 11 },
    ['AMBULAN']  = { 1, 2, 3, 4, 11 },
    ['LGUARD']   = { 1, 2, 3, 4, 11 },
}
```

Para liberar tons específicos a um veículo, adicione uma linha com o `gameName` dele e a lista de IDs do catálogo. O primeiro item da lista é sempre o airhorn/manual; os demais viram os tons acessíveis pelas teclas numéricas, na ordem em que aparecem.

---

## Armazenamento (KVP)

O LVC não usa banco de dados. Todas as preferências do jogador (volume, esquema de SFX, HUD, nomes de tons, perfis por veículo) são gravadas no **client-side KVP** do FiveM, com o prefixo definido em `community_id`.

Consequências práticas:

- as configurações acompanham o jogador, não o personagem;
- trocar o `community_id` depois do servidor no ar apaga o acesso a tudo que já foi salvo;
- `/lvcfactoryreset` é a única forma de o jogador limpar esses dados.

---

## Plug-ins

Com `plugins_installed = true`, o menu do LVC ganha uma aba de plug-ins, e `PLUGINS/cl_plugins.lua` monta os botões dos plug-ins encontrados (traffic advisor, extra controls, blackout, etc.).

Nesta fork os plug-ins estão **desabilitados**: `plugins_installed = false` no `SETTINGS.lua` e, no `fxmanifest.lua`, as linhas que carregam os arquivos dos plug-ins estão comentadas:

```lua
-- 'PLUGINS/**/*.json'
-- '/PLUGINS/**/SETTINGS.lua',
-- '/PLUGINS/**/cl_*.lua',
-- '/PLUGINS/**/sv_*.lua'
```

Para usar plug-ins, descomente essas linhas, coloque o plug-in em `PLUGINS/` e ligue o `plugins_installed`.

---

## Entrypoints para outros recursos

O LVC **não expõe exports**. A comunicação é feita por eventos de rede, usados internamente para sincronizar o estado dos veículos entre os clientes.

```lua
-- Cliente: força o LVC a recarregar o perfil, os tons e a HUD do veículo atual.
-- É o gancho usado quando outro recurso troca o veículo do jogador.
TriggerEvent('lvc:onVehicleChange')
```

Os demais eventos (`lvc:GetRepoVersion_s` e os de broadcast de estado de sirene/setas) são internos ao par cliente-servidor do próprio recurso.

---

## Localização

Os arquivos de idioma ficam em `UI/locale/`:

- `en.lua` — inglês
- `de.lua` — alemão
- `pt-br.lua` — português do Brasil (o que está ativo nesta fork)

Diferente dos recursos que usam `ox_lib`, **o idioma não é escolhido por convar**: o arquivo é carregado direto no `fxmanifest.lua`. Para trocar, edite a linha do `shared_script` e reinicie o recurso:

```lua
shared_script {
    '/UTIL/semver.lua',
    '/UI/cl_locale.lua',
    '/UI/locale/pt-br.lua',	-- Set locale / language file here.
    'SETTINGS.lua',
}
```

Lembre que os nomes dos comandos `/lvclock` e `/lvcdebug` vêm do arquivo de locale — trocar o idioma pode trocar os comandos.

---

## Estrutura de arquivos

```
lvc/
├── SETTINGS.lua              — community_id, teclas, masterswitches, volumes e plug-ins
├── SIRENS.lua                — catálogo dos 14 tons e atribuição de tons por veículo
├── UTIL/
│   ├── cl_lvc.lua            — núcleo: input do jogador, estado das sirenes e setas, broadcast, comandos e keybinds
│   ├── cl_storage.lua        — leitura/gravação de KVP, perfis de veículo, /lvcfactoryreset e /lvcdumpkvp
│   ├── cl_utils.lua          — tons aprovados por veículo, prints e helpers
│   ├── sv_lvc.lua            — sincronia de estado entre clientes e checagem de versão no repositório
│   └── semver.lua            — comparação de versões
├── UI/
│   ├── cl_ragemenu.lua       — menu RageUI e registro da tecla de abertura
│   ├── cl_hud.lua            — HUD em NUI e notificações
│   ├── cl_audio.lua          — reprodução dos SFX e volumes
│   ├── cl_locale.lua         — motor de tradução (Lang:t)
│   ├── locale/               — en.lua, de.lua, pt-br.lua
│   ├── html/                 — index.html, lvc.js, style.css da HUD
│   ├── sounds/               — SFX por esquema (SSP2000, SSP3000, Cencom, ST300) e sons gerais
│   └── textures/             — ícones da HUD (variantes day/night)
├── PLUGINS/
│   └── cl_plugins.lua        — monta a aba de plug-ins do menu (inativo enquanto plugins_installed = false)
├── stream/
│   └── lvc.ytd               — texturas da HUD
└── fxmanifest.lua            — versão, beta_checking, experimental, debug_mode e arquivo de locale ativo
```
