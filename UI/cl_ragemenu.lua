--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM) - OX_LIB REFIT
---------------------------------------------------
FILE: cl_ragemenu.lua (Refactored to ox_lib Context Menu)
PURPOSE: Full feature-parity ox_lib Context Menu for LVC
---------------------------------------------------
]]

function IsMenuOpen()
	return lib.getOpenContextMenu() ~= nil
end

function OpenLVCMainMenu()
	if not player_is_emerg_driver then
		lib.notify({ type = 'error', description = 'Você precisa estar no controle de um veículo de emergência.' })
		return
	end

	local veh_name = 'DESCONHECIDO'
	if veh and DoesEntityExist(veh) then
		veh_name = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
	end

	-- Menu Principal
	lib.registerContext({
		id = 'lvc_main_menu',
		title = 'LVC - Controle de Sirenes',
		options = {
			{
				title = Lang:t('menu.siren') or 'Configurações de Sirene',
				description = 'Ajustar tons, atalhos e comportamentos de sirene',
				icon = 'bullhorn',
				menu = 'lvc_siren_menu'
			},
			{
				title = 'Atribuição de Tons de Sirene',
				description = 'Alterar sons atribuídos a PMANU, SMANU, AUX e Airhorn',
				icon = 'music',
				menu = 'lvc_tone_assign_menu'
			},
			{
				title = Lang:t('menu.hud') or 'Configurações de HUD',
				description = 'Visibilidade, escala, posição e iluminação',
				icon = 'sliders',
				menu = 'lvc_hud_menu'
			},
			{
				title = Lang:t('menu.audio') or 'Configurações de Áudio & Volume',
				description = 'Ajustar volumes individuais, cliques e lembretes',
				icon = 'volume-high',
				menu = 'lvc_audio_menu'
			},
			{
				title = Lang:t('menu.storage') or 'Armazenamento & Perfis',
				description = ('Perfil Atual: %s'):format(UTIL:GetVehicleProfileName() or veh_name),
				icon = 'floppy-disk',
				menu = 'lvc_storage_menu'
			},
			{
				title = Lang:t('menu.more_info') or 'Informações do LVC',
				description = ('Versão Instalada: v%s'):format(STORAGE:GetCurrentVersion() or '3.2.9'),
				icon = 'circle-info',
				onSelect = function()
					lib.alertDialog({
						header = 'Luxart Vehicle Control v3 (OX Stack)',
						content = 'Sistema de controle de veículos de emergência 100% otimizado via ox_lib.\n\nDesenvolvido por Lt. Caine & TrevorBarns.\nOtimização por Antigravity.',
						centered = true
					})
				end
			}
		}
	})

	-- Submenu 1: Comportamento de Sirene
	lib.registerContext({
		id = 'lvc_siren_menu',
		title = 'LVC - Comportamento de Sirene',
		menu = 'lvc_main_menu',
		options = {
			{
				title = Lang:t('menu.airhorn_interrupt') or 'Interrupção de Airhorn',
				description = 'Pressionar buzina pausa a sirene principal temporariamente',
				icon = 'bolt',
				checked = tone_airhorn_intrp,
				onSelect = function()
					tone_airhorn_intrp = not tone_airhorn_intrp
					lib.showContext('lvc_siren_menu')
				end
			},
			{
				title = Lang:t('menu.reset_standby') or 'Reset de Sirene em Standby',
				description = 'Voltar para o primeiro tom ao desligar a sirene',
				icon = 'rotate-left',
				checked = tone_main_reset_standby,
				onSelect = function()
					tone_main_reset_standby = not tone_main_reset_standby
					lib.showContext('lvc_siren_menu')
				end
			},
			{
				title = Lang:t('menu.siren_park_kill') or 'Park Kill (Desligar ao Sair)',
				description = 'Desliga automaticamente sirenes ao sair do veículo',
				icon = 'parking',
				checked = park_kill,
				onSelect = function()
					park_kill = not park_kill
					lib.showContext('lvc_siren_menu')
				end
			}
		}
	})

	-- Submenu 2: Atribuição de Tons
	local approved_tones = UTIL:GetApprovedTonesTableNameAndID() or {}
	local tone_options_list = {}
	for _, t in ipairs(approved_tones) do
		if t.Value and t.Name then
			table.insert(tone_options_list, { value = t.Value, label = t.Name })
		end
	end

	lib.registerContext({
		id = 'lvc_tone_assign_menu',
		title = 'LVC - Atribuição de Tons',
		menu = 'lvc_main_menu',
		options = {
			{
				title = 'Tom do Primary Manual (PMANU)',
				description = 'Alterar o som acionado no trocador primário',
				icon = 'sliders',
				onSelect = function()
					local input = lib.inputDialog('Atribuir Tom PMANU', {
						{ type = 'select', label = 'Selecione o Tom', options = tone_options_list, default = UTIL:GetToneID('PMANU') }
					})
					if input and input[1] then
						UTIL:SetToneByID('PMANU', input[1])
						lib.notify({ type = 'success', description = 'Tom PMANU atualizado.' })
					end
					lib.showContext('lvc_tone_assign_menu')
				end
			},
			{
				title = 'Tom do Secondary Manual (SMANU)',
				description = 'Alterar o som acionado no trocador secundário',
				icon = 'sliders',
				onSelect = function()
					local input = lib.inputDialog('Atribuir Tom SMANU', {
						{ type = 'select', label = 'Selecione o Tom', options = tone_options_list, default = UTIL:GetToneID('SMANU') }
					})
					if input and input[1] then
						UTIL:SetToneByID('SMANU', input[1])
						lib.notify({ type = 'success', description = 'Tom SMANU atualizado.' })
					end
					lib.showContext('lvc_tone_assign_menu')
				end
			},
			{
				title = 'Tom Auxiliar (AUX / Powercall)',
				description = 'Alterar o som da sirene auxiliar',
				icon = 'sliders',
				onSelect = function()
					local input = lib.inputDialog('Atribuir Tom Auxiliar', {
						{ type = 'select', label = 'Selecione o Tom', options = tone_options_list, default = UTIL:GetToneID('AUX') }
					})
					if input and input[1] then
						UTIL:SetToneByID('AUX', input[1])
						lib.notify({ type = 'success', description = 'Tom AUX atualizado.' })
					end
					lib.showContext('lvc_tone_assign_menu')
				end
			}
		}
	})

	-- Submenu 3: Configurações de HUD
	lib.registerContext({
		id = 'lvc_hud_menu',
		title = 'LVC - Configurações de HUD',
		menu = 'lvc_main_menu',
		options = {
			{
				title = 'Exibir HUD Visual',
				description = 'Alternar visibilidade da caixa de controle na tela',
				icon = 'eye',
				checked = HUD:GetHudState(),
				onSelect = function()
					HUD:SetHudState(not HUD:GetHudState())
					lib.showContext('lvc_hud_menu')
				end
			},
			{
				title = 'Ajustar Escala do HUD',
				description = ('Escala Atual: %.1fx'):format(HUD:GetHudScale() or 0.7),
				icon = 'expand',
				onSelect = function()
					local input = lib.inputDialog('Ajustar Escala do HUD', {
						{ type = 'slider', label = 'Tamanho (0.5 a 1.5)', min = 0.5, max = 1.5, step = 0.1, default = HUD:GetHudScale() or 0.7 }
					})
					if input and input[1] then
						HUD:SetHudScale(input[1])
						lib.notify({ type = 'inform', description = ('Escala do HUD definida para %.1f'):format(input[1]) })
					end
					lib.showContext('lvc_hud_menu')
				end
			},
			{
				title = 'Modo Backlight (Luz de Fundo)',
				description = ('Modo Atual: %s'):format(HUD:GetHudBacklightMode() == 1 and 'Automático (Faróis)' or 'Desativado'),
				icon = 'lightbulb',
				onSelect = function()
					local newMode = HUD:GetHudBacklightMode() == 1 and 0 or 1
					HUD:SetHudBacklightMode(newMode)
					lib.showContext('lvc_hud_menu')
				end
			},
			{
				title = 'Resetar Posição do HUD',
				description = 'Centraliza a posição da caixa de controle na tela',
				icon = 'arrows-to-dot',
				onSelect = function()
					HUD:ResetPosition()
					lib.notify({ type = 'success', description = 'Posição do HUD resetada.' })
					lib.showContext('lvc_hud_menu')
				end
			}
		}
	})

	-- Submenu 4: Configurações de Áudio & Volume
	lib.registerContext({
		id = 'lvc_audio_menu',
		title = 'LVC - Áudio & Volumes',
		menu = 'lvc_main_menu',
		options = {
			{
				title = 'Ajustar Volumes de Sons',
				description = 'Configurar volumes dos cliques, sirenes e avisos',
				icon = 'volume-low',
				onSelect = function()
					local input = lib.inputDialog('Configurar Volumes do LVC', {
						{ type = 'slider', label = 'Volume ao Ligar (On)', min = 0.0, max = 1.0, step = 0.05, default = AUDIO.on_volume or 0.5 },
						{ type = 'slider', label = 'Volume ao Desligar (Off)', min = 0.0, max = 1.0, step = 0.05, default = AUDIO.off_volume or 0.5 },
						{ type = 'slider', label = 'Volume do Lembrete de Atividade', min = 0.0, max = 1.0, step = 0.05, default = AUDIO.activity_reminder_volume or 0.3 }
					})
					if input then
						AUDIO.on_volume = input[1]
						AUDIO.off_volume = input[2]
						AUDIO.activity_reminder_volume = input[3]
						lib.notify({ type = 'success', description = 'Volumes atualizados!' })
					end
					lib.showContext('lvc_audio_menu')
				end
			},
			{
				title = 'Efeito Sonoro do Airhorn',
				description = 'Tocar clique ao pressionar/soltar Airhorn',
				icon = 'volume-low',
				checked = AUDIO.airhorn_button_SFX,
				onSelect = function()
					AUDIO.airhorn_button_SFX = not AUDIO.airhorn_button_SFX
					lib.showContext('lvc_audio_menu')
				end
			},
			{
				title = 'Efeito Sonoro de Troca Manual',
				description = 'Tocar clique ao pressionar trocador de tons',
				icon = 'volume-low',
				checked = AUDIO.manu_button_SFX,
				onSelect = function()
					AUDIO.manu_button_SFX = not AUDIO.manu_button_SFX
					lib.showContext('lvc_audio_menu')
				end
			}
		}
	})

	-- Submenu 5: Armazenamento & Perfis
	lib.registerContext({
		id = 'lvc_storage_menu',
		title = 'LVC - Armazenamento',
		menu = 'lvc_main_menu',
		options = {
			{
				title = 'Salvar Perfil do Veículo Atual',
				description = 'Salva as preferências personalizadas deste modelo de viatura',
				icon = 'floppy-disk',
				onSelect = function()
					STORAGE:SaveSettings()
					lib.notify({ type = 'success', description = 'Configurações de perfil salvas com sucesso!' })
				end
			},
			{
				title = 'Carregar Perfil Salvo',
				description = 'Recarrega as configurações salvas para este veículo',
				icon = 'download',
				onSelect = function()
					STORAGE:LoadSettings()
					lib.notify({ type = 'inform', description = 'Configurações de perfil recarregadas.' })
				end
			},
			{
				title = 'Copiar Perfil de Outro Veículo',
				description = 'Importa as configurações de outro modelo salvo',
				icon = 'copy',
				onSelect = function()
					local saved_profiles = STORAGE:GetSavedProfiles()
					if #saved_profiles == 0 then
						lib.notify({ type = 'error', description = 'Nenhum outro perfil salvo encontrado.' })
					else
						local profile_options = {}
						for _, prof in ipairs(saved_profiles) do
							table.insert(profile_options, { value = prof, label = prof })
						end
						local input = lib.inputDialog('Copiar Perfil', {
							{ type = 'select', label = 'Escolha o Perfil Origem', options = profile_options }
						})
						if input and input[1] then
							STORAGE:LoadSettings(input[1])
							STORAGE:SaveSettings()
							lib.notify({ type = 'success', description = ('Perfil %s copiado!'):format(input[1]) })
						end
					end
					lib.showContext('lvc_storage_menu')
				end
			},
			{
				title = 'Resetar para Padrão de Fábrica',
				description = 'Apaga todos os perfis salvos e restaura o LVC original',
				icon = 'trash-can',
				onSelect = function()
					local confirm = lib.alertDialog({
						header = 'Confirmar Reset de Fábrica',
						content = 'Tem certeza que deseja apagar todos os perfis salvos e restaurar os padrões?',
						cancel = true
					})
					if confirm == 'confirm' then
						STORAGE:ResetSettings()
						lib.notify({ type = 'warning', description = 'Configurações restauradas para o padrão.' })
					end
				end
			}
		}
	})

	lib.showContext('lvc_main_menu')
end