static float g_TimerStartTime;
static float g_TimerEndTime;

static Handle g_RoundTimerHudSync;

void Timer_Init()
{
	g_RoundTimerHudSync = CreateHudSynchronizer();
}

void Timer_OnRoundStart()
{
	g_TimerStartTime = GetGameTime();
	g_TimerEndTime = g_TimerStartTime + dr_round_time.FloatValue;
	
	if (g_TimerEndTime > g_TimerStartTime)
		CreateTimer(g_TimerEndTime - g_TimerStartTime, Timer_ExplodePlayers);
}

void Timer_Think()
{
	if (g_TimerEndTime > g_TimerStartTime && GameRules_GetRoundState() == RoundState_Stalemate)
	{
		float timeLeft = g_TimerEndTime - GetGameTime();
		if (timeLeft >= 0)
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					int mins = (RoundToFloor(timeLeft) / 60) % 60;
					int secs = RoundToFloor(timeLeft) % 60;
					ShowSyncHudText(client, g_RoundTimerHudSync, "Round time left: %02d:%02d", mins, secs);
					SetHudTextParams(-1.0, 0.925, 0.1, 0, 255, 255, 255);
				}
			}
		}
	}
}

Action Timer_ExplodePlayers(Handle timer)
{
	int activator = GetActivator();
	if (GameRules_GetRoundState() == RoundState_Stalemate && activator != -1)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Red)
					SDKHooks_TakeDamage(client, _, _, float(INTEGER_MAX_VALUE), DMG_BLAST);
			}
			
			//No, this is not a bug ;)
			EmitSoundToAll(TIMER_EXPLOSION_SOUND);
		}
	}
}
