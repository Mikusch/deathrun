void Console_Init()
{
	AddCommandListener(CommandListener_Build, "build");
	AddCommandListener(CommandListener_JoinTeam, "jointeam");
	AddCommandListener(CommandListener_JoinTeam, "autoteam");
	AddCommandListener(CommandListener_JoinTeam, "spectate");
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
	if (GetActivator() == -1)
		return Plugin_Continue;
	
	if (DRPlayer(client).IsActivator())
		TF2_ChangeClientTeam(client, TFTeam_Blue);
	else
		TF2_ChangeClientTeam(client, TFTeam_Red);
	
	ShowVGUIPanel(client, TF2_GetClientTeam(client) == TFTeam_Red ? "class_red" : "class_blue");
	
	return Plugin_Handled;
}
