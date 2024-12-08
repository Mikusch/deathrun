#pragma newdecls required
#pragma semicolon 1

void Events_Init()
{
	PSM_AddEventHook("arena_round_start", OnGameEvent_arena_round_start);
	PSM_AddEventHook("arena_win_panel", OnGameEvent_arena_win_panel);
	PSM_AddEventHook("post_inventory_application", OnGameEvent_post_inventory_application);
	PSM_AddEventHook("player_spawn", OnGameEvent_player_spawn);
	PSM_AddEventHook("player_death", OnGameEvent_player_death);
}

static void OnGameEvent_arena_round_start(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (DRPlayer(client).IsActivator())
		{
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "Selected As Activator");
			
			if (!DRPlayer(client).HasPreference(Preference_DisableActivatorSpeedBoost))
				TF2_AddCondition(client, TFCond_SpeedBuffAlly);
		}
		else
		{
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "Selected As Runner");
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
