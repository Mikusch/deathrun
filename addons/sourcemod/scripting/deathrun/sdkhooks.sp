#pragma newdecls required
#pragma semicolon 1

static char g_aOwnerEntityList[][] =
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

static float g_flButtonDamagedTime;

void SDKHooks_OnMapStart()
{
	g_flButtonDamagedTime = 0.0;
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
	else if (StrEqual(classname, "func_tracktrain") || StrEqual(classname, "func_tanktrain"))
	{
		PSM_SDKHook(entity, SDKHook_SpawnPost, OnTrackTrainSpawnPost);
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
	else
	{
		for (int i = 0; i < sizeof(g_aOwnerEntityList); ++i)
		{
			if (StrEqual(classname, g_aOwnerEntityList[i]))
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
	if (DRPlayer(victim).IsActivator() && damagecustom == TF_CUSTOM_BACKSTAB && sm_dr_backstab_damage.FloatValue > 0.0)
	{
		damage = sm_dr_backstab_damage.FloatValue;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

static Action OnButtonTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	// Some maps allow runners to activate traps with explosives, either by lobbing them over walls or because the map has very thin barriers.
	// There is no good reason for RED to activate buttons with blast damage, so just prevent this.
	if (0 < attacker <= MaxClients && TF2_GetClientTeam(attacker) == TFTeam_Runners && damagetype & DMG_BLAST)
		return Plugin_Handled;
	
	// Prevent multiple buttons from being hit at the same time
	if (g_flButtonDamagedTime == GetGameTime() && view_as<TOGGLE_STATE>(GetEntProp(victim, Prop_Data, "m_toggle_state")) == TS_AT_BOTTOM)
		return Plugin_Handled;
	
	g_flButtonDamagedTime = GetGameTime();
	
	return Plugin_Continue;
}

static void OnObjectSpawnPost(int entity)
{
	if (GetEntProp(entity, Prop_Send, "m_bWasMapPlaced"))
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

static void OnTrackTrainSpawnPost(int entity)
{
	// This spawnflag is set by default but there is no sensible reason to want this in TF2
	SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags") | SF_TRACKTRAIN_NOCONTROL);
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
