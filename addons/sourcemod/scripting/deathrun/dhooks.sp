#pragma newdecls required
#pragma semicolon 1

static int g_prevGameType;

void DHooks_Init()
{
	PSM_AddDynamicDetourFromConf("CObjectDispenser::CouldHealTarget(CBaseEntity *)", _, CObjectDispenser_CouldHealTarget_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::GetMaxHealthForBuffing()", _, CTFPlayer_GetMaxHealthForBuffing_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::TeamFortress_CalculateMaxSpeed(bool)", _, CTFPlayer_TeamFortress_CalculateMaxSpeed_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::RegenThink()", CTFPlayer_RegenThink_Pre);
	PSM_AddDynamicDetourFromConf("CTeamplayRoundBasedRules::SetInWaitingForPlayers(bool)", CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post);
}

static MRESReturn CObjectDispenser_CouldHealTarget_Post(int dispenser, DHookReturn ret, DHookParam params)
{
	if (!ret.Value)
		return MRES_Ignored;
	
	if (GetEntProp(dispenser, Prop_Send, "m_bWasMapPlaced"))
		return MRES_Ignored;
	
	int target = params.Get(1);
	
	// Prevent dispenser healing while in hurt trigger or submerged
	ret.Value = !IsInTriggerHurt(target) && GetEntProp(target, Prop_Data, "m_nWaterLevel") < WL_Eyes;
	return MRES_Supercede;
}

static MRESReturn CTFPlayer_GetMaxHealthForBuffing_Post(int player, DHookReturn ret)
{
	if (!DRPlayer(player).IsActivator())
		return MRES_Ignored;
	
	int maxhealth = ret.Value;
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		if (DRPlayer(client).IsActivator())
			continue;
		
		maxhealth += RoundFloat(TF2_GetPlayerMaxHealth(client) * sm_dr_activator_health_modifier.FloatValue);
	}
	
	maxhealth /= g_currentActivators.Length;
	
	// Refill the activator's health during preround
	if (GameRules_GetRoundState() == RoundState_Preround)
		SetEntityHealth(player, maxhealth);
	
	ret.Value = maxhealth;
	return MRES_Supercede;
}

static MRESReturn CTFPlayer_TeamFortress_CalculateMaxSpeed_Post(int player, DHookReturn ret, DHookParam params)
{
	if (!IsPlayerAlive(player))
		return MRES_Ignored;
	
	TFClassType class = TF2_GetPlayerClass(player);
	if (class == TFClass_Unknown)
		return MRES_Ignored;
	
	float speed = ret.Value;
	
	if (speed <= 1.0)
		return MRES_Ignored;
	
	// FIXME: Figure out a way to add this to the base speed, instead of calculated speed
	ret.Value = speed + sm_dr_speed_modifier[class].FloatValue;
	return MRES_Supercede;
}

static MRESReturn CTFPlayer_RegenThink_Pre(int player)
{
	return sm_dr_disable_regen.BoolValue ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre(DHookParam params)
{
	if (!sm_dr_waiting_for_players.BoolValue)
		return MRES_Ignored;
	
	g_prevGameType = GameRules_GetProp("m_nGameType");
	GameRules_SetProp("m_nGameType", 0);
	
	bool bWaitingForPlayers = params.Get(1);
	
	if (bWaitingForPlayers)
		GameRules_SetPropFloat("m_flRestartRoundTime", -1.0);
	
	return MRES_Handled;
}

static MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post(DHookParam params)
{
	if (!sm_dr_waiting_for_players.BoolValue)
		return MRES_Ignored;
	
	GameRules_SetProp("m_nGameType", g_prevGameType);
	
	return MRES_Handled;
}
