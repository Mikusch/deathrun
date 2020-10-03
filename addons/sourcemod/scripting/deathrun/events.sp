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
	int numActivators;
	
	//Calculate max health to grant to activators
	int maxHealth;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
			maxHealth += TF2_GetMaxHealth(client);
	}
	
	//Iterate all chosen activators and check if they are still in-game
	for (int i = 0; i < g_CurrentActivators.Length; i++)
	{
		int activator = g_CurrentActivators.Get(i);
		if (IsClientInGame(activator))
		{
			TF2Attrib_SetByName(activator, "max health additive bonus", float(maxHealth) / dr_num_activators.FloatValue);
			SetEntityHealth(activator, TF2_GetMaxHealth(activator) + maxHealth / dr_num_activators.IntValue);
			
			numActivators++;
		}
	}
	
	if (numActivators > 1) //Multiple activators
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (DRPlayer(client).IsActivator())
					PrintMessage(client, "%t", "RoundStart_MultipleActivators_Activator");
				else
					PrintMessage(client, "%t", "RoundStart_MultipleActivators_Runners");
			}
		}
	}
	else if (numActivators < 1) //No activators
	{
		PrintMessageToAll("%t", "RoundStart_Activator_Disconnected", FindConVar("tf_bonusroundtime").IntValue);
	}
	else //One activator
	{
		int activator = g_CurrentActivators.Get(0); //Should be safe
		char activatorName[MAX_NAME_LENGTH];
		GetClientName(activator, activatorName, sizeof(activatorName));
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (client == activator)
					PrintMessage(client, "%t", "RoundStart_NewActivator_Activator");
				else
					PrintMessage(client, "%t", "RoundStart_NewActivator_Runners", activatorName);
			}
		}
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).IsActivator())
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", dr_runner_glow.BoolValue);
	}
}

public Action EventHook_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	if (GameRules_GetRoundState() == RoundState_Stalemate && !DRPlayer(victim).IsActivator())
	{
		UpdateActivatorHealth(-TF2_GetMaxHealth(victim), false);
		
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
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
	Config_Apply(client);
	
	//If this is a latespawn, give the activator health
	if (GameRules_GetRoundState() == RoundState_Stalemate && !DRPlayer(client).IsActivator())
		CreateTimer(0.2, Timer_UpdateActivatorHealth, userid);
	
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
				case TFTeam_Runners: red++;
				case TFTeam_Activators: blue++;
			}
		}
	}
	
	//Both teams must have at least one player
	if (red == 0 || blue == 0)
	{
		if (red + blue >= 2) //If we have atleast 2 players in red or blue, force one person to the other team and try again
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
						return;
					}
					else if (team == TFTeam_Activators)
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
	Queue_SetNextActivatorsFromQueue();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		//Put every non-activators in the runners team
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator && !DRPlayer(client).IsActivator())
			TF2_ChangeClientTeamAlive(client, TFTeam_Runners);
	}
}

public Action EventHook_TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		DRPlayer player = DRPlayer(client);
		if (IsClientInGame(client))
		{
			if (team == TFTeam_Activators)
				PrintMessage(client, "%t", "RoundWin_Activator");
			else if (team == TFTeam_Runners)
				PrintMessage(client, "%t", "RoundWin_Runners");
			
			if (player.IsActivator())
				TF2Attrib_RemoveByName(client, "max health additive bonus");
			else if (TF2_GetClientTeam(client) != TFTeam_Spectator)
				Queue_AddPoints(client, dr_queue_points.IntValue);
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
			if (team == TFTeam_Runners) //Check if player is in the runner team, if so put them back to the activator team
			{
				TF2_ChangeClientTeam(client, TFTeam_Activators);
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (team == TFTeam_Activators) //Check if player is in the activator team, if so put them back to the runner team
			{
				TF2_ChangeClientTeam(client, TFTeam_Runners);
				TF2_RespawnPlayer(client);
			}
		}
	}
}

public Action Timer_UpdateActivatorHealth(Handle timer, int userid)
{
	UpdateActivatorHealth(TF2_GetMaxHealth(GetClientOfUserId(userid)), true);
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
