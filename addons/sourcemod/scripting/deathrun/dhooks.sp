static DynamicHook g_DHookSetWinningTeam;

void DHooks_Init(GameData gamedata)
{
	g_DHookSetWinningTeam = DynamicHook.FromConf(gamedata, "CTeamplayRoundBasedRules::SetWinningTeam");
	
	DynamicDetour detour = DynamicDetour.FromConf(gamedata, "CTFPlayer::TeamFortress_CalculateMaxSpeed");
	detour.Enable(Hook_Post, DHookCallback_CalculateMaxSpeed_Post);
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

public MRESReturn DHookCallback_CalculateMaxSpeed_Post(int client, DHookReturn ret, DHookParam param)
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
