#pragma newdecls required
#pragma semicolon 1

static Cookie g_hCookieQueue;
static Cookie g_hCookiePreferences;

void ClientPrefs_Init()
{
	g_hCookieQueue = new Cookie("dr_queue", "Deathrun: Queue Points", CookieAccess_Protected);
	g_hCookiePreferences = new Cookie("dr_preferences", "Deathrun: Preferences", CookieAccess_Protected);
}

void ClientPrefs_OnClientCookiesCached(int client)
{
	DRPlayer player = DRPlayer(client);
	player.m_nQueuePoints = g_hCookieQueue.GetInt(client);
	player.m_preferences = g_hCookiePreferences.GetInt(client);
}

void ClientPrefs_SaveQueuePoints(int client)
{
	g_hCookieQueue.SetInt(client, DRPlayer(client).m_nQueuePoints);
}

void ClientPrefs_SavePreferences(int client)
{
	g_hCookiePreferences.SetInt(client, DRPlayer(client).m_preferences);
}
