void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
}

public Action SDKHookCB_ClientSetTransmit(int entity, int client)
{
	RemoveAlwaysTransmit(entity);
	
	if (DRPlayer(client).CanHideClient(entity))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_ThrownEntitySetTransmit(int entity, int client)
{
	RemoveAlwaysTransmit(entity);
	
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (DRPlayer(client).CanHideClient(thrower))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_OwnedEntitySetTransmit(int entity, int client)
{
	RemoveAlwaysTransmit(entity);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (DRPlayer(client).CanHideClient(owner))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
