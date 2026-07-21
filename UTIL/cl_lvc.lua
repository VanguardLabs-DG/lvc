--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_lvc.lua
PURPOSE: Core Functionality and User Input
---------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
---------------------------------------------------
]]

--GLOBAL VARIABLES used in cl_ragemenu, UTILs, and plug-ins.
--	GENERAL VARIABLES
key_lock = false
playerped = nil
last_veh = nil
veh = nil
trailer = nil
player_is_emerg_driver = false
debug_mode = false

--	MAIN SIREN SETTINGS
tone_main_reset_standby 	= reset_to_standby_default
tone_airhorn_intrp 			= airhorn_interrupt_default
park_kill 					= park_kill_default

--LOCAL VARIABLES
local radio_wheel_active = false

local count_bcast_timer = 0
local delay_bcast_timer = 300

local count_sndclean_timer = 0
local delay_sndclean_timer = 400

local actv_ind_timer = false
local count_ind_timer = 0
local delay_ind_timer = 180

actv_lxsrnmute_temp = false
local srntone_temp = 0
local dsrn_mute = true
local lights_on = false
local new_tone = nil
local tone_mem_id = nil
local tone_mem_option = nil
local default_tone = nil
local default_tone_option = nil

state_indic = {}
state_lxsiren = {}
state_pwrcall = {}
state_airmanu = {}
state_aux2 = {}
state_aux3 = {}
state_pursuit = {}

actv_manu = nil
actv_horn = nil
local is_mouse_held = false

local ind_state_o = 0
local ind_state_l = 1
local ind_state_r = 2
local ind_state_h = 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}
local snd_aux2 = {}
local snd_aux3 = {}

--	Local fn forward declaration
local RegisterKeyMaps, MakeOrdinal

----------------EVENT-DRIVEN VEHICLE DETECTION (OX_LIB)----------------
local function CheckVehicleState(vehicle, seat)
	local ped = cache.ped or PlayerPedId()
	local vehicle = vehicle or cache.vehicle or GetVehiclePedIsIn(ped, false)
	local seat = seat or cache.seat or (vehicle > 0 and GetPedInVehicleSeat(vehicle, -1) == ped and -1 or 0)

	local is_emerg = false
	if vehicle and vehicle > 0 and DoesEntityExist(vehicle) then
		local vc = GetVehicleClass(vehicle)
		if vc == 18 or IsVehicleSirenOn(vehicle) then
			is_emerg = true
		end
	end

	if is_emerg and (seat == -1 or seat == 0) then
		if not player_is_emerg_driver or veh ~= vehicle then
			playerped = ped
			veh = vehicle
			_, trailer = GetVehicleTrailerVehicle(veh)
			player_is_emerg_driver = true

			if last_veh ~= veh then
				TriggerEvent('lvc:onVehicleChange')
			else
				HUD:SetHudState(true, true)
			end

			DistantCopCarSirens(false)
			SetVehicleRadioEnabled(veh, false)
		end
	else
		if player_is_emerg_driver then
			player_is_emerg_driver = false
			TriggerEvent('lvc:onVehicleExit')
			veh = nil
			trailer = nil
		end
	end
end

lib.onCache('vehicle', function(vehicle)
	CheckVehicleState(vehicle, cache.seat)
end)

lib.onCache('seat', function(seat)
	CheckVehicleState(cache.vehicle, seat)
end)

-- Register ox_lib keybind for opening LVC Menu
lib.addKeybind({
	name = 'lvc_open_menu',
	description = 'Abrir Menu Luxart Vehicle Control',
	defaultKey = open_menu_key or 'O',
	onPressed = function()
		if player_is_emerg_driver and not key_lock then
			OpenLVCMainMenu()
		end
	end
})

-- Keybind para segurar e interagir com o Painel Rontan via Mouse sem perder o controle do veículo
lib.addKeybind({
	name = 'lvc_hold_mouse_z',
	description = 'Segurar para exibir o ponteiro do mouse no Painel LVC (Manter Direção)',
	defaultKey = 'Z',
	onPressed = function()
		if player_is_emerg_driver and not key_lock then
			is_mouse_held = true
			SetNuiFocusKeepInput(true)
			SetNuiFocus(true, true)
		end
	end,
	onReleased = function()
		is_mouse_held = false
		SetNuiFocusKeepInput(false)
		SetNuiFocus(false, false)
	end
})

