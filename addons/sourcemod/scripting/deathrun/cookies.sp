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

void Cookies_Refresh()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			Cookies_RefreshQueue(client);
			Cookies_RefreshSettings(client);
		}
	}
}

void Cookies_RefreshQueue(int client)
{
	char value[16];
	g_CookieQueuePoints.Get(client, value, sizeof(value));
	DRPlayer(client).QueuePoints = StringToInt(value);
}

void Cookies_SaveQueue(int client, int value)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char value[16];
		IntToString(value, value, sizeof(value));
		g_CookieQueuePoints.Set(client, value);
	}
}

void Cookies_RefreshSettings(int client)
{
	char value[16];
	g_CookieSettings.Get(client, value, sizeof(value));
	DRPlayer(client).Settings = StringToInt(value);
}

void Cookies_SaveSettings(int client, int value)
{
	if (IsValidClient(client) && !IsFakeClient(client))
	{
		char value[16];
		IntToString(value, value, sizeof(value));
		g_CookieSettings.Set(client, value);
	}
}
