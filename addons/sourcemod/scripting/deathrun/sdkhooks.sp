void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
	SDKHook(client, SDKHook_PreThink, SDKHookCB_ClientPreThink);
}

public Action SDKHookCB_ClientSetTransmit(int entity, int client)
{
	if (!DRPlayer(client).GetPreference(Preference_HidePlayers)	//Check if this client wants to hide other players
		 && TF2_GetClientTeam(client) == TFTeam_Red	//Only runners can hide other players
		 && client != entity	//Don't hide ourself
		 && 0 < entity <= MaxClients	//Only hide client entities
		 && IsPlayerAlive(client)	//Stop hiding players when dead
		 && IsClientInGame(entity) && TF2_GetClientTeam(entity) != TFTeam_Blue)	//Do not hide the activator
	return Plugin_Handled;
	
	return Plugin_Continue;
}

public void SDKHookCB_ClientPreThink(int client)
{
	Timer_OnClientThink(client);
}
