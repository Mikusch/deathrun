#pragma semicolon 1
#pragma newdecls required

#define INFO_QUEUE			"queue"
#define INFO_PREFERENCES	"preferences"

void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MenuAction_Select | MenuAction_End | MenuAction_DrawItem | MenuAction_DisplayItem);
	
	menu.SetTitle("%T", "Main Menu: Title", client, PLUGIN_VERSION);
	
	menu.AddItem(INFO_QUEUE, "Main Menu: Queue");
	menu.AddItem(INFO_PREFERENCES, "Main Menu: Preferences");
	
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
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			char info[64], display[128];
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
		
		if (DRPlayer(client).m_nQueuePoints != -1)
			menu.SetTitle("%T\n%T", "Queue Menu: Title", client, "Your Queue Points", client, DRPlayer(client).m_nQueuePoints);
		else
			menu.SetTitle("%T\n%T", "Queue Menu: Title", client, "Queue Not Loaded", client);
		
		for (int i = 0; i < queue.Length; ++i)
		{
			int queuePoints = queue.Get(i, QueueData::points);
			int queueClient = queue.Get(i, QueueData::client);
			
			char display[MAX_NAME_LENGTH + 8];
			Format(display, sizeof(display), "%N (%d)", queueClient, queuePoints);
			
			menu.AddItem(NULL_STRING, display, client == queueClient ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
		}
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
	else
	{
		PrintHintText(client, "%t", "No Players In Queue");
		Menus_DisplayMainMenu(client);
	}
	
	delete queue;
}

void Menus_DisplayPreferencesMenu(int client)
{
	Menu menu = new Menu(MenuHandler_PreferencesMenu, MenuAction_Select | MenuAction_Cancel | MenuAction_End | MenuAction_DisplayItem);
	menu.SetTitle("%T", "Preferences Menu: Title", client);
	menu.ExitBackButton = true;
	
	AddPreferenceToMenu(menu, Preference_DisableActivatorQueue, "Preference: Disable Activator");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

static void AddPreferenceToMenu(Menu menu, Preference preference, const char[] display)
{
	char info[32];
	if (IntToString(view_as<int>(preference), info, sizeof(info)))
		menu.AddItem(info, display);
}

static int MenuHandler_PreferencesMenu(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			int style;
			char info[32], display[64];
			menu.GetItem(param2, info, sizeof(info), style, display, sizeof(display));
			
			int i = StringToInt(info);
			Preference preference = view_as<Preference>(i);
			
			DRPlayer(param1).SetPreference(preference, !DRPlayer(param1).HasPreference(preference));
			
			Menus_DisplayPreferencesMenu(param1);
		}
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
			{
				Menus_DisplayMainMenu(param1);
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
		case MenuAction_DisplayItem:
		{
			char info[32], display[64];
			menu.GetItem(param2, info, sizeof(info), _, display, sizeof(display));
			
			int i = StringToInt(info);
			Preference preference = view_as<Preference>(i);
			
			Format(display, sizeof(display), "%s %t", DRPlayer(param1).HasPreference(preference) ? "☑" : "☐", display, param1);
			
			return RedrawMenuItem(display);
		}
	}
	
	return 0;
}

static int MenuHandler_QueueMenu(Menu menu, MenuAction action, int param1, int param2)
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
	
	return 0;
}
