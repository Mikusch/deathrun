static char g_CommandPrefixes[][] =  {
	"dr", 
	"dr_", 
	"deathrun", 
	"deathrun_"
};

void Commands_Init()
{
	RegConsoleCmd("dr", Command_MainMenu, "Displays the main gamemode menu");
	RegConsoleCmd("deathrun", Command_MainMenu, "Displays the main gamemode menu");
	
	Command_Create("next", Command_QueueMenu, "Displays the queue of activators");
	Command_Create("queue", Command_QueueMenu, "Displays the queue of activators");
	Command_Create("preferences", Command_PreferencesMenu, "Displays settings");
	Command_Create("settings", Command_PreferencesMenu, "Displays settings");
	
	Command_Create("tp", Command_Thirdperson, "Toggles Thirdperson mode");
	Command_Create("thirdperson", Command_Thirdperson, "Toggles Thirdperson mode");
	
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
}

stock void Command_Create(const char[] cmd, ConCmd callback, const char[] description = "")
{
	for (int i = 0; i < sizeof(g_CommandPrefixes); i++)
	{
		char buffer[256];
		Format(buffer, sizeof(buffer), "%s%s", g_CommandPrefixes[i], cmd);
		RegConsoleCmd(buffer, callback, description);
	}
}

public Action Command_MainMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

public Action Command_QueueMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

public Action Command_PreferencesMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

public Action Command_Thirdperson(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "This command can only be used in-game");
		return Plugin_Handled;
	}
	
	if (!dr_allow_thirdperson.BoolValue)
	{
		CPrintToChat(client, DEATHRUN_TAG..." The server operator has disabled this command.");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	if (player.ThirdpersonEnabled)
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		CPrintToChat(client, DEATHRUN_TAG..." You have disabled thirdperson mode.");
	}
	else
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		CPrintToChat(client, DEATHRUN_TAG..." You have enabled thirdperson mode.");
	}
	
	player.ThirdpersonEnabled = !player.ThirdpersonEnabled;
	
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