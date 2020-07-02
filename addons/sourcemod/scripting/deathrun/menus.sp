void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(Menus_HandleMainMenu);
	
	menu.SetTitle("%T", "Menu_Main_Title", client, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_URL);
	
	char display[256];
	Format(display, sizeof(display), "%T", "Menu_Main_Queue", client);
	menu.AddItem("queue", display);
	
	Format(display, sizeof(display), "%T", "Menu_Main_Preferences", client);
	menu.AddItem("preferences", display);
	
	Format(display, sizeof(display), "%T", "Menu_Main_ThirdPerson", client);
	menu.AddItem("thirdperson", display, dr_allow_thirdperson.BoolValue ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	
	Format(display, sizeof(display), "%T", "Menu_Main_HideRunners", client);
	menu.AddItem("hiderunners", display);
	
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
				FakeClientCommand(param1, DRPlayer(param1).InThirdPerson ? "dr_firstperson" : "dr_thirdperson");
				Menus_DisplayMainMenu(param1);
			}
			else if (StrEqual(info, "hiderunners"))
			{
				FakeClientCommand(param1, "dr_hiderunners");
				Menus_DisplayMainMenu(param1);
			}
		}
	}
}

void Menus_DisplayQueueMenu(int client)
{
	ArrayList queue = Queue_GetQueueList();
	if (queue.Length > 0)
	{
		Menu menu = new Menu(Menus_HandleQueueMenu);
		menu.ExitBackButton = true;
		
		if (DRPlayer(client).QueuePoints != -1)
			menu.SetTitle("%T\n%T", "Menu_Queue_Title", client, "Menu_Queue_Title_QueuePoints", client, DRPlayer(client).QueuePoints);
		else
			menu.SetTitle("%T\n%T", "Menu_Queue_Title", client, "Menu_Queue_NotLoaded", client);
		
		for (int i = 0; i < queue.Length; i++)
		{
			int queuePoints = queue.Get(i, 0);
			int queueClient = queue.Get(i, 1);
			
			char name[MAX_NAME_LENGTH];
			GetClientName(queueClient, name, sizeof(name));
			
			char display[256];
			Format(display, sizeof(display), "%s (%d)", name, queuePoints);
			
			menu.AddItem(NULL_STRING, display, ITEMDRAW_DISABLED);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Queue_NotLoaded");
		Menus_DisplayMainMenu(client);
	}
	delete queue;
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
	if (DRPlayer(client).Preferences != -1)
	{
		Menu menu = new Menu(Menus_HandlePreferencesMenu);
		menu.SetTitle("%T", "Menu_Preferences_Title", client);
		menu.ExitBackButton = true;
		
		for (int i = 0; i < sizeof(g_PreferenceNames); i++)
		{
			PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
			
			char display[512];
			if (DRPlayer(client).HasPreference(preference))
				Format(display, sizeof(display), "■ %T", g_PreferenceNames[i], client);
			else
				Format(display, sizeof(display), "□ %T", g_PreferenceNames[i], client);
			
			char info[4];
			if (IntToString(i, info, sizeof(info)) > 0)
				menu.AddItem(info, display);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Preferences_NotLoaded");
		Menus_DisplayMainMenu(client);
	}
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
			player.SetPreference(preference, !player.HasPreference(preference));
			
			char preferenceName[256];
			Format(preferenceName, sizeof(preferenceName), "%T", g_PreferenceNames[i], param1);
			
			if (player.HasPreference(preference))
				PrintLocalizedMessage(param1, "%t", "Preferences_Enabled", preferenceName);
			else
				PrintLocalizedMessage(param1, "%t", "Preferences_Disabled", preferenceName);
			
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
			Format(display, sizeof(display), "%t", g_PreferenceNames[i], param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}
