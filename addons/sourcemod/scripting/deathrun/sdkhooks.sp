static char g_OwnerEntityList[][] =  {
	"weapon",
	"wearable",
	"prop_physics",	//Concheror
	"tf_projectile"
};

void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
}

public void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < sizeof(g_OwnerEntityList); i++)
	{
		if (StrContains(classname, g_OwnerEntityList[i]) != -1)
		{
			if (HasEntProp(entity, Prop_Send, "m_hThrower"))
				SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ThrownEntitySetTransmit);
			else
				SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnedEntitySetTransmit);
		}
	}
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
