void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(Menus_HandleMainMenu);
	
	menu.SetTitle("Deathrun");
	menu.AddItem("queue", "View Activator Queue");
	menu.AddItem("preferences", "Change Preferences");
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandleMainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	//TODO
}

void Menus_DisplayQueueMenu(int client)
{
	Menu menu = new Menu(Menus_HandleQueueMenu);
	
	if (DRPlayer(client).QueuePoints == -1)
		menu.SetTitle("Activator Queue List");
	else
		menu.SetTitle("Activator Queue List\nYour queue points: %i", DRPlayer(client).QueuePoints);
	
	ArrayList queue = Queue_GetQueueList();
	for (int i = 0; i < queue.Length; i++)
	{
		int queuePoints = queue.Get(i, 0);
		int queueClient = queue.Get(i, 1);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(queueClient, name, sizeof(name));
		
		char display[256];
		Format(display, sizeof(display), "%s (%d)", name, queuePoints);
		
		menu.AddItem(NULL_STRING, display);
	}
	delete queue;
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandleQueueMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void Menus_DisplayPreferencesMenu(int client)
{
	Menu menu = new Menu(Menus_HandlePreferencesMenu);
	menu.SetTitle("Client Settings\nSettings can be ■ enabled and □ disabled.");
	
	for (int i = 0; i < sizeof(g_SettingNames); i++)
	{
		if (g_SettingNames[i][0] == '\0')
			continue;
		
		ClientSetting settings = view_as<ClientSetting>(RoundToNearest(Pow(2.0, float(i))));
		
		char display[512];
		if (DRPlayer(client).GetPreference(settings))
			Format(display, sizeof(display), "□ %s", g_SettingNames[i]);
		else
			Format(display, sizeof(display), "■ %s", g_SettingNames[i]);
		
		menu.AddItem(g_SettingNames[i], display);
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandlePreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
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
					DRPlayer player = DRPlayer(param1);
					player.SetPreference(settings, !player.GetPreference(settings));
					CPrintToChat(param1, DEATHRUN_TAG..." The setting \"%s\" has been toggled.", g_SettingNames[i]);
					return;
				}
			}
		}
	}
}
