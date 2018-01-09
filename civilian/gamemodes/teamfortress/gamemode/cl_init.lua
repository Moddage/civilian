
local LOGFILE = "teamfortress/log_client.txt"
file.Delete(LOGFILE)
file.Append(LOGFILE, "Loading clientside script\n")
local load_time = SysTime()

include("tf_lang_module.lua") 
tf_lang.Load("tf_english.txt")

include("cl_proxies.lua")

include("shared.lua")
include("cl_entclientinit.lua")
include("cl_deathnotice.lua")
include("cl_scheme.lua")

include("cl_camera.lua")

include("tf_draw_module.lua")

include("cl_materialfix.lua")

CreateClientConVar( "tf_haltinspect", "1", FCVAR_CLIENTCMD_CAN_EXECUTE, "Whether or not players can inspect while no-clipping." )
CreateClientConVar( "cl_secret_femalescout", "0", FCVAR_CLIENTCMD_CAN_EXECUTE, "" )
function GM:ShouldDrawWorldModel(pl)
	return true
end

--[[
timer.Create("lol",0.2,0,function() m=T:GetBoneMatrix(T:LookupBone("bip_head")) m:Translate(Vector(0,-5,0)) local e=EffectData() e:SetOrigin(m:GetTranslation()) e:SetAngles(Angle(180,0,0)) util.Effect("BloodImpact",e) end)

LocalPlayer().BuildBonePositions=function(pl) local m = pl:GetBoneMatrix(pl:LookupBone("bip_neck")) m:Scale(Vector(0,0,0)) m:Translate(Vector(0,0,0)) pl:SetBoneMatrix(pl:LookupBone("bip_neck"),m) end

TBB=function() local m=P:GetBoneMatrix(P:LookupBone("bip_spine_3")) m:Rotate(Angle(-10,0,-20)) m:Translate(Vector(0,-8,-3.5)) T:SetBoneMatrix(T:LookupBone("bip_head"),m) end

]]

--include("vgui/vgui_teammenubg.lua")

--[[
tf_util.AddDebugInfo("move_x", function()
	return "forward : "..tostring(LocalPlayer():GetNWFloat("MoveForward"))
end)

tf_util.AddDebugInfo("move_y", function()
	return "side : "..tostring(LocalPlayer():GetNWFloat("MoveSide"))
end)

tf_util.AddDebugInfo("move_z", function()
	return "up : "..tostring(LocalPlayer():GetNWFloat("MoveUp"))
end)]]

hook.Add("RenderScreenspaceEffects", "RenderPlayerStateOverlay", function()
	if IsValid(LocalPlayer()) then
		LocalPlayer():DrawStateOverlay()
	end
end)

concommand.Add("muzzlepos", function(pl)
	local att = pl:GetViewModel():GetAttachment(pl:GetViewModel():LookupAttachment("muzzle"))
	if not att then return end
	
	print(att.Pos - pl:GetShootPos())
end)

function GM:PlayerBindPress(pl, bind)
	local w = pl:GetActiveWeapon()
	if w and w:IsValid() and w:GetNWBool("SlotInputEnabled") then
		local num = tonumber(string.match(bind, "^slot(%d)") or "")
		if num then
			pl:ConCommand("select_slot "..num)
			return true
		end
	end
end

function GetPlayerByUserID(id)
	for _,v in pairs(player.GetAll()) do
		if v:UserID()==id then
			return v
		end
	end
	return NULL
end

-- Spawn player gibs
usermessage.Hook("GibPlayer", function(um)
	local pl = GetPlayerByUserID(um:ReadLong())
	if not IsValid(pl) then return end
	
	pl.DeathFlags = um:ReadShort()
	
	local effectdata = EffectData()
		effectdata:SetEntity(pl)
	util.Effect("tf_player_gibbed", effectdata)
end)

usermessage.Hook("GibNPC", function(um)
	local npc = um:ReadEntity()
	if not IsValid(npc) then return end
	
	npc.DeathFlags = um:ReadShort()
	
	local effectdata = EffectData()
		effectdata:SetEntity(npc)
	util.Effect("tf_player_gibbed", effectdata)
end)

usermessage.Hook("SilenceNPC", function(um)
	local npc = um:ReadEntity()
	if not IsValid(npc) then return end
	
	timer.Simple(0, function() npc:EmitSound("AI_BaseNPC.SentenceStop") end)
	timer.Simple(0.1, function() npc:EmitSound("AI_BaseNPC.SentenceStop") end)
end)

-- Critical hit notifications
usermessage.Hook("CriticalHit", function(um)
	local pos = um:ReadVector()
	LocalPlayer():EmitSound("TFPlayer.CritHit")
	ParticleEffect("crit_text", pos, Angle(0,0,0))
end)

usermessage.Hook("CriticalHitMini", function(um)
	local pos = um:ReadVector()
	LocalPlayer():EmitSound("TFPlayer.CritHit")
	ParticleEffect("minicrit_text", pos, Angle(0,0,0))
end)

usermessage.Hook("CriticalHitMiniOther", function(um)
	local pos = um:ReadVector()
	sound.Play("TFPlayer.CritHitMini", pos)
	ParticleEffect("minicrit_text", pos, Angle(0,0,0))
end)

