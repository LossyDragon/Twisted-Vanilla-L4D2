/* Includes */
#include <sourcemod>
#include <sdktools>
#include <sceneprocessor>

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "Vocalize Anti-Flood",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Stops vocalize flooding",
	version		= "1.0.2",
	url		= "https://forums.alliedmods.net/showthread.php?t=241588"
}

/* Globals */
#define CVAR_FLOODTIME_NAME "vocalizeantiflood_time"
#define CVAR_FLOODTIME_DESC "Amount of time between player initiated vocalizes for a token to be added (Max 3 tokens before being marked as flooding)"
#define CVAR_FLOODTIME_VALUE "15.0"
#define CVAR_PENALTYTIME_NAME "vocalizeantiflood_penalty"
#define CVAR_PENALTYTIME_DESC "Amount of penalty time before player can initialize another vocalize after flooding"
#define CVAR_PENALTYTIME_VALUE "10.0"
#define CVAR_WORLD_FLOODTIME_NAME "vocalizeantiflood_talker_time"
#define CVAR_WORLD_FLOODTIME_DESC "Amount of time between forced vocalizes from player for a token to be added (Max 3 tokens before being marked as flooding)"
#define CVAR_WORLD_FLOODTIME_VALUE "5.0"
#define CVAR_WORLD_PENALTYTIME_NAME "vocalizeantiflood_talker_penalty"
#define CVAR_WORLD_PENALTYTIME_DESC "Amount of penalty time before forced vocalizes will be heard from the player again after flooding"
#define CVAR_WORLD_PENALTYTIME_VALUE "10.0"

#define MAX_VOCALIZE_TOKENS 3
#define MAX_WORLD_VOCALIZE_TOKENS 3

#define VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND "vocalize_flood_access"
#define VOCALIZE_ANTIFLOOD_OVERRIDE_FLAG ADMFLAG_ROOT

#define WORLD_VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND "world_vocalize_flood_access"
#define WORLD_VOCALIZE_ANTIFLOOD_OVERRIDE_FLAG ADMFLAG_ROOT

new Float:g_FloodTime
new Float:g_PenaltyTime
new Float:g_WorldFloodTime
new Float:g_WorldPenaltyTime

new Float:g_flLastVocalizeTimeStamp[MAXPLAYERS + 1]
new Float:g_flLastWorldVocalizeTimeStamp[MAXPLAYERS + 1]
new g_VocalizeTokens[MAXPLAYERS + 1]
new g_WorldVocalizeTokens[MAXPLAYERS + 1]
new g_VocalizeFloodCheckTick[MAXPLAYERS + 1]

/* Plugin Functions */
public OnPluginStart()
{
	new Handle:convar = CreateConVar(CVAR_FLOODTIME_NAME, CVAR_FLOODTIME_VALUE, CVAR_FLOODTIME_DESC, FCVAR_PLUGIN)
	g_FloodTime = GetConVarFloat(convar)
	HookConVarChange(convar, FloodTime_ConVarChanged)
	
	convar = CreateConVar(CVAR_PENALTYTIME_NAME, CVAR_PENALTYTIME_VALUE, CVAR_PENALTYTIME_DESC, FCVAR_PLUGIN)
	g_PenaltyTime = GetConVarFloat(convar)
	HookConVarChange(convar, PenaltyTime_ConVarChanged)
	
	convar = CreateConVar(CVAR_WORLD_FLOODTIME_NAME, CVAR_WORLD_FLOODTIME_VALUE, CVAR_WORLD_FLOODTIME_DESC, FCVAR_PLUGIN)
	g_WorldFloodTime = GetConVarFloat(convar)
	HookConVarChange(convar, FloodTime_Auto_ConVarChanged)
	
	convar = CreateConVar(CVAR_WORLD_PENALTYTIME_NAME, CVAR_WORLD_PENALTYTIME_VALUE, CVAR_WORLD_PENALTYTIME_DESC, FCVAR_PLUGIN)
	g_WorldPenaltyTime = GetConVarFloat(convar)
	HookConVarChange(convar, PenaltyTime_Auto_ConVarChanged)
	
	AutoExecConfig()
}

