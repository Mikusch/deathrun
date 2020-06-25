void Commands_Init()
{
	RegConsoleCmd("drnext", Command_Queue, "Displays the queue of activators");
	RegConsoleCmd("drsettings", Command_Settings, "Displays settings");
	
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
}

public Action Command_Queue(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueue(client);
	return Plugin_Handled;
}

public Action Command_Settings(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	Menus_DisplaySettings(client);
	return Plugin_Handled;
}

public Action CommandListener_Build(int client, const char[] command, int argc)
{
	//Disallow building
	return Plugin_Handled;
}

public Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	char team[32];
	GetCmdArg(1, team, sizeof(team));
	
	//Disallow joining activator team
	if (StrEqual(team, "blue", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}