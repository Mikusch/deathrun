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
	ConVars = new ArrayList(sizeof(ConVarInfo));
	
	ConVars_Add("mp_autoteambalance", 0.0);
	ConVars_Add("mp_teams_unbalance_limit", 0.0);
	ConVars_Add("tf_arena_first_blood", 0.0);
	ConVars_Add("tf_arena_use_queue", 0.0);
	ConVars_Add("tf_avoidteammates_pushaway", 0.0);
	ConVars_Add("tf_scout_air_dash_count", 0.0);
}

void ConVars_Add(const char[] name, float value, bool enforce = false)
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
