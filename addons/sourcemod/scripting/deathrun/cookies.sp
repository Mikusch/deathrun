static Cookie g_CookieQueuePoints;

void Cookies_Init()
{
	g_CookieQueuePoints = new Cookie("dr_queue", "Queue points this player has", CookieAccess_Protected);
}

void Cookies_OnClientPutInServer(int client)
{
	Cookies_RefreshQueue(client);
}

void Cookies_RefreshQueue(int client)
{
	char cookieValue[16];
	g_CookieQueuePoints.Get(client, cookieValue, sizeof(cookieValue));
	
	int value = StringToInt(cookieValue);
	if (value > 0)
		DRPlayer(client).QueuePoints = value;
	else
		DRPlayer(client).QueuePoints = 0;
}

void Cookies_SaveQueue(int client, int value)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	char cookieValue[16];
	IntToString(value, cookieValue, sizeof(cookieValue));
	g_CookieQueuePoints.Set(client, cookieValue);
}
