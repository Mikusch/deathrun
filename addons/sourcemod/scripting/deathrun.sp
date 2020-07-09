/*
 * Copyright © 2020 Mikusch and the Deathrun Neu contributors.
 *
 * This file is part of Deathrun Neu.
 * 
 * Deathrun Neu is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * Deathrun Neu is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with Deathrun Neu.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma semicolon 1 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <tf2_stocks>
#include <dhooks>
#include <tf2attributes>
#include <morecolors>

#pragma newdecls required

#define PLUGIN_NAME			"Deathrun Neu"
#define PLUGIN_AUTHOR		"Mikusch"
#define PLUGIN_DESCRIPTION	"Team Fortress 2 Deathrun"
#define PLUGIN_VERSION		"1.3.0"
#define PLUGIN_URL			"https://github.com/Mikusch/deathrun"

#define GAMESOUND_EXPLOSION		"MVM.BombExplodes"

#define TF_MAXPLAYERS			33
#define INTEGER_MAX_VALUE		0x7FFFFFFF
#define MAX_CHATMESSAGE_LENGTH	192

// m_lifeState values
#define LIFE_ALIVE				0 // alive
#define LIFE_DYING				1 // playing death animation or still falling off of a ledge waiting to hit ground
#define LIFE_DEAD				2 // dead. lying still.
#define LIFE_RESPAWNABLE		3
#define LIFE_DISCARDBODY		4

const TFTeam TFTeam_Runners = TFTeam_Red;
const TFTeam TFTeam_Activators = TFTeam_Blue;

enum
{
	WeaponSlot_Primary = 0, 
	WeaponSlot_Secondary, 
	WeaponSlot_Melee, 
	WeaponSlot_PDABuild, 
	WeaponSlot_PDADisguise = 3, 
	WeaponSlot_PDADestroy, 
	WeaponSlot_InvisWatch = 4, 
	WeaponSlot_BuilderEngie, 
	WeaponSlot_Unknown1, 
	WeaponSlot_Head, 
	WeaponSlot_Misc1, 
	WeaponSlot_Action, 
	WeaponSlot_Misc2
};

// TF2 win reasons (from teamplayroundbased_gamerules.h)
enum
{
	WINREASON_NONE = 0, 
	WINREASON_ALL_POINTS_CAPTURED, 
	WINREASON_OPPONENTS_DEAD, 
	WINREASON_FLAG_CAPTURE_LIMIT, 
	WINREASON_DEFEND_UNTIL_TIME_LIMIT, 
	WINREASON_STALEMATE, 
	WINREASON_TIMELIMIT, 
	WINREASON_WINLIMIT, 
	WINREASON_WINDIFFLIMIT, 
	WINREASON_RD_REACTOR_CAPTURED, 
	WINREASON_RD_CORES_COLLECTED, 
	WINREASON_RD_REACTOR_RETURNED, 
	WINREASON_PD_POINTS, 
	WINREASON_SCORED, 
	WINREASON_STOPWATCH_WATCHING_ROUNDS, 
	WINREASON_STOPWATCH_WATCHING_FINAL_ROUND, 
	WINREASON_STOPWATCH_PLAYING_ROUNDS
};

enum PreferenceType
{
	Preference_DontBeActivator = (1 << 0), 
	Preference_HideChatTips = (1 << 1)
}

char g_PreferenceNames[][] =  {
	"Preference_DontBeActivator", 
	"Preference_HideChatTips"
};

ConVar dr_queue_points;
ConVar dr_allow_thirdperson;
ConVar dr_chattips_interval;
ConVar dr_runner_glow;
ConVar dr_num_activators;
ConVar dr_activator_health;

ArrayList g_CurrentActivators;

#include "deathrun/player.sp"

#include "deathrun/console.sp"
#include "deathrun/config.sp"
#include "deathrun/cookies.sp"
#include "deathrun/convars.sp"
#include "deathrun/dhooks.sp"
#include "deathrun/events.sp"
#include "deathrun/menus.sp"
#include "deathrun/queue.sp"
#include "deathrun/sdkcalls.sp"
#include "deathrun/sdkhooks.sp"
#include "deathrun/stocks.sp"
#include "deathrun/timers.sp"

public Plugin pluginInfo =  {
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases.txt");
	LoadTranslations("deathrun.phrases.txt");
	
	CAddColor("primary", 0x4285F4);
	CAddColor("secondary", 0xAA66CC);
	CAddColor("success", 0x00C851);
	CAddColor("danger", 0xFF4444);
	
	AddNormalSoundHook(OnSoundPlayed);
	
	g_CurrentActivators = new ArrayList();
	
	Console_Init();
	Cookies_Init();
	Config_Init();
	ConVars_Init();
	Events_Init();
	Timers_Init();
	
	GameData gamedata = new GameData("deathrun");
	if (gamedata == null)
		SetFailState("Could not find deathrun gamedata");
	DHooks_Init(gamedata);
	SDKCalls_Init(gamedata);
	delete gamedata;
	
	DHooks_HookGamerules();
	
	ConVars_Enable();
	
	//Late load
	OnMapStart();
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			OnClientPutInServer(client);
		
		if (AreClientCookiesCached(client))
			OnClientCookiesCached(client);
	}
}

public void OnPluginEnd()
{
	ConVars_Disable();
}

public void OnMapStart()
{
	PrecacheScriptSound(GAMESOUND_EXPLOSION);
}

public void OnConfigsExecuted()
{
	Cookies_Refresh();
}

public void OnClientPutInServer(int client)
{
	SDKHooks_OnClientPutInServer(client);
}

public void OnClientCookiesCached(int client)
{
	Cookies_RefreshQueue(client);
	Cookies_RefreshSettings(client);
}

public void OnClientDisconnect(int client)
{
	int index = g_CurrentActivators.FindValue(client);
	if (index != -1)
		g_CurrentActivators.Erase(index);
	
	DRPlayer(client).Reset();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	SDKHooks_OnEntityCreated(entity, classname);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	bool changed;
	
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon == -1)
		return Plugin_Continue;
	
	//No weapon firing in preround
	if (GameRules_GetRoundState() == RoundState_Preround)
	{
		if (buttons & IN_ATTACK)
		{
			buttons &= ~IN_ATTACK;
			changed = true;
		}
		
		if (buttons & IN_ATTACK2)
		{
			buttons &= ~IN_ATTACK2;
			changed = true;
		}
	}
	
	WeaponConfig config;
	if (Config_GetWeaponByDefIndex(GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex"), config))
	{
		if (buttons & IN_ATTACK && config.blockPrimaryAttack)
		{
			buttons &= ~IN_ATTACK;
			changed = true;
		}
		
		if (buttons & IN_ATTACK2 && config.blockSecondaryAttack)
		{
			buttons &= ~IN_ATTACK2;
			changed = true;
		}
	}
	
	return changed ? Plugin_Changed : Plugin_Continue;
}

public Action OnSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (IsValidClient(entity))
	{
		return OnClientSoundPlayed(clients, numClients, entity);
	}
	else if (HasEntProp(entity, Prop_Send, "m_hBuilder"))
	{
		int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
		if (IsValidClient(builder))
			return OnClientSoundPlayed(clients, numClients, builder);
	}
	else if (HasEntProp(entity, Prop_Send, "m_hThrower"))
	{
		int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
		if (IsValidClient(thrower))
			return OnClientSoundPlayed(clients, numClients, thrower);
	}
	else if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(owner))
			return OnClientSoundPlayed(clients, numClients, owner);
	}
	
	return Plugin_Continue;
}

static Action OnClientSoundPlayed(int clients[MAXPLAYERS], int &numClients, int client)
{
	Action action = Plugin_Continue;
	
	//Iterate all clients this sound is played to and remove them from the array if they are hiding other runners
	for (int i = 0; i < numClients; i++)
	{
		if (DRPlayer(clients[i]).CanHideClient(client))
		{
			for (int j = i; j < numClients - 1; j++)
			{
				clients[j] = clients[j + 1];
			}
			
			numClients--;
			i--;
			action = Plugin_Changed;
		}
	}
	
	return action;
}
