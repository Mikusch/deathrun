static char g_OwnerEntityList[][] =  {
	"env_sniperdot", 
	"halloween_souls_pack", 
	"item_healthkit", 
	"tf_ammo_pack", 
	"tf_bonus_duck_pickup", 
	"tf_flame", 
	"tf_halloween_pickup", 
	"tf_weapon", 
	"tf_wearable"
};

void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	for (int i = 0; i < sizeof(g_OwnerEntityList); i++)
	{
		if (StrContains(classname, g_OwnerEntityList[i]) != -1)
		{
			RemoveAlwaysTransmit(entity);
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnedEntitySetTransmit);
		}
	}
	
	if (StrContains(classname, "tf_projectile") != -1)
	{
		RemoveAlwaysTransmit(entity);
		SDKHook(entity, SDKHook_SetTransmit, HasEntProp(entity, Prop_Send, "m_hThrower") ? SDKHookCB_ThrownEntitySetTransmit : SDKHookCB_OwnedEntitySetTransmit);
	}
	
	if (StrEqual(classname, "tf_ragdoll"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_RagdollSetTransmit);
	}
	
	if (StrEqual(classname, "tf_dropped_weapon"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_DroppedWeaponSetTransmit);
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
	if (IsValidClient(thrower) && DRPlayer(client).CanHideClient(thrower))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_OwnedEntitySetTransmit(int entity, int client)
{
	RemoveAlwaysTransmit(entity);
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && DRPlayer(client).CanHideClient(owner))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_RagdollSetTransmit(int entity, int client)
{
	int playerIndex = GetEntProp(entity, Prop_Send, "m_iPlayerIndex");
	if (IsValidClient(playerIndex) && DRPlayer(client).CanHideClient(playerIndex))
	{
		//We need to remove the flag here instead because otherwise no ragdolls get created for anyone
		RemoveAlwaysTransmit(entity);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_DroppedWeaponSetTransmit(int entity, int client)
{
	int accountID = GetEntProp(entity, Prop_Send, "m_iAccountID");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetSteamAccountID(i, false) == accountID && DRPlayer(client).CanHideClient(i))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
