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
	if (g_Enabled)
		return Plugin_Stop;
	
	char tip[MAX_BUFFER_LENGTH];
	strcopy(tip, sizeof(tip), g_ChatTips[GetRandomInt(0, sizeof(g_ChatTips) - 1)]);
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).HasPreference(Preference_HideChatTips))
			CPrintToChat(client, PLUGIN_TAG ... " %t", tip);
	}
	
	return Plugin_Continue;
}
