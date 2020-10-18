static DynamicHook g_DHookSetWinningTeam;

void DHooks_Init(GameData gamedata)
{
	g_DHookSetWinningTeam = DHook_CreateVirtualHook(gamedata, "CTeamplayRoundBasedRules::SetWinningTeam");
	
	DHook_CreateDetour(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed", _, DHookCallback_CalculateMaxSpeed_Post);
}

static DynamicHook DHook_CreateVirtualHook(GameData gamedata, const char[] name)
{
	DynamicHook hook = DynamicHook.FromConf(gamedata, name);
	if (!hook)
		LogError("Failed to create virtual hook: %s", name);
	
	return hook;
}

static void DHook_CreateDetour(GameData gamedata, const char[] name, DHookCallback callbackPre = INVALID_FUNCTION, DHookCallback callbackPost = INVALID_FUNCTION)
{
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, name);
	if (!detour)
	{
		LogError("Failed to create detour: %s", name);
	}
	else
	{
		if (callbackPre != INVALID_FUNCTION)
			detour.Enable(Hook_Pre, callbackPre);
		
		if (callbackPost != INVALID_FUNCTION)
			detour.Enable(Hook_Post, callbackPost);
	}
}

void DHooks_HookGamerules()
{
	g_DHookSetWinningTeam.HookGamerules(Hook_Pre, DHook_SetWinningTeam_Pre);
}

public MRESReturn DHook_SetWinningTeam_Pre(DHookParam param)
{
	int winReason = param.Get(2);
	
	//The arena timer has no assigned targetname and doesn't fire its OnFinished output before the round ends, making this the only way to detect the timer stalemate
	if (FindConVar("tf_arena_round_time").IntValue > 0 && winReason == WINREASON_STALEMATE && GetAliveClientCount() > 0)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
			{
				if (g_CurrentActivators.Length == 1)
					SDKHooks_TakeDamage(client, g_CurrentActivators.Get(0), 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
				else
					SDKHooks_TakeDamage(client, 0, 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
			}
		}
		
		EmitGameSoundToAll(GAMESOUND_EXPLOSION);
		
		param.Set(1, TFTeam_Activators); //team
		param.Set(2, WINREASON_TIMELIMIT); //iWinReason
		return MRES_ChangedOverride;
	}
	
	return MRES_Ignored;
}

public MRESReturn DHookCallback_CalculateMaxSpeed_Post(int client, DHookReturn ret)
{
	//We don't want speedy scouts
	if (IsClientInGame(client) && TF2_GetPlayerClass(client) == TFClass_Scout)
	{
		float speed = ret.Value;
		ret.Value = FloatMax(speed - 80.0, 1.0);
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}
