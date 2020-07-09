#define INFO_QUEUE			"queue"
#define INFO_PREFERENCES	"preferences"
#define INFO_THIRDPERSON	"thirdperson"
#define INFO_HIDETEAMMATES	"hideteammates"

void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MenuAction_Select | MenuAction_End | MenuAction_DrawItem | MenuAction_DisplayItem);
	
	menu.SetTitle("%T", "Menu_Main_Title", client, PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR, PLUGIN_URL);
	
	menu.AddItem(INFO_QUEUE, "Menu_Main_Queue");
	menu.AddItem(INFO_PREFERENCES, "Menu_Main_Preferences");
	menu.AddItem(INFO_THIRDPERSON, "Menu_Main_ThirdPerson");
	menu.AddItem(INFO_HIDETEAMMATES, "Menu_Main_HideTeammates");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char info[64];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, INFO_QUEUE))
			{
				Menus_DisplayQueueMenu(param1);
			}
			else if (StrEqual(info, INFO_PREFERENCES))
			{
				Menus_DisplayPreferencesMenu(param1);
			}
			else if (StrEqual(info, INFO_THIRDPERSON))
			{
				FakeClientCommand(param1, DRPlayer(param1).InThirdPerson ? "dr_firstperson" : "dr_thirdperson");
				Menus_DisplayMainMenu(param1);
			}
			else if (StrEqual(info, INFO_HIDETEAMMATES))
			{
				FakeClientCommand(param1, "dr_hideteammates");
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DrawItem:
		{
			int style;
			char info[64];
			menu.GetItem(param2, info, sizeof(info), style);
			
			if (StrEqual(info, INFO_THIRDPERSON) && !dr_allow_thirdperson.BoolValue)
				return ITEMDRAW_DISABLED;
			
			return style;
		}
		case MenuAction_DisplayItem:
		{
			char info[64], display[64];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			Format(display, sizeof(display), "%T", display, param1);
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

void Menus_DisplayQueueMenu(int client)
{
	ArrayList queue = Queue_GetQueueList();
	if (queue.Length > 0)
	{
		Menu menu = new Menu(MenuHandler_QueueMenu, MenuAction_Cancel | MenuAction_End);
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
			
			char display[64];
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

public int MenuHandler_QueueMenu(Menu menu, MenuAction action, int param1, int param2)
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
		Menu menu = new Menu(MenuHandler_PreferencesMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
		menu.SetTitle("%T", "Menu_Preferences_Title", client);
		menu.ExitBackButton = true;
		
		for (int i = 0; i < sizeof(g_PreferenceNames); i++)
		{
			char info[4];
			if (IntToString(i, info, sizeof(info)) > 0)
				menu.AddItem(info, g_PreferenceNames[i]);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "Menu_Preferences_NotLoaded");
		Menus_DisplayMainMenu(client);
	}
}

public int MenuHandler_PreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
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
			
			char name[64];
			Format(name, sizeof(name), "%T", g_PreferenceNames[i], param1);
			
			if (player.HasPreference(preference))
				PrintMessage(param1, "%t", "Preferences_Enabled", name);
			else
				PrintMessage(param1, "%t", "Preferences_Disabled", name);
			
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
			char info[4], display[64];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			int i = StringToInt(info);
			PreferenceType preference = view_as<PreferenceType>(RoundToNearest(Pow(2.0, float(i))));
			
			if (DRPlayer(param1).HasPreference(preference))
				Format(display, sizeof(display), "■ %T", g_PreferenceNames[i], param1);
			else
				Format(display, sizeof(display), "□ %T", g_PreferenceNames[i], param1);
			
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}
