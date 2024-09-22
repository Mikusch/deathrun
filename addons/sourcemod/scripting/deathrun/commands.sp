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
