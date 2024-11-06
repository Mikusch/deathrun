#pragma newdecls required
#pragma semicolon 1

void Events_Init()
{
	PSM_AddEventHook("teamplay_round_start", OnGameEvent_teamplay_round_start);
	PSM_AddEventHook("arena_round_start", OnGameEvent_arena_round_start);
	PSM_AddEventHook("arena_win_panel", OnGameEvent_arena_win_panel);
	PSM_AddEventHook("post_inventory_application", OnGameEvent_post_inventory_application);
	PSM_AddEventHook("player_spawn", OnGameEvent_player_spawn);
	PSM_AddEventHook("player_death", OnGameEvent_player_death);
}

static Action OnGameEvent_teamplay_round_start(Event event, const char[] name, bool dontBroadcast)
{
	if (GameRules_GetProp("m_bInWaitingForPlayers"))
		return Plugin_Continue;
	
	// Arena has very dumb logic, if all players from a team leave the round will end and then restart without resetting the game state
	// Catch that issue and don't run our logic!
	int red, blue;
	for (int client = 1; client <= MaxClients; ++client)
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
	
	// Both teams must have at least one player
	if (red == 0 || blue == 0)
	{
		if (red + blue >= 2)	// If we have atleast 2 players in red or blue, force one person to the other team and try again
		{
			for (int client = 1; client <= MaxClients; ++client)
			{
				if (IsClientInGame(client))
				{
					// Once we found someone who is in red or blue, swap their team
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
		
		// If we reach this part, either nobody is in the server or everyone is spectating
		return Plugin_Continue;
	}
	
	// New round has begun
	SetNextActivatorsFromQueue();
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		// Put every non-activator in the runners team
		TF2_ChangeClientTeamAlive(client, DRPlayer(client).IsActivator() ? TFTeam_Activators : TFTeam_Runners);
	}
	
	return Plugin_Continue;
}

static void OnGameEvent_arena_round_start(Event event, const char[] name, bool dontBroadcast)
{
	if (sm_dr_activator_speed_buff.BoolValue)
	{
		for (int client = 1; client <= MaxClients; ++client)
		{
			if (!IsClientInGame(client))
				continue;
			
			if (!DRPlayer(client).IsActivator())
				continue;
			
			TF2_AddCondition(client, TFCond_SpeedBuffAlly);
		}
	}
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		switch (TF2_GetClientTeam(client))
		{
			case TFTeam_Runners:
			{
				CPrintToChat(client, "%s %t", PLUGIN_TAG, "Selected As Runner");
			}
			case TFTeam_Activators:
			{
				CPrintToChat(client, "%s %t", PLUGIN_TAG, "Selected As Activator");
			}
		}
	}
}

static void OnGameEvent_arena_win_panel(Event event, const char[] name, bool dontBroadcast)
{
	int points = sm_dr_queue_points.IntValue;
	
	// Award queue points
	ArrayList queue = Queue_GetQueueList();
	for (int i = 0; i < queue.Length; ++i)
	{
		int client = queue.Get(i, QueueData::client);
		DRPlayer(client).AddQueuePoints(points);
		
		CPrintToChat(client, "%s %t", PLUGIN_TAG, "Queue Points Earned", points, DRPlayer(client).QueuePoints);
	}
	delete queue;
}

static void OnGameEvent_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(Config_ApplyItemAttributes, event.GetInt("userid"));
}

static void OnGameEvent_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0)
		return;
	
	if (!DRPlayer(client).IsActivator() && sm_dr_runner_glow.BoolValue)
	{
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", true);
	}
	
	// We already refill health during preround (see GetMaxHealthForBuffing)
	if (GameRules_GetRoundState() != RoundState_Preround)
	{
		for (int i = 0; i < g_currentActivators.Length; ++i)
		{
			int activator = g_currentActivators.Get(i);
			
			int healthToAdd = TF2_GetPlayerMaxHealth(client) / g_currentActivators.Length;
			SetEntityHealth(activator, TF2_GetPlayerMaxHealth(activator) + healthToAdd);
		}
	}
}

static Action OnGameEvent_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (victim == 0)
		return Plugin_Continue;
	
	if (GameRules_GetRoundState() == RoundState_Stalemate)
		return Plugin_Continue;
	
	if (!DRPlayer(victim).IsActivator() && g_currentActivators.Length == 1)
	{
		int activator = g_currentActivators.Get(0);
		event.SetInt("attacker", GetClientUserId(activator));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