-- Keybind para ativar o Modo Pursuit (Perseguição)
lib.addKeybind({
	name = 'lvc_pursuit_mode',
	description = 'Alternar Modo Perseguição (Luzes + Sirene + Takedowns)',
	defaultKey = '',
	onPressed = function()
		if HUD and HUD.TogglePursuitMode then
			HUD:TogglePursuitMode()
		end
	end
})

-- Keybind Reativo OX para Giroflex / Luzes de Emergência (Tecla Q)
lib.addKeybind({
	name = 'lvc_toggle_lights',
	description = 'Alternar Luzes de Emergência / Giroflex',
	defaultKey = 'Q',
	onPressed = function()
		if player_is_emerg_driver and veh ~= nil and not key_lock and not IsPauseMenuActive() then
			local lights_on = IsVehicleSirenOn(veh)
			if lights_on then
				AUDIO:Play('Off', AUDIO.off_volume)
				HUD:SetItemState('switch', false)
				HUD:SetItemState('siren', false)
				SetVehicleSiren(veh, false)
				if trailer ~= nil and trailer ~= 0 then
					SetVehicleSiren(trailer, false)
				end
			else
				AUDIO:Play('On', AUDIO.on_volume)
				HUD:SetItemState('switch', true)
				SetVehicleSiren(veh, true)
				if trailer ~= nil and trailer ~= 0 then
					SetVehicleSiren(trailer, true)
				end
			end
			AUDIO:ResetActivityTimer()
			count_bcast_timer = delay_bcast_timer
		end
	end
})

-- Keybind Reativo OX para Powercall / Aux 1 (Seta Cima)
lib.addKeybind({
	name = 'lvc_powercall',
	description = 'Alternar Sirene Auxiliar (Powercall)',
	defaultKey = 'UP',
	onPressed = function()
		if player_is_emerg_driver and veh ~= nil and not key_lock and not IsMenuOpen() and not IsPauseMenuActive() then
			local lights_on = IsVehicleSirenOn(veh)
			if state_pwrcall[veh] == 0 then
				if lights_on then
					AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
					HUD:SetItemState('siren', true)
					SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX'))
					count_bcast_timer = delay_bcast_timer
				end
			else
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
				if state_lxsiren[veh] == 0 then
					HUD:SetItemState('siren', false)
				end
				SetPowercallStateForVeh(veh, 0)
				count_bcast_timer = delay_bcast_timer
			end
			AUDIO:ResetActivityTimer()
		end
	end
})

-- Keybind Reativo OX para Buzina Airhorn (Tecla E)
lib.addKeybind({
	name = 'lvc_airhorn',
	description = 'Segurar Buzina Airhorn',
	defaultKey = 'E',
	onPressed = function()
		if player_is_emerg_driver and veh ~= nil and not key_lock and not IsPauseMenuActive() then
			actv_horn = true
			AUDIO:ResetActivityTimer()
			HUD:SetItemState('horn', true)
			if AUDIO.airhorn_button_SFX then AUDIO:Play('Press', AUDIO.upgrade_volume) end
		end
	end,
	onReleased = function()
		if actv_horn then
			actv_horn = false
			HUD:SetItemState('horn', false)
			if AUDIO.airhorn_button_SFX then AUDIO:Play('Release', AUDIO.upgrade_volume) end
		end
	end
})

-- Keybind Reativo OX para Sirene Manual / Troca de Tom (Tecla R)
lib.addKeybind({
	name = 'lvc_manu_siren',
	description = 'Sirene Manual / Alternar Tom de Sirene',
	defaultKey = 'R',
	onPressed = function()
		if player_is_emerg_driver and veh ~= nil and not key_lock and not IsPauseMenuActive() then
			if state_lxsiren[veh] > 0 then
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
				HUD:SetItemState('horn', false)
				SetLxSirenStateForVeh(veh, UTIL:GetNextSirenTone(state_lxsiren[veh], veh, true))
				count_bcast_timer = delay_bcast_timer
			else
				AUDIO:ResetActivityTimer()
				actv_manu = true
				HUD:SetItemState('siren', true)
				if AUDIO.manu_button_SFX then AUDIO:Play('Press', AUDIO.upgrade_volume) end
			end
		end
	end,
	onReleased = function()
		if actv_manu then
			actv_manu = false
			HUD:SetItemState('siren', false)
			if AUDIO.manu_button_SFX then AUDIO:Play('Release', AUDIO.upgrade_volume) end
		end
	end
})

