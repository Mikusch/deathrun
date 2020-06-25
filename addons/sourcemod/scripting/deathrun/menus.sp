void Menus_DisplayQueue(int caller)
{
	Menu menu = new Menu(Menus_HandleQueue);
	
	if (DRPlayer(caller).QueuePoints == -1)
		menu.SetTitle("Activator Queue List");
	else
		menu.SetTitle("Activator Queue List\nYour queue points: %i", DRPlayer(caller).QueuePoints);
	
	ArrayList queue = Queue_GetQueueList();
	for (int i = 0; i < queue.Length; i++)
	{
		int points = queue.Get(i, 0);
		int client = queue.Get(i, 1);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		char display[256];
		Format(display, sizeof(display), "%s (%d)", name, points);
		
		menu.AddItem(NULL_STRING, display, ITEMDRAW_DEFAULT);
	}
	delete queue;
	
	menu.ExitButton = true;
	menu.Display(caller, MENU_TIME_FOREVER);
}

int Menus_HandleQueue(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void Menus_DisplaySettings(int caller)
{
	Menu menu = new Menu(Menus_HandleSettings);
	menu.SetTitle("Client Settings\nSettings can be ■ enabled and □ disabled.");
	
	for (int i = 0; i < sizeof(g_SettingNames); i++)
	{
		if (g_SettingNames[i][0] == '\0')
			continue;
		
		ClientSetting settings = view_as<ClientSetting>(RoundToNearest(Pow(2.0, float(i))));
		
		char display[512];
		if (!Settings_Get(caller, settings))
			Format(display, sizeof(display), "■ %s", g_SettingNames[i]);
		else
			Format(display, sizeof(display), "□ %s", g_SettingNames[i]);
		
		menu.AddItem(g_SettingNames[i], display);
	}
	
	menu.Display(caller, MENU_TIME_FOREVER);
}

int Menus_HandleSettings(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			for (int i = 0; i < sizeof(g_SettingNames); i++)
			{
				ClientSetting settings = view_as<ClientSetting>(RoundToNearest(Pow(2.0, float(i))));
				
				if (StrEqual(info, g_SettingNames[i]))
				{
					Settings_Set(param1, settings, !Settings_Get(param1, settings));
					CPrintToChat(param1, DEATHRUN_TAG..." The setting \"%s\" has been toggled.", g_SettingNames[i]);
					return;
				}
			}
		}
	}
}
