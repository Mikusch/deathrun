bool Settings_Get(int client, ClientSetting setting)
{
	if (DRPlayer(client).Settings == -1)
		return false;
	
	return !(DRPlayer(client).Settings & view_as<int>(setting));
}

bool Settings_Set(int client, ClientSetting setting, bool enable)
{
	if (DRPlayer(client).Settings == -1)
		return false;
	
	//Since the initial value is 0 to turn on all settings, we set 0 if true, 1 if false
	enable = !enable;
	
	if (enable)
		DRPlayer(client).Settings |= view_as<int>(setting);
	else
		DRPlayer(client).Settings &= ~view_as<int>(setting);
	
	Cookies_SaveSettings(client, DRPlayer(client).Settings);
	
	return true;
}
