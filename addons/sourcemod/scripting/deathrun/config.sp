enum AttributeModMode
{
	ModMode_Set,		/*< Sets the attribute, adding it if it doesn't exist */
	ModMode_Add,		/*< Adds to the current value of the attribute */
	ModMode_Subtract,	/*< Subtracts from the current value of the attribute */
	ModMode_Remove		/*< Removes the attribute */
}

enum struct WeaponEntPropConfig
{
	char name[256];				/*< Property name */
	PropType type;				/*< Property type */
	PropFieldType fieldType;	/*< Property value field type */
	char value[256];			/*< Property value */
	
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
	char name[PLATFORM_MAX_PATH];	/*< Attribute name */
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
	ArrayList entprops;			/*< Entity props - ArrayList<WeaponEntPropConfig> */
	
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
		
		this.entprops = new ArrayList(sizeof(WeaponEntPropConfig));
		if (kv.JumpToKey("entprops", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					WeaponEntPropConfig entprop;
					entprop.ReadConfig(kv);
					this.entprops.PushArray(entprop);
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

static WeaponConfigList g_Weapons;

void Config_Init()
{
	g_Weapons = new WeaponConfigList();
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), WEAPON_CONFIG_FILE);
	KeyValues kv = new KeyValues("Weapons");
	if (kv.ImportFromFile(path))
	{
		g_Weapons.ReadConfig(kv);
		kv.GoBack();
	}
	delete kv;
}

bool Config_GetWeaponByDefIndex(int defindex, WeaponConfig config)
{
	return g_Weapons.GetByDefIndex(defindex, config) > 0;
}

void Config_Apply(int client)
{
	for (int slot = 0; slot <= WeaponSlot_InvisWatch; slot++)
	{
		int weapon = TF2_GetItemInSlot(client, slot);
		
		if (IsValidEntity(weapon))
		{
			int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
			WeaponConfig config;
			if (Config_GetWeaponByDefIndex(defindex, config))
			{
				//Remove weapon if wanted
				if (config.remove)
					RemovePlayerItem(client, weapon);
				
				//Handle attributes
				for (int i = 0; i < config.attributes.Length; i++)
				{
					WeaponAttributeConfig attribute;
					if (config.attributes.GetArray(i, attribute, sizeof(attribute)) > 0)
					{
						if (attribute.mode == ModMode_Set)
						{
							TF2Attrib_SetByName(weapon, attribute.name, attribute.value);
						}
						else if (attribute.mode == ModMode_Add)
						{
							Address address = TF2Attrib_GetByName(weapon, attribute.name);
							TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) + attribute.value);
							TF2Attrib_ClearCache(weapon);
							TF2Attrib_ClearCache(GetEntProp(weapon, Prop_Data, "m_hOwnerEntity"));
						}
						else if (attribute.mode == ModMode_Subtract)
						{
							Address address = TF2Attrib_GetByName(weapon, attribute.name);
							TF2Attrib_SetValue(address, TF2Attrib_GetValue(address) - attribute.value);
							TF2Attrib_ClearCache(weapon);
							TF2Attrib_ClearCache(GetEntProp(weapon, Prop_Data, "m_hOwnerEntity"));
						}
						else if (attribute.mode == ModMode_Remove)
						{
							TF2Attrib_SetByName(weapon, attribute.name, 0.0); //TF2Attrib_RemoveByName can't remove static attributes
						}
					}
				}
				
				//Handle entity props
				for (int i = 0; i < config.entprops.Length; i++)
				{
					WeaponEntPropConfig entprop;
					if (config.entprops.GetArray(i, entprop, sizeof(entprop)) > 0)
					{
						switch (entprop.fieldType)
						{
							case PropField_Integer:
							{
								SetEntProp(weapon, entprop.type, entprop.name, StringToInt(entprop.value));
							}
							case PropField_Float:
							{
								SetEntPropFloat(weapon, entprop.type, entprop.name, StringToFloat(entprop.value));
							}
							case PropField_Vector:
							{
								float vector[3];
								StringToVector(entprop.value, vector);
								SetEntPropVector(weapon, entprop.type, entprop.name, vector);
							}
							case PropField_String:
							{
								SetEntPropString(weapon, entprop.type, entprop.name, entprop.value);
							}
						}
					}
				}
			}
		}
	}
}
