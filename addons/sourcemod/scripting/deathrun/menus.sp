/**
 * Copyright (C) 2024  Mikusch
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

#pragma newdecls required
#pragma semicolon 1

#define INFO_QUEUE			"queue"
#define INFO_PREFERENCES	"preferences"
#define INFO_HIDEPLAYERS	"hideplayers"

void Menus_DisplayMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_MainMenu, MenuAction_Select | MenuAction_End | MenuAction_DrawItem | MenuAction_DisplayItem);
	
	menu.SetTitle("%t\n%t", "Menu Header", "Main Menu: Title");
	
	menu.AddItem(INFO_QUEUE, "Main Menu: Queue");
	menu.AddItem(INFO_PREFERENCES, "Main Menu: Preferences");
	menu.AddItem(INFO_HIDEPLAYERS, "Main Menu: Hide Players");
	
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
			else if (StrEqual(info, INFO_HIDEPLAYERS))
			{
				FakeClientCommand(param1, "sm_hideplayers");
				Menus_DisplayMainMenu(param1);
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
		menu.SetTitle("%t\n%t\n%t", "Menu Header", "Queue Menu: Title", "Your Queue Points", DRPlayer(client).QueuePoints);
		menu.ExitBackButton = true;
		
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
	menu.SetTitle("%t\n%t", "Menu Header", "Preferences Menu: Title");
	menu.ExitBackButton = true;
	
	AddPreferenceToMenu(menu, Preference_DisableActivatorQueue, "Preference: Disable Activator Queue");
	AddPreferenceToMenu(menu, Preference_DisableChatHints, "Preference: Disable Chat Hints");
	
	if (dr_activator_speed_buff.BoolValue)
		AddPreferenceToMenu(menu, Preference_DisableActivatorSpeedBuff, "Preference: Disable Activator Speed Buff");
	
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
