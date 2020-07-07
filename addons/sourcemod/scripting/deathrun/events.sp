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
	int activator = GetActivator();
	
	if (IsClientInGame(activator))
	{
		char activatorName[MAX_NAME_LENGTH];
		GetClientName(activator, activatorName, sizeof(activatorName));
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (DRPlayer(client).IsActivator())
				{
					PrintMessage(client, "%t", "RoundStart_NewActivator_Activator");
				}
				else
				{
					PrintMessage(client, "%t", "RoundStart_NewActivator_Runners", activatorName);
					SetEntProp(client, Prop_Send, "m_bGlowEnabled", dr_runner_glow.BoolValue);
				}
			}
		}
		
		TF2Attrib_SetByName(activator, "max health additive bonus", 1000.0 - TF2_GetMaxHealth(activator));
		SetEntityHealth(activator, 1000);
	}
	else
	{
		PrintMessageToAll("%t", "RoundStart_Activator_Disconnected", FindConVar("tf_bonusroundtime").IntValue);
	}
}

public Action EventHook_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int activator = GetActivator();
	
	if (GameRules_GetRoundState() == RoundState_Stalemate && IsValidClient(activator) && victim != activator)
	{
		event.SetInt("attacker", GetClientUserId(activator));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action EventHook_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	Config_Apply(client);
	
	if (DRPlayer(client).InThirdPerson)
		CreateTimer(0.2, Timer_SetThirdPerson, userid);
	
	RequestFrame(RequestFrameCallback_VerifyTeam, userid);
}

public Action EventHook_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Arena has a very dumb logic, if all players from a team leave the round will end and then restart without reseting the game state
	//Catch that issue and don't run our logic!
	int red, blue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			switch (TF2_GetClientTeam(client))
			{
				case TFTeam_Runners:red++;
				case TFTeam_Activator:blue++;
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
						TF2_ChangeClientTeamAlive(client, TFTeam_Activator);
						return;
					}
					else if (team == TFTeam_Activator)
					{
						TF2_ChangeClientTeamAlive(client, TFTeam_Runners);
						return;
					}
				}
			}
		}
		//If we reach this part, either nobody is in the server or everyone is spectating
		return;
	}
	
	//New round has begun
	for (int client = 1; client <= MaxClients; client++)
	{
		//Put every player in the same team and pick the activator later
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
			TF2_ChangeClientTeamAlive(client, TFTeam_Runners);
	}
	
	Queue_SetNextActivator();
}

public Action EventHook_TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		DRPlayer player = DRPlayer(client);
		if (IsClientInGame(client))
		{
			if (team == TFTeam_Activator)
				PrintMessage(client, "%t", "RoundWin_Activator");
			else if (team == TFTeam_Runners)
				PrintMessage(client, "%t", "RoundWin_Runners");
			
			if (player.IsActivator())
			{
				TF2Attrib_RemoveByName(client, "max health additive bonus");
			}
			else
			{
				Queue_AddPoints(client, dr_queue_points.IntValue);
			}
		}
	}
}

public void RequestFrameCallback_VerifyTeam(int userid)
{
	int client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsClientInGame(client))
	{
		TFTeam team = TF2_GetClientTeam(client);
		if (team <= TFTeam_Spectator)return;
		
		if (DRPlayer(client).IsActivator())
		{
			if (team == TFTeam_Runners)	//Check if player is in the runner team, if so put them back to the activator team
			{
				TF2_ChangeClientTeam(client, TFTeam_Activator);
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (team == TFTeam_Activator)	//Check if player is in the activator team, if so put them back to the runner team
			{
				TF2_ChangeClientTeam(client, TFTeam_Runners);
				TF2_RespawnPlayer(client);
			}
		}
	}
}

public Action Timer_SetThirdPerson(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (DRPlayer(client).InThirdPerson)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}
