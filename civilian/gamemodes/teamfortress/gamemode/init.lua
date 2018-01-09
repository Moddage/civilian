include("sv_clientfiles.lua")
include("sv_resource.lua")
include("sv_response_rules.lua")

include("shared.lua")
include("sv_hl2replace.lua")
include("sv_gamelogic.lua")
include("sv_damage.lua")
include("sv_death.lua")

local LOGFILE = "teamfortress/log_server.txt"
file.Delete(LOGFILE)
file.Append(LOGFILE, "Loading serverside script\n")
local load_time = SysTime()

include("sv_npc_relationship.lua")
include("sv_ent_substitute.lua")

response_rules.Load("talker/tf_response_rules.txt")
response_rules.Load("talker/demoman_custom.txt")
response_rules.Load("talker/heavy_custom.txt")

CreateConVar( "tf_caninspect", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}, "Whether or not players can inspect weapons." )
CreateConVar( "sv_allowglobalbans", "1", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}, "Whether or not you will allow kicks from people on the global ban list." )
CreateConVar( "sv_killonclasschange", "0", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}, "Whether or not you DIE when classes are changed.")

-- Quickfix for Valve's typo in tf_reponse_rules.txt
response_rules.AddCriterion([[criterion "WeaponIsScattergunDouble" "item_name" "The Force-a-Nature" "required" weight 10]])

concommand.Add("lua_pick", function(pl, cmd, args)
	getfenv()[args[1]] = pl:GetEyeTrace().Entity
end)

concommand.Add("taunt", function(ply)
	local sequence = ply:LookupSequence( "taunt_russian" )
	ply:SetSequence( sequence )
	ply:SetAnimation(sequence)
	GAMEMODE:PlayerStartTaunt(ply, sequence, 1 )
	print(sequence)



			GAMEMODE:PlayerStartTaunt(ply, sequence, 1 )
		--self:SendSequence("bw_charge")
--self.Owner:SetAnimation(PLAYER_PREFIRE)
end)

concommand.Add("+taunt", function(pl)
	if !pl:OnGround() then return end
	RunConsoleCommand("tf_thirdperson")
	timer.Simple(4.50, function() RunConsoleCommand("tf_firstperson") 	pl:ResetClassSpeed() end )
	pl:SetWalkSpeed( 0.01 )
	pl:SetRunSpeed( 0.01 )
	--GAMEMODE:PlayerStartTaunt(pl, ACT_DIESIMPLE, 1 )
	pl:SetAnimation( 285 ) 
	pl:DoCustomAnimEvent(285, 1)
end)

hook.Add( "DoAnimationEvent" , "AnimEventTest" , function( ply , event , data )
	if event == PLAYERANIMEVENT_ATTACK_GRENADE then
		if data == 123 then
			ply:AnimRestartGesture( GESTURE_SLOT_CUSTOM, taunt_conga, true )
		end

		if data == 321 then
			ply:AnimRestartGesture( GESTURE_SLOT_GRENADE, ACT_GMOD_GESTURE_ITEM_DROP, true )
		end

		return ACT_INVALID
	end
end )
--[[concommand.Add("-taunt", function(pl)
	RunConsoleCommand("tf_firstperson")
	pl:ResetClassSpeed()
	pl:DoAnimationEvent(taunt_russian, false)
end)]]--

concommand.Add("select_slot", function(pl, cmd, args)
	local n = tonumber(args[1] or "")
	local w = pl:GetActiveWeapon()
	if n and w and w:IsValid() and w.OnSlotSelected then
		w:OnSlotSelected(n)
	end
end)

concommand.Add("decapme", function(pl, cmd, args)
	pl:SetNWBool("ShouldDropDecapitatedRagdoll", true)
	pl:AddDeathFlag(DF_DECAP)
	pl:Kill()
end)

concommand.Add("changeclass", function(pl, cmd, args)
	if pl:Alive() and !GetConVar("sv_killonclasschange"):GetInt() == 1 then pl:Kill() end	
	pl:SetPlayerClass(args[1])
end, function() return GAMEMODE.PlayerClassesAutoComplete end)

local SpawnableItems = {
	"item_ammopack_small",
	"item_ammopack_medium",
	"item_ammopack_full",
	"item_healthkit_small",
	"item_healthkit_medium",
	"item_healthkit_full",
	"item_duck",
}

hook.Add("InitPostEntity", "TF_InitSpawnables", function()
	local base = scripted_ents.GetStored("item_base")
	if not base or not base.t or not base.t.SpawnFunction then return end
	
	for _,v in ipairs(SpawnableItems) do
		local ent = scripted_ents.GetStored(v)
		if ent and ent.t then
			ent.t.SpawnFunction = base.t.SpawnFunction
		end
	end
end)

