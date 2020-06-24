int Queue_GetPlayerInQueue(int index)
{
	ArrayList queue = new ArrayList(2, MaxClients);
	int length = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (Queue_IsClientAllowed(client))
		{
			queue.Set(length, DRPlayer(client).QueuePoints, 0); //block 0 gets sorted
			queue.Set(length, client, 1);
			length++;
		}
	}
	
	if (index >= length || length < 0)
		return -1;
	
	queue.Resize(length);
	queue.Sort(Sort_Descending, Sort_Integer);
	int client = queue.Get(index, 1);
	delete queue;
	
	return client;
}

bool Queue_IsClientAllowed(int iClient)
{
	// TODO: Check preferences here
	if (0 < iClient <= MaxClients
		 && IsClientInGame(iClient)
		 && TF2_GetClientTeam(iClient) > TFTeam_Spectator //Is client not in spectator
		 && DRPlayer(iClient).QueuePoints != -1) //Does client have his queue points loaded
	{
		return true;
	}
	else
	{
		return false;
	}
}

void Queue_AddPlayerPoints(int client, int points)
{
	DRPlayer player = DRPlayer(client);
	
	if (player.QueuePoints == -1)
	{
		PrintToChat(client, "Your queue points seem to be not loaded...");
		return;
	}
	
	player.QueuePoints += points;
	Cookies_SaveQueue(client, player.QueuePoints);
	
	PrintToChat(client, "You have been awarded %d queue points! (Total: %d)", points, player.QueuePoints);
}

void Queue_ResetPlayer(int client)
{
	DRPlayer player = DRPlayer(client);
	
	if (player.QueuePoints == -1)
		return;
	
	player.QueuePoints = 0;
	Cookies_SaveQueue(client, player.QueuePoints);
}
