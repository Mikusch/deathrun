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

int g_PlayerQueuePoints[MAXPLAYERS + 1] = { -1, ... };
int g_PlayerPreferences[MAXPLAYERS + 1] = { -1, ... };
bool g_PlayerIsHidingTeammates[MAXPLAYERS + 1];

methodmap DRPlayer
{
	public DRPlayer(int client)
	{
		return view_as<DRPlayer>(client);
	}
	
	property int Client
	{
		public get()
		{
			return view_as<int>(this);
		}
	}
	
	property int QueuePoints
	{
		public get()
		{
			return g_PlayerQueuePoints[this.Client];
		}
		public set(int val)
		{
			g_PlayerQueuePoints[this.Client] = val;
		}
	}
	
	property int Preferences
	{
		public get()
		{
			return g_PlayerPreferences[this.Client];
		}
		public set(int val)
		{
			g_PlayerPreferences[this.Client] = val;
		}
	}
	
	property bool IsHidingTeammates
	{
		public get()
		{
			return g_PlayerIsHidingTeammates[this.Client];
		}
		public set(bool val)
		{
			g_PlayerIsHidingTeammates[this.Client] = val;
		}
	}
	
	public void Reset()
	{
		this.IsHidingTeammates = false;
	}
	
	public bool IsActivator()
	{
		return g_CurrentActivators.FindValue(this.Client) != -1;
	}
	
	public bool HasPreference(PreferenceType preference)
	{
		return this.Preferences != -1 && this.Preferences & view_as<int>(preference) != 0;
	}
	
	public bool SetPreference(PreferenceType preference, bool enable)
	{
		if (this.Preferences == -1)
			return false;
		
		if (enable)
			this.Preferences |= view_as<int>(preference);
		else
			this.Preferences &= ~view_as<int>(preference);
		
		Cookies_SavePreferences(this.Client, this.Preferences);
		
		return true;
	}
	
	public bool CanHideClient(int client)
	{
		return this.IsHidingTeammates //Does this client want to hide teammates?
		 && IsPlayerAlive(this.Client) //Only hide players when alive
		 && TF2_GetClientTeam(this.Client) == TF2_GetClientTeam(client) //Only hide players on our team
		 && this.Client != client; //Don't hide ourselves
	}
}
