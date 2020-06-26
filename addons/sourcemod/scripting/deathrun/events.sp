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
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	
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
	
	if (DRPlayer(client).InThirdPerson)
		CreateTimer(0.2, Timer_SetThirdperson, userid);
	
	RequestFrame(RequestFrameCallback_VerifyTeam, userid);
}

public Action Timer_SetThirdperson(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (DRPlayer(client).InThirdPerson)
	{
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
	}
}

public Action Event_TeamplayRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Arena has a very dumb logic, if all players from a team leave the round will end and then restart without reseting the game state
	//Catch that issue and don't run our logic!
	int red, blue;
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			switch (TF2_GetClientTeam(client))
			{
				case TFTeam_Red: red++;
				case TFTeam_Blue: blue++;
			}
		}
	}
	
	//Both teams must have at least one player
	if (red == 0 || blue == 0)
	{
		if (red + blue >= 2)	//If we have atleast 2 players in red or blue, force one person to the other team and try again
		{
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client))
				{
					//Once we found someone who is in red or blue, swap their team
					TFTeam team = TF2_GetClientTeam(client);
					if (team == TFTeam_Red)
					{
						TF2_ChangeClientTeamAlive(client, TFTeam_Blue);
						return;
					}
					else if (team == TFTeam_Blue)
					{
						TF2_ChangeClientTeamAlive(client, TFTeam_Red);
						return;
					}
				}
			}
		}
		//If we reach this part, either nobody is in the server or everyone is spectating
		return;
	}
	
	//New round has begun
	for (int client = 1; client <= MaxClients; client++)
	{
		//Put every player in the same team and pick the activator later
		if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
			TF2_ChangeClientTeamAlive(client, TFTeam_Red);
	}
	
	Queue_SetNextActivator();
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
				PrintLocalizedMessage(client, "%T", "RoundWin_Activator", LANG_SERVER);
			else if (team == TFTeam_Red)
				PrintLocalizedMessage(client, "%T", "RoundWin_Runners", LANG_SERVER);
			
			if (player.IsActivator())
			{
				TF2Attrib_RemoveByName(client, "max health additive bonus");
			}
			else
			{
				Queue_AddPoints(client, dr_queue_points.IntValue);
			}
		}
	}
	
	g_RoundTimer = null;	//Block the big boom
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
					SetHudTextParams(-1.0, 0.25, 10.0, 0, 255, 255, 255);
					ShowHudText(client, -1, "You became the Activator!\nKill all runners by activating traps\nand emerge victorious over the enemy!", activatorName);
				}
				else
				{
					SetHudTextParams(-1.0, 0.25, 10.0, 0, 255, 255, 255);
					ShowHudText(client, -1, "%s became the Activator!\nAvoid getting killed by the traps\nand bring your team to the victory!", activatorName);
				}
				
				SetHudTextParams(-1.0, 0.375, 10.0, 255, 255, 0, 255);
				ShowHudText(client, -1, PLUGIN_URL);
				
				PrintLocalizedMessage(client, "%T", "RoundStart_NewActivator", LANG_SERVER, activatorName);
			}
		}
		
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
				SetHudTextParams(-1.0, 0.25, FindConVar("mp_bonusroundtime").FloatValue, 0, 255, 255, 255);
				ShowHudText(client, -1, "The activator has disconnected!\nRestarting the round!");
			}
		}
	}
	
	Timer_OnRoundStart();
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
