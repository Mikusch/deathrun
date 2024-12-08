#pragma newdecls required
#pragma semicolon 1

void Commands_Init()
{
	RegConsoleCmd("sm_queue", OnCommand_ShowQueue, "Displays the current activator queue.");
	RegConsoleCmd("sm_hideplayers", OnCommand_HidePlayers, "Hides players on the same team.");
	RegConsoleCmd("+sm_hideplayers", OnCommand_HidePlayers, "Hides players on the same team.");
	RegConsoleCmd("-sm_hideplayers", OnCommand_HidePlayers, "Hides players on the same team.");
	RegConsoleCmd("sm_deathrun", OnCommand_OpenMainMenu, "Opens the main menu.");
	RegConsoleCmd("sm_dr", OnCommand_OpenMainMenu, "Opens the main menu.");
	RegConsoleCmd("sm_queue", OnCommand_OpenQueueMenu, "Opens the queue menu.");
	RegConsoleCmd("sm_drnext", OnCommand_OpenQueueMenu, "Opens the queue menu.");
	RegConsoleCmd("sm_settings", OnCommand_OpenPreferencesMenu, "Opens the preferences menu.");
	RegConsoleCmd("sm_preferences", OnCommand_OpenPreferencesMenu, "Opens the preferences menu.");
	
	RegAdminCmd("sm_addqueue", OnCommand_AddQueuePoints, ADMFLAG_GENERIC, "Adds queue points to players.");
}

static Action OnCommand_ShowQueue(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

static Action OnCommand_HidePlayers(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	player.IsHidingPlayers = !player.IsHidingPlayers;
	return Plugin_Handled;
}

static Action OnCommand_OpenMainMenu(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

static Action OnCommand_OpenQueueMenu(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

static Action OnCommand_OpenPreferencesMenu(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

static Action OnCommand_AddQueuePoints(int client, int args)
{
	if (!PSM_IsEnabled())
		return Plugin_Continue;
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addqueue <#userid|name> <amount>");
		return Plugin_Handled;
	}
	
	char target[MAX_TARGET_LENGTH];
	GetCmdArg(1, target, sizeof(target));
	
	int amount = GetCmdArgInt(2);
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(target, client, target_list, sizeof(target_list), COMMAND_TARGET_NONE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		DRPlayer(target_list[i]).AddQueuePoints(amount);
	}
	
	if (tn_is_ml)
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Added Queue Points", amount, target_name);
	}
	else
	{
		CReplyToCommand(client, "%s %t", PLUGIN_TAG, "Added Queue Points", amount, "_s", target_name);
	}
	
	return Plugin_Handled;
}
