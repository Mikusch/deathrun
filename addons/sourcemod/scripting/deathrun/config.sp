/*
 * Copyright (C) 2020  Mikusch
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

enum struct ItemAttributeConfig
{
	char name[256];			/*< Attribute name */
	float value;			/*< Attribute value */
	
	void ReadConfig(KeyValues kv)
	{
		kv.GetString("name", this.name, 256);
		this.value = kv.GetFloat("value");
	}
}

enum struct ItemEntPropConfig
{
	char name[256];				/*< Property name */
	PropType type;				/*< Property type */
	PropFieldType fieldType;	/*< Property field type */
	char value[256];			/*< Property value */
	
	void ReadConfig(KeyValues kv)
	{
		kv.GetString("name", this.name, 256);
		
		char type[256];
		kv.GetString("type", type, sizeof(type));
		if (StrEqual(type, "send"))
			this.type = Prop_Send;
		else if (StrEqual(type, "data"))
			this.type = Prop_Data;
		
		char fieldType[256];
		kv.GetString("field_type", fieldType, sizeof(fieldType));
		if (StrEqual(fieldType, "int") || StrEqual(fieldType, "integer"))
			this.fieldType = PropField_Integer;
		else if (StrEqual(fieldType, "float"))
			this.fieldType = PropField_Float;
		else if (StrEqual(fieldType, "vector"))
			this.fieldType = PropField_Vector;
		else if (StrEqual(fieldType, "string"))
			this.fieldType = PropField_String;
		
		kv.GetString("value", this.value, 256);
	}
}

enum struct ItemConfig
{
	int defindex;				/*< Item definition index of the item */
	bool blockPrimaryAttack;	/*< Whether the primary fire of this item should be blocked */
	bool blockSecondaryAttack;	/*< Whether the secondary fire of this item should be blocked */
	bool remove;				/*< Whether this item should be removed from the player */
	ArrayList attributes;		/*< Item attributes - ArrayList<ItemAttributeConfig> */
	ArrayList entprops;			/*< Entity properties - ArrayList<ItemEntPropConfig> */
	
	void SetConfig(int defindex, KeyValues kv)
	{
		this.defindex = defindex;
		this.blockPrimaryAttack = view_as<bool>(kv.GetNum("block_attack"));
		this.blockSecondaryAttack = view_as<bool>(kv.GetNum("block_attack2"));
		this.remove = view_as<bool>(kv.GetNum("remove"));
		
		this.attributes = new ArrayList(sizeof(ItemAttributeConfig));
		if (kv.JumpToKey("attributes", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					ItemAttributeConfig attribute;
					attribute.ReadConfig(kv);
					this.attributes.PushArray(attribute);
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
		
		this.entprops = new ArrayList(sizeof(ItemEntPropConfig));
		if (kv.JumpToKey("entprops", false))
		{
			if (kv.GotoFirstSubKey(false))
			{
				do
				{
					ItemEntPropConfig entprop;
					entprop.ReadConfig(kv);
					this.entprops.PushArray(entprop);
				}
				while (kv.GotoNextKey(false));
				kv.GoBack();
			}
			kv.GoBack();
		}
	}
	
	void Destroy()
	{
		delete this.attributes;
		delete this.entprops;
	}
}

methodmap ItemConfigList < ArrayList
{
	public ItemConfigList()
	{
		return view_as<ItemConfigList>(new ArrayList(sizeof(ItemConfig)));
	}
	
	public void ReadConfig(KeyValues kv)
	{
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				char section[8];
				int defindex;
				if (kv.GetSectionName(section, sizeof(section)) && StringToIntEx(section, defindex) > 0)
				{
					ItemConfig item;
					item.SetConfig(defindex, kv);
					
					ItemConfig oldItem;
					int i = this.FindValue(defindex);
					if (i != -1 && this.GetArray(i, oldItem) > 0)
					{
						oldItem.Destroy();
						this.SetArray(i, item);
					}
					else
					{
						this.PushArray(item);
					}
				}
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
		kv.GoBack();
	}
	
	public int GetByDefIndex(int defindex, ItemConfig config)
	{
		int i = this.FindValue(defindex);
		return i != -1 ? this.GetArray(i, config) : 0;
	}
}

static ItemConfigList g_ItemConfig;

void Config_Init()
{
	g_ItemConfig = new ItemConfigList();
	
	KeyValues kv = new KeyValues("Items");
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/deathrun/items.cfg");
	if (kv.ImportFromFile(path))
	{
		g_ItemConfig.ReadConfig(kv);
		kv.GoBack();
	}
	
	char map[128];
	GetCurrentMap(map, sizeof(map));
	GetMapDisplayName(map, map, sizeof(map));
	
	kv = new KeyValues("Items");
	BuildPath(Path_SM, path, sizeof(path), "configs/deathrun/maps/%s.items.cfg", map);
	if (kv.ImportFromFile(path))
	{
		g_ItemConfig.ReadConfig(kv);
		kv.GoBack();
	}
	
	delete kv;
}

bool Config_GetItemByDefIndex(int defindex, ItemConfig config)
{
	if(!g_IsMapDR) return false;
	return g_ItemConfig.GetByDefIndex(defindex, config) > 0;
}

void Config_Apply(int client)
{
	if(!g_IsMapDR) return;
	
	for (int slot = 0; slot <= ItemSlot_Misc2; slot++)
	{
		int item = TF2_GetItemInSlot(client, slot);
		
		if (IsValidEntity(item))
		{
			int defindex = GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex");
			
			ItemConfig config;
			if (Config_GetItemByDefIndex(defindex, config))
			{
				//Remove item if wanted
				if (config.remove)
				{
					char classname[256];
					GetEntityClassname(item, classname, sizeof(classname));
					
					if (StrContains(classname, "tf_wearable") != -1)
						TF2_RemoveWearable(client, item);
					else
						RemovePlayerItem(client, item);
					
					continue;
				}
				
				//Handle attributes
				for (int i = 0; i < config.attributes.Length; i++)
				{
					ItemAttributeConfig attribute;
					if (config.attributes.GetArray(i, attribute, sizeof(attribute)) > 0)
					{
						TF2Attrib_SetByName(item, attribute.name, attribute.value);
					}
				}
				
				//Handle entity props
				for (int i = 0; i < config.entprops.Length; i++)
				{
					ItemEntPropConfig entprop;
					if (config.entprops.GetArray(i, entprop, sizeof(entprop)) > 0)
					{
						if (!HasEntProp(item, entprop.type, entprop.name))
						{
							LogError("Invalid entity property: %s", entprop.name);
							continue;
						}
						
						switch (entprop.fieldType)
						{
							case PropField_Integer:
							{
								SetEntProp(item, entprop.type, entprop.name, StringToInt(entprop.value));
							}
							case PropField_Float:
							{
								SetEntPropFloat(item, entprop.type, entprop.name, StringToFloat(entprop.value));
							}
							case PropField_Vector:
							{
								float vector[3];
								StringToVector(entprop.value, vector);
								SetEntPropVector(item, entprop.type, entprop.name, vector);
							}
							case PropField_String:
							{
								SetEntPropString(item, entprop.type, entprop.name, entprop.value);
							}
						}
					}
				}
			}
		}
	}
}
