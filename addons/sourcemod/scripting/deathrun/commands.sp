void Commands_Init()
{
	RegConsoleCmd("drnext", Command_Queue, "Displays the queue of activators");
	RegConsoleCmd("drsettings", Command_Settings, "Displays settings");
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
