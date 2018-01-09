CLASS.Name = "Civillian"
CLASS.Speed = 75
CLASS.Health = 100

PrecacheParticleSystem("doublejump_puff")

if CLIENT then
	CLASS.CharacterImage = {
		surface.GetTextureID("hud/class_scoutred"),
		surface.GetTextureID("hud/class_scoutblue")
	}
	CLASS.ScoreboardImage = {
		surface.GetTextureID("hud/leaderboard_class_scout"),
		surface.GetTextureID("hud/leaderboard_class_scout_d")
	}
end

CLASS.Loadout = {"none"}
CLASS.DefaultLoadout = {"none"}
CLASS.ModelName = "scout"

CLASS.Gibs = {
	[GIB_LEFTLEG]		= GIBS_SCOUT_START,
	[GIB_RIGHTLEG]		= GIBS_SCOUT_START+1,
	[GIB_LEFTARM]		= GIBS_SCOUT_START+3,
	[GIB_RIGHTARM]		= GIBS_SCOUT_START+4,
	[GIB_TORSO]			= GIBS_SCOUT_START+5,
	[GIB_TORSO2]		= GIBS_SCOUT_START+2,
	[GIB_HEAD]			= GIBS_SCOUT_START+6,
	[GIB_HEADGEAR1]		= GIBS_SCOUT_START+7,
	[GIB_HEADGEAR2]		= GIBS_SCOUT_START+8,
	[GIB_ORGAN]			= GIBS_ORGANS_START,
}

CLASS.Sounds = {
	paincrticialdeath = {
		Sound("misc/taps_02.wav"),
		Sound("misc/taps_03.wav"),
	},
	painsevere = {
		Sound("player/crit_death1.wav"),
		Sound("player/crit_death2.wav"),
		Sound("player/crit_death3.wav"),
		Sound("player/crit_death4.wav"),
		Sound("player/crit_death5.wav"),
	},
	painsharp = {
		Sound("player/crit_death1.wav"),
		Sound("player/crit_death2.wav"),
		Sound("player/crit_death3.wav"),
		Sound("player/crit_death4.wav"),
		Sound("player/crit_death5.wav"),
	},
}

CLASS.AmmoMax = {
	[TF_PRIMARY]	= 0,		-- primary
	[TF_SECONDARY]	= 0,		-- secondary
	[TF_METAL]		= 0,		-- metal
	[TF_GRENADES1]	= 0,		-- grenades1
	[TF_GRENADES2]	= 0,		-- grenades2
}