--On resource start/restart
CreateThread(function()
	debug_mode = GetResourceMetadata(GetCurrentResourceName(), 'debug_mode', 0) == 'true'
	TriggerEvent('chat:addSuggestion', Lang:t('command.lock_command'), Lang:t('command.lock_desc'))
	SetNuiFocus( false )
	
	UTIL:FixOversizeKeys(SIREN_ASSIGNMENTS)
	RegisterKeyMaps()
	STORAGE:SetBackupTable()
	Wait(200)
	CheckVehicleState(cache.vehicle or GetVehiclePedIsIn(PlayerPedId(), false), cache.seat)
end)

------------REGISTERED VEHICLE EVENTS------------
--Kill siren on Exit
RegisterNetEvent('lvc:onVehicleExit')
AddEventHandler('lvc:onVehicleExit', function()
	if park_kill_masterswitch and park_kill then
		if not tone_main_reset_standby and state_lxsiren[veh] ~= 0 then
			UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
		end
		SetLxSirenStateForVeh(veh, 0)
		SetPowercallStateForVeh(veh, 0)
		SetAirManuStateForVeh(veh, 0)
		HUD:SetItemState('siren', false)
		HUD:SetItemState('horn', false)
		count_bcast_timer = delay_bcast_timer
	end
end)

RegisterNetEvent('lvc:onVehicleChange')
AddEventHandler('lvc:onVehicleChange', function()
	last_veh = veh
	UTIL:UpdateApprovedTones(veh)
	Wait(100)	--waiting for JS event handler
	STORAGE:ResetSettings()
	UTIL:BuildToneOptions()
	STORAGE:LoadSettings()
	HUD:RefreshHudItemStates()
	HUD:SetHudState(true, true)
	SetVehRadioStation(veh, 'OFF')
	Wait(500)
	SetVehRadioStation(veh, 'OFF')
end)

--------------REGISTERED COMMANDS---------------
--Toggle Debug Mode
RegisterCommand(Lang:t('command.debug_command'), function(source, args)
	debug_mode = not debug_mode
	HUD:ShowNotification(Lang:t('info.debug_mode_frontend', {state = debug_mode}), true)
	UTIL:Print(Lang:t('info.debug_mode_console', {state = debug_mode}), true)
	if debug_mode then
		TriggerEvent('lvc:onVehicleChange')
	end
end)

--Toggle LUX lock command
RegisterCommand(Lang:t('command.lock_command'), function(source, args)
	if player_is_emerg_driver then
		key_lock = not key_lock
		AUDIO:Play('Key_Lock', AUDIO.lock_volume, true)
		HUD:SetItemState('lock', key_lock)
		--if HUD is visible do not show notification
		if not HUD:GetHudState() then
			if key_lock then
				HUD:ShowNotification(Lang:t('info.locked'), true)
			else
				HUD:ShowNotification(Lang:t('info.unlocked'), true)
			end
		end
	end
end)

RegisterKeyMapping(Lang:t('command.lock_command'), Lang:t('control.lock_desc'), 'keyboard', lockout_default_hotkey)

