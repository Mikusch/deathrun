static Handle g_DHook_SetWinningTeam;

static int g_DHookCalculateMaxSpeedClient;

void DHooks_Init(GameData gamedata)
{
	g_DHook_SetWinningTeam = DHooks_CreateVirtual(gamedata, "CTeamplayRoundBasedRules::SetWinningTeam");
	
	DHooks_CreateDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", DHookCallback_CalculateMaxSpeed_Pre, DHookCallback_CalculateMaxSpeed_Post);
}

static Handle DHooks_CreateVirtual(GameData gamedata, const char[] name)
{
	Handle hook = DHookCreateFromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create hook: %s", name);
	
	return hook;
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

void DHooks_HookGamerules()
{
	DHookGamerules(g_DHook_SetWinningTeam, false, _, DHook_SetWinningTeam_Pre);
}

public MRESReturn DHook_SetWinningTeam_Pre(Handle params)
{
	int winReason = DHookGetParam(params, 2);
	
	//The arena timer has no assigned targetname and doesn't fire its OnFinished output before the round ends, making this the only way to detect the timer stalemate
	if (FindConVar("tf_arena_round_time").IntValue > 0 && winReason == WINREASON_STALEMATE && GetAliveClientCount() > 0)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
				SDKHooks_TakeDamage(client, GetRandomAliveActivator(), 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
		}
		
		EmitGameSoundToAll(GAMESOUND_EXPLOSION);
		
		DHookSetParam(params, 1, TFTeam_Activators); //team
		DHookSetParam(params, 2, WINREASON_TIMELIMIT); //iWinReason
		return MRES_ChangedOverride;
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
