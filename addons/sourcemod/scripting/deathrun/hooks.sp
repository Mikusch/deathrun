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

void Hooks_Init()
{
	PSM_AddCommandListener(CommandListener_JoinTeam, "jointeam");
	PSM_AddCommandListener(CommandListener_JoinTeam, "autoteam");
	PSM_AddCommandListener(CommandListener_JoinTeam, "spectate");
	
	PSM_AddNormalSoundHook(OnNormalSoundPlayed);
}

static Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	if (GameRules_GetRoundState() == RoundState_Pregame || GameRules_GetProp("m_bInWaitingForPlayers"))
		return Plugin_Continue;
	
	char team[16];
	if (StrEqual(command, "spectate"))
		Format(team, sizeof(team), command);
	
	if (argc > 0 && StrEqual(command, "jointeam"))
		GetCmdArg(1, team, sizeof(team));
	
	if (StrEqual(team, "spectate"))
	{
		if (DRPlayer(client).IsActivator() && IsPlayerAlive(client) && (GameRules_GetRoundState() == RoundState_Stalemate || GameRules_GetRoundState() == RoundState_Preround))
			return Plugin_Handled;
		
		return Plugin_Continue;
	}
	
	if (DRPlayer(client).IsActivator())
		TF2_ChangeClientTeam(client, TFTeam_Activators);
	else
		TF2_ChangeClientTeam(client, TFTeam_Runners);
	
	ShowVGUIPanel(client, TF2_GetClientTeam(client) == TFTeam_Red ? "class_red" : "class_blue");
	
	return Plugin_Handled;
}

static Action OnNormalSoundPlayed(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
	if (IsEntityClient(entity))
	{
		return OnClientSoundPlayed(clients, numClients, entity);
	}
	else if (IsValidEntity(entity))
	{
		if (HasEntProp(entity, Prop_Send, "m_hBuilder"))
		{
			int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
			if (IsEntityClient(builder))
				return OnClientSoundPlayed(clients, numClients, builder);
		}
		else if (HasEntProp(entity, Prop_Send, "m_hThrower"))
		{
			int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
			if (IsEntityClient(thrower))
				return OnClientSoundPlayed(clients, numClients, thrower);
		}
		else if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		{
			int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			if (IsEntityClient(owner))
				return OnClientSoundPlayed(clients, numClients, owner);
		}
	}
	
	return Plugin_Continue;
}

static Action OnClientSoundPlayed(int clients[MAXPLAYERS], int &numClients, int client)
{
	Action action = Plugin_Continue;
	
	for (int i = 0; i < numClients; ++i)
	{
		if (DRPlayer(clients[i]).ShouldHideClient(client))
		{
			for (int j = i; j < numClients - 1; ++j)
			{
				clients[j] = clients[j + 1];
			}
			
			numClients--;
			i--;
			action = Plugin_Changed;
		}
	}
	
	return action;
}
