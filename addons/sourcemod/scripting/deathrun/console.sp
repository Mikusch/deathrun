static char g_CommandPrefixes[][] =  {
	"dr", 
	"dr_", 
	"deathrun", 
	"deathrun_"
};

void Console_Init()
{
	RegConsoleCmd("dr", ConCmd_DeathrunMenu);
	RegConsoleCmd("deathrun", ConCmd_DeathrunMenu);
	
	RegConsoleCmd2("next", ConCmd_QueueMenu);
	RegConsoleCmd2("queue", ConCmd_QueueMenu);
	RegConsoleCmd2("preferences", ConCmd_PreferencesMenu);
	RegConsoleCmd2("settings", ConCmd_PreferencesMenu);
	
	RegConsoleCmd2("tp", ConCmd_ThirdPerson);
	RegConsoleCmd2("thirdperson", ConCmd_ThirdPerson);
	RegConsoleCmd2("fp", ConCmd_FirstPerson);
	RegConsoleCmd2("firstperson", ConCmd_FirstPerson);
	
	RegConsoleCmd2("hide", ConCmd_HideTeammates);
	RegConsoleCmd2("hideteammates", ConCmd_HideTeammates);
	RegConsoleCmd2("hideplayers", ConCmd_HideTeammates);
	
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	AddCommandListener(CommandListener_JoinTeam, "autoteam");
	AddCommandListener(CommandListener_JoinTeam, "spectate");
}

stock void RegConsoleCmd2(const char[] cmd, ConCmd callback)
{
	for (int i = 0; i < sizeof(g_CommandPrefixes); i++)
	{
		char buffer[256];
		Format(buffer, sizeof(buffer), "%s%s", g_CommandPrefixes[i], cmd);
		RegConsoleCmd(buffer, callback);
	}
}

public Action ConCmd_DeathrunMenu(int client, int args)
{
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
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	Menus_DisplayPreferencesMenu(client);
	return Plugin_Handled;
}

public Action ConCmd_ThirdPerson(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!dr_allow_thirdperson.BoolValue)
	{
		PrintMessage(client, "%t", "Command_Disabled");
		return Plugin_Handled;
	}
	
	SetVariantInt(true);
	if (AcceptEntityInput(client, "SetForcedTauntCam"))
	{
		DRPlayer(client).InThirdPerson = true;
		
		if (!IsPlayerAlive(client) || TF2_IsPlayerInCondition(client, TFCond_Taunting))
			PrintMessage(client, "%t", "Command_ThirdPerson_Enabled");
	}
	
	return Plugin_Handled;
}

public Action ConCmd_FirstPerson(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!dr_allow_thirdperson.BoolValue)
	{
		PrintMessage(client, "%t", "Command_Disabled");
		return Plugin_Handled;
	}
	
	SetVariantInt(false);
	if (AcceptEntityInput(client, "SetForcedTauntCam"))
	{
		DRPlayer(client).InThirdPerson = false;
		
		if (!IsPlayerAlive(client) || TF2_IsPlayerInCondition(client, TFCond_Taunting))
			PrintMessage(client, "%t", "Command_ThirdPerson_Disabled");
	}
	
	return Plugin_Handled;
}

public Action ConCmd_HideTeammates(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "%t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	DRPlayer player = DRPlayer(client);
	player.IsHidingTeammates = !player.IsHidingTeammates;
	
	PrintMessage(client, "%t", player.IsHidingTeammates ? "Command_HideTeammates_Enabled" : "Command_HideTeammates_Disabled");
	
	return Plugin_Handled;
}

public Action CommandListener_Build(int client, const char[] command, int argc)
{
	//Disallow building
	return Plugin_Handled;
}

public Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
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
