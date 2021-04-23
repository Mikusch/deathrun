/*
 * Copyright (C) 2020  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

static char g_OwnerEntityList[][] =  {
	"env_sniperdot", 
	"halloween_souls_pack", 
	"light_dynamic", 
	"info_particle_system", 
	"item_healthkit", 
	"tf_ammo_pack", 
	"tf_bonus_duck_pickup", 
	"tf_flame", 
	"tf_halloween_pickup"
};

void SDKHooks_OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, SDKHookCB_ClientSetTransmit);
	SDKHook(client, SDKHook_OnTakeDamageAlive, SDKHookCB_ClientOnTakeDamageAlive);
}

void SDKHooks_OnEntityCreated(int entity, const char[] classname)
{
	if(!g_IsMapDR) return;
	
	for (int i = 0; i < sizeof(g_OwnerEntityList); i++)
	{
		if (StrContains(classname, g_OwnerEntityList[i]) != -1)
		{
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnerEntitySetTransmit);
		}
	}
	
	if (StrEqual(classname, "tf_dropped_weapon"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_DroppedWeaponSetTransmit);
	}
	
	if (StrEqual(classname, "vgui_screen"))
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_VGUIScreenSetTransmit);
	}
	
	if (strncmp(classname, "obj_", 4) == 0)
	{
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ObjectSetTransmit);
	}
	
	if (strncmp(classname, "tf_projectile_", 14) == 0)
	{
		if (HasEntProp(entity, Prop_Send, "m_hThrower"))
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ThrowerEntitySetTransmit);
		else if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
			SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_OwnerEntitySetTransmit);
	}
}

public Action SDKHookCB_ClientSetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	if (DRPlayer(client).CanHideClient(entity))
	{
		//Force player's items to not transmit
		for (int slot = 0; slot <= ItemSlot_Misc2; slot++)
		{
			int item = TF2_GetItemInSlot(entity, slot);
			if (IsValidEntity(item))
				SetEdictFlags(item, (GetEdictFlags(item) & ~FL_EDICT_ALWAYS));
		}
		
		//Force disguise weapon to not transmit
		int disguiseWeapon = GetEntPropEnt(entity, Prop_Send, "m_hDisguiseWeapon");
		if (IsValidEntity(disguiseWeapon))
			SetEdictFlags(disguiseWeapon, (GetEdictFlags(disguiseWeapon) & ~FL_EDICT_ALWAYS));
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_ClientOnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	if (DRPlayer(victim).IsActivator() && damagecustom == TF_CUSTOM_BACKSTAB && dr_backstab_damage.FloatValue > 0.0)
	{
		damage = dr_backstab_damage.FloatValue;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_OwnerEntitySetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(owner) && DRPlayer(client).CanHideClient(owner))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action SDKHookCB_DroppedWeaponSetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	int accountID = GetEntProp(entity, Prop_Send, "m_iAccountID");
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && (IsFakeClient(i) || GetSteamAccountID(i, false) == accountID) && DRPlayer(client).CanHideClient(i))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_VGUIScreenSetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	int obj = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if (IsValidEntity(obj) && HasEntProp(obj, Prop_Send, "m_hBuilder"))
	{
		int builder = GetEntPropEnt(obj, Prop_Send, "m_hBuilder");
		if (IsValidClient(builder) && DRPlayer(client).CanHideClient(builder))
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_ObjectSetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if (IsValidClient(builder) && DRPlayer(client).CanHideClient(builder))
	{
		//Level 3 sentry guns always transmit
		if (TF2_GetObjectType(entity) == TFObject_Sentry && GetEntProp(entity, Prop_Send, "m_iUpgradeLevel") == 3)
			SetEdictFlags(entity, (GetEdictFlags(entity) & ~FL_EDICT_ALWAYS));
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_ThrowerEntitySetTransmit(int entity, int client)
{
	if(!g_IsMapDR) return Plugin_Continue;
	
	int thrower = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
	if (IsValidClient(thrower) && DRPlayer(client).CanHideClient(thrower))
		return Plugin_Handled;
	
	return Plugin_Continue;
}
