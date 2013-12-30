if SERVER then
	AddCSLuaFile()
	resource.AddSingleFile( "resource/fonts/Aero_Matics_Display.ttf" )
	resource.AddSingleFile( "materials/paydayhud/paydayhud_health.png" )
	resource.AddSingleFile( "materials/paydayhud/paydayhud_health_small.png" )
	resource.AddSingleFile( "materials/paydayhud/paydayhud_armor.png" )
	resource.AddSingleFile( "materials/paydayhud/paydayhud_armor_small.png" )

	for _, v in pairs( player.GetAll() ) do
	 if ( v:Armor() == 0 ) then
	 v:SetArmor( 100 )
	 end
	end

else
	-- Removing the default HUD
	local hud = {"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo", "CHudCrosshair", "CHudVoiceStatus"}
	function HideHUD(name)
		for k, v in pairs(hud)do
			if name == v then return false end
		end
	end
	hook.Add("HUDShouldDraw", "HideHUD", HideHUD)

	FC_HUD = {}

	------------------
	-- CONFIG START --
	------------------

	FC_HUD.TeamBasedHP = false
	FC_HUD.DefaultTargetInfo = false
	FC_HUD.LargerStatus = false
	FC_HUD.ColoredRoleBack = false
	FC_HUD.ColoredRoleText = false
	FC_HUD.ShowOnlyHP = false

	------------------
	-- CONFIG START --
	------------------

	surface.CreateFont( "FC_HUD_10", { font = "Aero Matics Display Regular", antialias = true, size = 10 } )
	surface.CreateFont( "FC_HUD_20", { font = "Aero Matics Display Regular", antialias = true, size = 20 } )
	surface.CreateFont( "FC_HUD_30", { font = "Aero Matics Display Regular", antialias = true, size = 30 } )
	surface.CreateFont( "FC_HUD_40", { font = "Aero Matics Display Regular", antialias = true, size = 40 } )

	FC_HUD.White = Material("vgui/white")
	FC_HUD.SmallHP = Material("paydayhud/paydayhud_health_small.png")
	FC_HUD.BigHP = Material("paydayhud/paydayhud_health.png")
	FC_HUD.SmallAR = Material("paydayhud/paydayhud_armor_small.png")
	FC_HUD.BigAR = Material("paydayhud/paydayhud_armor.png")

	FC_HUD.LastHP = nil
	FC_HUD.HPFallout = {}

	local insert = table.insert

	local function clamp(v) if (v > 1) then return 1 else return v end end

	local function NiceUV(x, y, w, h, perc, flipped)

		if flipped then

			if (prec == 0) then return {} end

			local tbl = {} -- our pizza
			insert(tbl, {x = x, y = y, u = 0.5, v = 0.5})

			if (perc >= 315) then
				insert(tbl, {x = x + w - clamp((perc - 315) / 45) * w, y = y - h, u = 1 - clamp((perc - 315) / 45) / 2, v = 0})
			end

			if (perc >= 225) then
				insert(tbl, {x = x + w, y = y + h - clamp((perc - 225) / 90) * h * 2, u = 1, v = 1 - clamp((perc - 225) / 90)})
			end

			if (perc >= 135) then
				insert(tbl, {x = x - w + clamp((perc - 135) / 90) * h * 2, y = y + h, u = clamp((perc - 135) / 90), v = 1})
			end

			if (perc >= 45) then
				insert(tbl, {x = x - w, y = y - h + clamp((perc - 45) / 90) * h * 2, u = 0, v = clamp((perc - 45) / 90)})
			end

			insert(tbl, {x = x - clamp(perc / 45) * w, y = y - h, u = 0.5 - clamp(perc / 45) / 2, v = 0})
			insert(tbl, {x = x, y = y - h, u = 0.5, v = 0})

			return tbl

		else

			local tbl = {}
			insert(tbl, {x = x, y = y, u = 0.5, v = 0.5})
			insert(tbl, {x = x, y = y - h, u = 0.5, v = 0})

			if (perc > 45) then insert(tbl, {x = x + w, y = y - h, u = 1, v = 0})
			else				insert(tbl, {x = x + perc / 45 * w, y = y - h, u = 0.5 + clamp(perc / 45) / 2, v = 0}) return tbl
			end

			perc = perc - 45
			if (perc > 90) then
				insert(tbl, {x = x + w, y = y + h, u = 1, v = 1})
			else
				insert(tbl, {x = x + w, y = y - h + perc / 90 * h * 2, u = 1, v = clamp(perc / 90)}) return tbl
			end

			perc = perc - 90
			if (perc > 90) then
				insert(tbl, {x = x - w, y = y + h, u = 0, v = 1})
			else
				insert(tbl, {x = x + w - perc / 90 * h * 2, y = y + h, u = 1 - clamp(perc / 90), v = 1}) return tbl
			end

			perc = perc - 90
			if (perc > 90) then
				insert(tbl, {x = x - w, y = y - h, u = 0, v = 0})
			else
				insert(tbl, {x = x - w, y = y + h - perc / 90 * h * 2, u = 0, v = 1 - clamp(perc / 90)}) return tbl
			end

			perc = perc - 90
			insert(tbl, {x = x - w + perc / 45 * w, y = y - h, u = clamp(perc / 45) / 2, v = 0})

			return tbl
		end
	end

	function CreateBorderedCircle(x, y, size, border, perc, addrot, parts)

		local sin = math.sin
		local cos = math.cos
		local rad = math.rad

		local parts = parts or 100

		local tbl = {}
		local onerad = rad(360) / parts
		local fixpos = rad(90)
		local ret = false
		local ending = perc * 3.6 * (parts / 360)
		local innersize = size - border
		local i = 0

		if (addrot != nil) then
			fixpos = fixpos + rad(addrot)
		end

		while(true) do
			if (not ret) then
				table.insert(tbl, {
					x = x - cos(i * onerad - fixpos) * innersize,
					y = y + sin(i * onerad - fixpos) * innersize
				})

				i = i + 1

				if (i > ending) then
					ret = true
					i = i - 1
				end
			else
				table.insert(tbl, {
					x = x - cos(i * onerad - fixpos) * size,
					y = y + sin(i * onerad - fixpos) * size
				})

				i = i - 1

				if (i < 0) then
					table.insert(tbl, {
						x = x + cos(fixpos) * size,
						y = y + sin(fixpos) * size
					})

					break
				end
			end
		end

		return tbl
	end

	function DrawCorrectFuckingPoly(tbl, fade)
		local len = #tbl

		for i = 1, #tbl do

			if fade and (i < 5 or i >= (len-5)) then
				local col = i / 5

				if i > len/2 then
					col = (len-i-1) / 5
				end

				surface.SetDrawColor( 175 * col, 225 * col, 100 * col, 200 * col )
			elseif fade then
				surface.SetDrawColor( 175, 225, 100, 200 )
			end

			surface.DrawPoly({tbl[i], tbl[len - (i - 1)], tbl[len - i]})
			surface.DrawPoly({tbl[i], tbl[i + 1], tbl[len - i]})
		end
	end

	local function GetAmmo()
		local ply = LocalPlayer()
		local weap = ply:GetActiveWeapon()
   	if not weap or not ply:Alive() then return -1 end

		local ammo_inv = weap:Ammo1() or 0
		local ammo_clip = weap:Clip1() or 0
		local ammo_max = weap.Primary.ClipSize or 0
		local ammo_invmax = weap.Primary.ClipMax or 0

		return ammo_clip, ammo_max, ammo_inv, ammo_invmax
	end

	---- Crosshair
	surface.CreateFont("TargetIDSmall2", {font = "TargetID", size = 16, weight = 1000})

	local magnifier_mat = Material("icon16/magnifier.png")
	local ring_tex = surface.GetTextureID("effects/select_ring")
	local rag_color = Color(200,200,200,255)

	local delay = 0.075
	local showtime = 3
	local client = LocalPlayer()

	local margin = 10
	local width = 350
	local height = 22

	local barcorner = surface.GetTextureID( "gui/corner8" )
	local round = math.Round

	function GetAmmoForCurrentWeapon()
	  local ply = LocalPlayer()
	  local wep = ply:GetActiveWeapon()
	  if ( not wep ) then return 0,0,0,0 end
	  if ( not IsValid(ply:GetActiveWeapon())) then return 0,0,0,0 end

	  local ammo_inv    = ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) or 0
		local ammo_clip   = wep:Clip1() or 0
		local ammo_max    = ply:GetAmmoCount( wep:GetPrimaryAmmoType() ) or 0
		local ammo_invmax = ply:GetAmmoCount( wep:GetSecondaryAmmoType()) or 0

	  return ammo_clip, ammo_max, ammo_inv, ammo_invmax
	end

	hook.Add("HUDPaint", "FC_HUD", function()

		GAMEMODE.HUDPaint = function()

			local addw, addh = 0, 0
			local x = ScrW()
			local y = ScrH()

		  local trace = LocalPlayer():GetEyeTrace(MASK_SHOT)
			local ent = trace.Entity

			if LocalPlayer():Alive() and LocalPlayer():Team() != TEAM_SPECTATOR then

				local clip, max, inv, invmax = GetAmmoForCurrentWeapon()

				if clip != -1 then
					draw.RoundedBoxEx(2, x - 205, y - 115, 120, 30, Color(0,0,0,125), false, true, false, true)

					local col1, col2 = Color(255,255,255,200), Color(255,255,255,200)

					if clip == 0 then
						col1 = Color(200,20,20,200)
					elseif clip/max <= 0.25 then
						col1 = Color(200,200,20,200)
					end

					if inv == 0 then
						col2 = Color(200,20,20,200)
					elseif inv/invmax <= 0.25 then
						col2 = Color(200,200,20,200)
					end

					if clip < 10 then
						clip = "0"..clip
					end

					if inv < 10 then
						inv = "0"..inv
					end

					draw.SimpleText("+", "FC_HUD_30", x - 155, y - 100, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
					draw.SimpleText(clip, "FC_HUD_30", x - 155 - 8, y - 100, col1, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
					draw.SimpleText(inv, "FC_HUD_30", x - 155 + 10, y - 100, col2, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
					surface.SetMaterial( FC_HUD.White )

				end
			end

			--Player Name Circle and Name
			local tab = CreateBorderedCircle(x - 275, y - 130, 12, 12, 100, 0, 10)
			surface.SetDrawColor( 0, 0, 0, 125 )
			surface.SetMaterial( FC_HUD.White )
			DrawCorrectFuckingPoly(tab)

			local tab = CreateBorderedCircle(x - 275, y - 130, 8, 8, 100, 0, 10)
			surface.SetDrawColor(  team.GetColor(1) )
			surface.SetMaterial( FC_HUD.White )
			DrawCorrectFuckingPoly(tab)

			draw.RoundedBoxEx(2, x - 260, y - 140, 150, 20, Color(0,0,0,125), false, true, false, true)
			draw.SimpleText(LocalPlayer():Nick(), "FC_HUD_20", x - 185, y - 132, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			--HEALTH Cricle
			if LocalPlayer():Alive() then
				--Fake grey behind
				local parts = NiceUV(x - 250, y - 67, 64, 64, 360, 0, 100 / 100 * 360, true )
				surface.SetMaterial( FC_HUD.BigHP )
				surface.SetDrawColor( 0, 0, 0, 125 )
				surface.DrawPoly(parts)
				local parts = NiceUV(x - 250, y - 67, 64, 64, math.Clamp(LocalPlayer():Health(), 0, 100) / 100 * 360, true )
				surface.SetMaterial( FC_HUD.BigHP )
				surface.SetDrawColor( 160, 217, 104, 245 )
				surface.DrawPoly(parts)
			end

			--ARMOUR Circle
			if LocalPlayer():Alive() && LocalPlayer():Armor() > 0 then
				--Fake grey behind
				local parts = NiceUV(x - 250, y - 67, 74, 74, 360, 0, 100 / 100 * 360, true )
				surface.SetMaterial( FC_HUD.BigAR )
				surface.SetDrawColor( 0, 0, 0, 125 )
				surface.DrawPoly(parts)
				local parts = NiceUV(x - 250, y - 67, 74, 74, math.Clamp(LocalPlayer():Armor(), 0, 100) / 100 * 360, true )
				surface.SetMaterial( FC_HUD.BigAR )
				surface.SetDrawColor(255, 255, 255, 200)
				surface.DrawPoly(parts)
			end

			--Health Text inside circle
			-- draw.SimpleText(LocalPlayer():Health(), "FC_HUD_40", x - 250, y - 67, Color(255,255,255,200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

			--test
			local visible_entity = LocalPlayer():GetEyeTrace().Entity
			local distance_from_object = 85
			local player_to_entity_distance = LocalPlayer():GetPos():Distance(visible_entity:GetPos())

			if ( input.IsKeyDown( KEY_F ) || input.IsKeyDown( KEY_E ) ) and ( visible_entity:GetClass() == 'payday_duffle_bag') and ( player_to_entity_distance < distance_from_object) then
				local parts = NiceUV((ScrW())/2, ScrH()/2, 128, 128, 360, 0, 100 / 100 * 360, true )
				surface.SetMaterial( FC_HUD.BigHP )
				surface.SetDrawColor(255, 255, 255, 25)
				surface.DrawPoly(parts)
			end
			--

		end

	end)
end