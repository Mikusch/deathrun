int Queue_GetPlayerInQueuePos(int pos)
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
	
	if (pos > length || pos < 1)
		return -1;
	
	queue.Resize(length);
	queue.Sort(Sort_Descending, Sort_Integer);
	int client = queue.Get(pos - 1, 1);
	delete queue;
	
	return client;
}

ArrayList Queue_GetQueueList()
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
	
	queue.Resize(length);
	queue.Sort(Sort_Descending, Sort_Integer);
	return queue;
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
