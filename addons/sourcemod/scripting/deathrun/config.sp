#pragma newdecls required
#pragma semicolon 1

enum NetPropTarget
{
	Target_Player, 
	Target_Item
}

enum struct AttributeData
{
	char name[64];
	float value;
	
	bool Parse(KeyValues kv)
	{
		if (!kv.GetSectionName(this.name, sizeof(this.name)))
			return false;
		
		this.value = kv.GetFloat(NULL_STRING);
		return true;
	}
}

enum struct NetPropData
{
	char name[64];
	PropType type;
	PropFieldType field_type;
	char value[64];
	int int_value;
	float float_value;
	int element;
	NetPropTarget target;
	
	bool Parse(KeyValues kv)
	{
		if (!kv.GetSectionName(this.name, sizeof(this.name)))
			return false;
		
		char type[64];
		if (kv.GetString("type", type, sizeof(type)))
		{
			if (StrEqual(type, "send"))
			{
				this.type = Prop_Send;
			}
			else if (StrEqual(type, "data"))
			{
				this.type = Prop_Data;
			}
			else
			{
				LogError("[%s] Invalid value for \"type\": %s", this.name, type);
				return false;
			}
		}
		else
		{
			LogError("[%s] Required attribute \"type\" not set", this.name);
			return false;
		}
		
		char field_type[64];
		if (kv.GetString("field_type", field_type, sizeof(field_type)))
		{
			if (StrEqual(field_type, "int"))
			{
				this.field_type = PropField_Integer;
			}
			else if (StrEqual(field_type, "float"))
			{
				this.field_type = PropField_Float;
			}
			else if (StrEqual(field_type, "string"))
			{
				this.field_type = PropField_String;
			}
			else
			{
				LogError("[%s] Invalid value for \"field_type\": %s", this.name, field_type);
				return false;
			}
		}
		else
		{
			LogError("[%s] Required attribute \"field_type\" not set", this.name);
			return false;
		}
		
		if (kv.GetString("value", this.value, sizeof(this.value)))
		{
			this.int_value = StringToInt(this.value);
			this.float_value = StringToFloat(this.value);
		}
		
		char target[64];
		if (kv.GetString("target", target, sizeof(target)))
		{
			if (StrEqual(target, "player"))
			{
				this.target = Target_Player;
			}
			else if (StrEqual(target, "item"))
			{
				this.target = Target_Item;
			}
			else
			{
				LogError("[%s] Invalid value for \"target\": %s", this.name, target);
				return false;
			}
		}
		else
		{
			this.target = Target_Item;
		}
		
		this.element = kv.GetNum("element", 0);
		
		return true;
	}
}

enum struct ItemData
{
	int def_index;
	ArrayList attributes;
	ArrayList netprops;
	bool remove;
	
	bool Parse(KeyValues kv)
	{
		char section[8];
		if (kv.GetSectionName(section, sizeof(section)))
		{
			if (!StringToIntEx(section, this.def_index))
			{
				LogError("Failed to parse item definition index: %s", section);
				return false;
			}
			
			int prefab = kv.GetNum("prefab", -1);
			if (prefab != -1)
			{
				int index = g_hItemData.FindValue(prefab, ItemData::def_index);
				
				ItemData data;
				if (index != -1 && g_hItemData.GetArray(index, data))
				{
					this.CopyFrom(data);
				}
				else
				{
					LogError("[%d] Failed to fetch prefab info from item: %d", this.def_index, prefab);
					return false;
				}
			}
			
			if (kv.JumpToKey("attributes", false))
			{
				if (!this.attributes)
					this.attributes = new ArrayList(sizeof(AttributeData));
				
				if (kv.GotoFirstSubKey(false))
				{
					do
					{
						AttributeData data;
						if (data.Parse(kv))
							this.attributes.PushArray(data);
						else
							LogError("[%d] Failed to parse attributes", this.def_index);
					}
					while (kv.GotoNextKey(false));
					kv.GoBack();
				}
				kv.GoBack();
			}
			
			if (kv.JumpToKey("netprops", false))
			{
				if (!this.netprops)
					this.netprops = new ArrayList(sizeof(NetPropData));
				
				if (kv.GotoFirstSubKey(false))
				{
					do
					{
						NetPropData data;
						if (data.Parse(kv))
							this.netprops.PushArray(data);
						else
							LogError("[%d] Failed to parse netprops", this.def_index);
					}
					while (kv.GotoNextKey(false));
					kv.GoBack();
				}
				kv.GoBack();
			}
			
			this.remove = kv.GetNum("remove", this.remove) != 0;
			
			return true;
		}
		else
		{
			return false;
		}
	}
	
	void CopyFrom(ItemData data)
	{
		if (data.attributes)
			this.attributes = data.attributes.Clone();
		
		if (data.netprops)
			this.netprops = data.netprops.Clone();
		
		this.remove = data.remove;
	}
}

void Config_Init()
{
	char file[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, file, sizeof(file), "configs/deathrun/items.cfg");
	KeyValues kv = new KeyValues("items");
	if (kv.ImportFromFile(file))
	{
		g_hItemData = new ArrayList(sizeof(ItemData));
		
		if (kv.GotoFirstSubKey(false))
		{
			do
			{
				ItemData item;
				if (item.Parse(kv))
					g_hItemData.PushArray(item);
			}
			while (kv.GotoNextKey(false));
			kv.GoBack();
		}
	}
	else
	{
		LogError("Failed to import config file \"%s\"", file);
	}
	delete kv;
}

void Config_ApplyItemAttributes(int userid)
{
	int client = GetClientOfUserId(userid);
	if (client == 0)
		return;
	
	ArrayList myItems = new ArrayList();
	
	int numWeapons = GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons");
	for (int i = 0; i < numWeapons; ++i)
	{
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		if (weapon == -1)
			continue;
		
		myItems.Push(weapon);
	}
	
	int numWearables = TF2Util_GetPlayerWearableCount(client);
	for (int wbl = numWearables - 1; wbl >= 0; --wbl)
	{
		int wearable = TF2Util_GetPlayerWearable(client, wbl);
		if (wearable == -1)
			continue;
		
		myItems.Push(wearable);
	}
	
	int numItems = myItems.Length;
	for (int i = 0; i < numItems; ++i)
	{
		int item = myItems.Get(i);
		int def_index = GetEntProp(item, Prop_Send, "m_iItemDefinitionIndex");
		
		int index = g_hItemData.FindValue(def_index, ItemData::def_index);
		if (index == -1)
			continue;
		
		ItemData data;
		if (!g_hItemData.GetArray(index, data))
			continue;
		
		if (data.attributes)
		{
			for (int j = 0; j < data.attributes.Length; ++j)
			{
				AttributeData attribute;
				if (data.attributes.GetArray(j, attribute))
				{
					TF2Attrib_SetByName(item, attribute.name, attribute.value);
				}
			}
		}
		
		if (data.netprops)
		{
			for (int j = 0; j < data.netprops.Length; ++j)
			{
				NetPropData netprop;
				if (data.netprops.GetArray(j, netprop))
				{
					switch (netprop.field_type)
					{
						case PropField_Integer:
						{
							SetEntProp(client, netprop.type, netprop.name, netprop.int_value, _, netprop.element);
						}
						case PropField_Float:
						{
							SetEntPropFloat(client, netprop.type, netprop.name, netprop.float_value, netprop.element);
						}
						case PropField_String:
						{
							SetEntPropString(client, netprop.type, netprop.name, netprop.value, netprop.element);
						}
					}
				}
			}
		}
	}
	
	delete myItems;
}
