/**
 * Copyright (C) 2024  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

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
