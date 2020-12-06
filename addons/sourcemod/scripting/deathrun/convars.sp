enum struct ConVarInfo
{
	ConVar convar;
	float value;
	float defaultValue;
	bool enforce;
}

static ArrayList g_GameConVars;

void ConVars_Init()
{
	CreateConVar("dr_version", PLUGIN_VERSION, "Plugin version");
	dr_queue_points = CreateConVar("dr_queue_points", "15", "Amount of queue points awarded to clients at the end of each round.", _, true, 1.0);
	dr_allow_thirdperson = CreateConVar("dr_allow_thirdperson", "1", "Whether thirdperson mode may be toggled by clients. Set to 0 if you use other thirdperson plugins that may conflict.");
	dr_chattips_interval = CreateConVar("dr_chattips_interval", "240", "How often in seconds chat tips should be shown to clients. Set to 0 to disable chat tips.");
	dr_runner_glow = CreateConVar("dr_runner_glow", "0", "Whether runners should have a glowing outline.");
	dr_num_activators = CreateConVar("dr_num_activators", "1", "Amount of activators chosen at the start of a round.", _, true, 1.0, true, float(MaxClients - 1));
	
	HookConVarChange(dr_allow_thirdperson, ConVarChanged_AllowThirdPerson);
	HookConVarChange(dr_runner_glow, ConVarChanged_RunnerGlow);
	
	g_GameConVars = new ArrayList(sizeof(ConVarInfo));
	
	ConVars_Add("mp_autoteambalance", 0.0);
	ConVars_Add("mp_teams_unbalance_limit", 0.0);
	ConVars_Add("tf_arena_first_blood", 0.0);
	ConVars_Add("tf_arena_use_queue", 0.0);
	ConVars_Add("tf_avoidteammates_pushaway", 0.0);
	ConVars_Add("tf_scout_air_dash_count", 0.0, false);
	ConVars_Add("tf_spy_cloak_regen_rate", 0.0, false);
	ConVars_Add("tf_demoman_charge_regen_rate", 0.0, false);
	ConVars_Add("tf_spy_cloak_consume_rate", 25.0, false);
}

void ConVars_Add(const char[] name, float value, bool enforce = true)
{
	ConVarInfo info;
	info.convar = FindConVar(name);
	info.value = value;
	info.enforce = enforce;
	g_GameConVars.PushArray(info);
}

void ConVars_Enable()
{
	for (int i = 0; i < g_GameConVars.Length; i++)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(i, info);
		info.defaultValue = info.convar.FloatValue;
		g_GameConVars.SetArray(i, info);
		
		info.convar.SetFloat(info.value);
		
		if (info.enforce)
			info.convar.AddChangeHook(ConVarChanged_GameConVar);
	}
}

void ConVars_Disable()
{
	for (int i = 0; i < g_GameConVars.Length; i++)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(i, info);
		
		if (info.enforce)
			info.convar.RemoveChangeHook(ConVarChanged_GameConVar);
		
		info.convar.SetFloat(info.defaultValue);
	}
}

public void ConVarChanged_GameConVar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int index = g_GameConVars.FindValue(convar, ConVarInfo::convar);
	if (index != -1)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(index, info);
		float value = StringToFloat(newValue);
		
		if (value != info.value)
			info.convar.SetFloat(info.value);
	}
}

public void ConVarChanged_AllowThirdPerson(ConVar convar, const char[] oldValue, const char[] newValue)
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
				PrintMessage(client, "%t", "Thirdperson_ForceDisable");
			}
		}
	}
}

public void ConVarChanged_RunnerGlow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).IsActivator())
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", StringToInt(newValue));
	}
}
