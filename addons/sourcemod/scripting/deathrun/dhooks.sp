static int g_DHookCalculateMaxSpeedClient;

void DHooks_Init(GameData gamedata)
{
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
