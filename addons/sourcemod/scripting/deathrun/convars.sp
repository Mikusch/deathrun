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

void ConVars_Init()
{
	CreateConVar("dr_version", PLUGIN_VERSION, "The plugin version.", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	CreateConVar("dr_enabled", "1", "Whether to enable the plugin.");
	
	dr_queue_points = CreateConVar("dr_queue_points", "5", "Amount of queue points being given to runners every round.");
	dr_speed_modifier[TFClass_Scout] = CreateConVar("dr_speed_modifier_scout", "-80", "Value to add to Scout's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Sniper] = CreateConVar("dr_speed_modifier_sniper", "0", "Value to add to Sniper's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Soldier] = CreateConVar("dr_speed_modifier_soldier", "0", "Value to add to Soldier's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_DemoMan] = CreateConVar("dr_speed_modifier_demoman", "0", "Value to add to Demoman's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Medic] = CreateConVar("dr_speed_modifier_medic", "0", "Value to add to Medic's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Heavy] = CreateConVar("dr_speed_modifier_heavy", "10", "Value to add to Heavy's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Pyro] = CreateConVar("dr_speed_modifier_pyro", "0", "Value to add to Pyro's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Spy] = CreateConVar("dr_speed_modifier_spy", "0", "Value to add to Spy's maximum speed, in HU/s.");
	dr_speed_modifier[TFClass_Engineer] = CreateConVar("dr_speed_modifier_engineer", "0", "Value to add to Engineer's maximum speed, in HU/s.");
	dr_backstab_damage = CreateConVar("dr_backstab_damage", "750", "Damage dealt to the activator by backstabs. Set to 0 to use the default damage calculation.", _, true, 0.0);
	dr_runner_allow_button_damage = CreateConVar("dr_runner_allow_button_damage", "1", "Whether runners are allowed to damage buttons with ranged weapons.");
	dr_runner_glow = CreateConVar("dr_runner_glow", "0", "Whether runners should have a glowing outline.");
	dr_activator_speed_buff = CreateConVar("dr_activator_speed_buff", "1", "Whether activators should have a speed buff.");
	dr_activator_count = CreateConVar("dr_activator_count", "1", "Amount of activators.", _, true, 1.0);
	dr_activator_health_modifier = CreateConVar("dr_activator_health_modifier", "1.0", "The percentage of health activators gain from every runner.", _, true, 0.0);
	dr_activator_allow_healthkits = CreateConVar("dr_activator_allow_healthkits", "0", "Whether activators are allowed to pick up health kits.");
	dr_activator_healthbar_lifetime = CreateConVar("dr_activator_healthbar_lifetime", "5", "The duration to display the activator health bar for after taking damage, in seconds. Set to 0 to disable the health bar.");
	dr_disable_regen = CreateConVar("dr_disable_regen", "1", "Whether to disable all passive health and ammo regeneration for players.");
	dr_allow_teleporter_use = CreateConVar("dr_allow_teleporter_use", "0", "Whether to allow using player-built teleporters.");
	dr_chat_hint_interval = CreateConVar("dr_chat_hint_interval", "240", "Time between chat hints, in seconds. Set to 0 to disable chat hints.", _, true, 0.0);
	dr_prevent_multi_button_hits = CreateConVar("dr_prevent_multi_button_hits", "0", "Whether to prevent multiple buttons from being activated at the same time.");
	
	PSM_AddEnforcedConVar("mp_autoteambalance", "0");
	PSM_AddEnforcedConVar("mp_teams_unbalance_limit", "0");
	PSM_AddEnforcedConVar("tf_arena_first_blood", "0");
	PSM_AddEnforcedConVar("tf_arena_use_queue", "0");
	PSM_AddEnforcedConVar("tf_avoidteammates_pushaway", "0");
	PSM_AddEnforcedConVar("tf_scout_air_dash_count", "0");
	PSM_AddEnforcedConVar("tf_solidobjects", "0");
	
	PSM_AddConVarChangeHook(dr_activator_speed_buff, OnConVarChanged_ActivatorSpeedBuff);
	PSM_AddConVarChangeHook(dr_runner_glow, OnConVarChanged_RunnerGlow);
	PSM_AddConVarChangeHook(dr_chat_hint_interval, OnConVarChanged_ChatHintInterval);
}

static void OnConVarChanged_ActivatorSpeedBuff(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		DRPlayer(client).OnPreferencesChanged(Preference_DisableActivatorSpeedBuff);
	}
}

static void OnConVarChanged_RunnerGlow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (DRPlayer(client).IsActivator())
			continue;
		
		if (!IsPlayerAlive(client))
			continue;
		
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", convar.BoolValue);
	}
}

static void OnConVarChanged_ChatHintInterval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_chatHintTimer = CreateChatHintTimer(convar.FloatValue);
}
