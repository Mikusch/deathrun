static Handle g_SDKCallGetEquippedWearableForLoadoutSlot;

void SDKCalls_Init(GameData gamedata)
{
	g_SDKCallGetEquippedWearableForLoadoutSlot = PrepSDKCall_GetEquippedWearableForLoadoutSlot(gamedata);
}

static Handle PrepSDKCall_GetEquippedWearableForLoadoutSlot(GameData gamedata)
{
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Signature, "CTFPlayer::GetEquippedWearableForLoadoutSlot");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	
	Handle call = EndPrepSDKCall();
	if (!call)
		LogMessage("Failed to create call: CTFPlayer::GetEquippedWearableForLoadoutSlot");
	
	return call;
}

int SDKCalls_GetEquippedWearableForLoadoutSlot(int client, int iSlot)
{
	if (g_SDKCallGetEquippedWearableForLoadoutSlot != null)
		return SDKCall(g_SDKCallGetEquippedWearableForLoadoutSlot, client, iSlot);
	return -1;
}
