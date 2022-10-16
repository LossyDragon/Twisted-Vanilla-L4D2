#pragma semicolon 1
#define PLUGIN_VERSION "1.0"  
#define PLUGIN_NAME "Survivor Spawn Position Fix (Gabu's Version)"

#include <sourcemod>  
#include <sdktools>  
#include <left4dhooks>  

#pragma newdecls required

ConVar	g_cvarEnabled;

bool 	g_bIsL4D1 = false;
int		g_iGenericSpawn = -1;

public Plugin myinfo =  
{  
	name = PLUGIN_NAME,  
	author = "Gabu",  
	description = "Fixed survivor spawns on 'special' maps where other survivors might spawn in a non-intended area.",  
	version = PLUGIN_VERSION,
	url = "https://github.com/gabuch2"
}  

public void OnPluginStart()  
{  
	g_cvarEnabled = CreateConVar("sm_l4d2_spawnpos_enabled", "1", "Enable the Plugin", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
}  

public void OnMapStart() 
{
	g_bIsL4D1 = L4D2_GetSurvivorSetMap() == 2 ? false : true;
	//	We need to do it on map start as well
	//	Because if we do it on round_start only, the first round won't be fixed
	FixSpawns();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	FixSpawns();
}

void FixSpawns()
{
	if(GetConVarBool(g_cvarEnabled))
	{
		// Determine if the spawns are standarized
		// Fixes survivors spawning in incorrect places in those special maps
		// Maybe now the addon creators will stop blaming modded servers for the mess they made 🥴
		// This is quite complex by the way because we need to check both the gamemode
		// and their proper spawns and all the possible ways a survivor can spawn
		ConVar cvarGameMode = FindConVar("mp_gamemode");
		char sGameMode[32];
		GetConVarString(cvarGameMode, sGameMode, sizeof(sGameMode));

		bool bFoundNamedSpawnPoint = false;

		int iEnt = -1;
		int iSpawnPoint = -1;
		while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
		{
			char sSpawnGameMode[32], sSurvivorName[32];
			GetEntPropString(iEnt, Prop_Data, "m_iszGameMode", sSpawnGameMode, sizeof(sSpawnGameMode));
			GetEntPropString(iEnt, Prop_Data, "m_iszSurvivorName", sSurvivorName, sizeof(sSurvivorName));
			if(((StrEqual(sGameMode, "coop") && (strlen(sSpawnGameMode) == 0 || StrEqual(sSpawnGameMode, sGameMode))) || StrEqual(sSpawnGameMode, sGameMode)) && StrEqual(sSurvivorName, g_bIsL4D1 ? "Bill" : "Nick", false))
			{
				bFoundNamedSpawnPoint = true;
				iSpawnPoint = iEnt;
				break;
			}
		}

		if(bFoundNamedSpawnPoint)
		{
			//we found named spawnpoint
			//now we need to create the new logic
			float fPosition[3];
			GetEntPropVector(iSpawnPoint, Prop_Send, "m_vecOrigin", fPosition);
			g_iGenericSpawn = CreateGenericSpawnPoint(fPosition);

			//cleanup
			iEnt = -1;
			while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
			{
				char sSpawnGameMode[32], sSurvivorName[32];
				GetEntPropString(iEnt, Prop_Data, "m_iszGameMode", sSpawnGameMode, sizeof(sSpawnGameMode));
				GetEntPropString(iEnt, Prop_Data, "m_iszSurvivorName", sSurvivorName, sizeof(sSurvivorName));
				if((StrEqual(sGameMode, "coop") && ((strlen(sSpawnGameMode) > 0 && !StrEqual(sSpawnGameMode, sGameMode)) ||(strlen(sSpawnGameMode) == 0 && strlen(sSurvivorName) == 0))) || (!StrEqual(sGameMode, "coop") && !StrEqual(sSpawnGameMode, sGameMode)))
					RemoveEntity(iEnt);
			}

			iEnt = -1;
			while ((iEnt = FindEntityByClassname(iEnt, "info_player_start")) != -1)
			{
				if(g_iGenericSpawn != iEnt)
					RemoveEntity(iEnt);
			}
		}
		else
		{
			// We didn't find a named spawn point
			// We need to try with Ordered spawn points now
			iEnt = -1;
			bool bFoundOrderedSpawnPoint = false;
			while ((iEnt = FindEntityByClassname(iEnt, "info_player_start")) != -1)
			{
				if(GetEntProp(iEnt, Prop_Data, "m_order") > 0)
				{
					bFoundOrderedSpawnPoint = true;
					iSpawnPoint = iEnt;
					break;
				}
			}

			if(bFoundOrderedSpawnPoint)
			{
				float fPosition[3];
				GetEntPropVector(iSpawnPoint, Prop_Send, "m_vecOrigin", fPosition);
				g_iGenericSpawn = CreateGenericSpawnPoint(fPosition);

				//cleanup
				iEnt = -1;
				while ((iEnt = FindEntityByClassname(iEnt, "info_survivor_position")) != -1)
				{
					if(GetEntProp(iEnt, Prop_Data, "m_order") == 0)
						RemoveEntity(iEnt);
				}

				iEnt = -1;
				while ((iEnt = FindEntityByClassname(iEnt, "info_player_start")) != -1)
				{
					if(g_iGenericSpawn != iEnt)
						RemoveEntity(iEnt);
				}
			}
		}

		// If everything above failed to trigger, the mapper decided to just use info_player_start for player spawns.
		// In that case we don't need to do anything because AFAIK you can't set individual spawns with those.
	}
}

int CreateGenericSpawnPoint(float fPosition[3])
{
	g_iGenericSpawn = CreateEntityByName("info_player_start");
	SetEntPropVector(g_iGenericSpawn, Prop_Send, "m_vecOrigin", fPosition); 
	DispatchSpawn(g_iGenericSpawn);
	return g_iGenericSpawn;
}