usermessage.Hook("CriticalHitReceived", function(um)
	LocalPlayer():EmitSound("TFPlayer.CritPain", 100, 100)
end)

-- Domination notifications
usermessage.Hook("PlayerDomination", function(um)
	local victim = um:ReadEntity()
	local attacker = um:ReadEntity()
	if not IsValid(victim) or not IsValid(attacker) then
		return
	end
	
	if victim == LocalPlayer() then
		local data = EffectData()
			data:SetOrigin(attacker:GetPos())
			data:SetEntity(attacker)
		util.Effect("tf_nemesis_icon", data)
		LocalPlayer():EmitSound("Game.Nemesis")
	elseif attacker == LocalPlayer() then
		LocalPlayer():EmitSound("Game.Domination")
	end
	
	if not victim.NemesisesList then victim.NemesisesList = {} end
	if not attacker.DominationsList then attacker.DominationsList = {} end
	
	victim.NemesisesList[attacker] = true
	attacker.DominationsList[victim] = true
end)

usermessage.Hook("PlayerRevenge", function(um)
	local victim = um:ReadEntity()
	local attacker = um:ReadEntity()
	if not IsValid(victim) or not IsValid(attacker) then
		return
	end
	
	if attacker == LocalPlayer() then
		if IsValid(victim.NemesisEffect) and victim.NemesisEffect.Destroy then
			victim.NemesisEffect:Destroy()
		end
		LocalPlayer():EmitSound("Game.Revenge")
	elseif victim == LocalPlayer() then
		LocalPlayer():EmitSound("Game.Revenge")
	end
	
	if attacker.NemesisesList then
		attacker.NemesisesList[victim] = nil
	end
	
	if victim.DominationsList then
		victim.DominationsList[attacker] = nil
	end
end)

usermessage.Hook("PlayerResetDominations", function(um)
	local pl = um:ReadEntity()
	if not IsValid(pl) then return end
	
	pl.NemesisesList = nil
	pl.DominationsList = nil
	
	if IsValid(pl.NemesisEffect) and pl.NemesisEffect.Destroy then
		pl.NemesisEffect:Destroy()
	end
	
	for _,v in pairs(player.GetAll()) do
		if v ~= pl then
			if v.NemesisesList then
				v.NemesisesList[pl] = nil
			end
			if v.DominationsList then
				v.DominationsList[pl] = nil
			end
		end
	end
end)

usermessage.Hook("SendPlayerDominations", function(um)
	local pl = um:ReadEntity()
	if not IsValid(pl) then return end
	
	local num = um:ReadChar()
	if num <= 0 then return end
	
	pl.DominationsList = {}
	for i=1,num do
		local k = um:ReadEntity()
		if IsValid(pl) then
			pl.DominationsList[k] = true
		end
	end
end)

local function DoHealthBonusEffect(ent, positive)
	if not IsValid(ent) then return end
	
	local col = "red"
	if ent:EntityTeam()==TEAM_BLU then col = "blu" end
	
	local pos = ent:GetPos() + Vector(0,0,75) + math.Rand(0,4) * Angle(math.Rand(-180,180),math.Rand(-180,180),0):Forward()
	
	if positive then
		ParticleEffect("healthgained_"..col, pos, Angle(0,0,0))
	else
		ParticleEffect("healthlost_"..col, pos, Angle(0,0,0))
	end
end

usermessage.Hook("PlayerHealthBonusEffect", function(um)
	local ent = GetPlayerByUserID(um:ReadLong())
	local positive = um:ReadBool()
	
	if ent ~= LocalPlayer() or ent:ShouldDrawLocalPlayer() then
		DoHealthBonusEffect(ent, positive)
	end
end)

usermessage.Hook("EntityHealthBonusEffect", function(um)
	local ent = um:ReadEntity()
	local positive = um:ReadBool()
	DoHealthBonusEffect(ent, positive)
end)

usermessage.Hook("PlayerRocketJumpEffect", function(um)
	local ent = GetPlayerByUserID(um:ReadLong())
	
	if ent ~= LocalPlayer() or ent:ShouldDrawLocalPlayer() then
		ParticleEffectAttach("rocketjump_smoke", PATTACH_POINT_FOLLOW, ent, ent:LookupAttachment("foot_L"))
		ParticleEffectAttach("rocketjump_smoke", PATTACH_POINT_FOLLOW, ent, ent:LookupAttachment("foot_R"))
	end
end)

usermessage.Hook("PlayChargeReadySound", function(um)
	LocalPlayer():EmitSound("TFPlayer.ReCharged")
end)

include("cl_hud.lua")

file.Append(LOGFILE, Format("Done loading, time = %f\n", SysTime() - load_time))
local load_time = SysTime()

function ClassSelection()
local ply = LocalPlayer()
local ClassFrame = vgui.Create("DFrame") --create a frame
ClassFrame:SetSize( ScrW() * 1, ScrH() * 1 ) --set its size
ClassFrame:Center() --position it at the center of the screen
ClassFrame:SetTitle("Pick a Class") --set the title of the menu 
ClassFrame:SetDraggable(false) --can you move it around
ClassFrame:SetSizable(false) --can you resize it?
ClassFrame:ShowCloseButton(true) --can you close it
ClassFrame:MakePopup() --make it appear
--models/vgui/ui_class01.mdl
  local iconC = vgui.Create( "DModelPanel", ClassFrame )
