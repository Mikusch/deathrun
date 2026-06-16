#pragma newdecls required
#pragma semicolon 1

static Cookie g_cookieQueue;
static Cookie g_cookiePreferences;

void ClientPrefs_Init()
{
	g_cookieQueue = new Cookie("dr_queue", "Deathrun: Queue Points", CookieAccess_Protected);
	g_cookiePreferences = new Cookie("dr_preferences", "Deathrun: Preferences", CookieAccess_Protected);
}

void ClientPrefs_OnClientCookiesCached(int client)
{
	DRPlayer player = DRPlayer(client);
	player.QueuePoints = g_cookieQueue.GetInt(client);
	player.Preferences = g_cookiePreferences.GetInt(client);
}

void ClientPrefs_SaveQueuePoints(int client)
{
	g_cookieQueue.SetInt(client, DRPlayer(client).QueuePoints);
}

void ClientPrefs_SavePreferences(int client)
{
	g_cookiePreferences.SetInt(client, DRPlayer(client).Preferences);
}
