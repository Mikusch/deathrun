void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
	SDKHook(client, SDKHook_PreThink, SDKHookCB_ClientPreThink);
}

public Action SDKHookCB_ClientSetTransmit(int entity, int client)
{
	RemoveEdictAlwaysTransmitFlag(entity);
	
	if (DRPlayer(client).HasPreference(Preference_HidePlayers)	//Check if this client wants to hide other players
		 && TF2_GetClientTeam(client) == TFTeam_Runners	//Only runners can hide other players
		 && IsPlayerAlive(client)	//Stop hiding players when dead
		 && client != entity	//Don't hide ourself
		 && IsValidClient(entity)	//Only hide client entities
		 && TF2_GetClientTeam(entity) != TFTeam_Activator)	//Do not hide the activator
	return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_OwnedEntitySetTransmit(int entity, int client)
{
	RemoveEdictAlwaysTransmitFlag(entity);
	
	if (DRPlayer(client).HasPreference(Preference_HidePlayers)	//Check if this client wants to hide other player's items
		 && TF2_GetClientTeam(client) == TFTeam_Runners	//Only runners can hide other player's items
		 && IsPlayerAlive(client))
	{
		int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if (owner != client && IsValidClient(owner) && TF2_GetClientTeam(owner) != TFTeam_Activator)	// Don't hide the activator's items
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void SDKHookCB_ClientPreThink(int client)
{
	Timer_OnClientThink(client);
}
