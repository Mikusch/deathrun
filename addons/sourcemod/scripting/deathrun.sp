#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <tf2attributes>

#define CONFIG_FILE		"configs/deathrun/deathrun.cfg"

enum AttributeModMode
{
	ModMode_Set,		/*< Sets the attribute, overriding any previous value */
	ModMode_Add,		/*< Adds to the current value of the attribute */
	ModMode_Subtract,	/*< Subtracts from the current value of the attribute */
	ModMode_Remove		/*< Removes the attribute */
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
	bool blockPrimaryAttack;		/*< Whether to block primary fire */
	bool blockSecondaryAttack;	/*< Whether to block the secondary attack */
	bool remove;				/*< Whether this weapon should be removed entirely */
	ArrayList attributes;		/*< Attributes of the weapon - ArrayList<WeaponAttributeConfig> */
	
	void SetConfig(int defindex, KeyValues kv)
	{
		this.defindex = defindex;
		this.blockPrimaryAttack = view_as<bool>(kv.GetNum("block_attack"));
		this.blockSecondaryAttack = view_as<bool>(kv.GetNum("block_attack2"));
		this.remove = view_as<bool>(kv.GetNum("block_attack2"));
		
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

WeaponConfigList g_Weapons;

#include "deathrun/sdk.sp"

public Plugin pluginInfo =  {
	name = "Deathrun", 
	author = "Mikusch", 
	description = "Deathrun", 
	version = "1.0", 
	url = "https://github.com/Mikusch/deathrun"
};

public void OnPluginStart()
{
	SDK_Init();
	
	g_Weapons = new WeaponConfigList();
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), CONFIG_FILE);
	KeyValues kv = new KeyValues("Weapons");
	if (kv.ImportFromFile(path))
	{
		g_Weapons.ReadConfig(kv);
		kv.GoBack();
	}
	delete kv;
	
	AddCommandListener(CommandListener_Build, "build");
	
	// Late load!
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
			OnClientPutInServer(client);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	if (activeWeapon == -1)
		return Plugin_Continue;
	
	bool changed;
	
	WeaponConfig config;
	if (g_Weapons.GetByDefIndex(GetEntProp(activeWeapon, Prop_Send, "m_iItemDefinitionIndex"), config) > 0)
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

public Action CommandListener_Build(int client, const char[] command, int argc)
{
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	DHook_HookGiveNamedItem(client);
}
