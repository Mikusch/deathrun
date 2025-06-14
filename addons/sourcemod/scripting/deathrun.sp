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

#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2utils>
#include <tf2attributes>
#include <tf2items>
#include <tf_econ_data>
#include <pluginstatemanager>
#include <morecolors>

#define PLUGIN_VERSION	"2.2.1"

ArrayList g_itemData;
ArrayList g_currentActivators;
Handle g_chatHintTimer;
int g_lastShownHint;

ConVar dr_speed_modifier[view_as<int>(TFClass_Engineer) + 1];
ConVar dr_queue_points;
ConVar dr_backstab_damage;
ConVar dr_runner_glow;
ConVar dr_activator_speed_buff;
ConVar dr_activator_count;
ConVar dr_activator_health_modifier;
ConVar dr_activator_allow_healthkits;
ConVar dr_activator_healthbar_lifetime;
ConVar dr_disable_regen;
ConVar dr_allow_teleporter_use;
ConVar dr_allow_dispenser_heal;
ConVar dr_chat_hint_interval;
ConVar dr_prevent_multi_button_hits;

#include "deathrun/shareddefs.sp"

#include "deathrun/clientprefs.sp"
#include "deathrun/commands.sp"
#include "deathrun/config.sp"
#include "deathrun/convars.sp"
#include "deathrun/dhooks.sp"
#include "deathrun/events.sp"
#include "deathrun/hooks.sp"
#include "deathrun/menus.sp"
#include "deathrun/player.sp"
#include "deathrun/queue.sp"
#include "deathrun/sdkhooks.sp"
#include "deathrun/util.sp"

public Plugin myinfo =
{
	name = "Deathrun Neu",
	author = "Mikusch",
	description = "Team Fortress 2 Deathrun",
	version = PLUGIN_VERSION,
	url = "https://github.com/Mikusch/deathrun"
};

public void OnPluginStart()
{
	GameData gameconf = new GameData("deathrun");
	if (!gameconf)
		SetFailState("Failed to find deathrun gamedata");
	
	LoadTranslations("common.phrases");
	LoadTranslations("deathrun.phrases");
	
	PSM_Init("dr_enabled", gameconf);
	PSM_AddPluginStateChangedHook(OnPluginStateChanged);
	
	ClientPrefs_Init();
	Commands_Init();
	Config_Init();
	ConVars_Init();
	DHooks_Init();
	Events_Init();
	Hooks_Init();
	Queue_Init();
	
	delete gameconf;
}

public void OnPluginEnd()
{
	if (!PSM_IsEnabled())
		return;
	
	PSM_SetPluginState(false);
}

public void OnClientPutInServer(int client)
{
	if (!PSM_IsEnabled())
		return;
	
	if (AreClientCookiesCached(client))
		OnClientCookiesCached(client);
}

public void OnMapStart()
{
	if (!PSM_IsEnabled())
		return;
	
	SDKHooks_OnMapStart();
	DHooks_OnMapStart();
	
	g_currentActivators.Clear();
}

public void OnConfigsExecuted()
{
	PSM_TogglePluginState();
}

public void OnClientCookiesCached(int client)
{
	if (!PSM_IsEnabled())
		return;
	
	ClientPrefs_OnClientCookiesCached(client);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!PSM_IsEnabled())
		return;
	
	SDKHooks_HookEntity(entity, classname);
}

public void OnEntityDestroyed(int entity)
{
	if (!PSM_IsEnabled())
		return;
	
	PSM_SDKUnhook(entity);
}

