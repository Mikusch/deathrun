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

#define PLUGIN_TAG	"[{royalblue}DEATHRUN NEU{default}]"

// m_lifeState values
#define	LIFE_ALIVE				0 // alive
#define	LIFE_DYING				1 // playing death animation or still falling off of a ledge waiting to hit ground
#define	LIFE_DEAD				2 // dead. lying still.
#define	LIFE_RESPAWNABLE		3
#define	LIFE_DISCARDBODY		4

#define DMG_MELEE	DMG_BLAST_SURFACE

enum TOGGLE_STATE
{
	TS_AT_TOP, 
	TS_AT_BOTTOM, 
	TS_GOING_UP, 
	TS_GOING_DOWN
};

enum
{
	SOLID_TO_PLAYER_USE_DEFAULT = 0,
	SOLID_TO_PLAYER_YES,
	SOLID_TO_PLAYER_NO,
};

enum
{
	WL_NotInWater = 0,
	WL_Feet,
	WL_Waist,
	WL_Eyes
};

enum Preference
{
	Preference_DisableActivatorQueue = (1 << 0),
	Preference_DisableActivatorSpeedBuff = (1 << 1),
	Preference_DisableChatHints = (1 << 2),
}

const TFTeam TFTeam_Runners = TFTeam_Red;
const TFTeam TFTeam_Activators = TFTeam_Blue;
