int g_PlayerQueuePoints[TF_MAXPLAYERS] =  { -1, ... };
int g_PlayerPreferences[TF_MAXPLAYERS] =  { -1, ... };
bool g_PlayerInThirdPerson[TF_MAXPLAYERS];
bool g_PlayerIsHidingTeammates[TF_MAXPLAYERS];

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
			return g_PlayerQueuePoints[this];
		}
		public set(int val)
		{
			g_PlayerQueuePoints[this] = val;
		}
	}
	
	property int Preferences
	{
		public get()
		{
			return g_PlayerPreferences[this];
		}
		public set(int val)
		{
			g_PlayerPreferences[this] = val;
		}
	}
	
	property bool InThirdPerson
	{
		public get()
		{
			return g_PlayerInThirdPerson[this];
		}
		public set(bool val)
		{
			g_PlayerInThirdPerson[this] = val;
		}
	}
	
	property bool IsHidingTeammates
	{
		public get()
		{
			return g_PlayerIsHidingTeammates[this];
		}
		public set(bool val)
		{
			g_PlayerIsHidingTeammates[this] = val;
		}
	}
	
	public void Reset()
	{
		this.InThirdPerson = false;
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
