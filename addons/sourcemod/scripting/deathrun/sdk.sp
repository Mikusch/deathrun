static Handle g_DHookGiveNamedItem;

void SDK_Init()
{
	GameData gamedata = new GameData("deathrun");
	if (gamedata == null)
		SetFailState("Could not find deathrun gamedata");
	
	g_DHookGiveNamedItem = DHook_CreateVirtual(gamedata, "CTFPlayer::GiveNamedItem");
}

static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, false, preCallback))
				LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION)
			if (!DHookEnableDetour(detour, true, postCallback))
				LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

static Handle DHook_CreateVirtual(GameData gamedata, const char[] name)
{
	Handle hook = DHookCreateFromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create virtual: %s", name);
	
	return hook;
}

void DHook_HookGiveNamedItem(int client)
{
	if (g_DHookGiveNamedItem)
	{
		DHookEntity(g_DHookGiveNamedItem, false, client, _, DHook_GiveNamedItemPre);
		DHookEntity(g_DHookGiveNamedItem, true, client, _, DHook_GiveNamedItemPost);
	}
}

public MRESReturn DHook_GiveNamedItemPre(int client, Handle returnVal, Handle params)
{
	/*if (DHookIsNullParam(params, 1) || DHookIsNullParam(params, 3))
	{
		DHookSetReturn(returnVal, 0);
		return MRES_Override;
	}
	
	char classname[256];
	DHookGetParamString(params, 1, classname, sizeof(classname));
	int defindex = DHookGetParamObjectPtrVar(params, 3, g_OffsetItemDefinitionIndex, ObjectValueType_Int) & 0xFFFF;
	
	if (CanKeepWeapon(classname, index))
		return MRES_Ignored;
	
	HookSetReturn(returnVal, 0);
	return MRES_Override;*/
}

public MRESReturn DHook_GiveNamedItemPost(int client, Handle returnVal, Handle params)
{
	int weapon = DHookGetReturn(returnVal);
	if (weapon > 0)
	{
		int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		// TODO: This is a bloody mess, doesn't get called half of the time
		// Move this to post_inventory_application or something and then iterate the slots, anything to make this work
		WeaponConfig config;
		if (g_Weapons.GetByDefIndex(defindex, config) > 0)
		{
			for (int i = 0; i < config.attributes.Length; i++)
			{
				WeaponAttributeConfig attribute;
				if (config.attributes.GetArray(i, attribute, sizeof(attribute)) > 0)
				{
					if (attribute.mode == ModMode_Set)
						TF2Attrib_SetByName(weapon, attribute.name, attribute.value);
					else if (attribute.mode == ModMode_Add)
						TF2Attrib_SetByName(weapon, attribute.name, TF2Attrib_GetValue(TF2Attrib_GetByName(weapon, attribute.name)) + attribute.value);
					else if (attribute.mode == ModMode_Subtract)
						TF2Attrib_SetByName(weapon, attribute.name, TF2Attrib_GetValue(TF2Attrib_GetByName(weapon, attribute.name)) - attribute.value);
					else if (attribute.mode == ModMode_Remove)
						TF2Attrib_RemoveByName(weapon, attribute.name);
				}
			}
			
			for (int i = 0; i < config.props.Length; i++)
			{
				WeaponEntPropConfig prop;
				if (config.props.GetArray(i, prop, sizeof(prop)) > 0)
				{
					switch (prop.fieldType)
					{
						case PropField_Integer: SetEntProp(weapon, prop.type, prop.name, StringToInt(prop.value));
						case PropField_Float: SetEntPropFloat(weapon, prop.type, prop.name, StringToFloat(prop.value));
						case PropField_Vector:
						{
							float vector[3];
							StringToVector(prop.value, vector);
							SetEntPropVector(weapon, prop.type, prop.name, vector);
						}
						case PropField_String: SetEntPropString(weapon, prop.type, prop.name, prop.value);
					}
				}
			}
		}
	}
}

stock void StringToVector(const char[] buffer, float vec[3], float defvalue[3] = {0.0, 0.0, 0.0})
{
	if (strlen(buffer) == 0)
	{
		vec[0] = defvalue[0];
		vec[1] = defvalue[1];
		vec[2] = defvalue[2];
		return;
	}

	char sPart[3][32];
	int iReturned = ExplodeString(buffer, StrContains(buffer, ",") != -1 ? ", " : " ", sPart, 3, 32);

	if (iReturned != 3)
	{
		vec[0] = defvalue[0];
		vec[1] = defvalue[1];
		vec[2] = defvalue[2];
		return;
	}

	vec[0] = StringToFloat(sPart[0]);
	vec[1] = StringToFloat(sPart[1]);
	vec[2] = StringToFloat(sPart[2]);
}