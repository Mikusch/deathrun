#pragma semicolon 1 

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>
#include <tf2_stocks>
#include <tf2attributes>
#include <clientprefs>
#include <morecolors>

#pragma newdecls required

#define PLUGIN_NAME			"Deathrun Neu"
#define PLUGIN_AUTHOR		"Mikusch"
#define PLUGIN_DESCRIPTION	"Team Fortress 2 Deathrun"
#define PLUGIN_VERSION		"v1.1"
#define PLUGIN_URL			"https://github.com/Mikusch/deathrun"

#define GAMESOUND_EXPLOSION	"MVM.BombExplodes"

#define TF_MAXPLAYERS		33
#define INTEGER_MAX_VALUE	0x7FFFFFFF

// m_lifeState values
#define LIFE_ALIVE				0 // alive
#define LIFE_DYING				1 // playing death animation or still falling off of a ledge waiting to hit ground
#define LIFE_DEAD				2 // dead. lying still.
#define LIFE_RESPAWNABLE		3
#define LIFE_DISCARDBODY		4

const TFTeam TFTeam_Runners = TFTeam_Red;
const TFTeam TFTeam_Activator = TFTeam_Blue;

enum PreferenceType
{
	Preference_DontBeActivator = (1 << 0), 
	Preference_HideChatTips = (1 << 1)
}

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

char g_PreferenceNames[][] =  {
	"Preference_DontBeActivator", 
	"Preference_HideChatTips"
};

char g_OwnerEntityList[][] =  {
	"weapon", 
	"wearable", 
	"prop_physics",	//Concheror
	"tf_projectile"
};

ConVar dr_queue_points;
ConVar dr_allow_thirdperson;
ConVar dr_chattips_interval;
ConVar dr_runner_glow;

int g_CurrentActivator = -1;

#include "deathrun/player.sp"

#include "deathrun/commands.sp"
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
	
	CAddColor("primary", 0xF26C4F);
	CAddColor("secondary", 0x3A89C9);
	
	Commands_Init();
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

public void OnMapStart()
{
	PrecacheScriptSound(GAMESOUND_EXPLOSION);
}

public void OnConfigsExecuted()
{
	Cookies_Refresh();
}

public void OnPluginEnd()
{
	ConVars_Disable();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < sizeof(g_OwnerEntityList); i++)
	{
		if (StrContains(classname, g_OwnerEntityList[i]) != -1)
		{
			if (HasEntProp(entity, Prop_Send, "m_hThrower"))
				SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ThrownEntitySetTransmit);
			else
				SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnedEntitySetTransmit);
			break;
		}
	}
}

void RequestFrameCallback_VerifyTeam(int userid)
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
				TF2_ChangeClientTeam(client, TFTeam_Activator);
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (team == TFTeam_Activator) //Check if player is in the activator team, if so put them back to the runner team
			{
				TF2_ChangeClientTeam(client, TFTeam_Runners);
				TF2_RespawnPlayer(client);
			}
		}
	}
}

int GetActivator()
{
	return g_CurrentActivator;
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

public void OnClientPutInServer(int client)
{
	SDKHooks_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	DRPlayer(client).Reset();
}