------------------------------------------------
-------------------FUNCTIONS--------------------
------------------------------------------------
------------------------------------------------
--Dynamically Run RegisterCommand and KeyMapping functions for all 14 possible sirens
--Then at runtime 'slide' all sirens down removing any restricted sirens.
RegisterKeyMaps = function()
	for i, _ in ipairs(SIRENS) do
		if i ~= 1 then
			local command = '_lvc_siren_' .. i-1
			local description = Lang:t('control.siren_control_desc', {ord_num = MakeOrdinal(i-1)})

			RegisterCommand(command, function(source, args)
				if veh ~= nil and player_is_emerg_driver ~= nil then
					if IsVehicleSirenOn(veh) and player_is_emerg_driver and not key_lock then
						local proposed_tone = UTIL:GetToneAtPos(i)
						local tone_option = UTIL:GetToneOption(proposed_tone)
						if i-1 < #UTIL:GetApprovedTonesTable() then
							if tone_option ~= nil then
								if tone_option == 1 or tone_option == 3 then
									if ( state_lxsiren[veh] ~= proposed_tone or state_lxsiren[veh] == 0 ) then
										HUD:SetItemState('siren', true)
										AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
										SetLxSirenStateForVeh(veh, proposed_tone)
										count_bcast_timer = delay_bcast_timer
									else
										if state_pwrcall[veh] == 0 then
											HUD:SetItemState('siren', false)
										end
										AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
										SetLxSirenStateForVeh(veh, 0)
										count_bcast_timer = delay_bcast_timer
									end
								end
							else
								HUD:ShowNotification(Lang:t('error.reg_keymap_nil_1', {i = i, proposed_tone = proposed_tone, profile_name = UTIL:GetVehicleProfileName()}), true)
								HUD:ShowNotification(Lang:t('error.reg_keymap_nil_2'), true)
							end
						end
					end
				end
			end)

			--CHANGE BELOW if you'd like to change which keys are used for example NUMROW1 through 0
			if i > 0 and i < 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, 'keyboard', i-1)
			elseif i == 11 and main_siren_set_register_keys_set_defaults then
				RegisterKeyMapping(command, description, 'keyboard', '0')
			else
				RegisterKeyMapping(command, description, 'keyboard', '')
			end
		end
	end
end

--Make number into ordinal number, used for FiveM RegisterKeys
MakeOrdinal = function(number)
	local sufixes = { 'th', 'st', 'nd', 'rd', 'th', 'th', 'th', 'th', 'th', 'th' }
	local mod = (number % 100)
	if mod == 11 or mod == 12 or mod == 13 then
		return number .. 'th'
	else
		return number..sufixes[(number % 10) + 1]
	end
end

---------------------------------------------------------------------
---------------------------------------------------------------------
local function CleanupSounds()
	if count_sndclean_timer > delay_sndclean_timer then
		count_sndclean_timer = 0
		for k, v in pairs(state_lxsiren) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_lxsiren[k] ~= nil then
						StopSound(snd_lxsiren[k])
						ReleaseSoundId(snd_lxsiren[k])
						snd_lxsiren[k] = nil
						state_lxsiren[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_pwrcall) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_pwrcall[k] ~= nil then
						StopSound(snd_pwrcall[k])
						ReleaseSoundId(snd_pwrcall[k])
						snd_pwrcall[k] = nil
						state_pwrcall[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_aux2) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_aux2[k] ~= nil then
						StopSound(snd_aux2[k])
						ReleaseSoundId(snd_aux2[k])
						snd_aux2[k] = nil
						state_aux2[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_aux3) do
			if v > 0 then
				if not DoesEntityExist(k) or IsEntityDead(k) then
					if snd_aux3[k] ~= nil then
						StopSound(snd_aux3[k])
						ReleaseSoundId(snd_aux3[k])
						snd_aux3[k] = nil
						state_aux3[k] = nil
					end
				end
			end
		end
		for k, v in pairs(state_airmanu) do
			if v == true then
				if not DoesEntityExist(k) or IsEntityDead(k) or IsVehicleSeatFree(k, -1) then
					if snd_airmanu[k] ~= nil then
						StopSound(snd_airmanu[k])
						ReleaseSoundId(snd_airmanu[k])
						snd_airmanu[k] = nil
						state_airmanu[k] = nil
					end
				end
			end
		end
	else
		count_sndclean_timer = count_sndclean_timer + 1
	end
end
---------------------------------------------------------------------
function TogIndicStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate == ind_state_o then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_l then
			SetVehicleIndicatorLights(veh, 0, false) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		elseif newstate == ind_state_r then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, false) -- L
		elseif newstate == ind_state_h then
			SetVehicleIndicatorLights(veh, 0, true) -- R
			SetVehicleIndicatorLights(veh, 1, true) -- L
		end
		state_indic[veh] = newstate
	end
end

---------------------------------------------------------------------
function TogMuteDfltSrnForVeh(veh, toggle)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		DisableVehicleImpactExplosionActivation(veh, toggle)
	end
end

