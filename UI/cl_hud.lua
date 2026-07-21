--[[
---------------------------------------------------
LUXART VEHICLE CONTROL V3 (FOR FIVEM)
---------------------------------------------------
Coded by Lt.Caine
ELS Clicks by Faction
Additional Modification by TrevorBarns
---------------------------------------------------
FILE: cl_hud.lua
PURPOSE: All HUD functions, callbacks, and GTA V 
		 front-end functions.
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
HUD = { }

local show_HUD = hud_first_default
local HUD_temp_hidden = true
local HUD_scale
local HUD_pos 
local HUD_backlight_mode = 1 
local HUD_backlight_state = false

---------------------------------------------------------------------
--[[Gets initial HUD scale from JS]]
CreateThread(function()
	Wait(500)
	SendNUIMessage({
	  _type = 'hud:getHudScale',
	})
end)

---------------------------------------------------------------------
--[[Handles HUD backlight and visibility control.]]
CreateThread(function()
	while true do
		local sleep = 1000
		if player_is_emerg_driver then
			sleep = 500
			-- Backlight control
			if HUD:GetHudBacklightMode() == 1 and veh ~= nil then
				local _, veh_lights, veh_headlights  = GetVehicleLightsState(veh)
				if (veh_lights == 1 or veh_headlights == 1) and not HUD:GetHudBacklightState() then
					HUD:SetHudBacklightState(true)
				elseif (veh_lights == 0 and veh_headlights == 0) and HUD:GetHudBacklightState() then
					HUD:SetHudBacklightState(false)
				end
			end
		end

		-- Visibility control
		if show_HUD or HUD_temp_hidden then
			if (not player_is_emerg_driver) or (IsHudHidden() == 1) or (IsPauseMenuActive() == 1) then
				if not HUD_temp_hidden then
					HUD:SetHudState(false, true)
					HUD_temp_hidden = true
				end
			elseif player_is_emerg_driver and (IsHudHidden() ~= 1) and (IsPauseMenuActive() ~= 1) and HUD_temp_hidden then
				HUD:SetHudState(true, true)
				HUD_temp_hidden = false
			end
		end
		Wait(sleep)
	end
end)

------------------------------------------------
--[[Getter for HUD State (whether hud is enabled).]]
function HUD:GetHudState()
	return show_HUD
end

--[[Setter for HUD State temp changes the state temporarily for pausing/hud hiding.]]
function HUD:SetHudState(state, temporary)
	local temporary = temporary or false
	if not temporary then
		show_HUD = state
	end
	HUD:SetItemState('hud', state)
end

------------------------------------------------
--[[Getter for HUD scale. Updates local save from JS and returns.]]
function HUD:GetHudScale()
	SendNUIMessage({
	  _type = 'hud:getHudScale'
	})
	return HUD_scale or 0.6
end

--[[Setter for HUD scale. Updates JS & CSS.]]
function HUD:SetHudScale(scale)
	if scale ~= nil then
		SendNUIMessage({
		  _type = 'hud:setHudScale',
		  scale = scale,
		})
	end
end

--[[Callback for JS -> LUA to set HUD_scale with current CSS]]
RegisterNUICallback('hud:sendHudScale', function(data, cb)
	if type(data) == 'table' and data.scale then
		HUD_scale = data.scale
	else
		HUD_scale = data
	end
	if cb then cb('ok') end
end )

------------------------------------------------
--[[Toggles HUD images based on their state on/off]]
function HUD:SetItemState(item, state)
	SendNUIMessage({
	  _type = 'hud:setItemState',
	  item  = item,
	  state = state
	})
end

------------------------------------------------
--[[HUD Backlight Modes: 1 - auto, 2 - off, 3 - on]]
function HUD:GetHudBacklightMode()
	return HUD_backlight_mode
end

function HUD:SetHudBacklightMode(mode)
	if mode ~= nil then
		HUD_backlight_mode = mode
		
		if mode == 2 then
			HUD:SetHudBacklightState(false)
		elseif mode == 3 then
			HUD:SetHudBacklightState(true)	
		end
	end
end

function HUD:GetHudBacklightState()
	return HUD_backlight_state
end

function HUD:SetHudBacklightState(state)
	if state ~= nil then
		HUD_backlight_state = state
		if state then
			HUD:SetItemState('time', 'night')
		else
			HUD:SetItemState('time', 'day')
		end
		
		HUD:RefreshHudItemStates()
	end
end

------------------------------------------------
--[[Verifies HUD item states are correct]]
function HUD:RefreshHudItemStates()
	if state_lxsiren[veh] ~= nil and state_lxsiren[veh] > 0 then
		HUD:SetItemState('siren', state_lxsiren[veh])
	elseif actv_lxsrnmute_temp then
		HUD:SetItemState('siren', true)
	else
		HUD:SetItemState('siren', false)
	end
	
	if state_pwrcall[veh] ~= nil and state_pwrcall[veh] > 0 then
		HUD:SetItemState('aux1', true)
	else
		HUD:SetItemState('aux1', false)
	end

	if state_aux2 ~= nil and state_aux2[veh] ~= nil and state_aux2[veh] > 0 then
		HUD:SetItemState('aux2', true)
	else
		HUD:SetItemState('aux2', false)
	end

	if (state_aux3 ~= nil and state_aux3[veh] ~= nil and state_aux3[veh] > 0) or (state_tkd ~= nil and state_tkd[veh]) then
		HUD:SetItemState('aux3', true)
	else
		HUD:SetItemState('aux3', false)
	end

	if state_pursuit ~= nil and state_pursuit[veh] then
		HUD:SetItemState('pursuit', true)
	else
		HUD:SetItemState('pursuit', false)
	end
	
	if (state_airmanu[veh] ~= nil and state_airmanu[veh] > 0) or actv_horn then
		HUD:SetItemState('horn', true)
	else
		HUD:SetItemState('horn', false)
	end

	if actv_manu then
		HUD:SetItemState('man', true)
	else
		HUD:SetItemState('man', false)
	end
	
	if key_lock then
		HUD:SetItemState('lock', true)
	else
		HUD:SetItemState('lock', false)
	end
	
	if state_ta ~= nil and state_ta[veh] ~= nil then
		HUD:SetItemState('ta', state_ta[veh])
	else
		HUD:SetItemState('ta', 0)
	end	
	
	HUD:SetItemState('switch', IsVehicleSirenOn(veh))
end

------------------------------------------------
--[[Setter for HUD position, used when loading save data.]]
function HUD:SetHudPosition(data)
	HUD_pos = data
	SendNUIMessage({
	  _type = 'hud:setHudPosition',
	  pos = HUD_pos,
	})	
end

--[[Getter for HUD position, used when saving data.]]
function HUD:GetHudPosition()
	return HUD_pos
end

--[[Sets HUD position based off backup stored in JS, in case HUD is off screen.]]
function HUD:ResetPosition()
	SendNUIMessage({
	  _type = 'hud:resetPosition',
	})
end

--[[Callback for JS -> LUA to set HUD_pos with current position to save.]]
RegisterNUICallback( 'hud:setHudPositon', function(data, cb)
	HUD_pos = data
	STORAGE:SaveHUDSettings()
	if cb then cb('ok') end
end )

------------------------------------------------
--[[Sets NUI focus for move mode.]]
function HUD:SetMoveMode(state)
	SetNuiFocus( state, state )
end

--[[Sets NUI focus to false when right-click, esc, etc. are clicked.]]
RegisterNUICallback( 'hud:setMoveState', function(state, cb)
	SetNuiFocus(state, state)
	if cb then cb('ok') end
end )

------------------------------------------------
--[[Modo Pursuit (Perseguição)]]
function HUD:TogglePursuitMode()
	if player_is_emerg_driver and veh ~= nil and not key_lock then
		if state_pursuit == nil then state_pursuit = {} end
		local cur = state_pursuit[veh] or false
		state_pursuit[veh] = not cur

		if state_pursuit[veh] then
			SetVehicleSiren(veh, true)
			local tone = UTIL:GetToneAtPos(2) or 2
			SetLxSirenStateForVeh(veh, tone)
			if state_tkd ~= nil then state_tkd[veh] = true end
			AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
		else
			SetLxSirenStateForVeh(veh, 0)
			if state_tkd ~= nil then state_tkd[veh] = false end
			AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
		end
		HUD:RefreshHudItemStates()
	end
end

------------------------------------------------
--[[NUI Callbacks para Interações com o Painel Rontan]]
RegisterNUICallback('hud:toggleMaster', function(data, cb)
	if player_is_emerg_driver and veh ~= nil and not key_lock then
		local state = data.state
		SetVehicleSiren(veh, state)
		if trailer ~= nil and trailer ~= 0 then
			SetVehicleSiren(trailer, state)
		end
		if state then
			AUDIO:Play('On', AUDIO.on_volume)
		else
			AUDIO:Play('Off', AUDIO.off_volume)
			SetLxSirenStateForVeh(veh, 0)
			SetPowercallStateForVeh(veh, 0)
			if SetAux2StateForVeh then SetAux2StateForVeh(veh, 0) end
			if SetAux3StateForVeh then SetAux3StateForVeh(veh, 0) end
			if state_pursuit then state_pursuit[veh] = false end
		end
		HUD:RefreshHudItemStates()
	end
	cb('ok')
end)

RegisterNUICallback('hud:clickButton', function(data, cb)
	if player_is_emerg_driver and veh ~= nil and not key_lock then
		local btn = data.button
		if btn == 'wail' then
			local tone = UTIL:GetToneAtPos(2)
			if state_lxsiren[veh] == tone then
				SetLxSirenStateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			else
				if not IsVehicleSirenOn(veh) then SetVehicleSiren(veh, true) end
				SetLxSirenStateForVeh(veh, tone)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			end
		elseif btn == 'yelp' then
			local tone = UTIL:GetToneAtPos(3)
			if state_lxsiren[veh] == tone then
				SetLxSirenStateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			else
				if not IsVehicleSirenOn(veh) then SetVehicleSiren(veh, true) end
				SetLxSirenStateForVeh(veh, tone)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			end
		elseif btn == 'hilo' then
			local tone = UTIL:GetToneAtPos(4)
			if state_lxsiren[veh] == tone then
				SetLxSirenStateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			else
				if not IsVehicleSirenOn(veh) then SetVehicleSiren(veh, true) end
				SetLxSirenStateForVeh(veh, tone)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			end
		elseif btn == 'pierce' then
			local tone = UTIL:GetToneAtPos(5) or UTIL:GetToneAtPos(4)
			if state_lxsiren[veh] == tone then
				SetLxSirenStateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			else
				if not IsVehicleSirenOn(veh) then SetVehicleSiren(veh, true) end
				SetLxSirenStateForVeh(veh, tone)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			end
		elseif btn == 'off' then
			SetLxSirenStateForVeh(veh, 0)
			SetPowercallStateForVeh(veh, 0)
			if SetAux2StateForVeh then SetAux2StateForVeh(veh, 0) end
			if SetAux3StateForVeh then SetAux3StateForVeh(veh, 0) end
			if state_pursuit then state_pursuit[veh] = false end
			SetVehicleSiren(veh, false)
			AUDIO:Play('Off', AUDIO.off_volume)
		elseif btn == 'neutro' then
			SetLxSirenStateForVeh(veh, 0)
			SetPowercallStateForVeh(veh, 0)
			if SetAux2StateForVeh then SetAux2StateForVeh(veh, 0) end
			if SetAux3StateForVeh then SetAux3StateForVeh(veh, 0) end
			if state_pursuit then state_pursuit[veh] = false end
			AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
		elseif btn == 'aux1' then
			if state_pwrcall[veh] == 0 then
				SetPowercallStateForVeh(veh, UTIL:GetToneID('AUX') or 11)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			else
				SetPowercallStateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			end
		elseif btn == 'aux2' then
			if (state_aux2[veh] or 0) == 0 then
				local tone = UTIL:GetToneAtPos(3) or 3
				SetAux2StateForVeh(veh, tone)
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			else
				SetAux2StateForVeh(veh, 0)
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			end
		elseif btn == 'aux3' then
			if (state_aux3[veh] or 0) == 0 then
				local tone = UTIL:GetToneAtPos(4) or 4
				SetAux3StateForVeh(veh, tone)
				if state_tkd ~= nil then state_tkd[veh] = true end
				AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
			else
				SetAux3StateForVeh(veh, 0)
				if state_tkd ~= nil then state_tkd[veh] = false end
				AUDIO:Play('Downgrade', AUDIO.downgrade_volume)
			end
		elseif btn == 'pursuit' then
			HUD:TogglePursuitMode()
		elseif btn == 'emerg' then
			SetVehicleSiren(veh, true)
			local tone = UTIL:GetToneAtPos(4) or 4
			SetLxSirenStateForVeh(veh, tone)
			AUDIO:Play('Upgrade', AUDIO.upgrade_volume)
		elseif btn == 'light' then
			local cur_siren = IsVehicleSirenOn(veh)
			SetVehicleSiren(veh, not cur_siren)
			if cur_siren then
				AUDIO:Play('Off', AUDIO.off_volume)
			else
				AUDIO:Play('On', AUDIO.on_volume)
			end
		elseif btn == 'barsup' then
			AUDIO.on_volume = math.min(1.0, (AUDIO.on_volume or 0.5) + 0.1)
			AUDIO:Play('Press', AUDIO.on_volume)
		elseif btn == 'barsdown' then
			AUDIO.on_volume = math.max(0.0, (AUDIO.on_volume or 0.5) - 0.1)
			AUDIO:Play('Press', AUDIO.on_volume)
		end
		HUD:RefreshHudItemStates()
	end
	cb('ok')
end)

RegisterNUICallback('hud:pressButton', function(data, cb)
	if player_is_emerg_driver and veh ~= nil and not key_lock then
		local btn = data.button
		if btn == 'horn' then
			actv_horn = true
			HUD:SetItemState('horn', true)
		elseif btn == 'man' then
			actv_manu = true
			HUD:SetItemState('man', true)
		end
	end
	cb('ok')
end)

RegisterNUICallback('hud:releaseButton', function(data, cb)
	if player_is_emerg_driver and veh ~= nil and not key_lock then
		local btn = data.button
		if btn == 'horn' then
			actv_horn = false
			HUD:SetItemState('horn', false)
		elseif btn == 'man' then
			actv_manu = false
			HUD:SetItemState('man', false)
		end
	end
	cb('ok')
end)

------------------------------------------------
--On screen GTA V notification
function HUD:ShowNotification(text, override)
	override = override or false
	if debug_mode or override then
		SetNotificationTextEntry('STRING')
		AddTextComponentString(text)
		DrawNotification(false, true)
	end
end

------------------------------------------------
--Drawn On Screen Text at X, Y
function HUD:ShowText(x, y, align, text, scale, label)
	scale = scale or 0.4
	SetTextJustification(align)
	SetTextFont(0)
	SetTextProportional(1)
	SetTextScale(0.0, scale)
	SetTextColour(128, 128, 128, 255)
	SetTextDropshadow(0, 0, 0, 0, 255)
	SetTextEdge(1, 0, 0, 0, 255)
	SetTextDropShadow()
	SetTextOutline()
	if text ~= nil then
		SetTextEntry('STRING')
		AddTextComponentString(text)
	else
		SetTextEntry(label)
	end
	DrawText(x, y)
	ResetScriptGfxAlign()
end

------------------------------------------------
--Full screen Confirmation Message
function HUD:FrontEndAlert(title, subtitle, options)
	AddTextEntry('FACES_WARNH2', title)
	AddTextEntry('QM_NO_0', subtitle)
	local result = -1
	while result == -1 do
		DrawFrontendAlert('FACES_WARNH2', 'QM_NO_0', 0, 0, '', 0, -1, 0, '', '', false, 0)
		HUD:ShowText(0.5, 0.75, 0, options, 0.75)
		if IsDisabledControlJustReleased(2, 202) then
			return false
		end		
		if IsDisabledControlJustReleased(2, 201) then
			return true
		end
		Wait(0)
	end
end

------------------------------------------------
--Get User Input from Keyboard
function HUD:KeyboardInput(input_title, existing_text, max_length)
	AddTextEntry('custom_keyboard_title', input_title)
	DisplayOnscreenKeyboard(1, 'custom_keyboard_title', '', existing_text, '', '', '', max_length) 

	while UpdateOnscreenKeyboard() ~= 1 and UpdateOnscreenKeyboard() ~= 2 do
		Wait(0)
	end
		
	if UpdateOnscreenKeyboard() ~= 2 then
		local result = GetOnscreenKeyboardResult() 
		Wait(500) 
		if result ~= '' then
			return result 
		else 
			return nil
		end
	else
		Wait(500)
		return nil 
	end
end