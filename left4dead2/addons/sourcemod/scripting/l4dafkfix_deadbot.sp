#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define TEAM_SURVIVORS 2
#define TEAM_SPECTATOR 1

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D2] 4+ Survivor Afk Fix",
	author = "MI 5, HarryPotter",
	description = "Fixes issue when a bot die, his IDLE player become fully spectator rather than take over dead bot in 4+ survivors games",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913"
}

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}


public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == TEAM_SURVIVORS)
	{
		int idleplayer = FindidOfIdlePlayer(client);
		if(idleplayer != 0)
		{
			L4D_SetHumanSpec(idleplayer, client);
			L4D_TakeOverBot(client);
		}
	}
}

int FindidOfIdlePlayer(int bot)
{
	char sNetClass[12];
	GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

	if( strcmp(sNetClass, "SurvivorBot") == 0 )
	{
		if( !GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID") )
			return 0;

		int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));
		if(client && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == TEAM_SPECTATOR)
		{
			return client;
		}
	}

	return 0;
}