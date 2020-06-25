int g_PlayerQueuePoints[TF_MAXPLAYERS] =  { -1, ... };

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
			Cookies_SaveQueue(this.Client, g_PlayerQueuePoints[this]);
		}
	}
	
	public bool IsActivator()
	{
		return view_as<int>(this) == g_CurrentActivator;
	}
}
