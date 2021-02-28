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
	"gib", 
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
	SDKHook(client, SDKHook_GetMaxHealth, SDKHookCB_ClientGetMaxHealth);
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
	
	if (StrContains(classname, "obj_") != -1)
	{
		RemoveAlwaysTransmit(entity);
		SDKHook(entity, SDKHook_SetTransmit, SDKHookCB_ObjectSetTransmit);
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

public Action SDKHookCB_ClientGetMaxHealth(int client, int &maxhealth)
{
	if (DRPlayer(client).IsActivator())
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (client != i && IsValidClient(i) && IsPlayerAlive(i) && !DRPlayer(i).IsActivator())
				maxhealth += RoundFloat(TF2_GetMaxHealth(i) * dr_activator_health_modifier.FloatValue);
		}
		
		maxhealth /= dr_activator_count.IntValue;
		
		//Refill the activator's health during preround
		if (GameRules_GetRoundState() == RoundState_Preround)
			SetEntityHealth(client, maxhealth);
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Action SDKHookCB_ObjectSetTransmit(int entity, int client)
{
	int builder = GetEntPropEnt(entity, Prop_Send, "m_hBuilder");
	if (IsValidClient(builder) && DRPlayer(client).CanHideClient(builder))
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
