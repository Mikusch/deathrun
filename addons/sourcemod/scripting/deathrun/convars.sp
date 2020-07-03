enum struct ConVarInfo
{
	ConVar convar;
	float value;
	float defaultValue;
	bool enforce;
}

static ArrayList ConVars;

void ConVars_Init()
{
	CreateConVar("dr_version", PLUGIN_VERSION, "Plugin version");
	dr_queue_points = CreateConVar("dr_queue_points", "15", "Amount of queue points awarded to clients at the end of each round.");
	dr_allow_thirdperson = CreateConVar("dr_allow_thirdperson", "1", "Whether thirdperson mode may be toggled by clients. Set to 0 if you use other thirdperson plugins that may conflict.");
	dr_chattips_interval = CreateConVar("dr_chattips_interval", "240", "How often in seconds chat tips should be shown to clients. Set to 0 to disable chat tips.");
	dr_runner_glow = CreateConVar("dr_runner_glow", "0", "Whether runners should have an outline.");
	
	HookConVarChange(dr_allow_thirdperson, OnAllowThirdpersonChanged);
	HookConVarChange(dr_runner_glow, OnRunnerGlowChanged);
	
	ConVars = new ArrayList(sizeof(ConVarInfo));
	
	ConVars_Add("mp_autoteambalance", 0.0);
	ConVars_Add("mp_teams_unbalance_limit", 0.0);
	ConVars_Add("tf_arena_first_blood", 0.0);
	ConVars_Add("tf_arena_use_queue", 0.0);
	ConVars_Add("tf_avoidteammates_pushaway", 0.0);
	ConVars_Add("tf_scout_air_dash_count", 0.0);
}

void ConVars_Add(const char[] name, float value, bool enforce = true)
{
	ConVarInfo info;
	info.convar = FindConVar(name);
	info.value = value;
	info.enforce = enforce;
	ConVars.PushArray(info);
}

void ConVars_Enable()
{
	for (int i = 0; i < ConVars.Length; i++)
	{
		ConVarInfo info;
		ConVars.GetArray(i, info);
		info.defaultValue = info.convar.FloatValue;
		ConVars.SetArray(i, info);
		
		info.convar.SetFloat(info.value);
		info.convar.AddChangeHook(ConVars_OnChanged);
	}
}

void ConVars_Disable()
{
	for (int i = 0; i < ConVars.Length; i++)
	{
		ConVarInfo info;
		ConVars.GetArray(i, info);
		
		info.convar.RemoveChangeHook(ConVars_OnChanged);
		info.convar.SetFloat(info.defaultValue);
	}
}

void OnAllowThirdpersonChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StringToInt(newValue))
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && DRPlayer(client).InThirdPerson)
			{
				DRPlayer(client).InThirdPerson = false;
				SetVariantInt(0);
				AcceptEntityInput(client, "SetForcedTauntCam");
				PrintMessage(client, "%T", "Thirdperson_ForceDisable", LANG_SERVER);
			}
		}
	}
}

void OnRunnerGlowChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", StringToInt(newValue));
	}
}

void ConVars_OnChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int index = ConVars.FindValue(convar, ConVarInfo::convar);
	if (index != -1)
	{
		ConVarInfo info;
		ConVars.GetArray(index, info);
		float value = StringToFloat(newValue);
		
		if (info.enforce && value != info.value)
			info.convar.SetFloat(info.value);
	}
}