---------------------------------------------------------------------
function SetLxSirenStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_lxsiren[veh] and newstate ~= nil then
			if snd_lxsiren[veh] ~= nil then
				StopSound(snd_lxsiren[veh])
				ReleaseSoundId(snd_lxsiren[veh])
				snd_lxsiren[veh] = nil
			end
			if newstate ~= 0 then
				snd_lxsiren[veh] = GetSoundId()
				PlaySoundFromEntity(snd_lxsiren[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
				TogMuteDfltSrnForVeh(veh, true)
			end
			state_lxsiren[veh] = newstate
			HUD:RefreshHudItemStates()
		end
	end
end

---------------------------------------------------------------------
function SetPowercallStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_pwrcall[veh] and newstate ~= nil then
			if snd_pwrcall[veh] ~= nil then
				StopSound(snd_pwrcall[veh])
				ReleaseSoundId(snd_pwrcall[veh])
				snd_pwrcall[veh] = nil
			end
			if newstate ~= 0 then
				snd_pwrcall[veh] = GetSoundId()
				PlaySoundFromEntity(snd_pwrcall[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
			end
			state_pwrcall[veh] = newstate
			HUD:RefreshHudItemStates()
		end
	end
end

---------------------------------------------------------------------
function SetAux2StateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_aux2[veh] and newstate ~= nil then
			if snd_aux2[veh] ~= nil then
				StopSound(snd_aux2[veh])
				ReleaseSoundId(snd_aux2[veh])
				snd_aux2[veh] = nil
			end
			if newstate ~= 0 then
				snd_aux2[veh] = GetSoundId()
				PlaySoundFromEntity(snd_aux2[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
			end
			state_aux2[veh] = newstate
			HUD:RefreshHudItemStates()
		end
	end
end

---------------------------------------------------------------------
function SetAux3StateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_aux3[veh] and newstate ~= nil then
			if snd_aux3[veh] ~= nil then
				StopSound(snd_aux3[veh])
				ReleaseSoundId(snd_aux3[veh])
				snd_aux3[veh] = nil
			end
			if newstate ~= 0 then
				snd_aux3[veh] = GetSoundId()
				PlaySoundFromEntity(snd_aux3[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
			end
			state_aux3[veh] = newstate
			HUD:RefreshHudItemStates()
		end
	end
end

---------------------------------------------------------------------
function SetAirManuStateForVeh(veh, newstate)
	if DoesEntityExist(veh) and not IsEntityDead(veh) then
		if newstate ~= state_airmanu[veh] and newstate ~= nil then
			if snd_airmanu[veh] ~= nil then
				StopSound(snd_airmanu[veh])
				ReleaseSoundId(snd_airmanu[veh])
				snd_airmanu[veh] = nil
			end
			if newstate ~= 0 then
				snd_airmanu[veh] = GetSoundId()
				PlaySoundFromEntity(snd_airmanu[veh], SIRENS[newstate].String, veh, SIRENS[newstate].Ref, 0, 0)
			end
			state_airmanu[veh] = newstate
			HUD:RefreshHudItemStates()
		end
	end
end

------------------------------------------------
----------------EVENT HANDLERS------------------
------------------------------------------------
RegisterNetEvent('lvc:TogIndicState_c')
AddEventHandler('lvc:TogIndicState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogIndicStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:TogDfltSrnMuted_c')
AddEventHandler('lvc:TogDfltSrnMuted_c', function(sender)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				TogMuteDfltSrnForVeh(veh, true)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetLxSirenState_c')
AddEventHandler('lvc:SetLxSirenState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetLxSirenStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetPwrcallState_c')
AddEventHandler('lvc:SetPwrcallState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetPowercallStateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetAux2State_c')
AddEventHandler('lvc:SetAux2State_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAux2StateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetAux3State_c')
AddEventHandler('lvc:SetAux3State_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAux3StateForVeh(veh, newstate)
			end
		end
	end
end)

---------------------------------------------------------------------
RegisterNetEvent('lvc:SetAirManuState_c')
AddEventHandler('lvc:SetAirManuState_c', function(sender, newstate)
	local player_s = GetPlayerFromServerId(sender)
	local ped_s = GetPlayerPed(player_s)
	if DoesEntityExist(ped_s) and not IsEntityDead(ped_s) then
		if ped_s ~= GetPlayerPed(-1) then
			if IsPedInAnyVehicle(ped_s, false) then
				local veh = GetVehiclePedIsUsing(ped_s)
				SetAirManuStateForVeh(veh, newstate)
			end
		end
	end
end)


---------------------------------------------------------------------
---------------------------------------------------------------------
CreateThread(function()
	local count_distant_siren_timer = 500
	local is_radio_disabled = false
	while true do
		local sleep = 500
		----- IS IN EMERGENCY VEHICLE -----
		if player_is_emerg_driver and playerped ~= nil and veh ~= nil then
			-- Quando buzina ou sirene manual está segurada, reduz para 0ms para resposta ultra-rápida de áudio
			if actv_horn or actv_manu then
				sleep = 0
				DisableControlAction(0, 80, true) -- INPUT_VEH_CIN_CAM
				DisableControlAction(0, 86, true) -- INPUT_VEH_HORN
			else
				sleep = 150
			end

			-- Throttled distant siren handling
			if count_distant_siren_timer >= 500 then
				count_distant_siren_timer = 0
				DistantCopCarSirens(false)
			else
				count_distant_siren_timer = count_distant_siren_timer + 1
			end

			-- Sound cleanup on demand
			if next(snd_lxsiren) ~= nil or next(snd_pwrcall) ~= nil or next(snd_airmanu) ~= nil then
				CleanupSounds()
			end

			-- Radio Wheel Handling (disables radio once per entry)
			if not is_radio_disabled then
				SetVehicleRadioEnabled(veh, false)
				is_radio_disabled = true
			end

			lights_on = IsVehicleSirenOn(veh)

			if not IsEntityDead(veh) then
				--- SET INIT TABLE VALUES ---
				if state_lxsiren[veh] == nil then state_lxsiren[veh] = 0 end
				if state_pwrcall[veh] == nil then state_pwrcall[veh] = 0 end
				if state_airmanu[veh] == nil then state_airmanu[veh] = 0 end

				--- IF LIGHTS ARE OFF TURN OFF SIREN ---
				if not lights_on and state_lxsiren[veh] > 0 then
					if not tone_main_reset_standby then
						UTIL:SetToneByID('MAIN_MEM', state_lxsiren[veh])
					end
					SetLxSirenStateForVeh(veh, 0)
					count_bcast_timer = delay_bcast_timer
				end
				if not lights_on and state_pwrcall[veh] > 0 then
					SetPowercallStateForVeh(veh, 0)
					count_bcast_timer = delay_bcast_timer
				end

				---- ADJUST HORN / MANU STATE ----
				local hmanu_state_new = 0
				if actv_horn == true and actv_manu == false then
					hmanu_state_new = UTIL:GetToneID('ARHRN')
				elseif actv_horn == false and actv_manu == true then
					hmanu_state_new = UTIL:GetToneID('PMANU')
				elseif actv_horn == true and actv_manu == true then
					hmanu_state_new = UTIL:GetToneID('SMANU')
				end
				if tone_airhorn_intrp then
					if hmanu_state_new == UTIL:GetToneID('ARHRN') then
						if state_lxsiren[veh] > 0 and actv_lxsrnmute_temp == false then
							srntone_temp = state_lxsiren[veh]
							SetLxSirenStateForVeh(veh, 0)
							actv_lxsrnmute_temp = true
						end
					else
						if actv_lxsrnmute_temp == true then
							SetLxSirenStateForVeh(veh, srntone_temp)
							actv_lxsrnmute_temp = false
						end
					end
				end

				if state_airmanu[veh] ~= hmanu_state_new then
					SetAirManuStateForVeh(veh, hmanu_state_new)
					count_bcast_timer = delay_bcast_timer
				end
			end

			----- AUTO BROADCAST VEH STATES -----
			if count_bcast_timer >= delay_bcast_timer then
				count_bcast_timer = 0
				TriggerServerEvent('lvc:TogDfltSrnMuted_s')
				TriggerServerEvent('lvc:SetLxSirenState_s', state_lxsiren[veh])
				TriggerServerEvent('lvc:SetPwrcallState_s', state_pwrcall[veh])
				TriggerServerEvent('lvc:SetAux2State_s', state_aux2[veh] or 0)
				TriggerServerEvent('lvc:SetAux3State_s', state_aux3[veh] or 0)
				TriggerServerEvent('lvc:SetAirManuState_s', state_airmanu[veh])
			else
				count_bcast_timer = count_bcast_timer + 1
			end
		else
			is_radio_disabled = false
		end

		Wait(sleep)
	end
end)