iconC:SetSize( ScrW() * 1, ScrH() * 1 )

iconC:SetCamPos( Vector( 90, 0, 40 ) )
iconC:SetPos( 0, 0)
iconC:SetModel( "models/vgui/ui_class01.mdl" ) -- you can only change colors on playermodels
iconC:SetZPos(-2)
function iconC:LayoutEntity( Entity ) return end -- disables default rotation
  local icon = vgui.Create( "DModelPanel", ClassFrame )
icon:SetSize(ScrW() * 0.412, ScrH() * 0.571) --MedicButton:SetSize(ScrW() * 0.312, ScrH() * 0.601)
--MedicButton:SetPos(ScrW() * 0.598, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
icon:SetPos(ScrW() * 0.012, ScrH() * 0.301)
icon:SetAnimated(true)
icon:SetModel( "models/player/scout.mdl" ) -- you can only change colors on playermodels
function icon:LayoutEntity( Entity ) return end -- disables default rotation
dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" )
icon:GetEntity():SetSequence( dance )
icon:SetZPos(-1)
icon:SetCamPos( Vector( 90, 0, 40 ) )
-- Where 'source' is an entity
loopingSound = CreateSound( ply, "music/class_menu_bg.wav" );
loopingSound:Play();
 
-- Fade me out, scottyvMyFrame:SetSize( ScrW() * 0.208, ScrH() * 0.277 )
 -- Fade out over 10 seconds
--surface.PlaySound( "music/class_menu_bg.wav" )
local ScoutButton = vgui.Create("DButton", ClassFrame)
ScoutButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
ScoutButton:SetPos(ScrW() * 0.128, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
ScoutButton:SetText("Scout")
ScoutButton.DoClick = function() RunConsoleCommand("changeclass", "scout")  ClassFrame:Close() end
 local scout_img = vgui.Create( "DImage", ScoutButton )	-- Add image to Frame
scout_img:SetPos( 0, 0 )	-- Move it into frame
scout_img:SetSize( ScoutButton:GetSize() )	-- Size it to 150x150
ScoutButton.OnCursorEntered = function() icon:SetModel( "models/player/scout.mdl" )  surface.PlaySound( "/music/class_menu_01.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
scout_img:SetImage( "hud/class_scoutred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
scout_img:SetImage( "hud/class_scoutred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
scout_img:SetImage( "hud/class_scoutblue" )
icon:GetEntity():SetSkin(1)
else
	scout_img:SetImage( "hud/class_scoutblue" )
	icon:GetEntity():SetSkin(1)
end	
ScoutButton:SetAlpha(1)
local SoldierButton = vgui.Create("DButton", ClassFrame)
SoldierButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
SoldierButton:SetPos(ScrW() * 0.178, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
SoldierButton:SetText("Soldier") --Set the name of the button
SoldierButton.DoClick = function() RunConsoleCommand("changeclass", "soldier")  ClassFrame:Close() end
 local sol_img = vgui.Create( "DImage", SoldierButton )	-- Add image to Frame
sol_img:SetPos( 0, 0 )	-- Move it into frame
sol_img:SetSize( SoldierButton:GetSize() )	-- Size it to 150x150
SoldierButton.OnCursorEntered = function() icon:SetModel( "models/player/soldier.mdl" ) surface.PlaySound( "/music/class_menu_02.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
sol_img:SetImage( "hud/class_soldierred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
sol_img:SetImage( "hud/class_soldierred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
sol_img:SetImage( "hud/class_soldierblue" )
icon:GetEntity():SetSkin(1)
else
	sol_img:SetImage( "hud/class_soldierblue" )
icon:GetEntity():SetSkin(1)
end	
SoldierButton:SetAlpha(1)
local PyroButton = vgui.Create("DButton", ClassFrame)
PyroButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
PyroButton:SetPos(ScrW() * 0.248, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
PyroButton:SetText("Pyro") --Set the name of the button
PyroButton.DoClick = function() RunConsoleCommand("changeclass", "pyro")  ClassFrame:Close() end
 local py_img = vgui.Create( "DImage", PyroButton )	-- Add image to Frame
py_img:SetPos( 0, 0 )	-- Move it into frame
py_img:SetSize( PyroButton:GetSize() )	-- Size it to 150x150
PyroButton.OnCursorEntered = function() icon:SetModel( "models/player/pyro.mdl" ) surface.PlaySound( "/music/class_menu_03.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
py_img:SetImage( "hud/class_pyrored" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
py_img:SetImage( "hud/class_pyrored" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
py_img:SetImage( "hud/class_pyroblue" )
icon:GetEntity():SetSkin(1)
else
	py_img:SetImage( "hud/class_pyroblue" )
icon:GetEntity():SetSkin(1)
end	
PyroButton:SetAlpha(1)
local DemomanButton = vgui.Create("DButton", ClassFrame)
DemomanButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
DemomanButton:SetPos(ScrW() * 0.358, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
DemomanButton:SetText("Demoman") --Set the name of the button
DemomanButton.DoClick = function() RunConsoleCommand("changeclass", "demoman") ClassFrame:Close() end
 local de_img = vgui.Create( "DImage", DemomanButton )	-- Add image to Frame
de_img:SetPos( 0, 0 )	-- Move it into frame
de_img:SetSize( DemomanButton:GetSize() )	-- Size it to 150x150
DemomanButton.OnCursorEntered = function() icon:SetModel( "models/player/demo.mdl" ) surface.PlaySound( "/music/class_menu_04.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
de_img:SetImage( "hud/class_demored" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
de_img:SetImage( "hud/class_demored" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
de_img:SetImage( "hud/class_demoblue" )
icon:GetEntity():SetSkin(1)
else
	de_img:SetImage( "hud/class_demoblue" )
icon:GetEntity():SetSkin(1)
end	
DemomanButton:SetAlpha(1)
local HeavyButton = vgui.Create("DButton", ClassFrame)
HeavyButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
HeavyButton:SetPos(ScrW() * 0.428, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
HeavyButton:SetText("Heavy") --Set the name of the button
HeavyButton.DoClick = function() RunConsoleCommand("changeclass", "heavy")  ClassFrame:Close() end
 local he_img = vgui.Create( "DImage", HeavyButton )	-- Add image to Frame
he_img:SetPos( 0, 0 )	-- Move it into frame
he_img:SetSize(HeavyButton:GetSize())	-- Size it to 150x150
HeavyButton.OnCursorEntered = function() icon:SetModel( "models/player/heavy.mdl" ) surface.PlaySound( "/music/class_menu_05.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
he_img:SetImage( "hud/class_heavyred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
he_img:SetImage( "hud/class_heavyred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
he_img:SetImage( "hud/class_heavyblue" )
icon:GetEntity():SetSkin(1)
else
	he_img:SetImage( "hud/class_heavyblue" )
icon:GetEntity():SetSkin(1)
end	
HeavyButton:SetAlpha(1)
local EngineerButton = vgui.Create("DButton", ClassFrame)
EngineerButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
EngineerButton:SetPos(ScrW() * 0.478, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
EngineerButton:SetText("Engineer") --Set the name of the button
EngineerButton.DoClick = function() RunConsoleCommand("changeclass", "engineer")  ClassFrame:Close() end
 local en_img = vgui.Create( "DImage", EngineerButton )	-- Add image to Frame
en_img:SetPos( 0, 0 )	-- Move it into frame
en_img:SetSize( EngineerButton:GetSize() )	-- Size it to 150x150
EngineerButton.OnCursorEntered = function() icon:SetModel( "models/player/engineer.mdl" ) surface.PlaySound( "/music/class_menu_06.wav" )  end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
en_img:SetImage( "hud/class_engired" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
en_img:SetImage( "hud/class_engired" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
en_img:SetImage( "hud/class_engiblue" )
icon:GetEntity():SetSkin(1)
else
	en_img:SetImage( "hud/class_engiblue" )
icon:GetEntity():SetSkin(1)
end	
EngineerButton:SetAlpha(1)
local MedicButton = vgui.Create("DButton", ClassFrame)
MedicButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
MedicButton:SetPos(ScrW() * 0.598, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
MedicButton:SetText("Medic") --Set the name of the button
MedicButton.DoClick = function() RunConsoleCommand("changeclass", "medic") ClassFrame:Close() end
 local me_img = vgui.Create( "DImage", MedicButton )	-- Add image to Frame
me_img:SetPos( 0, 0 )	-- Move it into frame
me_img:SetSize( MedicButton:GetSize() )	-- Size it to 150x150
MedicButton.OnCursorEntered = function() icon:SetModel( "models/player/medic.mdl" ) surface.PlaySound( "/music/class_menu_07.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
me_img:SetImage( "hud/class_medicred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
me_img:SetImage( "hud/class_medicred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
me_img:SetImage( "hud/class_medicblue" )
icon:GetEntity():SetSkin(1)
else
	me_img:SetImage( "hud/class_medicblue" )
icon:GetEntity():SetSkin(1)
end	
MedicButton:SetAlpha(1)
local SniperButton = vgui.Create("DButton", ClassFrame)
SniperButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
SniperButton:SetPos(ScrW() * 0.658, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
SniperButton:SetText("Sniper") --Set the name of the button
SniperButton.DoClick = function() RunConsoleCommand("changeclass", "sniper") ClassFrame:Close() end
 local sni_img = vgui.Create( "DImage", SniperButton )	-- Add image to Frame
sni_img:SetPos( 0, 0 )	-- Move it into frame
sni_img:SetSize( SniperButton:GetSize() )	-- Size it to 150x150
SniperButton.OnCursorEntered = function() icon:SetModel( "models/player/sniper.mdl" ) surface.PlaySound( "/music/class_menu_08.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
sni_img:SetImage( "hud/class_sniperred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
sni_img:SetImage( "hud/class_sniperred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
sni_img:SetImage( "hud/class_sniperblue" )
icon:GetEntity():SetSkin(1)
else
	sni_img:SetImage( "hud/class_sniperblue" )
icon:GetEntity():SetSkin(1)
end	
SniperButton:SetAlpha(1)
local SpyButton = vgui.Create("DButton", ClassFrame)
SpyButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
SpyButton:SetPos(ScrW() * 0.718, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
SpyButton:SetText("Spy") --Set the name of the button
SpyButton.DoClick = function() RunConsoleCommand("changeclass", "spy") ClassFrame:Close() end
 local spy_img = vgui.Create( "DImage", SpyButton )	-- Add image to Frame
spy_img:SetPos( 0, 0 )	-- Move it into frame
spy_img:SetSize( SpyButton:GetSize() )	-- Size it to 150x150
SpyButton.OnCursorEntered = function() icon:SetModel( "models/player/spy.mdl" ) surface.PlaySound( "/music/class_menu_09.wav" ) dance = icon:GetEntity():LookupSequence( "selectionmenu_idle" ) icon:GetEntity():SetSequence( dance ) end -- DEATH
-- Set material relative to "garrysmod/materials/"
if LocalPlayer():Team()==4 then
spy_img:SetImage( "hud/class_spyred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==1 then
spy_img:SetImage( "hud/class_spyred" )
icon:GetEntity():SetSkin(0)
elseif LocalPlayer():Team()==2 then
spy_img:SetImage( "hud/class_spyblue" )
icon:GetEntity():SetSkin(1)
else
	spy_img:SetImage( "hud/class_spyblue" )
icon:GetEntity():SetSkin(1)
end	
SpyButton:SetAlpha(1)
local GmodButton = vgui.Create("DButton", ClassFrame)
GmodButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
GmodButton:SetPos(ScrW() * 0, ScrH() * 0.800) --ScrW() * 0.088, ScrH() * 0.002
GmodButton:SetText("GMod Player") --Set the name of the buttonPanel:SetAlpha
GmodButton.DoClick = function() RunConsoleCommand("changeclass", "gmodplayer") surface.PlaySound( "/garrysmod/save_load3.wav" ) ClassFrame:Close() end
 local gm_img = vgui.Create( "DImage", GmodButton )	-- Add image to Frame
gm_img:SetPos( 0, 0 )	-- Move it into frame
gm_img:SetSize( GmodButton:GetSize() )	-- Size it to 150x150
GmodButton.OnCursorEntered = function() icon:SetModel( "models/player/kleiner.mdl" ) surface.PlaySound( "/music/class_menu_01.wav" ) dance = icon:GetEntity():LookupSequence( "taunt_laugh_base" ) icon:SetAnimated(true) icon:GetEntity():SetSequence( dance ) icon:SetAnimated(true)  end
-- Set material relative to "garrysmod/materials/"

gm_img:SetImage( "vgui/hand" )

local CivButton = vgui.Create("DButton", ClassFrame)
CivButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
CivButton:SetPos(ScrW() * 0.800, ScrH() * 0.800) --ScrW() * 0.088, ScrH() * 0.002
CivButton:SetText("Civilian") --Set the name of the button
CivButton.DoClick = function() RunConsoleCommand("changeclass", "civillian") ClassFrame:Close() end
 local civ_img = vgui.Create( "DImage", CivButton )	-- Add image to Frame
civ_img:SetPos( 0, 0 )	-- Move it into frame
civ_img:SetSize( CivButton:GetSize() )	-- Size it to 150x150
local CButton = vgui.Create("DButton", ClassFrame)
CButton:SetSize(ScrW() * 0.056, ScrH() * 0.155)
CButton:SetPos(ScrW() * 0.900, ScrH() * 0.025) --ScrW() * 0.088, ScrH() * 0.002
CButton:SetText("CLOSE")--Set the name of the button
CButton.DoClick = function()  ClassFrame:Close() end
-- Set material relative to "garrysmod/materials/"

civ_img:SetImage( "entities/npc_citizen.png" )
function ClassFrame:OnClose()
--stuffPanel:IsHovered() 
loopingSound:FadeOut( 0.2 );
end
end

--[[function GM:PlayerBindPress(pl, bind, pressed)
	if (bind == "+menu") then
		RunConsoleCommand("lastinv")
	end
end]]

concommand.Add("changeclass_menu", ClassSelection)

if input.WasKeyPressed( KEY_COMMA ) then
LocalPlayer():ConCommand( "changeclass_menu" )
end

local function shouldShowItem(name, item, currentclass, filter)
	filter = filter or {}
	
	if not filter.show_hidden and item.hidden == 1 then return false end
	if not item.used_by_classes or not item.used_by_classes[currentclass] then return false end
	
	if not filter.not_an_entity then
		if not item.item_slot or (filter.slot and not filter.slot[item.item_slot]) then return false end
		if not scripted_ents.GetStored(item.item_class) and not weapons.GetStored(item.item_class) then return false end
	end
	
	if filter.itemclass and not filter.itemclass[item.item_class] then return false end
	if filter.custom_filter and not filter.custom_filter(name, item, currentclass) then return false end
	
	return true
end


--[[hook.Add( "AATab", "AddEntityContent", function( pnlContent, tree, node )
classname = LocalPlayer():GetPlayerClass()
    local Categorised = {}
	t = {}
	Items = {n=0}
	j = {}
class_lst = {}
filter_weapon = {slot={primary=true, secondary=true, melee=true, pda=true, pda2=true, building=true}}
--s = string.gsub(args, "^%s*", "^")
    -- Add this list into the tormoil
    local SpawnableEntities = scripted_ents.GetSpawnable()
    --	if table.HasValue( args, "list") then
		
--end
for k,v in pairs(Items) do
	if type(v)=="table" and shouldShowItem(k, v, classname, filter_weapon) then
			table.insert(class_lst,k)
		end
	end
	
	table.sort(class_lst)

    for k,v in pairs(SpawnableEntities) do --Remove all non basewars items
        if v.Price == nil then
            table.remove(SpawnableEntities, k)
        end
    end
	for _,k in ipairs(class_lst) do
		if string.find(k, string.gsub("", "^%s*", "^")) then
			table.insert(j,k)

			PrintTable(j)
			PrintTable(k)
			print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
						print("DONE YEY")
			
		end
	end
	print("Printing...")
	PrintTable(j)
	--Print(j)
print("DONE YEYAET")
print("DONE YEYaTWJIAJLKTEASKLTALKLK")
print("DONE YEYGEAKLMTLKEA")
    --[[if ( SpawnableEntities ) then
      --  for k, v in pairs( SpawnableEntities ) do
           -- v.Category = "Team Fortress 2 Utilities"
            --Categorised[ v.Category ] = Categorised[ v.Category ] or {}
            --table.insert( "Team Fortress 2 Utilities" )
            
        --end
    end

    --
    -- Add a tree node for each category
    --
                    
        -- Add a node to the tree
        local node = tree:AddNode( "Team Fortress 2 Utilities", "icon32/folder.png" );

            -- When we click on the node - populate it using this function
        node.DoPopulate = function( self )
    
            -- If we've already populated it - forget it.
            if ( self.PropPanel ) then return end
        
            -- Create the container panel
            self.PropPanel = vgui.Create( "ContentContainer", pnlContent )
            self.PropPanel:SetVisible( false )
            self.PropPanel:SetTriggerSpawnlistChange( false )
        
                            
                local Icon = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Change Class",
                    spawnname   = "Change Class",
                    material    = "materials/spawnicons/models/player/hwm/spy.png",
                    admin       = false
                            
                })
                Icon.DoClick = function ()
                    LocalPlayer():ConCommand("changeclass_menu")
                end
                local Tooltip =  Format( "Help: Change your class!" )
                Icon:SetTooltip( Tooltip )
                                                                
            
                                    local Team = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Join Red",
                    spawnname   = "Join Red",
                    material    = "materials/spawnicons/models/props_harbor/red_letter_sign_harbor01_ref.png",
                    admin       = false
                            
                })
                Team.DoClick = function ()
                    LocalPlayer():ConCommand("changeteam 1")
                end
                local Tooltipte =  Format( "Help: Join Red" )
                Team:SetTooltip( Tooltipte )
                                                                
            
                                    local Team2 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Join Blu",
                    spawnname   = "Join Blu",
                    material    = "materials/spawnicons/models/props_harbor/blue_letter_sign_harbor01_ref.png",
                    admin       = false
                            
                })
                Team2.DoClick = function ()
                    LocalPlayer():ConCommand("changeteam 2")
                end
                local Tooltipte2 =  Format( "Help: Join Blu" )
                Team2:SetTooltip( Tooltipte2 )
                                                                
                                    local Team3 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Join Gray",
                    spawnname   = "Join Gray",
                    material    = "materials/spawnicons/models/props_movies/bobblehead/bobblehead.png",
                    admin       = false
                            
                })
                Team3.DoClick = function ()
                    LocalPlayer():ConCommand("changeteam 3")
                end
                local Tooltipte3 =  Format( "Help: Join GRY" )
                Team3:SetTooltip( Tooltipte3 )
                                    local Team4 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Join Neutral",
                    spawnname   = "Join Neutral",
                    material    = "materials/spawnicons/models/props_movies/bobblehead/bobblehead.png",
                    admin       = false
                            
                })
                Team4.DoClick = function ()
                    LocalPlayer():ConCommand("changeteam 4")
                end

            local Icon2 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Voicemenu 1",
                    spawnname   = "Voicemenu 1",
                    material    = "materials/spawnicons/models/extras/info_speech.png",
                    admin       = false
                            
                })
                Icon2.DoClick = function ()
                    LocalPlayer():ConCommand("voice_menu_1")
                end
                 Tooltip2 =  Format( "Help: Voicemenu" )
                Icon2:SetTooltip( Tooltip3 )
                                                                
            
                   local Icon3 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Voicemenu 2",
                    spawnname   = "Voicemenu 2",
                    material    = "materials/spawnicons/models/extras/info_speech.png",
                    admin       = false
                            
                })
                Icon3.DoClick = function ()
                    LocalPlayer():ConCommand("voice_menu_2")
                end
                
                Icon3:SetTooltip( Tooltip2 )
                                                                
            
                       local Icon4 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Voicemenu 3",
                    spawnname   = "Voicemenu 3",
                    material    = "materials/spawnicons/models/extras/info_speech.png",
                    admin       = false
                            
                })
                Icon4.DoClick = function ()
                    LocalPlayer():ConCommand("voice_menu_3")
                end
                
                Icon4:SetTooltip( Tooltip2 )
                                 local Icon5 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Thirdperson",
                    spawnname   = "Thirdperson",
                    material    = "materials/spawnicons/models/extras/info_speech.png",
                    admin       = false
                            
                })
                Icon5.DoClick = function ()
                    LocalPlayer():ConCommand("tf_thirdperson")
                end
                Tooltip999 =  Format( "Help: Change View!" )
                Icon5:SetTooltip( Tooltip999 )   
                                 local Icon6 = spawnmenu.CreateContentIcon( "entity", self.PropPanel, 
                { 
                    nicename    = "Firstperson",
                    spawnname   = "Firstperson",
                    material    = "materials/spawnicons/models/extras/info_speech.png",
                    admin       = false
                            
                })
                Icon6.DoClick = function ()
                    LocalPlayer():ConCommand("tf_firstperson")
                end
                Tooltip999 =  Format( "Help: Change View!" )
                Icon6:SetTooltip( Tooltip999 )                
            end
        -- If we click on the node populate it and switch to it.
        node.DoClick = function( self )
    
            self:DoPopulate()       
            pnlContent:SwitchPanel( self.PropPanel );
    
        end
 local node2 = tree:AddNode( "Weapons", "icon16/gun.png" );

            -- When we click on the node - populate it using this function
        node2.DoPopulate = function( self )
    
            -- If we've already populated it - forget it.
            if ( self.PropPanel2 ) then return end
        
            -- Create the container panel
            self.PropPanel2 = vgui.Create( "ContentContainer", pnlContent )
            self.PropPanel2:SetVisible( false )
            self.PropPanel2:SetTriggerSpawnlistChange( false )
        
                            
                local wep = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Sandvich",
                    spawnname   = "Sandvich",
                    material    = "materials/spawnicons/models/weapons/c_models/c_sandwich/c_sandwich.png",
                    admin       = false
                            
                })
                wep.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Sandvich")
                end
                local wepTooltip =  Format( "Moist and delicious! HAHAHA!" )
                wep:SetTooltip( wepTooltip )
                                                                
            
                                    local wep2 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Jarate",
                    spawnname   = "Jarate",
                    material    = "materials/spawnicons/models/weapons/c_models/urinejar.png",
                    admin       = false
                            
                })
                wep2.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon Jarate")
                end
                local wepTooltip2 =  Format( "PISS OFF" )
                wep2:SetTooltip( wepTooltip2 )
                                                                
            
                                                 local wep3 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Huntsman",
                    spawnname   = "Huntsman",
                    material    = "materials/spawnicons/models/weapons/c_models/c_bow/c_bow.png",
                    admin       = false
                            
                })
                wep3.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Huntsman")
                end
                local wepTooltip3 =  Format( "Stab stab stab!" )
                wep3:SetTooltip( wepTooltip3 )
                                                                
            
            
                                                 local wep4 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Force-a-Nature",
                    spawnname   = "Force-a-Nature",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep4.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Force-a-Nature")
                end
                local wepTooltip4 =  Format( "Tip: You can use this for a third jump! Just use this on the ground while in the air!" )
                wep4:SetTooltip( wepTooltip4 )
                                                                      local wep5 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Golden Wrench",
                    spawnname   = "Golden Wrench",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep5.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Golden Wrench")
                end
                local wepTooltip5 =  Format( "ERECTING A STATUE OF A MORON!" )
                wep5:SetTooltip( wepTooltip5 )                                           
            
                                                                                  local wep6 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Mad Milk",
                    spawnname   = "Mad Milk",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep6.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon Mad Milk")
                end
                local wepTooltip6 =  Format( "Tastes funny..." )
                wep6:SetTooltip( wepTooltip6 )        
                                        
                                                                                  local wep7 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Boston Basher",
                    spawnname   = "Boston Basher",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep7.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Boston Basher")
                end
                local wepTooltip7 =  Format( "You missed dumbass!" )
                wep7:SetTooltip( wepTooltip7 ) 
                                                                                                      local wep7 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Golden Frying Pan",
                    spawnname   = "Golden Frying Pan",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep7.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon Golden Frying Pan")
                end
                local wepTooltip7 =  Format( "Over 4000 dollars to own this pan, for forever. AHAHAHAHAHA" )
                wep7:SetTooltip( wepTooltip7 )             
                                                                                                                                   local wep8 = spawnmenu.CreateContentIcon( "entity", self.PropPanel2, 
                { 
                    nicename    = "Soda Popper",
                    spawnname   = "Soda Popper",
                    material    = "materials/spawnicons/models/weapons/c_models/c_double_barrel.png",
                    admin       = false
                            
                })
                wep8.DoClick = function ()
                    LocalPlayer():ConCommand("giveweapon The Soda Popper")
                end
                local wepTooltip8 =  Format( "JUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMPJUMP" )
                wep8:SetTooltip( wepTooltip8 )                 
            end
        -- If we click on the node populate it and switch to it.
        node2.DoClick = function( self )
    
            self:DoPopulate()       
            pnlContent:SwitchPanel( self.PropPanel2 );
    
        end
       --[[    local node2 = tree:AddNode( "Credits", "icon32/folder.png" );

            -- When we click on the node - populate it using this function
        node2.DoPopulate = function( self )
    
            -- If we've already populated it - forget it.
            if ( self.PropPanel2 ) then return end
        
            -- Create the container panel
            self.PropPanel2 = vgui.Create( "ContentContainer", pnlContent )
            self.PropPanel2:SetVisible( false )
            self.PropPanel2:SetTriggerSpawnlistChange( false )
        
                            
                
                                                                
            end
                    

        -- If we click on the node populate it and switch to it.
        node2.DoClick = function( self )
    
            --self:DoPopulate()       
            --pnlContent:SwitchPanel( self.PropPanel );
local Frame = vgui.Create( "DFrame" )
Frame:SetPos( 5, 5 )
Frame:SetSize( ScrW() * 0.364, ScrH() * 0.277 )
Frame:SetTitle( "Credits" )
Frame:SetVisible( true )
Frame:SetDraggable( false )
Frame:ShowCloseButton( true )
Frame:MakePopup()
Frame:Center()
Frame.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
	draw.RoundedBox( 0, 0, 0, w, h, Color( 0, 150, 0, 200 ) ) -- Draw a red box instead of the frame
end]]

--[[local Panel = vgui.Create( "DPanel", Frame )
Panel:SetPos( 10, 10 )
Panel:SetSize( 500, 200 )
Panel.Paint = function( self, w, h ) -- 'function Frame:Paint( w, h )' works too
	draw.RoundedBox( 0, 0, 0, w, h, Color( 75, 0, 0, 100 ) ) -- Draw a red box instead of the frame
end
local DLabel = vgui.Create( "DLabel", Panel )
DLabel:SetPos( 40, 40 )]]
--DLabel:SetText( "Hello, world!" )

--local DLabel = vgui.Create( "DLabel", Frame )
--DLabel:SetPos( 40, 40 )
   -- local Letter2 = msg:ReadEntity()
   -- local Letter2Type = msg:ReadShort()
   -- local Letter2Pos = msg:ReadVector()
   -- local sectionCount = msg:ReadShort()
   -- local Letter2Y = ScrH() / 2 - 300
   -- local Letter2Alpha = 255
credits = "" --[[The Gamemode that allows you to play TF2 in Gmod! 

          Pre-Owners - Kilburn, wango911 
           Workshopper - Agent Agrimar 


If youre wondering why _Kilburn ended the development was
because he had a hard drive failure and lost all his data.
I was in talks with some other dude in regards to bringing back the gamemode,
but I have not talked to the guy in months, so I'm guessing his branch is dead.
-wango911/SmileyFace]]
--local font = (Letter2Type == 1 and "AckBarWriting") or "Default"
--DLabel:SetText( "PreOwnersKillburn,Wango911WorkshopperAndCurrentUpdaterAgentAgrimar" )
  --      draw.RoundedBox(2, ScrW() * .2, Letter2Y, ScrW() * .8 - (ScrW() * .2), ScrH(), Color(255, 255, 255, math.Clamp(Letter2Alpha, 0, 200)))
    --    draw.DrawNonParsedText(credits, font, ScrW() * .25 + 20, Letter2Y + 90, Color(0, 0, 0, Letter2Alpha), 0)
       -- end]]


    -- Select the first node
  --[[  local FirstNode = tree:Root():GetChildNode( 0 )
    if ( IsValid( FirstNode ) ) then
        FirstNode:InternalDoClick()
    end

end)
spawnmenu.AddCreationTab( "Team Fortress 2", function()

  local ctrl = vgui.Create( "SpawnmenuContentPanel" )
  ctrl:CallPopulateHook( "AATab" );
  return ctrl

end, "games/16/tf.png", 200 )

function GM:OnSpawnMenuOpen()
	--return --ply:IsAdmin()
end]]

local function DisableNoclip( ply )
	return ply:IsAdmin()
end
hook.Add( "PlayerNoClip", "DisableNoclip", DisableNoclip )

hook.Add( "PlayerSay", "Change class", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass" ) then
		RunConsoleCommand("changeclass_menu")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Scout", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass scout" ) then
		RunConsoleCommand("changeclass", "scout")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Soldier", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass soldier" ) then
		RunConsoleCommand("changeclass", "soldier")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Pyro", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass pyro" ) then
		RunConsoleCommand("changeclass", "pyro")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Demoman", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass demoman" ) then
		RunConsoleCommand("changeclass", "demoman")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Heavy", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass heavy" ) then
		RunConsoleCommand("changeclass", "heavy")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Engineer", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass engineer" ) then
		RunConsoleCommand("changeclass", "engineer")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Medic", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass medic" ) then
		RunConsoleCommand("changeclass", "medic")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Sniper", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass sniper" ) then
		RunConsoleCommand("changeclass", "sniper")
		return false
	end
end )

hook.Add( "PlayerSay", "Class Spy", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeclass spy" ) then
		RunConsoleCommand("changeclass", "spy")
		return false
	end
end )

hook.Add( "PlayerSay", "Change Team Red", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeteam red" ) then
		RunConsoleCommand("changeteam", "1")
		return false
	end
end )

hook.Add( "PlayerSay", "Change Team Blu", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeteam blu" ) then
		RunConsoleCommand("changeteam", "2")
		return false
	end
end )

hook.Add( "PlayerSay", "Change Team Blu", function( ply, text, public )
	text = string.lower( text ) -- Make the chat message entirely lowercase
	if ( string.sub( text, 1 ) == "!changeteam blu" ) then
		RunConsoleCommand("changeteam", "2")
		return false
	end
end )
