static char g_ChatTips[][] =  {
	"ChatTip_Deathrun", 
	"ChatTip_HideTeammates", 
	"ChatTip_ActivatorWeapons", 
	"ChatTip_CheckQueue", 
	"ChatTip_DisableChatTips", 
	"ChatTip_DisableActivator"
};

void Timers_Init()
{
	if (dr_chattips_interval.IntValue > 0)
		CreateTimer(dr_chattips_interval.FloatValue, Timer_PrintChatTip, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_PrintChatTip(Handle timer)
{
	char tip[MAX_MESSAGE_LENGTH];
	strcopy(tip, sizeof(tip), g_ChatTips[GetRandomInt(0, sizeof(g_ChatTips) - 1)]);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).HasPreference(Preference_HideChatTips))
			PrintMessage(client, "%t", tip);
	}
}
