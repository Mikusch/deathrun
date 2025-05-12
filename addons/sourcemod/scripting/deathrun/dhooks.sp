/**
 * Copyright (C) 2024  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma newdecls required
#pragma semicolon 1

static int g_prevGameType;

static DynamicHook g_CTeamplayRoundBasedRules_BHavePlayers;
static DynamicHook g_CTeamplayRoundBasedRules_RoundRespawn;

void DHooks_Init()
{
	PSM_AddDynamicDetourFromConf("CObjectDispenser::CouldHealTarget(CBaseEntity *)", _, CObjectDispenser_CouldHealTarget_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::GetMaxHealthForBuffing()", _, CTFPlayer_GetMaxHealthForBuffing_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::TeamFortress_CalculateMaxSpeed(bool)", _, CTFPlayer_TeamFortress_CalculateMaxSpeed_Post);
	PSM_AddDynamicDetourFromConf("CTFPlayer::RegenThink()", CTFPlayer_RegenThink_Pre);
	PSM_AddDynamicDetourFromConf("CTeamplayRoundBasedRules::SetInWaitingForPlayers(bool)", CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre, CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post);
	
	g_CTeamplayRoundBasedRules_BHavePlayers = PSM_AddDynamicHookFromConf("CTeamplayRoundBasedRules::BHavePlayers()");
	g_CTeamplayRoundBasedRules_RoundRespawn = PSM_AddDynamicHookFromConf("CTeamplayRoundBasedRules::RoundRespawn()");
}

void DHooks_OnMapStart()
{
	PSM_DHookGameRules(g_CTeamplayRoundBasedRules_BHavePlayers, Hook_Pre, CTeamplayRoundBasedRules_BHavePlayers_Pre);
	PSM_DHookGameRules(g_CTeamplayRoundBasedRules_RoundRespawn, Hook_Pre, CTeamplayRoundBasedRules_RoundRespawn_Pre);
}

static MRESReturn CObjectDispenser_CouldHealTarget_Post(int dispenser, DHookReturn ret, DHookParam params)
{
	if (!ret.Value)
		return MRES_Ignored;
	
	if (GetEntProp(dispenser, Prop_Send, "m_bWasMapPlaced"))
		return MRES_Ignored;
	
	int mode = dr_allow_dispenser_heal.IntValue;
	if (mode == 0)
		return MRES_Supercede;
	
	int target = params.Get(1);
	
	// Prevent dispenser healing while in hurt trigger or submerged
	ret.Value = mode == -1 && !IsInTriggerHurt(target) && GetEntProp(target, Prop_Data, "m_nWaterLevel") < WL_Eyes;
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
		
		maxhealth += RoundFloat(DRPlayer(client).GetMaxHealth() * dr_activator_health_modifier.FloatValue);
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
	ret.Value = speed + dr_speed_modifier[class].FloatValue;
	return MRES_Supercede;
}

static MRESReturn CTFPlayer_RegenThink_Pre(int player)
{
	return dr_disable_regen.BoolValue ? MRES_Supercede : MRES_Ignored;
}

static MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Pre(DHookParam params)
{
	g_prevGameType = GameRules_GetProp("m_nGameType");
	GameRules_SetProp("m_nGameType", 0);
	
	bool bWaitingForPlayers = params.Get(1);
	
	if (bWaitingForPlayers)
		GameRules_SetPropFloat("m_flRestartRoundTime", -1.0);
	
	return MRES_Handled;
}

static MRESReturn CTeamplayRoundBasedRules_SetInWaitingForPlayers_Post(DHookParam params)
{
	GameRules_SetProp("m_nGameType", g_prevGameType);
	
	return MRES_Handled;
}

static MRESReturn CTeamplayRoundBasedRules_BHavePlayers_Pre(DHookReturn ret)
{
	int totalPlayers = 0;
	
	for (int client = 1; client < MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		totalPlayers++;
	}
	
	if (dr_activator_count.IntValue >= totalPlayers || Queue_GetPlayersInQueue() < dr_activator_count.IntValue)
	{
		ret.Value = false;
		return MRES_Supercede;
	}
	
	ret.Value = true;
	return MRES_Supercede;
}

// RoundRespawn will restart waiting for players if any team has no players in it.
// This was easily triggered by players leaving the activator team, so we have to choose a new one before that logic runs.
static MRESReturn CTeamplayRoundBasedRules_RoundRespawn_Pre()
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return MRES_Ignored;
	
	Queue_SelectNextActivators();
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		TF2_ChangeClientTeamAlive(client, DRPlayer(client).IsActivator() ? TFTeam_Activators : TFTeam_Runners);
	}
	
	return MRES_Ignored;
}
