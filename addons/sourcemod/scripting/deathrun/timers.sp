static char g_ChatTips[][] =  {
	"ChatTip_Deathrun", 
	"ChatTip_HideTeammates", 
	"ChatTip_ActivatorWeapons", 
	"ChatTip_CheckQueue", 
	"ChatTip_DisableChatTips", 
	"ChatTip_DisableActivator"
};

static Handle g_ChatTipTimer;

void Timers_Init()
{
	Timers_CreateChatTipTimer(dr_chattips_interval.FloatValue);
}

void Timers_CreateChatTipTimer(float interval)
{
	if (interval > 0.0)
		g_ChatTipTimer = CreateTimer(interval, Timer_PrintChatTip, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PrintChatTip(Handle timer)
{
	if (timer != g_ChatTipTimer)
		return Plugin_Stop;
	
	char tip[MAX_BUFFER_LENGTH];
	strcopy(tip, sizeof(tip), g_ChatTips[GetRandomInt(0, sizeof(g_ChatTips) - 1)]);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).HasPreference(Preference_HideChatTips))
			PrintMessage(client, "%t", tip);
	}
	
	return Plugin_Continue;
}
