static Handle g_DHookGiveNamedItem;

void SDK_Init()
{
	GameData gamedata = new GameData("royale");
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
		
		WeaponConfig config;
		if (g_Weapons.GetByDefIndex(defindex, config) > 0)
		{
			for (int i = 0; i < config.attributes.Length; i++)
			{
				WeaponAttributeConfig attribute;
				if (config.attributes.GetArray(i, attribute, sizeof(attribute) > 0))
				{
					if (attribute.mode == ModMode_Set)
						TF2Attrib_SetByName(weapon, attribute.name, attribute.value);
					else if (attribute.mode == ModMode_Remove)
						TF2Attrib_RemoveByName(weapon, attribute.name);
				}
			}
		}
	}
}
