/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.3a"
#define INFECTEDTEAM 3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

new Handle:g_hConVar_JockeyReleaseOn;
new Handle:g_hConVar_HunterReleaseOn;
new Handle:g_hConVar_ChargerReleaseOn;
new Handle:g_hConVar_ChargerChargeInterval;
new Handle:g_hConVar_JockeyAttackDelay;
new Handle:g_hConVar_HunterAttackDelay;
new Handle:g_hConVar_ChargerAttackDelay;
new bool:g_isJockeyEnabled;
new bool:g_isHunterEnabled;
new bool:g_isChargerEnabled;

new bool:g_ButtonDelay[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "[L4D2] Infected Release",
	author = "Thraka",
	description = "Allows infected players to release victims with the melee button.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=109715"
}

public APLRes:AskPluginLoad2(Handle:hPlugin, bool:isAfterMapLoaded, String:error[], err_max)
{
	// Require Left 4 Dead 2
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false))
	{
		Format(error, err_max, "Plugin only supports Left4Dead 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	
	CreateConVar("l4d2_infected_release_ver", PLUGIN_VERSION, "Version of the infected release plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	g_hConVar_JockeyReleaseOn = CreateConVar("l4d2_jockey_dismount_on", "1", "Jockey dismount is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hConVar_HunterReleaseOn = CreateConVar("l4d2_hunter_release_on", "1", "Hunter release is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hConVar_ChargerReleaseOn = CreateConVar("l4d2_charger_release_on", "1", "Charger release is on or off. 1 = on", FCVAR_PLUGIN|FCVAR_NOTIFY);
	g_hConVar_JockeyAttackDelay = CreateConVar("l4d2_jockey_attackdelay", "3.0", "After dismounting with the jockey, how long can the player not use attack1 and attack2", FCVAR_PLUGIN|FCVAR_NOTIFY, true);
	g_hConVar_HunterAttackDelay = CreateConVar("l4d2_hunter_attackdelay", "3.0", "After dismounting with the hunter, how long can the player not use attack1 and attack2", FCVAR_PLUGIN|FCVAR_NOTIFY, true);
	g_hConVar_ChargerAttackDelay = CreateConVar("l4d2_charger_attackdelay", "3.0", "After dismounting with the charger, how long can the player not use attack1 and attack2", FCVAR_PLUGIN|FCVAR_NOTIFY, true);
	
	g_hConVar_ChargerChargeInterval = FindConVar("z_charge_interval");
	
	HookConVarChange(g_hConVar_JockeyReleaseOn, CVarChange_JockeyRelease);
	HookConVarChange(g_hConVar_HunterReleaseOn, CVarChange_HunterRelease);
	HookConVarChange(g_hConVar_ChargerReleaseOn, CVarChange_ChargerRelease);
	
	AutoExecConfig(true, "l4d2_infected_release");
	
	SetJockeyRelease();
	SetHunterRelease();
	SetChargerRelease();
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* CVAR Change events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public CVarChange_JockeyRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetJockeyRelease();
}

public CVarChange_HunterRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetHunterRelease();
}

public CVarChange_ChargerRelease(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetChargerRelease();
}

SetJockeyRelease()
{
	g_isJockeyEnabled = GetConVarInt(g_hConVar_JockeyReleaseOn) == 1;
}

SetHunterRelease()
{
	g_isHunterEnabled = GetConVarInt(g_hConVar_HunterReleaseOn) == 1;
}

SetChargerRelease()
{
	g_isChargerEnabled = GetConVarInt(g_hConVar_ChargerReleaseOn) == 1;
}

/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Normal Hooks\Events
* 
* ===========================================================================================================
* ===========================================================================================================
*/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (client == 0)
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK2 && !g_ButtonDelay[client])
	{
		if (GetClientTeam(client) == INFECTEDTEAM)
		{
			new zombieClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			
			if (zombieClass == ZOMBIECLASS_JOCKEY && g_isJockeyEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");
				
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					ExecuteCommand(client, "dismount");
					
					CreateTimer(GetConVarFloat(g_hConVar_JockeyAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_HUNTER && g_isHunterEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_pounceVictim");
				
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					CallOnPounceEnd(client);

					CreateTimer(GetConVarFloat(g_hConVar_HunterAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
			else if (zombieClass == ZOMBIECLASS_CHARGER && g_isChargerEnabled)
			{
				new h_vic = GetEntPropEnt(client, Prop_Send, "m_pummelVictim");
				
				if (IsValidEntity(h_vic) && h_vic != 0)
				{
					CallOnPummelEnded(client);
					
					if (g_hConVar_ChargerChargeInterval != INVALID_HANDLE)
						CallResetAbility(client, GetConVarFloat(g_hConVar_ChargerChargeInterval));
					
					CreateTimer(GetConVarFloat(g_hConVar_ChargerAttackDelay), ResetDelay, client)
					g_ButtonDelay[client] = true;
				}
			}
		}
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK;
	}
	
	// If delayed, don't let them click
	if (buttons & IN_ATTACK2 && g_ButtonDelay[client])
	{
		buttons &= ~IN_ATTACK2;
	}
	
	return Plugin_Continue;
}


public Action:ResetDelay(Handle:timer, any:client)
{
	g_ButtonDelay[client] = false;
}
/*
* ===========================================================================================================
* ===========================================================================================================
* 
* Private Methods
* 
* ===========================================================================================================
* ===========================================================================================================
*/

ExecuteCommand(Client, String:strCommand[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}

CallOnPummelEnded(client)
{
    static Handle:hOnPummelEnded=INVALID_HANDLE;
    if (hOnPummelEnded==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPummelEnded");
        PrepSDKCall_AddParameter(SDKType_Bool,SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_CBasePlayer,SDKPass_Pointer,VDECODE_FLAG_ALLOWNULL);
        hOnPummelEnded = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPummelEnded == INVALID_HANDLE){
            SetFailState("Can't get CTerrorPlayer::OnPummelEnded SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPummelEnded,client,true,-1);
}

CallOnPounceEnd(client)
{
    static Handle:hOnPounceEnd=INVALID_HANDLE;
    if (hOnPounceEnd==INVALID_HANDLE){
        new Handle:hConf = INVALID_HANDLE;
        hConf = LoadGameConfigFile("l4d2_infected_release");
        StartPrepSDKCall(SDKCall_Player);
        PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CTerrorPlayer::OnPounceEnd");
        hOnPounceEnd = EndPrepSDKCall();
        CloseHandle(hConf);
        if (hOnPounceEnd == INVALID_HANDLE){
            SetFailState("Can't get CTerrorPlayer::OnPounceEnd SDKCall!");
            return;
        }            
    }
    SDKCall(hOnPounceEnd,client);
} 

CallResetAbility(client,Float:time)
{
	static Handle:hStartActivationTimer=INVALID_HANDLE;
	if (hStartActivationTimer==INVALID_HANDLE)
	{
		new Handle:hConf = INVALID_HANDLE;
		hConf = LoadGameConfigFile("l4d2_infected_release");

		StartPrepSDKCall(SDKCall_Entity);

		PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CBaseAbility::StartActivationTimer");
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float,SDKPass_Plain);

		hStartActivationTimer = EndPrepSDKCall();
		CloseHandle(hConf);
		
		if (hStartActivationTimer == INVALID_HANDLE)
		{
			SetFailState("Can't get CBaseAbility::StartActivationTimer SDKCall!");
			return;
		}            
	}
	new AbilityEnt=GetEntPropEnt(client, Prop_Send, "m_customAbility");
	SDKCall(hStartActivationTimer, AbilityEnt, time, 0.0);
}  