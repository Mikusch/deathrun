#pragma newdecls required
#pragma semicolon 1

static int m_queuePoints[MAXPLAYERS + 1];
static bool m_isHidingPlayers[MAXPLAYERS + 1];
static int m_preferences[MAXPLAYERS + 1];
static int m_activatorHealthBonus[MAXPLAYERS + 1];

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

	property int ActivatorHealthBonus
	{
		public get()
		{
			return m_activatorHealthBonus[this.entindex];
		}
		public set(int bonus)
		{
			m_activatorHealthBonus[this.entindex] = bonus;
		}
	}

	public void Init()
	{
		this.QueuePoints = 0;
		this.IsHidingPlayers = false;
		this.Preferences = 0;
	}
	
	public void SetPreference(Preference preference, bool enable)
	{
		if (enable)
			this.Preferences |= view_as<int>(preference);
		else
			this.Preferences &= ~view_as<int>(preference);
		
		ClientPrefs_SavePreferences(this.entindex);
		this.OnPreferencesChanged(preference);
	}
	
	public bool HasPreference(Preference preference)
	{
		return this.Preferences != -1 && this.Preferences & view_as<int>(preference) != 0;
	}
	
	public void OnPreferencesChanged(Preference preference)
	{
		switch (preference)
		{
			case Preference_DisableActivatorSpeedBuff:
			{
				if (dr_activator_speed_buff.BoolValue && this.IsActivator() && !this.HasPreference(preference))
					TF2_AddCondition(this.entindex, TFCond_SpeedBuffAlly);
				else
					TF2_RemoveCondition(this.entindex, TFCond_SpeedBuffAlly);
			}
		}
	}

	
	public int GetMaxHealth()
	{
		return GetEntProp(this.entindex, Prop_Data, "m_iMaxHealth");
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
