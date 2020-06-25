static Cookie g_CookieQueuePoints;
static Cookie g_CookieSettings;

void Cookies_Init()
{
	g_CookieQueuePoints = new Cookie("dr_queue", "Queue points this player has", CookieAccess_Protected);
	g_CookieSettings = new Cookie("dr_settings", "Deathrun-specific settings", CookieAccess_Protected);
}

void Cookies_OnClientPutInServer(int client)
{
	Cookies_RefreshQueue(client);
	Cookies_RefreshSettings(client);
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

void Cookies_RefreshSettings(int client)
{
	int value;
	char cookieValue[16];
	g_CookieSettings.Get(client, cookieValue, sizeof(cookieValue));
	
	if (StringToIntEx(cookieValue, value) > 0)
		Settings_SetAll(client, value);
	else
		Settings_SetAll(client, 0);
}

void Cookies_SaveSettings(int client, int value)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client) || IsFakeClient(client))
		return;
	
	char cookieValue[16];
	IntToString(value, cookieValue, sizeof(cookieValue));
	g_CookieSettings.Set(client, cookieValue);
}
