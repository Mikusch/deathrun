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

void Events_Init()
{
	PSM_AddEventHook("arena_round_start", OnGameEvent_arena_round_start);
	PSM_AddEventHook("arena_win_panel", OnGameEvent_arena_win_panel);
	PSM_AddEventHook("scorestats_accumulated_update", OnGameEvent_scorestats_accumulated_update);
	PSM_AddEventHook("post_inventory_application", OnGameEvent_post_inventory_application);
	PSM_AddEventHook("player_spawn", OnGameEvent_player_spawn);
	PSM_AddEventHook("player_death", OnGameEvent_player_death, EventHookMode_Pre);
	PSM_AddEventHook("player_healed", OnGameEvent_player_healed, EventHookMode_Pre);
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
			
			DRPlayer(client).OnPreferencesChanged(Preference_DisableActivatorSpeedBuff);
		}
		else
		{
			CPrintToChat(client, "%s %t", PLUGIN_TAG, "Selected As Runner");
		}
	}
}

static void OnGameEvent_arena_win_panel(Event event, const char[] name, bool dontBroadcast)
{
	int points = dr_queue_points.IntValue;

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

static void OnGameEvent_scorestats_accumulated_update(Event event, const char[] name, bool dontBroadcast)
{
	SelectActivatorsAndAssignTeams();
}

static void OnGameEvent_post_inventory_application(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(Config_ApplyItemAttributes, event.GetInt("userid"));
}

static void OnGameEvent_player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	RequestFrame(OnPostPlayerSpawn, userid);

	// The game resets m_iMaxHealth during InitClass(), so tracked health must be zeroed here before any RequestFrame callbacks run
	DRPlayer(client).ActivatorHealthBonus = 0;

	if (!DRPlayer(client).IsActivator())
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", dr_runner_glow.BoolValue);
}

static void OnPostPlayerSpawn(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;

	ApplySpeedModifier(client);

	bool preround = GameRules_GetRoundState() == RoundState_Preround;
	RecalculateActivatorHealth(preround);

	// If runner spawned mid-round, add health to activators
	if (!DRPlayer(client).IsActivator() && !preround && g_currentActivators.Length > 0)
	{
		int healthToAdd = RoundFloat(DRPlayer(client).GetMaxHealth() * dr_activator_health_modifier.FloatValue) / g_currentActivators.Length;
		for (int i = 0; i < g_currentActivators.Length; ++i)
		{
			int activator = g_currentActivators.Get(i);
			if (!IsClientInGame(activator) || !IsPlayerAlive(activator))
				continue;

			SetEntityHealth(activator, GetEntProp(activator, Prop_Send, "m_iHealth") + healthToAdd);
		}
	}
}

static Action OnGameEvent_player_death(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));

	// Recalculate activator health when a runner dies.
	// The victim must be excluded because m_lifeState has not been updated yet.
	if (!DRPlayer(victim).IsActivator())
		RecalculateActivatorHealth(.excludeClient = victim);

	if (GameRules_GetRoundState() != RoundState_Stalemate)
		return Plugin_Continue;
	
	if (g_currentActivators.Length == 1)
	{
		int activator = g_currentActivators.Get(0);
		if (victim != activator && IsPlayerAlive(activator))
		{
			event.SetInt("attacker", GetClientUserId(activator));
		}
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

// https://developer.valvesoftware.com/wiki/Team_Fortress_2/Scripting/VScript_Examples#Disabling_Medic_health_regen
static Action OnGameEvent_player_healed(Event event, const char[] name, bool dontBroadcast)
{
	int patient = event.GetInt("patient");
	int healer = event.GetInt("healer");
	int amount = event.GetInt("amount");

	if (dr_disable_regen.BoolValue && patient == healer)
	{
		int player = GetClientOfUserId(patient);
		if (TF2_GetPlayerClass(player) == TFClass_Medic)
		{
			SetEntityHealth(player, GetEntProp(player, Prop_Data, "m_iHealth") - amount);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

void RecalculateActivatorHealth(bool refillHealth = false, int excludeClient = 0)
{
	if (g_currentActivators.Length == 0)
		return;

	int totalRunnerHealth = 0;
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (client == excludeClient)
			continue;

		if (!IsClientInGame(client))
			continue;

		if (!IsPlayerAlive(client))
			continue;

		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;

		if (DRPlayer(client).IsActivator())
			continue;

		totalRunnerHealth += RoundFloat(DRPlayer(client).GetMaxHealth() * dr_activator_health_modifier.FloatValue);
	}

	int bonusPerActivator = totalRunnerHealth / g_currentActivators.Length;

	for (int i = 0; i < g_currentActivators.Length; ++i)
	{
		int activator = g_currentActivators.Get(i);
		if (!IsClientInGame(activator) || !IsPlayerAlive(activator))
			continue;

		int oldBonus = DRPlayer(activator).ActivatorHealthBonus;
		int oldMaxHealth = GetEntProp(activator, Prop_Data, "m_iMaxHealth");
		int newMaxHealth = oldMaxHealth - oldBonus + bonusPerActivator;
		SetEntProp(activator, Prop_Data, "m_iMaxHealth", newMaxHealth);

		DRPlayer(activator).ActivatorHealthBonus = bonusPerActivator;

		if (bonusPerActivator > 0)
			RunScriptCode(activator, -1, -1, "self.AddCustomAttribute(\"max health additive bonus\", %d, 0)", bonusPerActivator);
		else
			RunScriptCode(activator, -1, -1, "self.RemoveCustomAttribute(\"max health additive bonus\")");

		if (refillHealth)
			SetEntityHealth(activator, newMaxHealth);
	}
}

void ApplySpeedModifier(int client)
{
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Unknown)
		return;

	float multiplier = dr_speed_multiplier[class].FloatValue;
	if (multiplier == 1.0)
	{
		RunScriptCode(client, -1, -1, "self.RemoveCustomAttribute(\"move speed bonus\")");
		return;
	}

	RunScriptCode(client, -1, -1, "self.AddCustomAttribute(\"move speed bonus\", %f, 0)", multiplier);
}

static void SelectActivatorsAndAssignTeams()
{
	Queue_SelectNextActivators();

	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;

		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;

		RunScriptCode(client, -1, -1, "self.ForceChangeTeam(%d, true)", DRPlayer(client).IsActivator() ? TFTeam_Activators : TFTeam_Runners);
	}
}
