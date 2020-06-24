void Events_Init()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
	HookEvent("teamplay_round_win", Event_TeamplayRoundWin);
}

public Action Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	for (int slot = 0; slot <= WeaponSlot_InvisWatch; slot++)
	{
		int weapon = TF2_GetItemInSlot(client, slot);
		
		if (IsValidEntity(weapon))
		{
			int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
			WeaponConfig config;
			if (Config_GetWeaponByDefIndex(defindex, config))
			{
				//Handle primary attack
				if (config.blockPrimaryAttack)
					SetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack", float(INTEGER_MAX_VALUE));
				
				//Handle secondary attack
				if (config.blockSecondaryAttack)
					SetEntPropFloat(weapon, Prop_Data, "m_flNextSecondaryAttack", float(INTEGER_MAX_VALUE));
				
				//Handle attributes
				for (int i = 0; i < config.attributes.Length; i++)
				{
					WeaponAttributeConfig attribute;
					if (config.attributes.GetArray(i, attribute, sizeof(attribute)) > 0)
					{
						if (attribute.mode == ModMode_Set)
							TF2Attrib_SetByName(weapon, attribute.name, attribute.value);
						else if (attribute.mode == ModMode_Add)
							TF2Attrib_SetByName(weapon, attribute.name, TF2Attrib_GetValue(TF2Attrib_GetByName(weapon, attribute.name)) + attribute.value);
						else if (attribute.mode == ModMode_Subtract)
							TF2Attrib_SetByName(weapon, attribute.name, TF2Attrib_GetValue(TF2Attrib_GetByName(weapon, attribute.name)) - attribute.value);
						else if (attribute.mode == ModMode_Remove)
							TF2Attrib_SetByName(weapon, attribute.name, 0.0); //TF2Attrib_RemoveByName can't remove static attributes
					}
				}
				
				//Handle entity props
				for (int i = 0; i < config.props.Length; i++)
				{
					WeaponEntPropConfig prop;
					if (config.props.GetArray(i, prop, sizeof(prop)) > 0)
					{
						switch (prop.fieldType)
						{
							case PropField_Integer:
							{
								SetEntProp(weapon, prop.type, prop.name, StringToInt(prop.value));
							}
							case PropField_Float:
							{
								SetEntPropFloat(weapon, prop.type, prop.name, StringToFloat(prop.value));
							}
							case PropField_Vector:
							{
								float vector[3];
								StringToVector(prop.value, vector);
								SetEntPropVector(weapon, prop.type, prop.name, vector);
							}
							case PropField_String:
							{
								SetEntPropString(weapon, prop.type, prop.name, prop.value);
							}
						}
					}
				}
			}
		}
	}
}

public Action Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int client = Queue_GetPlayerInQueue(0);
	Queue_ResetPlayer(client);
	SetActivator(client);
	
	BalanceTeams();
}

public Action Event_TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetActivator() != client)
		{
			Queue_AddPlayerPoints(client, 15);
		}
	}
}

public Action Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int activator = GetActivator();
	
	char activatorName[MAX_NAME_LENGTH];
	GetClientName(activator, activatorName, sizeof(activatorName));
	PrintToChatAll("%s has become the activator!", activatorName);	//TODO: HUD text
	
	BalanceTeams();
}
