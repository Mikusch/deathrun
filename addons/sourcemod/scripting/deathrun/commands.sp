static char g_CommandPrefixes[][] =  {
	"dr", 
	"dr_", 
	"deathrun", 
	"deathrun_"
};

void Commands_Init()
{
	RegConsoleCmd("dr", Command_MainMenu);
	RegConsoleCmd("deathrun", Command_MainMenu);
	
	Command_Create("next", Command_QueueMenu);
	Command_Create("queue", Command_QueueMenu);
	Command_Create("preferences", Command_PreferencesMenu);
	Command_Create("settings", Command_PreferencesMenu);
	
	Command_Create("tp", Command_Thirdperson);
	Command_Create("thirdperson", Command_Thirdperson);
	Command_Create("fp", Command_Firstperson);
	Command_Create("firstperson", Command_Firstperson);
}

stock void Command_Create(const char[] cmd, ConCmd callback)
{
	for (int i = 0; i < sizeof(g_CommandPrefixes); i++)
	{
		char buffer[256];
		Format(buffer, sizeof(buffer), "%s%s", g_CommandPrefixes[i], cmd);
		RegConsoleCmd(buffer, callback);
	}
}

public Action Command_MainMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command_NotUsableInConsole");
		return Plugin_Handled;
	}
	
	Menus_DisplayMainMenu(client);
	return Plugin_Handled;
}

public Action Command_QueueMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command_NotUsableInConsole");
		return Plugin_Handled;
	}
	
	Menus_DisplayQueueMenu(client);
	return Plugin_Handled;
}

public Action Command_PreferencesMenu(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command_NotUsableInConsole");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

public Action Command_Thirdperson(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command_NotUsableInConsole");
		return Plugin_Handled;
	}
	
	if (!dr_allow_thirdperson.BoolValue)
	{
		PrintLocalizedMessage(client, "%t", "Command_Disabled");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	if (player.InThirdPerson)
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		PrintHintText(client, "%t", "Command_ThirdPerson_Disabled");
	}
	else
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		PrintHintText(client, "%t", "Command_ThirdPerson_Enabled");
	}
	
	player.InThirdPerson = !player.InThirdPerson;
	return Plugin_Handled;
}

public Action Command_Firstperson(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command_NotUsableInConsole");
		return Plugin_Handled;
	}
	
	if (!dr_allow_thirdperson.BoolValue)
	{
		PrintLocalizedMessage(client, "%t", "Command_Disabled");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	if (player.InThirdPerson)
	{
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		PrintHintText(client, "%t", "Command_ThirdPerson_Disabled");
	}
	
	player.InThirdPerson = false;
	return Plugin_Handled;
}