public void OnGameFrame()
{
	int monsterResource = FindEntityByClassname(-1, "monster_resource");
	if (monsterResource == -1)
		return;
	
	int maxhealth, health;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (!DRPlayer(client).IsActivator())
			continue;
		
		if (IsPlayerAlive(client))
			health += GetEntProp(client, Prop_Send, "m_iHealth");
		
		maxhealth += DRPlayer(client).GetMaxHealth();
	}
	
	static float healthBarHideTime;
	static int oldHealthPercentageByte;
	
	int healthPercentageByte = Min(RoundFloat(float(health) / float(maxhealth) * 255), 255);
	
	if (GameRules_GetRoundState() == RoundState_Preround || (oldHealthPercentageByte != 0 && oldHealthPercentageByte != healthPercentageByte))
	{
		healthBarHideTime = GetGameTime() + dr_activator_healthbar_lifetime.FloatValue;
		oldHealthPercentageByte = healthPercentageByte;
		
		SetEntProp(monsterResource, Prop_Send, "m_iBossHealthPercentageByte", healthPercentageByte);
	}
	else if (healthBarHideTime <= GetGameTime())
	{
		SetEntProp(monsterResource, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}
}

void OnPluginStateChanged(bool enabled)
{
	if (enabled)
	{
		int entity = -1;
		while ((entity = FindEntityByClassname(entity, "*")) != -1)
		{
			char classname[64];
			if (!GetEntityClassname(entity, classname, sizeof(classname)))
				continue;
			
			OnEntityCreated(entity, classname);
		}
		
		for (int client = 1; client <= MaxClients; ++client)
		{
			if (!IsClientInGame(client))
				continue;
			
			OnClientPutInServer(client);
		}
		
		g_chatHintTimer = CreateChatHintTimer(dr_chat_hint_interval.FloatValue);
		
		OnMapStart();
	}
	else
	{
		delete g_chatHintTimer;
	}
}

public Action TF2_OnPlayerTeleport(int client, int teleporter, bool &result)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (!result)
		return Plugin_Continue;
	
	if (GetEntProp(teleporter, Prop_Send, "m_bWasMapPlaced"))
		return Plugin_Continue;
	
	result = dr_allow_teleporter_use.BoolValue;
	return Plugin_Changed;
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int itemDefIndex, Handle &item)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	int index = g_itemData.FindValue(itemDefIndex, ItemData::def_index);
	if (index == -1)
		return Plugin_Continue;
	
	ItemData data;
	if (!g_itemData.GetArray(index, data))
		return Plugin_Continue;
	
	if (data.replacement_defindex != -1)
	{
		char translatedWeaponName[64];
		if (TF2Econ_GetItemClassName(data.replacement_defindex, translatedWeaponName, sizeof(translatedWeaponName)))
		{
			TF2Econ_TranslateWeaponEntForClass(translatedWeaponName, sizeof(translatedWeaponName), TF2_GetPlayerClass(client));
			
			int minLevel, maxLevel;
			TF2Econ_GetItemLevelRange(data.replacement_defindex, minLevel, maxLevel);
			
			// Create a default item
			Handle newItem = TF2Items_CreateItem(OVERRIDE_ALL | PRESERVE_ATTRIBUTES);
			TF2Items_SetItemIndex(newItem, data.replacement_defindex);
			TF2Items_SetClassname(newItem, translatedWeaponName);
			TF2Items_SetLevel(newItem, GetRandomInt(minLevel, maxLevel));
			
			item = newItem;
			return Plugin_Changed;
		}
		else
		{
			LogError("Invalid item definition index %d", data.replacement_defindex);
		}
	}
	
	return data.remove ? Plugin_Handled : Plugin_Continue;
}

Handle CreateChatHintTimer(float interval)
{
	delete g_chatHintTimer;
	
	if (interval > 0.0)
		return CreateTimer(interval, Timer_DisplayChatHint, _, TIMER_REPEAT);
	else
		return null;
}

static void Timer_DisplayChatHint(Handle timer)
{
	char phrase[64];
	
	int index = g_lastShownHint++;
	if (index == 0)
		Format(phrase, sizeof(phrase), "Chat Hint Credits");
	else
		Format(phrase, sizeof(phrase), "Chat Hint %d", index);
	
	if (!TranslationPhraseExists(phrase))
	{
		g_lastShownHint = 0;
		return;
	}
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (DRPlayer(client).HasPreference(Preference_DisableChatHints))
			continue;
		
		if (index == 0)
			CPrintToChat(client, "%s %t", PLUGIN_TAG, phrase, PLUGIN_VERSION);
		else
			CPrintToChat(client, "%s %t", PLUGIN_TAG, phrase);
	}
}
