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

#define MAX_COMMAND_LENGTH 1024

enum struct ConVarInfo
{
	ConVar convar;
	char value[MAX_COMMAND_LENGTH];
	char initialValue[MAX_COMMAND_LENGTH];
	bool enforce;
}

static ArrayList g_GameConVars;

void ConVars_Init()
{
	CreateConVar("dr_version", PLUGIN_VERSION, PLUGIN_NAME..." version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	dr_queue_points = CreateConVar("dr_queue_points", "15", "Amount of queue points awarded to runners at the end of each round.", _, true, 1.0);
	dr_chattips_interval = CreateConVar("dr_chattips_interval", "240", "Interval between helpful tips printed to chat, in seconds. Set to 0 to disable chat tips.");
	dr_runner_glow = CreateConVar("dr_runner_glow", "0", "If enabled, runners will have a glowing outline.");
	dr_activator_count = CreateConVar("dr_activator_count", "1", "Amount of activators chosen at the start of a round.", _, true, 1.0, true, float(MaxClients - 1));
	dr_activator_health_modifier = CreateConVar("dr_activator_health_modifier", "1.0", "Modifier of the health the activator receives from runners.", _, true, 0.0);
	dr_activator_healthbar = CreateConVar("dr_activator_healthbar", "1", "If enabled, the activator health will be displayed on screen.");
	dr_backstab_damage = CreateConVar("dr_backstab_damage", "750.0", "Damage dealt to the activator by backstabs. Set to 0 to let the game determine the damage.");
	dr_speed_modifier[0] = CreateConVar("dr_speed_modifier", "0.0", "Maximum speed modifier for all classes, in HU/s.");
	dr_speed_modifier[1] = CreateConVar("dr_speed_modifier_scout", "0.0", "Maximum speed modifier for Scout, in HU/s.");
	dr_speed_modifier[2] = CreateConVar("dr_speed_modifier_sniper", "0.0", "Maximum speed modifier for Sniper, in HU/s.");
	dr_speed_modifier[3] = CreateConVar("dr_speed_modifier_soldier", "0.0", "Maximum speed modifier for Soldier, in HU/s.");
	dr_speed_modifier[4] = CreateConVar("dr_speed_modifier_demoman", "0.0", "Maximum speed modifier for Demoman, in HU/s.");
	dr_speed_modifier[5] = CreateConVar("dr_speed_modifier_medic", "0.0", "Maximum speed modifier for Medic, in HU/s.");
	dr_speed_modifier[6] = CreateConVar("dr_speed_modifier_heavy", "0.0", "Maximum speed modifier for Heavy, in HU/s.");
	dr_speed_modifier[7] = CreateConVar("dr_speed_modifier_pyro", "0.0", "Maximum speed modifier for Pyro, in HU/s.");
	dr_speed_modifier[8] = CreateConVar("dr_speed_modifier_spy", "0.0", "Maximum speed modifier for Spy, in HU/s.");
	dr_speed_modifier[9] = CreateConVar("dr_speed_modifier_engineer", "0.0", "Maximum speed modifier for Engineer, in HU/s.");
	
	dr_chattips_interval.AddChangeHook(ConVarChanged_ChatTipsInterval);
	dr_runner_glow.AddChangeHook(ConVarChanged_RunnerGlow);
	dr_activator_healthbar.AddChangeHook(ConVarChanged_ActivatorHealthBar);
	
	g_GameConVars = new ArrayList(sizeof(ConVarInfo));
	
	ConVars_Add("mp_autoteambalance", "0");
	ConVars_Add("mp_teams_unbalance_limit", "0");
	ConVars_Add("tf_arena_first_blood", "0");
	ConVars_Add("tf_arena_use_queue", "0");
	ConVars_Add("tf_avoidteammates_pushaway", "0", false);
	ConVars_Add("tf_scout_air_dash_count", "0", false);
}

void ConVars_Add(const char[] name, const char[] value, bool enforce = true)
{
	ConVarInfo info;
	info.convar = FindConVar(name);
	strcopy(info.value, sizeof(info.value), value);
	info.enforce = enforce;
	g_GameConVars.PushArray(info);
}

void ConVars_Enable()
{
	for (int i = 0; i < g_GameConVars.Length; i++)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(i, info);
		info.convar.GetString(info.initialValue, sizeof(info.initialValue));
		g_GameConVars.SetArray(i, info);
		
		info.convar.SetString(info.value);
		
		if (info.enforce)
			info.convar.AddChangeHook(ConVarChanged_GameConVar);
	}
}

void ConVars_Disable()
{
	for (int i = 0; i < g_GameConVars.Length; i++)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(i, info);
		
		if (info.enforce)
			info.convar.RemoveChangeHook(ConVarChanged_GameConVar);
		
		info.convar.SetString(info.initialValue);
	}
}

public void ConVarChanged_GameConVar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int index = g_GameConVars.FindValue(convar, ConVarInfo::convar);
	if (index != -1)
	{
		ConVarInfo info;
		g_GameConVars.GetArray(index, info);
		
		if (!StrEqual(newValue, info.value))
			info.convar.SetString(info.value);
	}
}

public void ConVarChanged_ChatTipsInterval(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Timers_CreateChatTipTimer(StringToFloat(newValue));
}

public void ConVarChanged_RunnerGlow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !DRPlayer(client).IsActivator())
			SetEntProp(client, Prop_Send, "m_bGlowEnabled", StringToInt(newValue));
	}
}

public void ConVarChanged_ActivatorHealthBar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (!StringToInt(newValue))
	{
		int monsterResource = FindEntityByClassname(MaxClients + 1, "monster_resource");
		if (monsterResource != -1)
			SetEntProp(monsterResource, Prop_Send, "m_iBossHealthPercentageByte", 0);
	}
}
