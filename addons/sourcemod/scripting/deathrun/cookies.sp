static Cookie g_CookieQueuePoints;
static Cookie g_CookiePreferences;

void Cookies_Init()
{
	g_CookieQueuePoints = new Cookie("dr_queue", "Deathrun Queue Points", CookieAccess_Protected);
	g_CookiePreferences = new Cookie("dr_preferences", "Deathrun Preferences Bitmask", CookieAccess_Protected);
}

void Cookies_RefreshQueue(int client)
{
	char value[16];
	g_CookieQueuePoints.Get(client, value, sizeof(value));
	DRPlayer(client).QueuePoints = StringToInt(value);
}

void Cookies_SaveQueue(int client, int value)
{
	if (IsValidClient(client))
	{
		char strValue[16];
		IntToString(value, strValue, sizeof(strValue));
		g_CookieQueuePoints.Set(client, strValue);
	}
}

void Cookies_RefreshPreferences(int client)
{
	char value[16];
	g_CookiePreferences.Get(client, value, sizeof(value));
	DRPlayer(client).Preferences = StringToInt(value);
}

void Cookies_SavePreferences(int client, int value)
{
	if (IsValidClient(client))
	{
		char strValue[16];
		IntToString(value, strValue, sizeof(strValue));
		g_CookiePreferences.Set(client, strValue);
	}
}
