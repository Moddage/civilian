CLASS.Name = "MERASMUS!"
CLASS.Speed = 100
CLASS.Health = 67500

if CLIENT then
	CLASS.CharacterImage = {
		surface.GetTextureID(""),
		surface.GetTextureID("")
	}
	CLASS.ScoreboardImage = {
		surface.GetTextureID(""),
		surface.GetTextureID("")
	}
end

CLASS.Loadout = {"Staff", "tf_weapon_merasmus_staff"}
CLASS.DefaultLoadout = {"Staff", "tf_weapon_merasmus_staff", "tf_weapon_smg"}
CLASS.ModelName = "sniper"

CLASS.Gibs = {
}

CLASS.Sounds = {
	paincrticialdeath = {
		Sound("vo/sniper_paincrticialdeath01.wav"),
		Sound("vo/sniper_paincrticialdeath02.wav"),
		Sound("vo/sniper_paincrticialdeath03.wav"),
		Sound("vo/sniper_paincrticialdeath04.wav"),
	},
	painsevere = {
		Sound("vo/sniper_painsevere01.wav"),
		Sound("vo/sniper_painsevere02.wav"),
		Sound("vo/sniper_painsevere03.wav"),
		Sound("vo/sniper_painsevere04.wav"),
	},
	painsharp = {
		Sound("vo/sniper_painsharp01.wav"),
		Sound("vo/sniper_painsharp02.wav"),
		Sound("vo/sniper_painsharp03.wav"),
		Sound("vo/sniper_painsharp04.wav"),
	},
}

CLASS.AmmoMax = {
	[TF_PRIMARY]	= 25,		-- primary
	[TF_SECONDARY]	= 75,		-- secondary
	[TF_METAL]		= 100,		-- metal
	[TF_GRENADES1]	= 1,		-- grenades1
	[TF_GRENADES2]	= 0,		-- grenades2
}
