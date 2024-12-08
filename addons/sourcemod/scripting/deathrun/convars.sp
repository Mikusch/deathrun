#pragma newdecls required
#pragma semicolon 1

void ConVars_Init()
{
	CreateConVar("sm_dr_version", PLUGIN_VERSION, "The plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	CreateConVar("sm_dr_enabled", "1", "Whether to enable the plugin.");
	
	sm_dr_queue_points = CreateConVar("sm_dr_queue_points", "5", "Amount of queue points being given to runners every round.");
	sm_dr_speed_modifier[TFClass_Scout] = CreateConVar("sm_dr_speed_modifier_scout", "-80", "Value to add to Scout's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Sniper] = CreateConVar("sm_dr_speed_modifier_sniper", "0", "Value to add to Sniper's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Soldier] = CreateConVar("sm_dr_speed_modifier_soldier", "0", "Value to add to Soldier's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_DemoMan] = CreateConVar("sm_dr_speed_modifier_demoman", "0", "Value to add to Demoman's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Medic] = CreateConVar("sm_dr_speed_modifier_medic", "0", "Value to add to Medic's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Heavy] = CreateConVar("sm_dr_speed_modifier_heavy", "10", "Value to add to Heavy's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Pyro] = CreateConVar("sm_dr_speed_modifier_pyro", "0", "Value to add to Pyro's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Spy] = CreateConVar("sm_dr_speed_modifier_spy", "0", "Value to add to Spy's maximum speed, in HU/s.");
	sm_dr_speed_modifier[TFClass_Engineer] = CreateConVar("sm_dr_speed_modifier_engineer", "0", "Value to add to Engineer's maximum speed, in HU/s.");
	sm_dr_runner_backstab_damage = CreateConVar("sm_dr_runner_backstab_damage", "750", "Damage dealt to the activator by backstabs. Set to 0 to use the default damage calculation.", _, true, 0.0);
	sm_dr_runner_allow_button_damage = CreateConVar("sm_dr_runner_allow_button_damage", "1", "Whether runners are allowed to damage buttons with ranged weapons.");
	sm_dr_runner_glow = CreateConVar("sm_dr_runner_glow", "0", "Whether runners should have a glowing outline.");
	sm_dr_activator_speed_buff = CreateConVar("sm_dr_activator_speed_buff", "1", "Whether activators should have a speed buff effect.");
	sm_dr_activator_count = CreateConVar("sm_dr_activator_count", "1", "Amount of activators.", _, true, 1.0);
	sm_dr_activator_health_modifier = CreateConVar("sm_dr_activator_health_modifier", "1.0", "Percentage of health the activator gains from every runner.", _, true, 0.0);
	sm_dr_activator_allow_healthkits = CreateConVar("sm_dr_activator_allow_healthkits", "0", "Whether the activator is allowed to pick up health kits.");
	sm_dr_disable_regen = CreateConVar("sm_dr_disable_regen", "1", "Whether to disable passive health regeneration.");
	sm_dr_allow_teleporters = CreateConVar("sm_dr_allow_teleporters", "0", "Whether to allow players to use player-built teleporters.");
	sm_dr_chat_hint_interval = CreateConVar("sm_dr_chat_hint_interval", "240", "Time between chat hints, in seconds.", _, true, 0.0);
	
	PSM_AddEnforcedConVar("mp_autoteambalance", "0");
	PSM_AddEnforcedConVar("mp_teams_unbalance_limit", "0");
	PSM_AddEnforcedConVar("tf_arena_first_blood", "0");
	PSM_AddEnforcedConVar("tf_arena_use_queue", "0");
	PSM_AddEnforcedConVar("tf_avoidteammates_pushaway", "0");
	PSM_AddEnforcedConVar("tf_scout_air_dash_count", "0");
	PSM_AddEnforcedConVar("tf_solidobjects", "0");
}

void ConVars_OnPluginStateChanged(bool enabled)
{
	if (enabled)
	{
		sm_dr_activator_speed_buff.AddChangeHook(OnConVarChanged_ActivatorSpeedBuff);
		sm_dr_runner_glow.AddChangeHook(OnConVarChanged_RunnerGlow);
		sm_dr_chat_hint_interval.AddChangeHook(OnConVarChanged_ChatHintInterval);
	}
	else
	{
		sm_dr_activator_speed_buff.RemoveChangeHook(OnConVarChanged_ActivatorSpeedBuff);
		sm_dr_runner_glow.RemoveChangeHook(OnConVarChanged_RunnerGlow);
		sm_dr_chat_hint_interval.RemoveChangeHook(OnConVarChanged_ChatHintInterval);
	}
}

static void OnConVarChanged_ActivatorSpeedBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		DRPlayer(client).OnPreferencesChanged(Preference_DisableActivatorSpeedBuff);
	}
}

static void OnConVarChanged_RunnerGlow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (DRPlayer(client).IsActivator())
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", convar.BoolValue);
	}
}

static void OnConVarChanged_ChatHintInterval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_chatHintTimer = CreateChatHintTimer(convar.FloatValue);
}