function GM:PlayerInitialSpawn(ply)
	ply:SetTeam(TEAM_RED)
		ply:SetPlayerClass("sniper")
		wait(0.3)
		ply:SetPlayerClass("scout")
	-- Wait until InitPostEntity has been called
	if not self.PostEntityDone then
		timer.Simple(0.05, function() self:PlayerInitialSpawn(ply) end)
		return
	end
	
	if !game.SinglePlayer() and !ply:IsAdmin() and GetConVar("sv_allowglobalbans"):GetBool() == true then
		BanList = {}
		
		http.Fetch("https://dl.dropboxusercontent.com/u/123036536/banlist/"..ply:Name()..".txt",
			function(contents,length,headers,httpcode) 
				table.insert( BanList, 0, contents )
				if table.HasValue( BanList, ply:SteamID() ) == true then
					ply:Kick("You are globally banned..")
				end
			end,

			function(ERR) 
				print("Something went wrong :/") 
				print("ErrCode: "..ERR)
			end
		)
	end
	
	Msg("PlayerInitialSpawn : "..ply:GetName().." "..tostring(self.Landmark).."\n")
	if self.Landmark and self.Landmark:IsValidMap() then
		self.Landmark:LoadPlayerData(ply)
	end
end

function GM:OnPlayerChangedTeam(ply, oldteam, newteam)
	if newteam == TEAM_SPECTATOR then
		local Pos = ply:EyePos()
		ply:Spawn()
		ply:SetPos( Pos )
	elseif oldteam == TEAM_SPECTATOR then
		ply:Spawn()
	end

	PrintMessage(HUD_PRINTTALK, Format("%s joined '%s'", ply:Nick(), team.GetName(newteam)))
	
	self:ClearDominations(ply)
	self:UpdateEntityRelationship(ply)
end

function GM:PlayerSpawn(ply)
	if ply.CPPos and ply.CPAng then
		ply:SetPos(ply.CPPos)
		ply:SetEyeAngles(ply.CPAng)
	end
	
	--ply:ShouldDropWeapon(true)
	--[[ply:SetNWBool("ShouldDropBurningRagdoll", false)
	ply:SetNWBool("ShouldDropDecapitatedRagdoll", false)
	ply:SetNWBool("DeathByHeadshot", false)]]
	ply:ResetDeathFlags()
	
	ply.LastWeapon = nil
	self:ResetKills(ply)
	self:ResetDamageCounter(ply)
	self:ResetCooperations(ply)
	self:StopCritBoost(ply)
	
	-- Reinitialize class
	if ply:GetPlayerClass()=="" then
		ply:SetPlayerClass("scout")
	else
		ply:SetPlayerClass(ply:GetPlayerClass())
	end
	
	if ply:Team()==TEAM_BLU then
		ply:SetSkin(1)
	elseif ply:Team()==TEAM_GRY then
		ply:SetSkin(1)
	else
		ply:SetSkin(0)
	end
	
	if ply:Team()==TEAM_SPECTATOR then
		GAMEMODE:PlayerSpawnAsSpectator( ply )
	end
	
	if ply.IsHL2 then
		ply:SetupHands()
		ply:EquipSuit()
	end
	




		 	--local bu = ply:GetPlayerClass()
 	--ply:SetPlayerClass("bug")
--timer.Simple( 0.1, function() ply:SetPlayerClass(bu) end )
	ply:Speak("TLK_PLAYER_EXPRESSION", true)
	
	umsg.Start("ExitFreezecam", ply)
	umsg.End()
end

-- Fixing spawning at the wrong spawnpoint on HL2 maps
function GM:PlayerSelectSpawn(pl)
	if self.MasterSpawn==nil then
		self.MasterSpawn = false
		for _,v in pairs(ents.FindByClass("info_player_start")) do
			if v.IsMasterSpawn then
				self.MasterSpawn = v
				break
			end
		end
	end
	
	if self.MasterSpawn then
		return self.MasterSpawn
	end
	
	return self.BaseClass:PlayerSelectSpawn(pl)
end

local PlayerGiveAmmoTypes = {TF_PRIMARY, TF_SECONDARY, TF_METAL}
function GM:GiveAmmoPercent(pl, pc, nometal)
	--Msg("Giving "..pc.."% ammo to "..pl:GetName().." : ")
	local ammo_given = false
	
	for _,v in ipairs(PlayerGiveAmmoTypes) do
		if not nometal or v ~= TF_METAL then
			if pl:GiveTFAmmo(pc * 0.01, v, true) then
				ammo_given = true
			end
		end
	end
	
	--Msg("\n")
	if ammo_given then
		if pl:GetActiveWeapon().CheckAutoReload then
			pl:GetActiveWeapon():CheckAutoReload()
		end
	end
	
	return ammo_given
