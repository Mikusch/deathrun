void Menus_DisplayQueue(int caller)
{
	Menu menu = new Menu(Menus_HandleQueue);
	
	for (int i = 0; i < 7; i++)
	{
		int client = Queue_GetPlayerInQueue(i);
		
		char name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		char display[256];
		Format(display, sizeof(display), "%s (%d)", name, DRPlayer(client).QueuePoints);
		
		menu.AddItem(NULL_STRING, display, ITEMDRAW_DEFAULT);
	}
	
	if (DRPlayer(caller).QueuePoints == -1)
		menu.SetTitle("Queue List");
	else
		menu.SetTitle("Queue List\nYour queue points: %i", DRPlayer(caller).QueuePoints);
	
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
