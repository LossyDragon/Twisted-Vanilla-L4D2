/*============================================================================================
							[L4D & L4D2] Survivor Sprint, Stamina and Exhaustion
----------------------------------------------------------------------------------------------
*	Author	:	Eärendil
*	Descrp	:	Allows survivors to sprint, adds stamina, if wasted stamina survivors can enter in exhaustion
*	Version	:	1.2
*	Link	:	None
----------------------------------------------------------------------------------------------
	- This plugin uses Survivor Utilities to call exhaustion and speeds.
	- Exhaustion events are completely managed by Utilities plugin, but movement speed is not
		reset on player death, that must be managed by plugin.
	- This gives full control of survivor speeds on round, but makes plugins responsible to
		add/revert player speeds when survivors die if is required.
	- If you want to add permanent survivor speed you give them once on round start, but
		in the case of this plugin we have to check and revert speeds everytime.
	- Moreover, taking in consideration some plugins can be doing the same as this one,
		instead of adding an absolute value and override other plugin modifications it
		multiplies/divides survivor speeds, allways trying to preserve the 
==============================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <survivorutilities>

#define PLUGIN_VERSION "1.2"
#define FCVAR_FLAGS
#define TOKEN_LIMIT 5

enum
{
	STATUS_INCAP,
	STATUS_LIMP,
	STATUS_NORMAL,
	STATUS_ADREN
};

public Plugin myinfo =
{
	name = "[L4D & L4D2] Sprint, stamina and exhaustion",	// Title pending of changes, I haven't found an appropiate name for this
	author = "Eärendil",
	description = "Allows survivors to sprint, adds stamina, if wasted stamina survivors can enter in exhaustion",
	version = PLUGIN_VERSION,
	url = "",
};

int g_iPlayerStamina[MAXPLAYERS+1], g_iStaminaMin, g_iPlayerInput[MAXPLAYERS+1], g_iStopTokens[MAXPLAYERS+1];

ConVar	g_hStaminaMin, g_hHealthMax, g_hHealthMin, g_hAllow, g_hGameModes, g_hCurrGameMode, g_hStaminaUse, g_hTempDecay, 
		g_hStaminaAm, g_hStaminaRegen, g_hStaminaRMov, g_hStaminaProp, g_hStaminaTemp, g_hExhaust, g_hSprintLimp, g_hLimpHealth,
		g_hSprintScale, g_hStaminaDecay, g_hExhaustAm, g_hLimpScale, g_hAdrenScale;
		
float g_fHealthMax, g_fHealthMin, g_fSprintScale, g_fLimpScale, g_fAdrenScale;

bool g_bAllow, g_bPluginOn, g_bAllowGamemode, g_bPlayerSprinting[MAXPLAYERS+1];

char g_sGameMode[64];

Handle g_hRegenTimer[MAXPLAYERS+1], g_hSprintTimer[MAXPLAYERS+1], g_hInputTimer[MAXPLAYERS+1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if( GetEngineVersion() != Engine_Left4Dead2 && GetEngineVersion() != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_sprintstamina_version", PLUGIN_VERSION, "Survivor sprint, stamina and exhaustion version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hAllow =			CreateConVar("l4d_sse_enable",					"1",			"0 = Plugin Off. 1 = Plugin On", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hGameModes =		CreateConVar("l4d_sse_gamemodes",				"",				"Enable the plugin in these gamemodes, separated by spaces. (Empty = all).", FCVAR_NOTIFY);
	g_hStaminaUse =		CreateConVar("l4d_sse_usestamina",				"1",			"0 = Infinite sprint. 1 = Use stamina.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hStaminaAm =		CreateConVar("l4d_sse_stamina_amount",			"120",			"Max amount of stamina.", FCVAR_NOTIFY, true, 0.0);
	g_hStaminaDecay =	CreateConVar("l4d_sse_stamina_decay",			"8",			"Stamina decay rate (every half second) while sprinting", FCVAR_NOTIFY, true, 0.0);
	g_hStaminaRegen = 	CreateConVar("l4d_sse_stamina_regen",			"5",			"Amount of stamina recovered (every half second) while not moving or walking.", FCVAR_NOTIFY, true, 0.0);
	g_hStaminaRMov =	CreateConVar("l4d_sse_stamina_regen_moving",	"1",			"Amount of stamina recovered (every half second) while normal running.", FCVAR_NOTIFY, true, 0.0);
	g_hStaminaProp =	CreateConVar("l4d_sse_stamina_hp_proportional",	"1",			"0 = Stamina allways max amount. 1 = Proportional to health.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hStaminaTemp =	CreateConVar("l4d_sse_stamina_temphealth",		"0.5",			"Temporary health will count as normal health this amount to calculate max stamina.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hExhaust =		CreateConVar("l4d_sse_exhaustion",				"1",			"Exhaust survivor when stamina reaches 0. 0 = Disable. 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hExhaustAm =		CreateConVar("l4d_sse_exhaust_amount",			"150",			"Amount of exhaust tokens that the player will get on exhaust.\n10 tokens = 1 second if survivor doesn't move, 2 seconds if its moving.", FCVAR_NOTIFY, true, 0.0);
	g_hSprintLimp =		CreateConVar("l4d_sse_sprint_limp",				"0",			"Allow survivors to sprint while limping. 0 = Disable, 1 = Enable.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hStaminaMin =		CreateConVar("l4d_sse_stamina_min",				"0",			"If proportional stamina, minimum amount of stamina at low health.", FCVAR_NOTIFY, true, 0.0);
	g_hHealthMax =		CreateConVar("l4d_sse_health_max",				"70.0",			"While survivor health is over this value, stamina will be at max value.", FCVAR_NOTIFY, true, 0.0);
	g_hHealthMin = 		CreateConVar("l4d_sse_health_min",				"20.0",			"When health reaches this value stamina will drop to min value", FCVAR_NOTIFY, true, 0.0);
	g_hSprintScale =	CreateConVar("l4d_sse_sprint_scale",			"1.5",			"Multiply survivor speed by this amount when sprinting.", FCVAR_NOTIFY, true, 1.0);
	g_hLimpScale =		CreateConVar("l4d_sse_sprint_limp_scale",		"1.5",			"If allowed, multiply limping speed by this value when sprinting.", FCVAR_NOTIFY, true, 1.0);
	g_hAdrenScale =		CreateConVar("l4d_sse_sprint_adren_scale",		"1.2",			"Scale survivor adrenaline run by this value while sprinting.", FCVAR_NOTIFY, true, 1.0);
	
	g_hTempDecay =	 	FindConVar("pain_pills_decay_rate");
	g_hLimpHealth = 	FindConVar("survivor_limp_health");
	g_hCurrGameMode = 	FindConVar("mp_gamemode");
	
	g_hAllow.AddChangeHook(CVarChange_Enable);
	g_hGameModes.AddChangeHook(CVarChange_Enable);
	g_hStaminaAm.AddChangeHook(CVarChange_CVars);
	g_hStaminaMin.AddChangeHook(CVarChange_CVars);
	g_hHealthMax.AddChangeHook(CVarChange_CVars);
	g_hHealthMin.AddChangeHook(CVarChange_CVars);
	g_hSprintScale.AddChangeHook(CVarChange_SprintScale);
	g_hLimpScale.AddChangeHook(CVarChange_SprintScale);
	g_hAdrenScale.AddChangeHook(CVarChange_SprintScale);
	
	for( int i = 0; i < MaxClients; i++ )
	{
		g_iPlayerStamina[i] = g_hStaminaAm.IntValue;
	}
	g_bPluginOn = false;
	AutoExecConfig(true, "l4d_sprintstamina");
}

public void OnConfigsExecuted()
{
	GetGameMode();
	SwitchPlugin();
	GetCVars();
	GetSprint();	
}

public void OnMapStart()
{
	for( int i = 0; i < MaxClients; i++ )
		ResetClientData(i);
}

public void OnMapEnd()
{
	for( int i = 0; i < MaxClients; i++ )
		ResetClientData(i);
}

// Reset client stamina amount and sprint state, utilities plugin sets player speeds to ConVar automatically
public void OnClientConnected(int client)
{
	ResetClientData(client);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if( !g_bPluginOn )	return Plugin_Continue;

	if( GetClientTeam(client) != 2 || !IsPlayerAlive(client) ) return Plugin_Continue;	// Allow only alive survivors
		
	if( SU_IsExhausted(client) ) return Plugin_Continue;	// Ignore exhausted players
	
	if( buttons & IN_SPEED || buttons & IN_DUCK )
	{
		if( g_iPlayerInput[client] == 3 )
			OnPlayerReleaseRunKey(client);	// Call a release run key	
			
		return Plugin_Continue;
	}
	
	if( buttons & IN_FORWARD )
	{
		int iStatus = GetSurvivorStatus(client);
		if( iStatus == STATUS_INCAP )
			return Plugin_Continue;

		if( !g_hSprintLimp.BoolValue && iStatus == STATUS_LIMP ) 
			return Plugin_Continue;

		if( g_iPlayerInput[client] %2 == 0 )	// Only perform on states 0 and 2
			OnPlayerPressRunKey(client);
	}
	else if( g_iPlayerInput[client] %2 != 0 ) // Only perform on states 1, 3 and -1
		OnPlayerReleaseRunKey(client);

	return Plugin_Continue;
}

//==========================================================================================
//									ConVar Logic
//==========================================================================================
public void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetGameMode();
	SwitchPlugin();
}

public void CVarChange_CVars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCVars();
}

public void CVarChange_SprintScale(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetSprint();
}

void SwitchPlugin()
{
	g_bAllow = g_hAllow.BoolValue;
	if( g_bPluginOn == false && g_bAllow == true && g_bAllowGamemode == true )
	{
		g_bPluginOn = true;
		HookEvent("player_death",			Event_Player_Death);
		HookEvent("round_start",			Event_Round_Start, EventHookMode_PostNoCopy);
		HookEvent("player_bot_replace",		Event_Player_Replaced);	// Bot replaced a player
		HookEvent("bot_player_replace",		Event_Bot_Replaced);	// Player replaced a bot
		HookEvent("heal_success",			Event_Healing);
		HookEvent("pills_used",				Event_Healing);
		
		for( int i = 0; i < MaxClients; i++ )
		{
			g_iPlayerStamina[i] = g_hStaminaAm.IntValue;
			g_bPlayerSprinting[i] = false;
			g_iPlayerInput[i] = 0;
		}
	}
	if( g_bPluginOn == true && (g_bAllow == false || g_bAllowGamemode == false) )
	{
		g_bPluginOn = false;
		UnhookEvent("player_death",			Event_Player_Death);
		UnhookEvent("round_start",			Event_Round_Start);
		UnhookEvent("player_bot_replace",	Event_Player_Replaced);
		UnhookEvent("bot_player_replace",	Event_Bot_Replaced);
		UnhookEvent("heal_success",			Event_Healing);
		UnhookEvent("pills_used",			Event_Healing);
		
		for( int i = 0; i < MaxClients; i++ )
		{
			g_iPlayerStamina[i] = g_hStaminaAm.IntValue;
			g_bPlayerSprinting[i] = false;
			g_iPlayerInput[i] = 0;
		}
	}
}

void GetGameMode()
{
	if( g_hCurrGameMode == null )
		return;

	char sGameModes[64];
	g_hCurrGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));	// Store "mp_gamemode" result in g_sGameMode
	g_hGameModes.GetString(sGameModes, sizeof(sGameModes));		// Store all gamemodes which will start plugin in sGameModes
	
	if( sGameModes[0] )	// If string is not empty that means that server admin only wants plugin in some gamemodes
	{
		if( StrContains(sGameModes, g_sGameMode, false) == -1 )	// Check if the current gamemode is not in the list of allowed gamemodes
		{
			g_bAllowGamemode = false;
			return;
		}
	}
	
	g_bAllowGamemode = true;
}

void GetCVars()
{
	g_hStaminaAm.IntValue = g_hStaminaAm.IntValue;
	
	if( g_hStaminaMin.IntValue > g_hStaminaAm.IntValue ) PrintToServer("WARNING: \"l4d_sse_stamina_min\" is higher than \"l4d_sse_stamina_amount\", clamping.");
	else g_iStaminaMin = g_hStaminaMin.IntValue;
	
	g_fHealthMax = g_hHealthMax.FloatValue;
	
	if( g_hHealthMin.FloatValue > g_fHealthMax ) PrintToServer("WARNING: \"l4d_sse_health_min\" is higher than \"l4d_sse_health_max\", clamping.");
	else g_fHealthMin = g_hHealthMin.FloatValue;
}

//==========================================================================================
//										Events
//==========================================================================================
public Action Event_Player_Death(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_hStaminaUse ) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || GetClientTeam(client) != 2 ) return Plugin_Continue;

	ToggleSprint(client, false); // Disable sprint if survivor is sprinting when death
	ResetClientData(client);
			
	return Plugin_Continue;
}

public Action Event_Player_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	if( !g_hStaminaUse ) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || GetClientTeam(client) != 2 )
		return Plugin_Continue;
	g_iPlayerStamina[client] = GetStamina(client);
	return Plugin_Continue;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i < MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			ToggleSprint(i, false);	
			ResetClientData(i);
		}
	}
}

public Action Event_Player_Replaced(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player")); 
	
	g_iPlayerInput[client] = 0;
	ToggleSprint(client, false);
	delete g_hRegenTimer[client];
	delete g_hSprintTimer[client];
}

public Action Event_Bot_Replaced(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	// If player needs to recover stamina, enable timer
	if( g_iPlayerStamina[client] < GetStamina(client) )
		g_hRegenTimer[client] = CreateTimer(0.5, Regen_Timer, client, TIMER_REPEAT);
}

public Action Event_Healing(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	
	if( g_bPlayerSprinting[client] ) return Plugin_Continue;
	
	if( g_hRegenTimer[client] != null ) return Plugin_Continue;
	
	if( g_iPlayerStamina[client] < GetStamina(client) )
	{
		delete g_hRegenTimer[client];
		g_hRegenTimer[client] = CreateTimer(0.5, Regen_Timer, client, TIMER_REPEAT);
	}
	return Plugin_Continue;
}
//==========================================================================================
//									Timers
//==========================================================================================
// This timer will loop until stamina drops off or survivor stops sprinting
public Action Sprint_Timer(Handle timer, int client)
{	
	if( !g_bPluginOn || !IsClientInGame(client) || !IsPlayerAlive(client) || !g_bPlayerSprinting[client] )
	{
		g_hSprintTimer[client] = null;
		return Plugin_Stop;
	}
	int iStatus = GetSurvivorStatus(client);	
	int maxStamina = GetStamina(client);
	
	if( iStatus == STATUS_INCAP )
	{
		g_hSprintTimer[client] = null;
		return Plugin_Stop;	
	}
	if( iStatus == STATUS_ADREN )
	{
		g_iPlayerStamina[client] = maxStamina;
		PrintStamina(client);
		return Plugin_Continue;
	}
	
	if( g_iPlayerStamina[client] > 0 ) 
	{
		if( g_hStaminaProp.BoolValue && g_iPlayerStamina[client] > maxStamina ) // To automatically take out the excess of the stamina
			g_iPlayerStamina[client] = maxStamina;
			
		g_iPlayerStamina[client] -= g_hStaminaDecay.IntValue;
		PrintStamina(client);
		return Plugin_Continue;
	}
	g_iPlayerStamina[client] = 0;
	if( g_hExhaust.BoolValue )	// Exhaust survivor if stamina is fully depleted
		SU_AddExhaust(client, g_hExhaustAm.IntValue);
	else
	{
		g_iPlayerInput[client] = 0;
		ToggleSprint(client, false);	// Only disable sprint
		
		g_hRegenTimer[client] = CreateTimer(0.5, Regen_Timer, client, TIMER_REPEAT);
	}
	g_hSprintTimer[client] = null;
	return Plugin_Stop;
}

// This timer will loop until stamina regens or survivor starts sprinting
public Action Regen_Timer(Handle timer, int client)
{	
	if( !g_bPluginOn || !IsClientInGame(client) || !IsPlayerAlive(client) || g_iPlayerInput[client] == 3 || SU_IsExhausted(client) )
	{
		g_hRegenTimer[client] = null;
		return Plugin_Stop;
	}

	int stamina = g_hStaminaProp.BoolValue ? GetStamina(client) : g_hStaminaAm.IntValue;	// Max stamina will depend if convar stamina proportional is 1 or 0
	if( g_iPlayerStamina[client] < stamina )
	{
		int buttons = GetEntProp(client, Prop_Data, "m_nButtons");
		if( buttons & IN_WALK || buttons & IN_DUCK ) g_iPlayerStamina[client] += g_hStaminaRegen.IntValue;
		else if( buttons & IN_FORWARD || buttons & IN_RIGHT || buttons & IN_LEFT || buttons & IN_BACK ) g_iPlayerStamina[client] += g_hStaminaRMov.IntValue;
		else g_iPlayerStamina[client] += g_hStaminaRegen.IntValue;
		
		PrintStamina(client);
		return Plugin_Continue;
	}
	g_iPlayerStamina[client] = stamina;
	
	g_hRegenTimer[client] = null;
	return Plugin_Stop;
}

public Action Input_Timer(Handle timer, int client)
{
	g_hInputTimer[client] = null;
	
	if( g_iPlayerInput[client] > 2 || g_iPlayerInput[client] < 1 )
		return;
		
	g_iPlayerInput[client] = -1;
}

// Check to stop sprint if player is blocked or uses scope
public Action CheckSprint_Timer(Handle timer, int client)
{
	if( !IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) != 2 || !g_bPlayerSprinting[client] )
		return Plugin_Stop;

	if( GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") != -1 )
	{
		OnPlayerReleaseRunKey(client);	// Trigger release run key effects
		return Plugin_Stop;		
	}
	
	float vVel[3], fSpeed;
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", vVel);
	fSpeed = GetVectorLength(vVel);
	
	if( fSpeed < 65.0 )
	{
		if( ++g_iStopTokens[client] >= TOKEN_LIMIT )
		{
			OnPlayerReleaseRunKey(client);
			return Plugin_Stop;			
		}
		return Plugin_Continue;
	}
	g_iStopTokens[client] = 0;
	return Plugin_Continue;
}

//==========================================================================================
//									Functions
//==========================================================================================

// Reset client data to default when mapchange, round start, client connect
void ResetClientData(int client)
{
	g_bPlayerSprinting[client] = false;
	g_iPlayerInput[client] = 0;
	g_iPlayerStamina[client] = g_hStaminaAm.IntValue;
	
	delete g_hRegenTimer[client];
	delete g_hInputTimer[client];
	delete g_hSprintTimer[client];
}

void OnPlayerPressRunKey(int client)
{		
	if( GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") != -1 )
		return;
		
	if( g_iPlayerInput[client] == 0 )	// Sate 0: Player press run for first time
	{
		delete g_hInputTimer[client];
		g_hInputTimer[client] = CreateTimer(0.6, Input_Timer, client);
		g_iPlayerInput[client] = 1;
	}
	if( g_iPlayerInput[client] == 2 )	// State 2: player press run a second time and is allowed to sprint
	{
		delete g_hInputTimer[client];
		g_iPlayerInput[client]++;
		ToggleSprint(client, true);
		if( g_hStaminaUse.BoolValue )	// Enable stamina usage if allowed
			g_hSprintTimer[client] = CreateTimer(0.5, Sprint_Timer, client, TIMER_REPEAT);
	}
}

void OnPlayerReleaseRunKey(int client)
{
	if( g_iPlayerInput[client] == 1 )	// Player just pressed run recently
		g_iPlayerInput[client] = 2;

	if( g_iPlayerInput[client] == 3 )	//Player is sprinting
	{
		g_iStopTokens[client] = 0;
		ToggleSprint(client, false);
		g_iPlayerInput[client] = 0;
		if( g_hStaminaUse.BoolValue && !SU_IsExhausted(client) )	// Enable stamina regeneration if allowed
			g_hRegenTimer[client] = CreateTimer(0.5, Regen_Timer, client, TIMER_REPEAT);	
	}
	if( g_iPlayerInput[client] == -1 )	// Sprint timer cancelled, restart
		g_iPlayerInput[client] = 0;
}

int GetStamina(int client)
{
	float fHealth = CalculateHealth(client, false);
	if( fHealth >= g_fHealthMax ) return g_hStaminaAm.IntValue;
	else if( fHealth <= g_fHealthMin ) return g_iStaminaMin;
	else
	{
		float result = LinealInterpolation(g_fHealthMin, g_fHealthMax, float(g_iStaminaMin), float(g_hStaminaAm.IntValue), fHealth);
		return RoundToNearest(result);
	}
}

float LinealInterpolation(const float x0, const float x1, const float y0, const float y1, const float x)
{
	float fSlope = (y1 - y0) / (x1 - x0);
	return (y0 + fSlope * (x - x0));
}

// Reescale sprinting speeds if you change convar value when survivors are sprinting, or it will change their normal speeds!
void GetSprint()
{
	bool[] bSprinting = new bool[MaxClients];
	for( int i = 1; i < MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 && g_bPlayerSprinting[i] )
		{
			bSprinting[i] = true;
			ToggleSprint(i, false);
		}
			
	}
	g_fSprintScale = g_hSprintScale.FloatValue;
	g_fLimpScale = g_hLimpScale.FloatValue;
	g_fAdrenScale = g_hAdrenScale.FloatValue;
	for( int i = 1; i < MaxClients; i++ )
	{
		if( bSprinting[i] )
			ToggleSprint(i, true);
	}
}

// IMPORTANT: Use relative values, multiply/divide player speed. If you set a custom speed like 300.0 you can mess speeds with other plugins
void ToggleSprint(int client, bool activate)
{
	// Safely prevents speed corruptions when method invoked incorrectly
	if( g_bPlayerSprinting[client] == activate )
		return;
	if( activate )
	{
		g_bPlayerSprinting[client] = true;
		SU_SetSpeed(client, SPEED_RUN, SU_GetSpeed(client, SPEED_RUN) * g_fSprintScale);
		SU_SetSpeed(client, SPEED_ADRENALINE, SU_GetSpeed(client, SPEED_ADRENALINE) * g_fAdrenScale);
		if( g_hSprintLimp.BoolValue )
			SU_SetSpeed(client, SPEED_LIMP, SU_GetSpeed(client, SPEED_LIMP) * g_fLimpScale);
			
		CreateTimer(0.1, CheckSprint_Timer, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_bPlayerSprinting[client] = false;
		SU_SetSpeed(client, SPEED_RUN, SU_GetSpeed(client, SPEED_RUN) / g_fSprintScale);
		SU_SetSpeed(client, SPEED_ADRENALINE, SU_GetSpeed(client, SPEED_ADRENALINE) / g_fAdrenScale);
		if( g_hSprintLimp.BoolValue )
			SU_SetSpeed(client, SPEED_LIMP, SU_GetSpeed(client, SPEED_LIMP) / g_fLimpScale);
	}
}

// Calculates health (permanent+temp) value to modify stamina, decreases the value of temp health if required
float CalculateHealth(int client, bool absoluteTemp)
{
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_hTempDecay.FloatValue;
	if( absoluteTemp )
		fHealth = fHealth < 0.0 ? 0.0 : fHealth;
	else
		fHealth = fHealth < 0.0 ? 0.0 : fHealth * g_hStaminaTemp.FloatValue;
	return float(GetClientHealth(client)) + fHealth;
}


public void SU_OnExhaustEnd(int client)
{
	if( !g_hStaminaUse.BoolValue ) return;	// We dont need this if stamina is not being used

	g_hRegenTimer[client] = CreateTimer(0.5, Regen_Timer, client, TIMER_REPEAT);
}

// When survivor exhaust stops regenerate stamina again
public Action SU_OnExhaust(int client)
{
	if( g_hStaminaUse.BoolValue && g_iPlayerStamina[client] > 0 ) g_iPlayerStamina[client] = 0;	// Empty player stamina if is being used
	ToggleSprint(client, false);	// End player sprinting in case its sprinting
	g_iPlayerInput[client] = 0;
	return Plugin_Continue;
}

void PrintStamina(int client)
{
	static int MSG_SIZE = 28;
	char sStaminaMsg[32]; // Declare
	sStaminaMsg[0] = '\0'; // Initialize
	int iMax = g_hStaminaProp.BoolValue ? GetStamina(client)*MSG_SIZE/g_hStaminaAm.IntValue : MSG_SIZE;
	int iStamina = g_iPlayerStamina[client]*MSG_SIZE/g_hStaminaAm.IntValue;
	for( int i = 0; i < MSG_SIZE; i++ )
	{
		if( i <= iStamina ) StrCat(sStaminaMsg, sizeof(sStaminaMsg), "#");
		else if( i <= iMax ) StrCat(sStaminaMsg, sizeof(sStaminaMsg), "=");
		else StrCat(sStaminaMsg, sizeof(sStaminaMsg), "/");
	}
	PrintHintText(client, "Stamina: |%s|", sStaminaMsg);
}

// Returns Incapacitation, Limping, Normal, or Adrenaline buff
int GetSurvivorStatus(int client)
{
	if( GetEntProp(client, Prop_Send, "m_isIncapacitated") == 1 ) return STATUS_INCAP;
	
	if( GetEntProp(client, Prop_Send, "m_bAdrenalineActive") != 0 ) return STATUS_ADREN;
	
	if( CalculateHealth(client, true) < g_hLimpHealth.FloatValue ) return STATUS_LIMP;

	else return STATUS_NORMAL;
}

/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.2	(01-Feb-2022)
		- Limping sprint and adrenaline speed can be scaled by ConVar.
		- Survivors can't attempt to sprint if they are incapacitated.
		- If a survivor isn't moving due to an obstacle or healing/reviving, sprint cancels automatically.
		- Survivor stamina will be at maximum value if survivor is under adrenaline effect.
		- Healing triggers stamina regeneration if maximum stamina increased.
* 1.1.2 (23-Jan-2022)
		- Fixed bug when survivor wouldn't sprint when limping if allowed by ConVar (thanks to Shao for the report).
* 1.1.1 (01-Jan-2022)
		- Fixed Handle errors related with timers.
		- Fixed a bug when survivor goes idle and comes back the stamina is fully restored.
* 1.1	(30-Dec-2021)
		- Fixed invalid_handle error on "player_death" event.
		- Fixed a bug where exhaustion corrupted survivor speeds.
		- Fixed bugs on mapchanges, round restarts or player connection.
		- Fixed a bug where sprint doesn't end if stamina is depleted and l4d_sse_exhaustion is set to 0.
		- The amount of exhaustion now can be controlled by COnVar.
		- If survivor goes replaced by a bot, its stamina will be stored for the next time he comes back.
* 1.0.1	(25-Dec-2021)
		- Fixed invalid client errors.
		- Fixed wrong ConVars.
		- sm_sse_enable now works properly.
* 1.0	(25-Dec-2021)
		- Initial release.
============================================================================================*/