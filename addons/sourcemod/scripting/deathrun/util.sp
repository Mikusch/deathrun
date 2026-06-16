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

void RunScriptCode(int entity, int activator, int caller, const char[] format, any...)
{
	if (!IsValidEntity(entity))
		return;
	
	static char buffer[1024];
	VFormat(buffer, sizeof(buffer), format, 5);
	
	SetVariantString(buffer);
	AcceptEntityInput(entity, "RunScriptCode", activator, caller);
}
