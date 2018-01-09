CLASS.Name = "bug"
CLASS.Speed = 0
CLASS.Health = 999

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

CLASS.Loadout = {}
CLASS.DefaultLoadout = {}
CLASS.ModelName = ""

CLASS.Gibs = {

}

CLASS.Sounds = {

}

CLASS.AmmoMax = {
	[TF_PRIMARY]	= 0,		-- primary
	[TF_SECONDARY]	= 0,		-- secondary
	[TF_METAL]		= 0,		-- metal
	[TF_GRENADES1]	= 0,		-- grenades1
	[TF_GRENADES2]	= 0,		-- grenades2
}
