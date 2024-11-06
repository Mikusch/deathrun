#pragma newdecls required
#pragma semicolon 1

static char g_ownerEntityList[][] =
{
	"env_sniperdot",
	"halloween_souls_pack",
	"light_dynamic",
	"info_particle_system",
	"item_healthkit",
	"tf_ammo_pack",
	"tf_bonus_duck_pickup",
	"tf_halloween_pickup"
};

static float g_buttonDamagedTime;

void SDKHooks_OnMapStart()
{
	g_buttonDamagedTime = 0.0;
}

void SDKHooks_HookEntity(int entity, const char[] classname)
{
	if (IsEntityClient(entity))
	{
		PSM_SDKHook(entity, SDKHook_SetTransmit, OnClientSetTransmit);
		PSM_SDKHook(entity, SDKHook_OnTakeDamageAlive, OnClientOnTakeDamageAlive);
	}
	else if (StrEqual(classname, "func_button"))
	{
		PSM_SDKHook(entity, SDKHook_OnTakeDamage, OnButtonTakeDamage);
	}
	else if (StrEqual(classname, "tf_dropped_weapon"))
	{
		PSM_SDKHook(entity, SDKHook_SetTransmit, OnDroppedWeaponSetTransmit);
	}
	else if (!strncmp(classname, "obj_", 4))
	{
		PSM_SDKHook(entity, SDKHook_SpawnPost, OnObjectSpawnPost);
		PSM_SDKHook(entity, SDKHook_SetTransmit, OnObjectSetTransmit);
	}
	else if (!strncmp(classname, "tf_projectile_", 14))
	{
		if (HasEntProp(entity, Prop_Send, "m_hThrower"))
			SDKHook(entity, SDKHook_SetTransmit, OnThrowerEntitySetTransmit);
		else if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
			SDKHook(entity, SDKHook_SetTransmit, OnOwnerEntitySetTransmit);
	}
	else if (StrEqual(classname, "tf_ragdoll"))
	{
		PSM_SDKHook(entity, SDKHook_SetTransmit, OnRagdollSetTransmit);
	}
	else if (StrEqual(classname, "vgui_screen"))
	{
		SDKHook(entity, SDKHook_SetTransmit, OnVGUIScreenSetTransmit);
	}
	else if (!strncmp(classname, "item_healthkit_", 15))
	{
		SDKHook(entity, SDKHook_Touch, OnHealthKitTouch);
	}
	else
	{
		for (int i = 0; i < sizeof(g_ownerEntityList); ++i)
		{
			if (StrEqual(classname, g_ownerEntityList[i]))
			{
				SDKHook(entity, SDKHook_SetTransmit, OnOwnerEntitySetTransmit);
			}
		}
	}
}

static Action OnClientSetTransmit(int entity, int client)
{
	if (IsEntityClient(entity) && DRPlayer(client).ShouldHideClient(entity))
	{
		RemoveEdictFlagFromChildren(entity, FL_EDICT_ALWAYS);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action OnClientOnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (DRPlayer(victim).IsActivator() && damagecustom == TF_CUSTOM_BACKSTAB && sm_dr_runner_backstab_damage.FloatValue > 0.0)
	{
		damage = sm_dr_runner_backstab_damage.FloatValue;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

static Action OnButtonTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Some maps allow runners to activate traps with ranged weapons
	if (!sm_dr_runner_allow_button_damage.BoolValue && (0 < attacker <= MaxClients) && !DRPlayer(attacker).IsActivator() && !(damagetype & DMG_MELEE))
		return Plugin_Handled;
	
	// Prevent multiple buttons from being hit at the same time
	if (g_buttonDamagedTime == GetGameTime() && view_as<TOGGLE_STATE>(GetEntProp(victim, Prop_Data, "m_toggle_state")) == TS_AT_BOTTOM)
		return Plugin_Handled;
	
	g_buttonDamagedTime = GetGameTime();
	
	return Plugin_Continue;
}

static void OnObjectSpawnPost(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_bWasMapPlaced"))
		return;
	
	if (TF2_GetObjectType(entity) == TFObject_Teleporter && sm_dr_allow_teleporters.BoolValue)
		return;
	
	SetVariantInt(SOLID_TO_PLAYER_NO);
	AcceptEntityInput(entity, "SetSolidToPlayer");
}

static Action OnObjectSetTransmit(int entity, int client)
{
	int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if (IsEntityClient(builder) && DRPlayer(client).ShouldHideClient(builder))
	{
		// Level 3 Sentry Guns always transmit
		if (TF2_GetObjectType(entity) == TFObject_Sentry && GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3)
			SetEdictFlags(entity, (GetEdictFlags(entity) & ~FL_EDICT_ALWAYS));
		
		RemoveEdictFlagFromChildren(entity, FL_EDICT_ALWAYS);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action OnDroppedWeaponSetTransmit(int entity, int client)
{
	int accountID = GetEntProp(entity, Prop_Send, "m_iAccountID");
	for (int i = 1; i <= MaxClients; ++i)
	{
		if (IsClientConnected(i) && (IsFakeClient(i) || GetSteamAccountID(i, false) == accountID) && DRPlayer(client).ShouldHideClient(i))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action OnThrowerEntitySetTransmit(int entity, int client)
{
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (IsEntityClient(thrower) && DRPlayer(client).ShouldHideClient(thrower))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static Action OnOwnerEntitySetTransmit(int entity, int client)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsEntityClient(owner) && DRPlayer(client).ShouldHideClient(owner))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static Action OnRagdollSetTransmit(int entity, int client)
{
	// CTFRagdoll will only call into SetTransmit once if we don't remove FL_EDICT_ALWAYS
	SetEdictFlags(entity, (GetEdictFlags(entity) & ~FL_EDICT_ALWAYS));
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hPlayer");
	if (IsEntityClient(owner) && DRPlayer(client).ShouldHideClient(owner))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

static Action OnVGUIScreenSetTransmit(int entity, int client)
{
	int obj = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidEntity(obj) && HasEntProp(obj, Prop_Send, "m_hBuilder"))
	{
		int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if (IsEntityClient(builder) && DRPlayer(client).ShouldHideClient(builder))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

static Action OnHealthKitTouch(int entity, int other)
{
	if ((0 < other <= MaxClients) && DRPlayer(other).IsActivator() && !sm_dr_activator_allow_healthkits.BoolValue)
		return Plugin_Handled;
	
	return Plugin_Continue;
}
