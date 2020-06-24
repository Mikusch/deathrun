static Handle g_DHookGiveNamedItem;

static int g_DHookCalculateMaxSpeedClient;

void DHooks_Init(GameData gamedata)
{
	g_DHookGiveNamedItem = DHooks_CreateVirtual(gamedata, "CTFPlayer::GiveNamedItem");
	
	DHooks_CreateDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", DHookCallback_CalculateMaxSpeed_Pre, DHookCallback_CalculateMaxSpeed_Post);
}

static void DHooks_CreateDetour(GameData gamedata, const char[] name, DHookCallback preCallback = INVALID_FUNCTION, DHookCallback postCallback = INVALID_FUNCTION)
{
	Handle detour = DHookCreateFromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (preCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, false, preCallback))
			LogError("Failed to enable pre detour: %s", name);
		
		if (postCallback != INVALID_FUNCTION && !DHookEnableDetour(detour, true, postCallback))
			LogError("Failed to enable post detour: %s", name);
		
		delete detour;
	}
}

static Handle DHooks_CreateVirtual(GameData gamedata, const char[] name)
{
	Handle hook = DHookCreateFromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create virtual: %s", name);
	
	return hook;
}

void DHooks_OnClientPutInServer(int client)
{
	if (g_DHookGiveNamedItem)
		DHookEntity(g_DHookGiveNamedItem, false, client, _, DHookCallback_GiveNamedItem_Pre);
}


public MRESReturn DHookCallback_GiveNamedItem_Pre(int client, Handle returnVal, Handle params)
{
	//Block if one of the pointers is null
	if (DHookIsNullParam(params, 1) || DHookIsNullParam(params, 3))
	{
		DHookSetReturn(returnVal, 0);
		return MRES_Override;
	}
	
	char classname[256];
	DHookGetParamString(params, 1, classname, sizeof(classname));
	int defindex = DHookGetParamObjectPtrVar(params, 3, 4, ObjectValueType_Int) & 0xFFFF;
	
	//Remove weapon if specified in config
	WeaponConfig config;
	if (Config_GetWeaponByDefIndex(defindex, config) && config.remove)
	{
		DHookSetReturn(returnVal, 0);
		return MRES_Override;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_CalculateMaxSpeed_Pre(int client, Handle returnVal, Handle params)
{
	g_DHookCalculateMaxSpeedClient = client;
}

public MRESReturn DHookCallback_CalculateMaxSpeed_Post(int client, Handle returnVal, Handle params)
{
	client = g_DHookCalculateMaxSpeedClient;
	
	//We don't want speedy scouts
	if (IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		float speed = DHookGetReturn(returnVal);
		DHookSetReturn(returnVal, FloatMax(speed - 80.0, 1.0));
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}
