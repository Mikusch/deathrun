void Event_Init()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public Action Event_PostInventoryApplication(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	TFClassType class = TF2_GetPlayerClass(client);
	
	for (int slot = 0; slot <= WeaponSlot_InvisWatch; slot++)
	{
		int weapon = TF2_GetItemInSlot(client, slot);
		
		if (IsValidEntity(weapon))
		{
			int defindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			
			WeaponConfig config;
			if (g_Weapons.GetByDefIndex(defindex, config) > 0)
			{
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

stock int TF2_GetItemInSlot(int client, int slot)
{
	int weapon = GetPlayerWeaponSlot(client, slot);
	if (!IsValidEntity(weapon))
	{
		// If no weapon was found in the slot, check if it is a wearable
		int wearable = SDK_GetEquippedWearable(client, slot);
		if (IsValidEntity(wearable))
			weapon = wearable;
	}
	
	return weapon;
}
