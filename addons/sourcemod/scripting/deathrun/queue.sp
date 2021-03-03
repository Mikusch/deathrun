/*
 * Copyright (C) 2020  Mikusch
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

ArrayList Queue_GetQueueList()
{
	ArrayList queue = new ArrayList(2, MaxClients);
	int length = 0;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (Queue_IsClientAllowed(client))
		{
			queue.Set(length, DRPlayer(client).QueuePoints, 0);	//block 0 gets sorted
			queue.Set(length, client, 1);
			length++;
		}
	}
	
	queue.Resize(length);
	queue.Sort(Sort_Descending, Sort_Integer);
	return queue;
}

void Queue_SetNextActivatorsFromQueue()
{
	g_CurrentActivators.Clear();
	
	ArrayList queue = Queue_GetQueueList();
	
	for (int i = 0; i < dr_activator_count.IntValue; i++)
	{
		int activator;
		
		if (i < queue.Length)	//Found player in queue
		{
			activator = queue.Get(i, 1);
			Queue_SetPoints(activator, 0);
		}
		else	//No players with queue points found, just find a random activator regardless of preferences
		{
			int[] clients = new int[MaxClients];
			int numClients = 0;
			
			for (int client = 1; client <= MaxClients; client++)
			{
				if (IsClientInGame(client) && TF2_GetClientTeam(client) > TFTeam_Spectator)
				{
					clients[numClients] = client;
					numClients++;
				}
			}
			
			activator = clients[GetRandomInt(0, numClients - 1)];
			CPrintToChat(activator, PLUGIN_TAG ... " %t", "Queue_ChosenAsRandomActivator");
		}
		
		g_CurrentActivators.Push(activator);
		TF2_ChangeClientTeamAlive(activator, TFTeam_Activators);
	}
	
	delete queue;
}

void Queue_AwardPoints(int client, int points)
{
	DRPlayer player = DRPlayer(client);
	
	if (player.QueuePoints == -1)
	{
		CPrintToChat(client, PLUGIN_TAG ... " %t", "Queue_NoPointsAwarded_NotLoaded");
		return;
	}
	else if (DRPlayer(client).HasPreference(Preference_DontBeActivator))
	{
		CPrintToChat(client, PLUGIN_TAG ... " %t", "Queue_NoPointsAwarded_Preferences");
		return;
	}
	
	player.QueuePoints += points;
	Cookies_SaveQueue(client, player.QueuePoints);
	
	CPrintToChat(client, PLUGIN_TAG ... " %t", "Queue_PointsAwarded", dr_queue_points.IntValue, player.QueuePoints);
}

void Queue_AddPoints(int client, int points)
{
	DRPlayer player = DRPlayer(client);
	player.QueuePoints += points;
	Cookies_SaveQueue(client, player.QueuePoints);
}

void Queue_SetPoints(int client, int points)
{
	DRPlayer player = DRPlayer(client);
	player.QueuePoints = points;
	Cookies_SaveQueue(client, player.QueuePoints);
}

bool Queue_IsClientAllowed(int client)
{
	if (IsValidClient(client)
		 && TF2_GetClientTeam(client) > TFTeam_Spectator	//Is the client not in spectator team?
		 && DRPlayer(client).QueuePoints != -1	//Does the client have their queue points loaded?
		 && !DRPlayer(client).HasPreference(Preference_DontBeActivator))	//Does the client want to be the activator?
	{
		return true;
	}
	else
	{
		return false;
	}
}
