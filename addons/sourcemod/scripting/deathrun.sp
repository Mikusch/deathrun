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
#define PLUGIN_VERSION		"Pre-Release Version"
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

enum PreferenceType
{
	Preference_AvoidBecomingActivator = (1 << 0), 
	Preference_HidePlayers = (1 << 1)
}

enum AttributeModMode
{
	ModMode_Set,		/*< Sets the attribute, overriding any previous value */
	ModMode_Add,		/*< Adds to the current value of the attribute */
	ModMode_Subtract,	/*< Subtracts from the current value of the attribute */
	ModMode_Remove		/*< Removes the attribute */
}

enum struct WeaponEntPropConfig
{
	char name[256];
	PropType type;
	PropFieldType fieldType;
	char value[256];
	
	void ReadConfig(KeyValues kv)
	{
		kv.GetString("name", this.name, 256);
		
		char type[256];
		kv.GetString("type", type, sizeof(type));
		if (StrEqual(type, "send"))
			this.type = Prop_Send;
		else if (StrEqual(type, "send"))
			this.type = Prop_Data;
		
		char fieldType[256];
		kv.GetString("field_type", fieldType, sizeof(fieldType));
		if (StrEqual(fieldType, "int") || StrEqual(fieldType, "integer"))
			this.fieldType = PropField_Integer;
		else if (StrEqual(fieldType, "float"))
			this.fieldType = PropField_Float;
		else if (StrEqual(fieldType, "vec") || StrEqual(fieldType, "vector"))
			this.fieldType = PropField_Vector;
		else if (StrEqual(fieldType, "str") || StrEqual(fieldType, "string"))
			this.fieldType = PropField_String;
		
		kv.GetString("value", this.value, 256);
	}
}

enum struct WeaponAttributeConfig
{
	char name[PLATFORM_MAX_PATH];	/*< Attribute name (e.g. "ammo regen") */
	float value;					/*< Attribute value */
	AttributeModMode mode;			/*< How this attribute should be modified */
	
	void ReadConfig(KeyValues kv)
	{
		kv.GetString("name", this.name, PLATFORM_MAX_PATH);
		this.value = kv.GetFloat("value");
		
		char mode[PLATFORM_MAX_PATH];
		kv.GetString("mode", mode, sizeof(mode));
		if (StrEqual(mode, "set"))
			this.mode = ModMode_Set;
		else if (StrEqual(mode, "add"))
			this.mode = ModMode_Add;
		else if (StrEqual(mode, "subtract"))
			this.mode = ModMode_Subtract;
		else if (StrEqual(mode, "remove"))
			this.mode = ModMode_Remove;
	}
}

enum struct WeaponConfig
{
	int defindex;				/*< Item definition index of the weapon */
	bool blockPrimaryAttack;	/*< Whether to block primary fire */
	bool blockSecondaryAttack;	/*< Whether to block the secondary attack */
	bool remove;				/*< Whether this weapon should be removed entirely */
	ArrayList attributes;		/*< Attributes of the weapon - ArrayList<WeaponAttributeConfig> */
	ArrayList props;			/*< Entity props - ArrayList<WeaponEntPropConfig> */
	
	void SetConfig(int defindex, KeyValues kv)
	{
		this.defindex = defindex;
		this.blockPrimaryAttack = view_as<bool>(kv.GetNum("block_attack"));
		this.blockSecondaryAttack = view_as<bool>(kv.GetNum("block_attack2"));
		this.remove = view_as<bool>(kv.GetNum("remove"));
		
		this.attributes = new ArrayList(sizeof(WeaponAttributeConfig));
		if (kv.JumpToKey("attributes", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					WeaponAttributeConfig attribute;
					attribute.ReadConfig(kv);
					this.attributes.PushArray(attribute);
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
		
		this.props = new ArrayList(sizeof(WeaponEntPropConfig));
		if (kv.JumpToKey("props", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					WeaponEntPropConfig prop;
					prop.ReadConfig(kv);
					this.props.PushArray(prop);
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
	}
}

methodmap WeaponConfigList < ArrayList
{
	public WeaponConfigList()
	{
		return view_as<WeaponConfigList>(new ArrayList(sizeof(WeaponConfig)));
	}
	
	public void ReadConfig(KeyValues kv)
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char defindexes[PLATFORM_MAX_PATH];
				kv.GetSectionName(defindexes, sizeof(defindexes));
				
				char parts[32][8]; // maximum 32 defindexes up to 8 characters
				int retrieved = ExplodeString(defindexes, ";", parts, sizeof(parts), sizeof(parts[]));
				
				for (int i = 0; i < retrieved; i++)
				{
					WeaponConfig weapon;
					weapon.SetConfig(StringToInt(parts[i]), kv);
					this.PushArray(weapon);
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	public int GetByDefIndex(int defindex, WeaponConfig config)
	{
		int i = this.FindValue(defindex);
		return i != -1 ? this.GetArray(i, config) : 0;
	}
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

char g_PreferenceNames[][] =  {
	"Preference_AvoidBecomingActivator",
	"Preference_HideRunners"
};

ConVar dr_queue_points;
ConVar dr_allow_thirdperson;
ConVar dr_round_time;

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
	
	// Late load!
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
}

public void OnConfigsExecuted()
{
	Cookies_Refresh();
}

public void OnPluginEnd()
{
	ConVars_Disable();
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
				TF2_ChangeClientTeam(client, TFTeam_Blue);
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
	DHooks_OnClientPutInServer(client);
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
