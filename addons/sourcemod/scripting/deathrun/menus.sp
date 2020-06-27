void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(Menus_HandleMainMenu);
	
	menu.SetTitle("%s - %s", PLUGIN_NAME, PLUGIN_VERSION);
	menu.AddItem("queue", "Activator Queue List (!drnext)");
	menu.AddItem("preferences", "Preferences (!drsettings)");
	
	if (dr_allow_thirdperson.BoolValue)
		menu.AddItem("thirdperson", "Toggle Thirdperson Mode (!drthirdperson)");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandleMainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "queue"))
			{
				Menus_DisplayQueueMenu(param1);
			}
			else if (StrEqual(info, "preferences"))
			{
				Menus_DisplayPreferencesMenu(param1);
			}
			else if (StrEqual(info, "thirdperson"))
			{
				FakeClientCommand(param1, "dr_thirdperson");
				Menus_DisplayMainMenu(param1);
			}
		}
	}
}

void Menus_DisplayQueueMenu(int client)
{
	Menu menu = new Menu(Menus_HandleQueueMenu);
	
	menu.SetTitle("%T", "Menu_Queue_Title", LANG_SERVER, DRPlayer(client).QueuePoints);
	
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
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandleQueueMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				Menus_DisplayMainMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

void Menus_DisplayPreferencesMenu(int client)
{
	Menu menu = new Menu(Menus_HandlePreferencesMenu);
	menu.SetTitle("%T", "Menu_Preferences_Title", LANG_SERVER);
	
	for (int i = 0; i < sizeof(g_PreferenceNames); i++)
	{
		PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
		
		char display[512];
		if (DRPlayer(client).GetPreference(preference))
			Format(display, sizeof(display), "□ %T", LANG_SERVER, g_PreferenceNames[i]);
		else
			Format(display, sizeof(display), "■ %T", LANG_SERVER, g_PreferenceNames[i]);
		
		char info[4];
		if (IntToString(i, info, sizeof(info)) > 0)
			menu.AddItem(info, display);
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int Menus_HandlePreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[4];
			menu.GetItem(param2, info, sizeof(info));
			
			int i = StringToInt(info);
			PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
			
			DRPlayer player = DRPlayer(param1);
			player.SetPreference(preference, !player.GetPreference(preference));
			
			char preferenceName[256];
			Format(preferenceName, sizeof(preferenceName), "%T", g_PreferenceNames[i], LANG_SERVER);
			
			if (!player.GetPreference(preference))
				PrintLocalizedMessage(param1, "%T", "Preferences_Enabled", LANG_SERVER, preferenceName);
			else
				PrintLocalizedMessage(param1, "%T", "Preferences_Disabled", LANG_SERVER, preferenceName);
			
			Menus_DisplayPreferencesMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				Menus_DisplayMainMenu(param1);
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			char info[4];
			menu.GetItem(param2, info, sizeof(info));
			
			int i = StringToInt(info);
			
			char display[64];
			Format(display, sizeof(display), "%T", g_PreferenceNames[i]);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}
