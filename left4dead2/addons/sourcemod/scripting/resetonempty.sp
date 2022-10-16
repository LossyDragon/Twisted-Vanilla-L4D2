#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "Reset Server When Empty",
	author      = "dustin",
	description = "Resets the server after everyone disconnects.",
	version     = "1.2.0",
	url         = ""
};

// globals
Handle g_hMaxSlots;
Handle g_hGameMode;
ConVar g_cvEnablePlugin;
ConVar g_cvEnableSlotReset;
ConVar g_cvHardReset;

//Original Game settings
char g_sMap[32];
char g_sGameMode[16];

int g_iSlots;
int g_iTimerCount;

bool g_bGrabGameSettings;
bool g_bResetCvars;

//Handles to manipulate cvars
ConVar convar_AFKTimeout;
ConVar convar_AllBotGame;
ConVar convar_AllowSurvBots;
ConVar convar_PostgameDelay;

//Original cvar storage
int g_iOriginal_AFKTimeout;
int g_iOriginal_AllBotGame;	
int g_iOriginal_AllowSurvBots;
int g_iOriginal_PostgameDelay;

public void OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect_Event, EventHookMode_Pre);
	
	g_hGameMode = FindConVar("mp_gamemode");
	g_hMaxSlots = FindConVar("sv_maxplayers");
	
	g_cvEnablePlugin = CreateConVar("sm_enable_Reset_Plugin", "1", "Enable the plugin? \n1 = true (default), 0 = false.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvEnableSlotReset = CreateConVar("sm_reset_player_slots", "0", "Reset player slots (sv_maxplayers) on map reset?\n(Incase an admin or plugin changes slots and doesn't set it back - this simply resets it back to the value found when the server first launched.)\n1 = true, 0 = false", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_cvHardReset = CreateConVar("sm_Hard_Restart_Enabled", "1", "Shut down the server when empty? (Don't enable unless you know how to set up a cron job script to reboot the game server.)\n1 = true, 0 = false", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// we don't want to force admins to set their AFK cvars in order to use a plugin, so we manually
	// check what they are and set them back afterward checking human count a few times
	convar_AFKTimeout = FindConVar("director_afk_timeout");
	convar_AllBotGame = FindConVar("sb_all_bot_game");
	convar_AllowSurvBots = FindConVar("allow_all_bot_survivor_team");
	convar_PostgameDelay = FindConVar("sv_hibernate_postgame_delay");
	
	g_bGrabGameSettings = true;
	
	AutoExecConfig(true, "ResetWhenEmpty");
}

public void OnMapStart()
{
	if (!GetConVarBool(g_cvEnablePlugin))
	{
		return;
	}

	if (g_bGrabGameSettings)
	{
		g_bGrabGameSettings = false;
		StoreOriginalCvars();
		GrabGameSettings();
	}
	if (g_bResetCvars)
	{
		g_bResetCvars = false;
		ResetAFKcvars();
		// Note: (tested in L4D2), if g_sGameMode is a coop mode and the map isn't set to chapter 1 (e.g. c1m4_atrium is ch 4),
		// the map will reset to chapter 1 after convar_PostgameDelay expires. There's some hacky
		// methods of manually loading the map again after this happens, but I feel it's not worth all the trouble.
		// In other modes such as survival, it stays on the correct map after convar_PostgameDelay expires.
	}
}

//PLAYER DISCONNECT
public Action PlayerDisconnect_Event(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(g_cvEnablePlugin))
	{
		return;
	}
		
	char strNetworkId[8];
	event.GetString("networkid", strNetworkId, sizeof(strNetworkId));
	
	if (StrEqual(strNetworkId, "BOT"))
	{
		return;
	}
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (GetRealHumanCount(client) == 0)
	{
		SetAFKcvars();
		g_iTimerCount = 0;
		CreateTimer(10.0, TIMER_RECHECK, _, TIMER_REPEAT);
	}
	
	return;
}

public Action TIMER_RECHECK(Handle timer)
{
	g_iTimerCount++;
	if (GetRealHumanCount() == 0)
	{
		if (g_iTimerCount >= 2)
		{
			g_bResetCvars = true;
			ResetGameSettings();
		}
	}
	else
	{
		ResetAFKcvars();
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

int GetRealHumanCount(int Disconnector = 0)
{
	int count;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;
		
		if (!IsFakeClient(i) && i != Disconnector)
		{
			count++;
		}
	}
	return count;
}

//CVAR MANIPULATION & STORAGE
void SetAFKcvars()
{
	convar_AFKTimeout.SetInt(99999);
	convar_AllBotGame.SetInt(1);
	convar_AllowSurvBots.SetInt(1);
	convar_PostgameDelay.SetInt(3600);
}

void ResetAFKcvars()
{
	convar_AFKTimeout.SetInt(g_iOriginal_AFKTimeout);
	convar_AllBotGame.SetInt(g_iOriginal_AllBotGame);
	convar_AllowSurvBots.SetInt(g_iOriginal_AllowSurvBots);
	convar_PostgameDelay.SetInt(g_iOriginal_PostgameDelay);
}

void StoreOriginalCvars()
{
	if (GetConVarInt(convar_AFKTimeout) < -1 || GetConVarInt(convar_AFKTimeout) > 9999999)
	{
		//They probably set the cvar too high so it's bugging out. Manually set this..
		SetConVarInt(convar_AFKTimeout, 9999999);
	}
		
	g_iOriginal_AFKTimeout = GetConVarInt(convar_AFKTimeout);
	g_iOriginal_AllBotGame = GetConVarInt(convar_AllBotGame);
	g_iOriginal_AllowSurvBots = GetConVarInt(convar_AllowSurvBots);
	g_iOriginal_PostgameDelay = GetConVarInt(convar_PostgameDelay);
}

//STORING & RESETTING GAME SETTINGS
void GrabGameSettings()
{
	char sGameFolder[16];
	GetGameFolderName(sGameFolder, sizeof(sGameFolder));
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	GetConVarString(g_hGameMode, g_sGameMode, sizeof(g_sGameMode));
	g_iSlots = GetConVarInt(g_hMaxSlots);
	if (g_iSlots == -1) // sv_maxplayers not set in server.cfg
	{
		if (StrEqual(sGameFolder, "left4dead", false) || StrEqual(sGameFolder, "left4dead2", false))
		{
			g_iSlots = 4;
		}
		else g_iSlots = 20; // default 20 slots in cs go. Untested for other games.
	}
}

void ResetGameSettings()
{
	if (!GetConVarBool(g_cvHardReset))
	{
		if (GetConVarBool(g_cvEnableSlotReset))
		{
			SetConVarInt(g_hMaxSlots, g_iSlots);
		}
		SetConVarString(g_hGameMode, g_sGameMode);
		ForceChangeLevel(g_sMap, "Resetting map..");
	}
	else
	{
		ServerCommand("quit");
	}
}