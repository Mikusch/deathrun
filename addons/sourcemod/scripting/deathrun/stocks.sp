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

stock bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
}

stock void StringToVector(const char[] buffer, float vec[3], float defvalue[3] =  { 0.0, 0.0, 0.0 } )
{
	if (strlen(buffer) == 0)
	{
		vec[0] = defvalue[0];
		vec[1] = defvalue[1];
		vec[2] = defvalue[2];
		return;
	}
	
	char parts[3][32];
	int iReturned = ExplodeString(buffer, StrContains(buffer, ",") != -1 ? ", " : " ", parts, 3, 32);
	
	if (iReturned != 3)
	{
		vec[0] = defvalue[0];
		vec[1] = defvalue[1];
		vec[2] = defvalue[2];
		return;
	}
	
	vec[0] = StringToFloat(parts[0]);
	vec[1] = StringToFloat(parts[1]);
	vec[2] = StringToFloat(parts[2]);
}

stock any Min(any a, any b)
{
	return (a < b) ? a : b;
}

stock any Max(any a, any b)
{
	return (a > b) ? a : b;
}

stock int TF2_GetItemInSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (!IsValidEntity(weapon))
	{
		// If no weapon was found in the slot, check if it is a wearable
		int wearable = SDKCalls_GetEquippedWearableForLoadoutSlot(client, slot);
		if (IsValidEntity(wearable))
			weapon = wearable;
	}
	
	return weapon;
}

stock int TF2_GetMaxHealth(int client)
{
	return GetEntProp(GetPlayerResourceEntity(), Prop_Send, "m_iMaxHealth", _, client);
}

stock void TF2_ChangeClientTeamAlive(int client, TFTeam team)
{
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Unknown)
	{
		// Player hasn't chosen a class. Choose one for him.
		TF2_SetPlayerClass(client, view_as<TFClassType>(GetRandomInt(1, 9)));
	}
	
	if (TF2_GetClientTeam(client) == team && class != TFClass_Unknown)	//Already in same team
		return;
	
	SetEntProp(client, Prop_Send, "m_lifeState", LIFE_DEAD);
	TF2_ChangeClientTeam(client, team);
	SetEntProp(client, Prop_Send, "m_lifeState", LIFE_ALIVE);
	
	TF2_RespawnPlayer(client);
}

stock int GetAliveClientCount()
{
	int count = 0;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
			count++;
	}
	return count;
}

stock void PrintMessage(int client, const char[] format, any...)
{
	char message[MAX_BUFFER_LENGTH];
	VFormat(message, sizeof(message), format, 3);
	Format(message, sizeof(message), "[{primary}"...PLUGIN_NAME..."{default}] %s", message);
	CPrintToChat(client, message);
}

stock void PrintMessageToAll(const char[] format, any...)
{
	char message[MAX_BUFFER_LENGTH];
	VFormat(message, sizeof(message), format, 2);
	Format(message, sizeof(message), "[{primary}"...PLUGIN_NAME..."{default}] %s", message);
	CPrintToChatAll(message);
}
