#pragma newdecls required
#pragma semicolon 1

void Hooks_Init()
{
	PSM_AddCommandListener(CommandListener_JoinTeam, "jointeam");
	PSM_AddCommandListener(CommandListener_JoinTeam, "autoteam");
	PSM_AddCommandListener(CommandListener_JoinTeam, "spectate");
	PSM_AddCommandListener(CommandListener_Suicide, "kill");
	PSM_AddCommandListener(CommandListener_Suicide, "explode");

	PSM_AddNormalSoundHook(OnNormalSoundPlayed);
}

static Action CommandListener_JoinTeam(int client, const char[] command, int argc)
{
	if (GameRules_GetRoundState() == RoundState_Pregame || GameRules_GetProp("m_bInWaitingForPlayers"))
		return Plugin_Continue;

	// Don't allow activators to switch teams during setup, or at any time when configured
	if (DRPlayer(client).IsActivator() && (GameRules_GetRoundState() == RoundState_Preround || dr_prevent_activator_escape.BoolValue))
		return Plugin_Handled;

	if (StrEqual(command, "autoteam", false))
	{
		// Rewrite autoteam
		FakeClientCommand(client, "jointeam %s", DRPlayer(client).IsActivator() ? "blue" : "red");
		return Plugin_Handled;
	}
	else if (StrEqual(command, "jointeam", false))
	{
		char team[16];
		if (argc > 0 && GetCmdArg(1, team, sizeof(team)))
		{
			if (StrEqual(team, "auto", false) || StrEqual(team, "blue", false) && !DRPlayer(client).IsActivator())
			{
				FakeClientCommand(client, "autoteam");
				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

static Action CommandListener_Suicide(int client, const char[] command, int argc)
{
	if (dr_prevent_activator_escape.BoolValue && DRPlayer(client).IsActivator() && IsPlayerAlive(client) && GameRules_GetRoundState() != RoundState_Preround)
	{
		// nope.avi
		PrintCenterText(client, "%t", "Activator Cannot Suicide");
		EmitGameSoundToClient(client, "Player.DenyWeaponSelection");
		return Plugin_Handled;
	}

	return Plugin_Continue;
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
