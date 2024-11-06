#pragma newdecls required
#pragma semicolon 1

#include <clientprefs>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2utils>
#include <tf2attributes>
#include <tf2items>
#include <pluginstatemanager>
#include <morecolors>

#define PLUGIN_VERSION	"2.0.0"

ArrayList g_itemData;
ArrayList g_currentActivators;
Handle g_chatHintTimer;
int g_lastShownHint;

ConVar sm_dr_speed_modifier[view_as<int>(TFClass_Engineer) + 1];
ConVar sm_dr_queue_points;
ConVar sm_dr_runner_backstab_damage;
ConVar sm_dr_runner_allow_button_damage;
ConVar sm_dr_runner_glow;
ConVar sm_dr_activator_speed_buff;
ConVar sm_dr_activator_count;
ConVar sm_dr_activator_health_modifier;
ConVar sm_dr_activator_allow_healthkits;
ConVar sm_dr_disable_regen;
ConVar sm_dr_allow_teleporters;
ConVar sm_dr_waiting_for_players;
ConVar sm_dr_chat_hint_interval;

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

public Plugin pluginInfo =
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
	
	PSM_Init("sm_dr_enabled", gameconf);
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
	SDKHooks_OnMapStart();
	
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
		
		g_chatHintTimer = CreateTimer(sm_dr_chat_hint_interval.FloatValue, Timer_DisplayChatHint, _, TIMER_REPEAT);
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
	
	if (sm_dr_allow_teleporters.BoolValue)
		return Plugin_Continue;
	
	if (GetEntProp(teleporter, Prop_Send, "m_bWasMapPlaced"))
		return Plugin_Continue;
	
	// Prevent player-built teleporters from actually teleporting
	result = false;
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
	
	return data.remove ? Plugin_Handled : Plugin_Continue;
}

static void Timer_DisplayChatHint(Handle timer)
{
	char phrase[256];
	Format(phrase, sizeof(phrase), "Chat Hint %d", ++g_lastShownHint);
	CPrintToChatAll("%s %t", PLUGIN_TAG, phrase);
	
	if (g_lastShownHint == MAX_CHAT_HINTS)
		g_lastShownHint = 0;
}
