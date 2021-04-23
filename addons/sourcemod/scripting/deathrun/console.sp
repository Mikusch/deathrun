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

static char g_CommandPrefixes[][] =  {
	"dr", 
	"dr_", 
	"deathrun", 
	"deathrun_"
};

void Console_Init()
{
	AddMultiTargetFilter("@runner", MultiTargetFilter_RunnerTeam, "Target_RunnerTeam", true);
	AddMultiTargetFilter("@runners", MultiTargetFilter_RunnerTeam, "Target_RunnerTeam", true);
	AddMultiTargetFilter("@activator", MultiTargetFilter_ActivatorTeam, "Target_ActivatorTeam", true);
	AddMultiTargetFilter("@activators", MultiTargetFilter_ActivatorTeam, "Target_ActivatorTeam", true);
	
	RegConsoleCmd("dr", ConCmd_DeathrunMenu);
	RegConsoleCmd("deathrun", ConCmd_DeathrunMenu);
	RegConsoleCmd2("menu", ConCmd_DeathrunMenu);
	
	RegConsoleCmd2("next", ConCmd_QueueMenu);
	RegConsoleCmd2("queue", ConCmd_QueueMenu);
	RegConsoleCmd2("preferences", ConCmd_PreferencesMenu);
	RegConsoleCmd2("settings", ConCmd_PreferencesMenu);
	
	RegConsoleCmd2("hide", ConCmd_HideTeammates);
	RegConsoleCmd2("hideplayers", ConCmd_HideTeammates);
	RegConsoleCmd2("hideteammates", ConCmd_HideTeammates);
	
	RegAdminCmd2("addpoints", ConCmd_AddQueuePoints, ADMFLAG_CHANGEMAP);
	RegAdminCmd2("addqueue", ConCmd_AddQueuePoints, ADMFLAG_CHANGEMAP);
	RegAdminCmd2("addqueuepoints", ConCmd_AddQueuePoints, ADMFLAG_CHANGEMAP);
	
	RegAdminCmd2("setpoints", ConCmd_SetQueuePoints, ADMFLAG_CHANGEMAP);
	RegAdminCmd2("setqueue", ConCmd_SetQueuePoints, ADMFLAG_CHANGEMAP);
	RegAdminCmd2("setqueuepoints", ConCmd_SetQueuePoints, ADMFLAG_CHANGEMAP);
	
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	AddCommandListener(CommandListener_JoinTeam, "autoteam");
	AddCommandListener(CommandListener_JoinTeam, "spectate");
}

void RegConsoleCmd2(const char[] cmd, ConCmd callback)
{
	for (int i = 0; i < sizeof(g_CommandPrefixes); i++)
	{
		char buffer[256];
		Format(buffer, sizeof(buffer), "%s%s", g_CommandPrefixes[i], cmd);
		RegConsoleCmd(buffer, callback);
	}
}

void RegAdminCmd2(const char[] cmd, ConCmd callback, int adminflags)
{
	for (int i = 0; i < sizeof(g_CommandPrefixes); i++)
	{
		char buffer[256];
		Format(buffer, sizeof(buffer), "%s%s", g_CommandPrefixes[i], cmd);
		RegAdminCmd(buffer, callback, adminflags);
	}
}

public bool MultiTargetFilter_RunnerTeam(const char[] pattern, ArrayList clients)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Runners)
			clients.Push(client);
	}
	
	return clients.Length > 0;
}

public bool MultiTargetFilter_ActivatorTeam(const char[] pattern, ArrayList clients)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && TF2_GetClientTeam(client) == TFTeam_Activators)
			clients.Push(client);
	}
	
	return clients.Length > 0;
}

public Action ConCmd_DeathrunMenu(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_QueueMenu(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_PreferencesMenu(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_HideTeammates(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	player.IsHidingTeammates = !player.IsHidingTeammates;
	
	CPrintToChat(client, PLUGIN_TAG ... " %t", player.IsHidingTeammates ? "Command_HideTeammates_Enabled" : "Command_HideTeammates_Disabled");
	
	return Plugin_Handled;
}

public Action ConCmd_AddQueuePoints(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (args < 2)
	{
		CReplyToCommand(client, PLUGIN_TAG ... " %t", "Command_AddQueuePoints_Usage");
		return Plugin_Handled;
	}
	
	char arg[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	
	int amount = 0;
	char arg2[16];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, amount) == 0 || amount <= 0)
	{
		CReplyToCommand(client, PLUGIN_TAG ... " %t", "Invalid Amount");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients + 1];
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;
	int target_count;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MaxClients + 1, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		Queue_AddPoints(target_list[i], amount);
	}
	
	if (tn_is_ml)
	{
		CShowActivity2(client, "{default}" ... PLUGIN_TAG ... " ", "%t", "Command_AddQueuePoints_Success", amount, target_name);
	}
	else
	{
		CShowActivity2(client, "{default}" ... PLUGIN_TAG ... " ", "%t", "Command_AddQueuePoints_Success", amount, "_s", target_name);
	}
	
	return Plugin_Handled;
}

public Action ConCmd_SetQueuePoints(int client, int args)
{
	if(g_Enabled) return Plugin_Continue;
	
	if (args < 2)
	{
		CReplyToCommand(client, PLUGIN_TAG ... " %t", "Command_SetQueuePoints_Usage");
		return Plugin_Handled;
	}
	
	char arg[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg, sizeof(arg));
	
	int amount = 0;
	char arg2[16];
	GetCmdArg(2, arg2, sizeof(arg2));
	if (StringToIntEx(arg2, amount) == 0 || amount < 0)
	{
		CReplyToCommand(client, PLUGIN_TAG ... " %t", "Invalid Amount");
		return Plugin_Handled;
	}
	
	int[] target_list = new int[MaxClients + 1];
	char target_name[MAX_TARGET_LENGTH];
	bool tn_is_ml;
	int target_count;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MaxClients + 1, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		CReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		Queue_SetPoints(target_list[i], amount);
	}
	
	if (tn_is_ml)
	{
		CShowActivity2(client, "{default}" ... PLUGIN_TAG ... " ", "%t", "Command_SetQueuePoints_Success", target_name, amount);
	}
	else
	{
		CShowActivity2(client, "{default}" ... PLUGIN_TAG ... " ", "%t", "Command_SetQueuePoints_Success", "_s", target_name, amount);
	}
	
	return Plugin_Handled;
}

public Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	if(g_Enabled) return Plugin_Continue;
	
	char team[64];
	if (strcmp(command, "spectate") == 0)
		Format(team, sizeof(team), command);
	
	if (strcmp(command, "jointeam") == 0 && argc > 0)
		GetCmdArg(1, team, sizeof(team));
	
	if (strcmp(team, "spectate") == 0)
	{
		RoundState roundState = GameRules_GetRoundState();
		if (DRPlayer(client).IsActivator() && IsPlayerAlive(client) && (roundState == RoundState_Stalemate || roundState == RoundState_Preround))
			return Plugin_Handled;
		
		return Plugin_Continue;
	}
	
	//Check if we have an active activator, otherwise we assume that no round was started
	if (g_CurrentActivators.Length == 0)
		return Plugin_Continue;
	
	if (DRPlayer(client).IsActivator())
		TF2_ChangeClientTeam(client, TFTeam_Activators);
	else
		TF2_ChangeClientTeam(client, TFTeam_Runners);
	
	ShowVGUIPanel(client, TF2_GetClientTeam(client) == TFTeam_Red ? "class_red" : "class_blue");
	
	return Plugin_Handled;
}
