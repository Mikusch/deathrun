static WeaponConfigList g_Weapons;

void Config_Init()
{
	g_Weapons = new WeaponConfigList();
	
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), WEAPON_CONFIG_FILE);
	KeyValues kv = new KeyValues("Weapons");
	if (kv.ImportFromFile(path))
	{
		g_Weapons.ReadConfig(kv);
		kv.GoBack();
	}
	delete kv;
}

bool Config_GetWeaponByDefIndex(int defindex, WeaponConfig config)
{
	return g_Weapons.GetByDefIndex(defindex, config) > 0;
}
