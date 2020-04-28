#include <sourcemod>
#include <sdktools>
#include <tf2attributes>

enum AttributeModMode
{
	ModMode_Set, 
	ModMode_Remove, 
}

enum struct WeaponAttributeConfig
{
	char name[PLATFORM_MAX_PATH];
	float value;
	AttributeModMode mode;
	
	void ReadConfig(KeyValues kv)
	{
		kv.GetString("name", this.name, PLATFORM_MAX_PATH);
		this.value = kv.GetFloat("value");
		
		char mode[PLATFORM_MAX_PATH];
		kv.GetString("mode", mode, sizeof(mode));
		
		if (StrEqual(mode, "set"))
			this.mode = ModMode_Set;
		else if (StrEqual(mode, "remove"))
			this.mode = ModMode_Remove;
	}
}

enum struct WeaponConfig
{
	int defindex;
	bool blockPrimaryFire;
	bool blockSecondaryAttack;
	bool remove;
	ArrayList attributes; // ArrayList of WeaponAttributeConfig
	
	void ReadConfig(KeyValues kv)
	{
		char defindex[8];
		kv.GetSectionName(defindex, sizeof(defindex));
		this.defindex = StringToInt(defindex);
		
		this.blockPrimaryFire = view_as<bool>(kv.GetNum("block_attack"));
		this.blockSecondaryAttack = view_as<bool>(kv.GetNum("block_attack2"));
		
		this.remove = view_as<bool>(kv.GetNum("block_attack2"));
		
		if (kv.JumpToKey("attributes", false))
		{
			this.attributes = new ArrayList();
			
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					WeaponAttributeConfig attribute;
					attribute.ReadConfig(kv);
					this.attributes.PushArray(attribute, sizeof(attribute));
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
		kv.GoBack();
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
				WeaponConfig weapon;
				weapon.ReadConfig(kv);
				this.PushArray(weapon, sizeof(weapon));
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

public Plugin pluginInfo =  {
	name = "Deathrun", 
	author = "Mikusch", 
	description = "Deathrun", 
	version = "1.0", 
	url = "https://github.com/Mikusch/deathrun"
};

public void OnPluginStart()
{
	
}
