/*
 * Copyright (C) 2020  Mikusch
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

static DynamicHook g_DHookSetWinningTeam;

void DHooks_Init(GameData gamedata)
{
	g_DHookSetWinningTeam = DHooks_CreateVirtualHook(gamedata, "CTeamplayRoundBasedRules::SetWinningTeam");
	
	DHooks_CreateDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", _, DHookCallback_CalculateMaxSpeed_Post);
	DHooks_CreateDetour(gamedata, "CTFPlayer::GetMaxHealthForBuffing", _, DHookCallback_GetMaxHealthForBuffing_Post);
}

static DynamicHook DHooks_CreateVirtualHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create virtual hook: %s", name);
	
	return hook;
}

static void DHooks_CreateDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
}

void DHooks_HookGamerules()
{
	g_DHookSetWinningTeam.HookGamerules(Hook_Pre, DHook_SetWinningTeam_Pre);
}

public MRESReturn DHook_SetWinningTeam_Pre(DHookParam param)
{
	int winReason = param.Get(2);
	
	//The arena timer has no assigned targetname and doesn't fire its OnFinished output before the round ends, making this the only way to detect the timer stalemate
	if (FindConVar("tf_arena_round_time").IntValue > 0 && winReason == WINREASON_STALEMATE && GetAliveClientCount() > 0)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
			{
				if (g_CurrentActivators.Length == 1)
					SDKHooks_TakeDamage(client, g_CurrentActivators.Get(0), 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
				else
					SDKHooks_TakeDamage(client, 0, 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
			}
		}
		
		EmitGameSoundToAll(GAMESOUND_EXPLOSION);
		
		param.Set(1, TFTeam_Activators);	//team
		param.Set(2, WINREASON_TIMELIMIT);	//iWinReason
		return MRES_ChangedOverride;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_CalculateMaxSpeed_Post(int client, DHookReturn ret)
{
	if (GameRules_GetRoundState() != RoundState_Preround && IsClientInGame(client))
	{
		//Modify player speed based on their class
		TFClassType class = TF2_GetPlayerClass(client);
		if (class != TFClass_Unknown)
		{
			float speed = ret.Value;
			float modifier = dr_speed_modifier[0].FloatValue + dr_speed_modifier[class].FloatValue;
			ret.Value = Max(speed + modifier, 1.0);
			
			return MRES_Supercede;
		}
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_GetMaxHealthForBuffing_Post(int client, DHookReturn ret)
{
	if (DRPlayer(client).IsActivator())
	{
		int maxhealth = ret.Value;
		
		for (int i = 1; i <= MaxClients; i++)
		{
			if (client != i && IsValidClient(i) && IsPlayerAlive(i) && !DRPlayer(i).IsActivator())
				maxhealth += RoundFloat(TF2_GetMaxHealth(i) * dr_activator_health_modifier.FloatValue);
		}
		
		maxhealth /= g_CurrentActivators.Length;
		
		// Refill the activator's health during preround
		if (GameRules_GetRoundState() == RoundState_Preround)
			SetEntityHealth(client, maxhealth);
		
		ret.Value = maxhealth;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}
