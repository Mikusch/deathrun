void Events_Init()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
	HookEvent("arena_round_start", Event_ArenaRoundStart);
	HookEvent("teamplay_round_start", Event_TeamplayRoundStart);
	HookEvent("teamplay_round_win", Event_TeamplayRoundWin);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
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
	int client = Queue_GetPlayerInQueuePos(1);
	if (IsValidClient(client))
	{
		DRPlayer(client).QueuePoints = 0;
		SetActivator(client);
		BalanceTeams();
	}
}

public Action Event_TeamplayRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	TFTeam team = view_as<TFTeam>(event.GetInt("team"));
	
	for (int client = 1; client <= MaxClients; client++)
	{
		DRPlayer player = DRPlayer(client);
		if (IsClientInGame(client))
		{
			if (team == TFTeam_Blue)
				CPrintToChat(client, DEATHRUN_TAG..." The {blue}Activator {default}wins!");
			else if (team == TFTeam_Red)
				CPrintToChat(client, DEATHRUN_TAG..." The {red}Runners {default}win!");
			
			if (player.IsActivator())
			{
				TF2Attrib_RemoveByName(client, "max health additive bonus");
			}
			else
			{
				player.QueuePoints += dr_queue_points.IntValue;
				CPrintToChat(client, DEATHRUN_TAG..." You have been awarded {green}%d {default}queue point(s) (Total: {green}%d{default}).", dr_queue_points.IntValue, player.QueuePoints);
			}
		}
	}
}

public Action Event_ArenaRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int activator = GetActivator();
	
	if (IsClientInGame(activator))
	{
		char activatorName[MAX_NAME_LENGTH];
		GetClientName(activator, activatorName, sizeof(activatorName));
		
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				if (DRPlayer(client).IsActivator())
				{
					SetHudTextParams(-1.0, 0.25, 10.0, 0, 255, 255, 0);
					ShowHudText(client, -1, "You became the Activator!\nKill all runners by activating traps\nand emerge victorious over the enemy!", activatorName);
				}
				else
				{
					SetHudTextParams(-1.0, 0.25, 10.0, 0, 255, 255, 0);
					ShowHudText(client, -1, "%s became the Activator!\nAvoid getting killed by the traps\nand bring your team to the victory!", activatorName);
				}
				
				SetHudTextParams(-1.0, 0.375, 10.0, 255, 255, 0, 0);
				ShowHudText(client, -1, PLUGIN_URL);
				
				CPrintToChat(client, DEATHRUN_TAG..." %s became the {blue}Activator{default}!", activatorName);
			}
		}
		
		BalanceTeams(); //Some cheeky players like to switch
		
		int maxhealth;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && TF2_GetClientTeam(i) == TFTeam_Red && IsPlayerAlive(i))
				maxhealth += TF2_GetMaxHealth(i);
		}
		
		TF2Attrib_SetByName(activator, "max health additive bonus", float(maxhealth));
		SetEntityHealth(activator, TF2_GetMaxHealth(activator) + maxhealth);
	}
	else
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client))
			{
				SetHudTextParams(-1.0, 0.25, FindConVar("mp_bonusroundtime").FloatValue, 0, 255, 255, 0);
				ShowHudText(client, -1, "The activator has disconnected!\nRestarting the round!");
			}
		}
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int activator = GetActivator();
	if (GameRules_GetRoundState() == RoundState_Stalemate && IsValidClient(activator))
	{
		event.SetInt("attacker", GetClientUserId(activator));
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}
