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

enum struct QueueData
{
	int client;
	int points;
}

void Queue_Init()
{
	g_currentActivators = new ArrayList();
}

ArrayList Queue_GetQueueList()
{
	ArrayList queue = new ArrayList(sizeof(QueueData));
	
	for (int client = 1; client <= MaxClients; ++client)
	{
		if (!IsClientInGame(client))
			continue;
		
		if (TF2_GetClientTeam(client) <= TFTeam_Spectator)
			continue;
		
		int points = DRPlayer(client).QueuePoints;
		if (points == -1)
			continue;
		
		if (DRPlayer(client).HasPreference(Preference_DisableActivatorQueue))
			continue;
		
		QueueData data;
		data.client = client;
		data.points = points;
		
		queue.PushArray(data);
	}
	
	queue.SortCustom(SortQueueByPointsDesc);
	return queue;
}

int Queue_GetPlayersInQueue()
{
	ArrayList queue = Queue_GetQueueList();
	int length = queue.Length;
	delete queue;
	return length;
}

void Queue_SelectNextActivators()
{
	g_currentActivators.Clear();
	
	ArrayList queue = Queue_GetQueueList();
	
	int numActivators = Min(dr_activator_count.IntValue, queue.Length);
	for (int i = 0; i < numActivators; ++i)
	{
		int client = queue.Get(i, QueueData::client);
		DRPlayer(client).SetQueuePoints(0);
		g_currentActivators.Push(client);
	}
	
	delete queue;
}

static int SortQueueByPointsDesc(int index1, int index2, Handle array, Handle hndl)
{
	ArrayList list = view_as<ArrayList>(array);
	
	QueueData data1, data2;
	list.GetArray(index1, data1);
	list.GetArray(index2, data2);
	
	return Compare(data2.points, data1.points);
}
