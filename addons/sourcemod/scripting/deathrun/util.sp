/**
 * Copyright (C) 2024  Mikusch
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

#pragma newdecls required
#pragma semicolon 1

static bool g_bInTriggerHurt;

bool IsEntityClient(int entity)
{
	return (0 < entity <= MaxClients) && IsValidEntity(entity);
}

ArrayList GetEntityChildren(int entity)
{
	ArrayList list = new ArrayList();
	
	int count = 0;
	int child = GetEntPropEnt(entity, Prop_Data, "m_hMoveChild");
	while (child != -1)
	{
		list.Push(child);
		count++;
		child = GetEntPropEnt(child, Prop_Data, "m_hMovePeer");
	}
	
	return list;
}

void RemoveEdictFlagFromChildren(int entity, int flagsToRemove)
{
	ArrayList children = GetEntityChildren(entity);
	int numChildren = children.Length;
	
	for (int i = 0; i < numChildren; ++i)
	{
		int child = children.Get(i);
		
		// Any children having FL_EDICT_ALWAYS will force the parent to transmit
		int flags = GetEdictFlags(child);
		if (flags & flagsToRemove)
			SetEdictFlags(child, flags & ~flagsToRemove);
	}
	
	delete children;
}

any Min(any a, any b)
{
	return (a <= b) ? a : b;
}

int Compare(any val1, any val2)
{
	if (val1 > val2)
		return 1;
	else if (val1 < val2)
		return -1;
	
	return 0;
}

bool IsInTriggerHurt(int entity)
{
	float origin[3];
	GetClientAbsOrigin(entity, origin);
	
	g_bInTriggerHurt = false;
	TR_EnumerateEntities(origin, origin, PARTITION_TRIGGER_EDICTS, RayType_EndPoint, EnumerateEntities);
	return g_bInTriggerHurt;
}

static bool EnumerateEntities(int entity)
{
	char classname[32];
	if (!GetEntityClassname(entity, classname, sizeof(classname)) || !StrEqual(classname, "trigger_hurt"))
		return true;
	
	if (GetEntPropFloat(entity, Prop_Data, "m_flDamage") <= 0.0)
		return true;
	
	Handle trace = TR_ClipCurrentRayToEntityEx(MASK_ALL, entity);
	bool didHit = TR_DidHit(trace);
	delete trace;
	
	g_bInTriggerHurt = didHit;
	return !didHit;
}

void RemoveExtraWearables(int item)
{
	int extraWearable = GetEntPropEnt(item, Prop_Send, "m_hExtraWearable");
	if (extraWearable != -1)
	{
		TF2_RemoveWearable(GetEntPropEnt(extraWearable, Prop_Send, "m_hOwnerEntity"), extraWearable);
		SetEntPropEnt(item, Prop_Send, "m_hExtraWearable", -1);
	}
	
	int extraWearableViewModel = GetEntPropEnt(item, Prop_Send, "m_hExtraWearableViewModel");
	if (extraWearableViewModel != -1)
	{
		TF2_RemoveWearable(GetEntPropEnt(extraWearableViewModel, Prop_Send, "m_hOwnerEntity"), extraWearableViewModel);
		SetEntPropEnt(item, Prop_Send, "m_hExtraWearableViewModel", -1);
	}
}

void RunScriptCode(int entity, int activator, int caller, const char[] format, any...)
{
	if (!IsValidEntity(entity))
		return;
	
	static char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 5);
	
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode", activator, caller);
}
