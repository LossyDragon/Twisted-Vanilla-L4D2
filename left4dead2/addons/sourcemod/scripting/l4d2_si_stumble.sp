#define PLUGIN_VERSION 		"2.1"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Special Infected Stumble - Grenade Launcher
*	Author	:	SilverShot
*	Descrp	:	Stumbles Special Infected when hurt by a Grenade Launcher.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=322063
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

2.1 (26-Jun-2020)
	- Added cvar "l4d2_si_stumble_survivors" to control if Survivors should be stumbled.
	- Added cvar "l4d2_si_stumble_self" to control if survivors can stumble themselves.
	- Thanks to "Black714" for requesting.

2.0 (16-Jun-2020)
	- Renamed plugin and changed cvar names.
	- Now supports all special infected. Thanks to "Black714" for requesting.
	- Added cvar "l4d2_si_stumble_special" to control which special infected can be affected.

1.4 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.2 (24-Mar-2020)
	- Fixed stupid mistake. Thanks to "tRololo312312" for reporting.

1.1 (19-Mar-2020)
	- Fixed not unhooking OnTakeDamage and affecting the wrong players. Thanks to "tRololo312312" for reporting.

1.0 (14-Mar-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRange, g_hCvarSelf, g_hCvarSpecial,g_hCvarSurvivors;
bool g_bCvarAllow, g_bMapStarted, g_bLateLoad, g_bCvarSelf, g_bCvarSurvivors;
float g_fCvarRange;
int g_iCvarSpecial;



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Special Infected Stumble - Grenade Launcher",
	author = "SilverShot",
	description = "Stumbles Special Infected when hurt by a Grenade Launcher.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=322063"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =			CreateConVar(	"l4d2_si_stumble_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d2_si_stumble_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d2_si_stumble_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d2_si_stumble_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRange =			CreateConVar(	"l4d2_si_stumble_range",			"200.0",			"The distance the special infected must be to the Grenade Launcher projectile impact to stumble.", CVAR_FLAGS );
	g_hCvarSelf =			CreateConVar(	"l4d2_si_stumble_self",				"0",				"0=Off. 1=On. Should you be able to stumble yourself.", CVAR_FLAGS );
	g_hCvarSpecial =		CreateConVar(	"l4d2_si_stumble_special",			"127",				"Which Special Infected to affect: 1=Smoker, 2=Boomer, 4=Hunter, 8=Spitter, 16=Jockey, 32=Charger, 64=Tank. 127=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarSurvivors =		CreateConVar(	"l4d2_si_stumble_survivors",		"0",				"0=Off. 1=On. Should Survivors be affected and stumble.", CVAR_FLAGS );
	CreateConVar(							"l4d2_si_stumble_version",			PLUGIN_VERSION,		"Special Infected Stumble GL plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d2_si_stumble");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRange.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSelf.AddChangeHook(ConVarChanged_Special);
	g_hCvarSpecial.AddChangeHook(ConVarChanged_Special);
	g_hCvarSurvivors.AddChangeHook(ConVarChanged_Special);

	IsAllowed();
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Special(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();

	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			HookClient(i);
		}
	}
}

void GetCvars()
{
	g_fCvarRange = g_hCvarRange.FloatValue;
	g_bCvarSelf = g_hCvarSelf.BoolValue;
	g_iCvarSpecial = g_hCvarSpecial.IntValue;
	g_bCvarSurvivors = g_hCvarSurvivors.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		if( g_bLateLoad )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( IsClientInGame(i) )
				{
					HookClient(i);
				}
			}
		}

		HookEvents(true);
		g_bCvarAllow = true;
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bLateLoad = true; // To-rehook active SI if plugin re-enabled.
		HookEvents(false);
		g_bCvarAllow = false;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents(bool hook)
{
	static bool hooked;

	if( !hooked && hook )
	{
		HookEvent("round_start",	Event_RoundStart);
		HookEvent("player_death",	Event_PlayerDeath);
		HookEvent("player_spawn",	Event_PlayerSpawn);
	}
	else if( hooked && !hook )
	{
		UnhookEvent("round_start",	Event_RoundStart);
		UnhookEvent("player_death",	Event_PlayerDeath);
		UnhookEvent("player_spawn", Event_PlayerSpawn);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) )
			SDKUnhook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client ) HookClient(client);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client ) SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

void HookClient(int client)
{
	int team = GetClientTeam(client);
	if( team == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == 8 ) class = 7;

		if( g_iCvarSpecial & (1 << (class - 1)) )
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	else if( team == 2 )
	{
		if( g_bCvarSelf || g_bCvarSurvivors )
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if( inflictor > MaxClients && IsValidEntity(inflictor) )
	{
		static char classname[17];
		GetEdictClassname(inflictor, classname, sizeof(classname));

		if( strcmp(classname, "grenade_launcher") == 0 )
		{
			int team = GetClientTeam(victim);
			if( team == 3 || (team == 2 && (g_bCvarSelf && victim == attacker) || (g_bCvarSurvivors && victim != attacker)) )
			{
				float vPos[3], vTarg[3];
				GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", vPos);
				GetClientAbsOrigin(victim, vTarg);

				if( GetVectorDistance(vPos, vTarg) <= g_fCvarRange )
				{
					StaggerClient(GetClientUserId(victim), vPos);
				}
			}
		}
	}
}

// Credit to Timocop on VScript function
void StaggerClient(int iUserID, const float fPos[3])
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
	{
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if( iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic) )
		{
			LogError("Could not create 'logic_script");
			return;
		}

		DispatchSpawn(iScriptLogic);
	}

	static char sBuffer[96];
	Format(sBuffer, sizeof(sBuffer), "GetPlayerFromUserID(%d).Stagger(Vector(%d,%d,%d))", iUserID, RoundFloat(fPos[0]), RoundFloat(fPos[1]), RoundFloat(fPos[2]));
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
	AcceptEntityInput(iScriptLogic, "Kill");
}