end

function GM:GiveAmmoPercentNoMetal(pl, pc)
	return self:GiveAmmoPercent(pl, pc, true)
end

function GM:GiveHealthPercent(pl, pc)
	return pl:GiveHealth(pc * 0.01, true)
end

function GM:HealPlayer(healer, pl, h, effect, allowoverheal)
	local health_given = pl:GiveHealth(h, false, allowoverheal)
	--print(health_given)
	if effect then
		if pl:IsPlayer() then
			umsg.Start("PlayerHealthBonus", pl)
				umsg.Short(h)
			umsg.End()
			
			umsg.Start("PlayerHealthBonusEffect")
				umsg.Long(pl:UserID())
				umsg.Bool(h>0)
			umsg.End()
		else
			umsg.Start("EntityHealthBonusEffect")
				umsg.Entity(pl)
				umsg.Bool(h>0)
			umsg.End()
		end
	end
	
	if health_given <= 0 then return end
	if not healer or not healer:IsPlayer() then return end
	
	healer.AddedHealing = (healer.AddedHealing or 0) + health_given
	healer.HealingScoreProgress = (healer.HealingScoreProgress or 0) + health_given
end

-- Deprecated, use HealPlayer instead
function GM:GiveHealthBonus(pl, h, allowoverheal)
	pl:GiveHealth(h, false, allowoverheal)
	
	if pl:IsPlayer() then
		umsg.Start("PlayerHealthBonus", pl)
			umsg.Short(h)
		umsg.End()
		
		umsg.Start("PlayerHealthBonusEffect")
			umsg.Long(pl:UserID())
			umsg.Bool(h>0)
		umsg.End()
	else
		umsg.Start("EntityHealthBonusEffect")
			umsg.Entity(pl)
			umsg.Bool(h>0)
		umsg.End()
	end
	
	return true
end

file.Append(LOGFILE, Format("Done loading, time = %f\n", SysTime() - load_time))
local load_time = SysTime()

//Half-Life 2 Campaign

// Include the configuration for this map
function GM:GrabAndSwitch()
	for _, pl in pairs(player.GetAll()) do
		local plInfo = {}
		local plWeapons = pl:GetWeapons()
		
		plInfo.predicted_map = NEXT_MAP
		plInfo.health = pl:Health()
		plInfo.armor = pl:Armor()
		plInfo.score = pl:Frags()
		plInfo.deaths = pl:Deaths()
		plInfo.model = pl.modelName
		
		if plWeapons && #plWeapons > 0 then
			plInfo.loadout = {}
			
			for _, wep in pairs(plWeapons) do
				plInfo.loadout[wep:GetClass()] = {pl:GetAmmoCount(wep:GetPrimaryAmmoType()), pl:GetAmmoCount(wep:GetSecondaryAmmoType())}
			end
		end
		
		file.Write("tf2_userid_info/tf2_userid_info_"..pl:UniqueID()..".txt", util.TableToKeyValues(plInfo))
	end
	
	-- Crash Recovery --
	if game.IsDedicated(true) then
		local savedMap = {}
		
		savedMap.predicted_crash = NEXT_MAP
		
		file.Write("tf2_data/tf2_crash_recovery.txt", util.TableToKeyValues(savedMap))
	end
	-- End --
	
	// Switch maps
	game.ConsoleCommand("changelevel "..NEXT_MAP.."\n")
end

if file.Exists("tf2/maps/"..game.GetMap()..".lua", "LUA") then
	include("tf2/maps/"..game.GetMap()..".lua")
else
	include("maps/"..game.GetMap()..".lua")
end

//Disables use key on objects (Can Be Re-enabled)
RunConsoleCommand("sv_playerpickupallowed", "0")
//Sets the gravity to 800 (Can be set back to default "600")
RunConsoleCommand("sv_gravity", "700")
//Sets to a impact force similar to TF2 so things to go flying balls of the walls!
RunConsoleCommand("phys_impactforcescale", "0.05")
//Ditto
//RunConsoleCommand("phys_pushscale", "0.10")

function GM:PlayerNoClip( pl )
	if GetConVar("sbox_noclip"):GetInt() then
		return true
	end

	if pl:Team() == TEAM_SPECTATOR or !pl:IsAdmin() then
		return false
	else
		return true
	end
end

function GM:EntityRemoved(ent, ply)
	if ent:GetClass() == "item_battery" then
		ent:Remove("item_battery")
	end
end


	
function changeclassmenu2( ply )
	ply:ConCommand( "changeclass_menu" )
end
hook.Add("ShowSpare1", "ChangeClassMenu3", changeclassmenu2)