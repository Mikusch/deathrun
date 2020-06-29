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

#define PLUGIN_NAME			"Deathrun Redux"
#define PLUGIN_AUTHOR		"Mikusch"
#define PLUGIN_DESCRIPTION	"Good old Deathrun"
#define PLUGIN_VERSION		"1.0"
#define PLUGIN_URL			"https://github.com/Mikusch/deathrun"

#define TIMER_EXPLOSION_SOUND	"items/cart_explode.wav"

#define TF_MAXPLAYERS		33
#define INTEGER_MAX_VALUE	0x7FFFFFFF

#define WEAPON_CONFIG_FILE		"configs/deathrun/weapons.cfg"

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
	Preference_AvoidBecomingActivator = (1 << 0), 
	Preference_HidePlayers = (1 << 1)
}

enum ETFGameType
{
	TF_GAMETYPE_UNDEFINED = 0,
	TF_GAMETYPE_CTF,
	TF_GAMETYPE_CP,
	TF_GAMETYPE_ESCORT,
	TF_GAMETYPE_ARENA,
	TF_GAMETYPE_MVM,
	TF_GAMETYPE_RD,
	TF_GAMETYPE_PASSTIME,
	TF_GAMETYPE_PD,

	TF_GAMETYPE_COUNT
};

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

char g_PreferenceNames[][] =  {
	"Preference_AvoidBecomingActivator",
	"Preference_HideRunners"
};

char g_OwnerEntityList[][] =  {
	"projectile_rocket", 
	"projectile_energy_ball", 
	"weapon", 
	"wearable", 
	"prop_physics"	//Conch
};

ConVar dr_queue_points;
ConVar dr_allow_thirdperson;
ConVar dr_round_time;

bool g_ArenaGameType;

int g_CurrentActivator = -1;

Handle g_RoundTimer;

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
#include "deathrun/timer.sp"

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
	
	Commands_Init();
	Console_Init();
	Cookies_Init();
	Config_Init();
	ConVars_Init();
	Events_Init();
	Timer_Init();
	
	GameData gamedata = new GameData("deathrun");
	if (gamedata == null)
		SetFailState("Could not find deathrun gamedata");
	
	DHooks_Init(gamedata);
	SDKCalls_Init(gamedata);
	
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
	PrecacheSound(TIMER_EXPLOSION_SOUND);
	
	if (GameRules_GetRoundState() == RoundState_Pregame && view_as<ETFGameType>(GameRules_GetProp("m_nGameType")) == TF_GAMETYPE_ARENA)
	{
		//Enable waiting for players
		g_ArenaGameType = true;
		GameRules_SetProp("m_nGameType", TF_GAMETYPE_UNDEFINED);
	}
}

public void OnConfigsExecuted()
{
	Cookies_Refresh();
}

public void OnPluginEnd()
{
	ConVars_Disable();
	
	//Restore arena if needed
	if (g_ArenaGameType)
		GameRules_SetProp("m_nGameType", TF_GAMETYPE_ARENA);
}

public void OnGameFrame()
{
	//Make sure other plugins are not overriding the gamerules prop
	if (g_ArenaGameType && view_as<ETFGameType>(GameRules_GetProp("m_nGameType")) != TF_GAMETYPE_UNDEFINED)
		GameRules_SetProp("m_nGameType", TF_GAMETYPE_UNDEFINED);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < sizeof(g_OwnerEntityList); i++)
	{
		if (StrContains(classname, g_OwnerEntityList[i]) != -1)
		{
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnedEntitySetTransmit);
			break;
		}
	}
}

public void TF2_OnWaitingForPlayersStart()
{
	//Set game type back to arena after waiting for players calculations are done
	g_ArenaGameType = false;
	GameRules_SetProp("m_nGameType", TF_GAMETYPE_ARENA);
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
			if (team == TFTeam_Red) //Check if player is in the runner team, if so put them back to the activator team
			{
				TF2_ChangeClientTeam(client, TFTeam_Activator);
				TF2_RespawnPlayer(client);
			}
		}
		else
		{
			if (team == TFTeam_Blue) //Check if player is in the activator team, if so put them back to the runner team
			{
				TF2_ChangeClientTeam(client, TFTeam_Red);
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

stock void PrintLocalizedMessage(int client, const char[] format, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), format, 3);
	CPrintToChat(client, "[{orange}DR{default}] %s", buffer);
}
