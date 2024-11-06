#pragma newdecls required
#pragma semicolon 1

static int m_queuePoints[MAXPLAYERS + 1];
static bool m_isHidingPlayers[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];

methodmap DRPlayer
{
	public DRPlayer(int client)
	{
		return view_as<DRPlayer>(client);
	}
	
	property int entindex
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
			return m_queuePoints[this.entindex];
		}
		public set(int queuePoints)
		{
			m_queuePoints[this.entindex] = queuePoints;
		}
	}
	
	property bool IsHidingPlayers
	{
		public get()
		{
			return m_isHidingPlayers[this.entindex];
		}
		public set(bool isHidingPlayers)
		{
			m_isHidingPlayers[this.entindex] = isHidingPlayers;
		}
	}
	
	property int Preferences
	{
		public get()
		{
			return m_preferences[this.entindex];
		}
		public set(int preferences)
		{
			m_preferences[this.entindex] = preferences;
		}
	}
	
	public void Init()
	{
		this.QueuePoints = 0;
		this.IsHidingPlayers = false;
		this.Preferences = 0;
	}
	
	public bool SetPreference(Preference preference, bool enable)
	{
		if (this.Preferences == -1)
			return false;
		
		if (enable)
			this.Preferences |= view_as<int>(preference);
		else
			this.Preferences &= ~view_as<int>(preference);
		
		ClientPrefs_SavePreferences(this.entindex);
		
		return true;
	}
	
	public bool HasPreference(Preference preference)
	{
		return this.Preferences != -1 && this.Preferences & view_as<int>(preference) != 0;
	}
	
	public void RemoveItem(int item)
	{
		if (TF2Util_IsEntityWeapon(item))
		{
			RemovePlayerItem(this.entindex, item);
			RemoveExtraWearables(item);
		}
		else if (TF2Util_IsEntityWearable(item))
		{
			TF2_RemoveWearable(this.entindex, item);
		}
		
		RemoveEntity(item);
	}
	
	public void RemoveAllItems()
	{
		for (int i = 0; i < GetEntPropArraySize(this.entindex, Prop_Send, "m_hMyWeapons"); ++i)
		{
			int weapon = GetEntPropEnt(this.entindex, Prop_Send, "m_hMyWeapons", i);
			if (weapon == -1)
				continue;
			
			this.RemoveItem(weapon);
		}
		
		for (int wbl = TF2Util_GetPlayerWearableCount(this.entindex) - 1; wbl >= 0; wbl--)
		{
			int wearable = TF2Util_GetPlayerWearable(this.entindex, wbl);
			if (wearable == -1)
				continue;
			
			this.RemoveItem(wearable);
		}
	}
	
	public bool ShouldHideClient(int client)
	{
		return this.IsHidingPlayers && this.entindex != client && IsPlayerAlive(this.entindex) && GetClientTeam(this.entindex) == GetClientTeam(client);
	}
	
	public bool IsActivator()
	{
		return g_currentActivators.FindValue(this.entindex) != -1;
	}
	
	public void AddQueuePoints(int nQueuePoints)
	{
		this.SetQueuePoints(this.QueuePoints + nQueuePoints);
	}
	
	public void SetQueuePoints(int nQueuePoints)
	{
		this.QueuePoints = nQueuePoints;
		ClientPrefs_SaveQueuePoints(this.entindex);
	}
}
