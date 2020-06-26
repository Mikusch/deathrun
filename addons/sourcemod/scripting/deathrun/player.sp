int g_PlayerQueuePoints[TF_MAXPLAYERS] =  { -1, ... };
int g_PlayerSettings[TF_MAXPLAYERS] =  { -1, ... };
bool g_PlayerThirdpersonEnabled[TF_MAXPLAYERS];

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
	
	property int Settings
	{
		public get()
		{
			return g_PlayerSettings[this];
		}
		public set(int val)
		{
			g_PlayerSettings[this] = val;
		}
	}
	
	property bool ThirdpersonEnabled
	{
		public get()
		{
			return g_PlayerThirdpersonEnabled[this];
		}
		public set(bool val)
		{
			g_PlayerThirdpersonEnabled[this] = val;
		}
	}
	
	public void Reset()
	{
		this.ThirdpersonEnabled = false;
	}
	
	public bool IsActivator()
	{
		return view_as<int>(this) == g_CurrentActivator;
	}
	
	public bool GetPreference(PreferenceType preference)
	{
		if (this.Settings == -1)
			return false;
		
		return !(this.Settings & view_as<int>(preference));
	}
	
	public bool SetPreference(PreferenceType preference, bool enable)
	{
		if (this.Settings == -1)
			return false;
		
		//Since the initial value is 0 to turn on all settings, we set 0 if true, 1 if false
		enable = !enable;
		
		if (enable)
			this.Settings |= view_as<int>(preference);
		else
			this.Settings &= ~view_as<int>(preference);
		
		Cookies_SaveSettings(this.Client, this.Settings);
		
		return true;
	}
}
