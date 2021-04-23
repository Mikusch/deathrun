/*
 * Copyright (C) 2020  Mikusch
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

static Cookie g_CookieQueuePoints;
static Cookie g_CookiePreferences;

void Cookies_Init()
{
	g_CookieQueuePoints = new Cookie("dr_queue", "Deathrun Queue Points", CookieAccess_Protected);
	g_CookiePreferences = new Cookie("dr_preferences", "Deathrun Preferences Bitmask", CookieAccess_Protected);
}

void Cookies_RefreshQueue(int client)
{
	if(g_Enabled) return;
	
	char value[16];
	g_CookieQueuePoints.Get(client, value, sizeof(value));
	DRPlayer(client).QueuePoints = StringToInt(value);
}

void Cookies_SaveQueue(int client, int value)
{
	if(g_Enabled) return;
	
	if (IsValidClient(client))
	{
		char strValue[16];
		IntToString(value, strValue, sizeof(strValue));
		g_CookieQueuePoints.Set(client, strValue);
	}
}

void Cookies_RefreshPreferences(int client)
{
	if(g_Enabled) return;
	
	char value[16];
	g_CookiePreferences.Get(client, value, sizeof(value));
	DRPlayer(client).Preferences = StringToInt(value);
}

void Cookies_SavePreferences(int client, int value)
{
	if(g_Enabled) return;
	
	if (IsValidClient(client))
	{
		char strValue[16];
		IntToString(value, strValue, sizeof(strValue));
		g_CookiePreferences.Set(client, strValue);
	}
}
