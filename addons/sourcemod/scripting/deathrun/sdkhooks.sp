static char g_OwnerEntityList[][] =  {
	"halloween_souls_pack", 
	"item_healthkit", 
	"tf_ammo_pack", 
	"tf_bonus_duck_pickup", 
	"tf_dropped_weapon", 
	"tf_flame", 	//TODO: Verify if this is needed
	"tf_halloween_pickup", 
	"tf_ragdoll", 
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
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnedEntitySetTransmit);
		}
	}
	
	//Thrown projectiles have m_hThrower instead of m_hOwnerEntity
	if (StrContains(classname, "tf_projectile") != -1)
	{
		if (HasEntProp(entity, Prop_Send, "m_hThrower"))
		{
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ThrownEntitySetTransmit);
		}
		else
		{
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
