void Menus_DisplayQueue(int caller)
{
	Menu menu = new Menu(Menus_HandleQueue);
	
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
	
	if (DRPlayer(caller).QueuePoints == -1)
		menu.SetTitle("Activator Queue List");
	else
		menu.SetTitle("Activator Queue List\nYour queue points: %i", DRPlayer(caller).QueuePoints);
	
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
