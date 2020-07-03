static float g_TimerStartTime;
static float g_TimerEndTime;

static Handle g_RoundTimerHudSync;

static char g_ChatTips[][] =  {
	"ChatTip_HideRunners", 
	"ChatTip_ActivatorWeapons", 
	"ChatTip_CheckQueue", 
	"ChatTip_DisableChatTips", 
	"ChatTip_DisableActivator"
};

void Timer_Init()
{
	g_RoundTimerHudSync = CreateHudSynchronizer();
	
	if (dr_chattips_interval.IntValue > 0)
		CreateTimer(dr_chattips_interval.FloatValue, Timer_PrintChatTip, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_OnRoundStart()
{
	g_TimerStartTime = GetGameTime();
	g_TimerEndTime = g_TimerStartTime + dr_round_time.FloatValue;
	
	if (g_TimerEndTime > g_TimerStartTime)
		g_RoundTimer = CreateTimer(g_TimerEndTime - g_TimerStartTime, Timer_ExplodePlayers, _, TIMER_FLAG_NO_MAPCHANGE);
}

void Timer_OnClientThink(int client)
{
	if (g_TimerEndTime > g_TimerStartTime && g_RoundTimer != null)
	{
		float timeLeft = g_TimerEndTime - GetGameTime();
		if (timeLeft >= 0)
		{
			int mins = RoundToFloor(timeLeft) / 60 % 60;
			int secs = RoundToFloor(timeLeft) % 60;
			ShowSyncHudText(client, g_RoundTimerHudSync, "Round time left: %02d:%02d", mins, secs);
			SetHudTextParams(-1.0, 0.925, 0.1, 0, 255, 255, 255);
		}
	}
}

public Action Timer_ExplodePlayers(Handle timer)
{
	if (timer != g_RoundTimer)
		return;
	
	int activator = GetActivator();
	if (activator != -1)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (IsPlayerAlive(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
					SDKHooks_TakeDamage(client, activator, 0, float(INTEGER_MAX_VALUE), DMG_BLAST);
			}
		}
		
		EmitGameSoundToAll(GAMESOUND_EXPLOSION);
	}
}

public Action Timer_PrintChatTip(Handle timer)
{
	char tip[MAX_MESSAGE_LENGTH];
	strcopy(tip, sizeof(tip), g_ChatTips[GetRandomInt(0, sizeof(g_ChatTips) - 1)]);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).HasPreference(Preference_HideChatTips))
			PrintLocalizedMessage(client, "%t", tip);
	}
}
