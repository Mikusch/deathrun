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

void Events_Init()
{
	HookEvent("arena_round_start", EventHook_ArenaRoundStart);
	HookEvent("player_death", EventHook_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("post_inventory_application", EventHook_PostInventoryApplication);
	HookEvent("teamplay_round_start", EventHook_TeamplayRoundStart);
	HookEvent("teamplay_round_win", EventHook_TeamplayRoundWin);
}

public Action EventHook_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Enabled) return Plugin_Continue;
	
	int numActivators;
	
	//Iterate all chosen activators and check if they are still in-game
	for (int i = 0; i < g_CurrentActivators.Length; i++)
	{
		int activator = g_CurrentActivators.Get(i);
		if (IsClientInGame(activator))
			numActivators++;
	}
	
	if (numActivators > 1)	//Multiple activators
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (DRPlayer(client).IsActivator())
					CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundStart_MultipleActivators_Activator");
				else
					CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundStart_MultipleActivators_Runners");
			}
		}
	}
	else if (numActivators < 1)	//No activators
	{
		CPrintToChatAll(PLUGIN_TAG ... " %t", "RoundStart_Activator_Disconnected", FindConVar("mp_bonusroundtime").IntValue);
	}
	else	//One activator
	{
		int activator = g_CurrentActivators.Get(0); //Should be safe
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (client == activator)
					CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundStart_NewActivator_Activator");
				else
					CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundStart_NewActivator_Runners", activator);
			}
		}
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).IsActivator())
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", dr_runner_glow.BoolValue);
	}
	
	return Plugin_Continue;
}

public Action EventHook_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Enabled) return Plugin_Continue;
	
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if (GameRules_GetRoundState() == RoundState_Stalemate && !DRPlayer(victim).IsActivator())
	{
		//Rewrite death event to credit activator
		if (g_CurrentActivators.Length == 1)
		{
			int activator = g_CurrentActivators.Get(0);
			event.SetInt("attacker", GetClientUserId(activator));
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

public Action EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Enabled) return Plugin_Continue;
	
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	Config_Apply(client);
	
	if (DRPlayer(client).InThirdPerson)
		CreateTimer(0.2, Timer_SetThirdPerson, userid);
	
	RequestFrame(RequestFrameCallback_VerifyTeam, userid);
	
	return Plugin_Continue;
}

public Action EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Enabled) return Plugin_Continue;
	
	//Arena has a very dumb logic, if all players from a team leave the round will end and then restart without reseting the game state
	//Catch that issue and don't run our logic!
	int red, blue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			switch (TF2_GetClientTeam(client))
			{
				case TFTeam_Runners: red++;
				case TFTeam_Activators: blue++;
			}
		}
	}
	
	//Both teams must have at least one player
	if (red == 0 || blue == 0)
	{
		if (red + blue >= 2)	//If we have atleast 2 players in red or blue, force one person to the other team and try again
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					//Once we found someone who is in red or blue, swap their team
					TFTeam team = TF2_GetClientTeam(client);
					if (team == TFTeam_Runners)
					{
						TF2_ChangeClientTeamAlive(client, TFTeam_Activators);
						return Plugin_Continue;
					}
					else if (team == TFTeam_Activators)
					{
						TF2_ChangeClientTeamAlive(client, TFTeam_Runners);
						return Plugin_Continue;
					}
				}
			}
		}
		//If we reach this part, either nobody is in the server or everyone is spectating
		return Plugin_Continue;
	}
	
	//New round has begun
	Queue_SetNextActivatorsFromQueue();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		//Put every non-activators in the runners team
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator && !DRPlayer(client).IsActivator())
			TF2_ChangeClientTeamAlive(client, TFTeam_Runners);
	}
	
	return Plugin_Continue;
}

public Action EventHook_TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_Enabled) return Plugin_Continue;
	
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			if (team == TFTeam_Activators)
				CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundWin_Activator");
			else if (team == TFTeam_Runners)
				CPrintToChat(client, PLUGIN_TAG ... " %t", "RoundWin_Runners");
			
			if (TF2_GetClientTeam(client) == TFTeam_Runners)
				Queue_AwardPoints(client, dr_queue_points.IntValue);
		}
	}
	
	return Plugin_Continue;
}

public void RequestFrameCallback_VerifyTeam(int userid)
{
	if (!g_Enabled) return;
	
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsClientInGame(client))
	{
		TFTeam team = TF2_GetClientTeam(client);
		if (team <= TFTeam_Spectator)return;
		
		if (DRPlayer(client).IsActivator())
		{
			if (team == TFTeam_Runners)	//Check if player is in the runner team, if so put them back to the activator team
			{
				TF2_ChangeClientTeam(client, TFTeam_Activators);
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (team == TFTeam_Activators)	//Check if player is in the activator team, if so put them back to the runner team
			{
				TF2_ChangeClientTeam(client, TFTeam_Runners);
				TF2_RespawnPlayer(client);
			}
		}
	}
}

public Action Timer_SetThirdPerson(Handle timer, int userid)
{
	if (!g_Enabled) return Plugin_Stop;
	
	int client = GetClientOfUserId(userid);
	if (DRPlayer(client).InThirdPerson)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
	
	return Plugin_Stop;
}