public FloodTime_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_FloodTime = GetConVarFloat(convar)
}

public PenaltyTime_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_PenaltyTime = GetConVarFloat(convar)
}

public FloodTime_Auto_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_WorldFloodTime = GetConVarFloat(convar)
}

public PenaltyTime_Auto_ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_WorldPenaltyTime = GetConVarFloat(convar)
}

public OnSceneStageChanged(scene, SceneStages:stage)
{
	if (stage != SceneStage_SpawnedPost)
	{
		return
	}
	
	new client = GetActorFromScene(scene)
	if (client <= 0 || client > MaxClients)
	{
		return
	}
	
	if (g_VocalizeFloodCheckTick[client] == GetGameTickCount())
	{
		return
	}
	
	new initiator = GetSceneInitiator(scene)
	if (!IsPlayerVocalizeFlooding(client, initiator))
	{
		return
	}
	
	CancelScene(scene)
}

public Action:OnVocalizeCommand(client, const String:vocalize[], initiator)
{
	g_VocalizeFloodCheckTick[client] = GetGameTickCount()
	return (IsPlayerVocalizeFlooding(client, initiator) ? Plugin_Stop : Plugin_Continue)
}

static stock bool:IsPlayerVocalizeFlooding(client, initiator)
{
	new bool:fromWorld = initiator == SCENE_INITIATOR_WORLD
	if (initiator == SCENE_INITIATOR_PLUGIN || (initiator != client && !fromWorld))
	{
		return false
	}
	
	decl flags
	
	if (fromWorld)
	{
		if (GetCommandOverride(WORLD_VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND, Override_Command, flags) && 
			CheckCommandAccess(client, WORLD_VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND, WORLD_VOCALIZE_ANTIFLOOD_OVERRIDE_FLAG, true))
		{
			return false
		}
	}
	else
	{
		if (GetCommandOverride(VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND, Override_Command, flags) &&
			CheckCommandAccess(client, VOCALIZE_ANTIFLOOD_OVERRIDE_COMMAND, VOCALIZE_ANTIFLOOD_OVERRIDE_FLAG, true))
		{
			return false
		}
	}
	
	new Float:curTime = GetEngineTime()
	new Float:newTime
	
	if (fromWorld)
	{
		if (g_WorldFloodTime <= 0.0)
		{
			return false
		}
		
		newTime = curTime + g_WorldFloodTime
		
		if (g_flLastWorldVocalizeTimeStamp[client] > curTime)
		{
			if (g_WorldVocalizeTokens[client] >= MAX_WORLD_VOCALIZE_TOKENS)
			{
				newTime += g_WorldPenaltyTime
				g_flLastWorldVocalizeTimeStamp[client] = newTime
				return true
			}
			else
			{
				g_WorldVocalizeTokens[client]++
			}
		}
		else if (g_WorldVocalizeTokens[client] > 0)
		{
			g_WorldVocalizeTokens[client]--
		}
		
		g_flLastWorldVocalizeTimeStamp[client] = newTime
	}
	else
	{
		if (g_FloodTime <= 0.0)
		{
			return false
		}
		
		newTime = curTime + g_FloodTime
		
		if (g_flLastVocalizeTimeStamp[client] > curTime)
		{
			if (g_VocalizeTokens[client] >= MAX_VOCALIZE_TOKENS)
			{
				newTime += g_PenaltyTime
				g_flLastVocalizeTimeStamp[client] = newTime
				return true
			}
			else
			{
				g_VocalizeTokens[client]++
			}
		}
		else if (g_VocalizeTokens[client] > 0)
		{
			g_VocalizeTokens[client]--
		}
		
		g_flLastVocalizeTimeStamp[client] = newTime
	}
	
	return false
}
