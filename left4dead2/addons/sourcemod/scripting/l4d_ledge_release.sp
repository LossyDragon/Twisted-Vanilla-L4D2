#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define PLUGIN_VERSION "3.5"

#define DEBUG 0
#define GAMEDATA	"l4d_ledge_release"
#define CVAR_FLAGS	FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Ledge Release",
	author = "Alex Dragokas",
	description = "Allow players who are hanging from a ledge to let go",
	version = PLUGIN_VERSION,
	url = "http://github.com/dragokas"
}

/*
	Based on my fork of:
	 - "Incapped Pills Pop" by AtomicStryker
	 - "L4D Ledge Release" by AltPluzF4, maintained by Madcap

	Recommended:
	 - [L4D] Health Exploit Fix by Dragokas

	Change Log:
	
	2.0 (05-May-2019)
	 - First release
	
	2.1 (20-May-2019)
	 - Ensure g_bGrabbed is reset.
	 
	2.2 (26-May-2019)
	 - Finally found why g_bGrabbed is not reset.
	 - Added client check on next frame.
	 
	2.3 (23-Nov-2019)
	 - Fixed infinite hanging sound.
	 - Now, correctly set health (compatible with my "Health Exploit Fix" plugin) and fire appropriate event.
	
	2.4 (~ somewhere in singularity)
	 - Refactoring, fixed lot of silly mistakes, including those coming from original plugin.
	 
	2.5 (22-Dec-2020)
	 - Fixing ugly music doesn't stop (thanks to Re:Creator for fix).
	
	2.6 (14-Mar-2021)
	 - Removed dependency on "Health Exploit Fix" by Dragokas (but, still recommended to use in L4D1).
	 - Now, health is restored accurately.
	 - Added ConVar "l4d_ledge_release_use_penalty" - 0 - Disable, 1 - Enable survivor hp penalty for hanging too long on a ledge.
	 - Added ConVar "l4d_ledge_release_button" - What button to press for release? 2 - Jump, 4 - Duck, 32 - Use. You can combine.
	 - New dependency required: DHooks Detours v.2.2.0.15+.
	
	3.0 (15-Apr-2021)
	 - Improved fix, when a player gets frozen when he tried to revive you.
	 - Added compatibility with L4D1 Windows, L4D2 Linux/Windows, and cases when "OnLedgeGrabbed", "OnRevived" DHook-ed by other plugins.
	 - Translation file is updated to reflect concrete button adjusted in ConVar.
	 - ConVar "l4d_ledge_release_forbid_when_reviving" removed since it is bugged. Now it is always forbidden.
	 - Added ConVar "l4d_ledge_release_enable" - Enable this plugin (1 - Yes, 2 - No).
	 - Improved music stop fix.
	 
	3.1 (28-Jun-2021)
	 - Added random hash to dhook's gamedata section preventing it from accidental breaking by another plugin.
	
	3.2 (18-Jan-2022)
	 - Prevented "double-hang" in more reliable way via inputs (thanks to Silvers for help).
	 - Code is simplified.
	
	3.4 (20-Jan-2022)
	 - Finally fixed stop sound nightmare using SDKCall to Music class instance.
	 - Hanging sound is restored as it should be by design.
	 - Added ConVar "l4d_ledge_release_msg_level". What messages to display? -1 - All, 1 - Advertisements, 2 - Warnings
	 - Code is simplified.
	 
	3.5 (21-Jan-2022)
	 - (experimentally) Fixed the bug, when player getting stuck in the bumps under the ledge on some map places after he released.
	 - Fixed compilation warnings on SM 1.11.
*/

enum MSG_LEVEL
{
	MSG_ADVERTISEMENT 	= 1 << 0,
	MSG_WARNING			= 1 << 1
}

ConVar 	g_hCvarEnable, g_hCvarDelaySetting, g_hCvarDecayRate, g_hCvarPenalty, g_hCvarReleaseButton, g_hCvarMessageLevel; // g_hCvarForbidInReviving
int 	g_iHealth[MAXPLAYERS+1], g_iReviveCount[MAXPLAYERS+1], g_iGoingToDie[MAXPLAYERS+1], g_iCvarButton;
float 	g_fTempHealth[MAXPLAYERS+1], g_fHangedTime[MAXPLAYERS+1], g_fDelaySetting;
bool 	g_bGrabbed[MAXPLAYERS+1], g_bForbidInReviving, g_bLeft4dead2, g_bEnabled;
Handle 	g_hSDK_OnSavedFromLedgeHang;
Address g_iOffsetMusic;

MSG_LEVEL g_iMsgLevel;

DynamicDetour hDetour_OnLedgeGrabbed;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 && test != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLeft4dead2 = test == Engine_Left4Dead2;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_ledge_release.phrases");
	
	CreateConVar("l4d_ledge_release_version", PLUGIN_VERSION, "Version of plugin", CVAR_FLAGS | FCVAR_DONTRECORD);
	
	g_hCvarEnable = 			CreateConVar("l4d_ledge_release_enable", "1", "Enable this plugin (1 - Yes, 2 - No)", CVAR_FLAGS);
	g_hCvarDelaySetting = 		CreateConVar("l4d_ledge_release_delaytime", "1.0", "How long before grabbing the ledge you can release", CVAR_FLAGS);
	//g_hCvarForbidInReviving = 	CreateConVar("l4d_ledge_release_forbid_when_reviving", "1", "Forbid release from the ledge when somebody reviving you (1 - Yes / 0 - No)", CVAR_FLAGS);
	g_hCvarPenalty = 			CreateConVar("l4d_ledge_release_use_penalty", "1", "0 - Disable, 1 - Enable survivor hp penalty for hanging too long on a ledge", CVAR_FLAGS);
	g_hCvarReleaseButton = 		CreateConVar("l4d_ledge_release_button", "4", "What button to press for release? 2 - Jump, 4 - Duck, 32 - Use. You can combine.", CVAR_FLAGS);
	g_hCvarMessageLevel =		CreateConVar("l4d_ledge_release_msg_level", "-1", "What messages to display? -1 - All, 1 - Advertisements, 2 - Warnings", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_ledge_release");
	
	g_hCvarDecayRate = FindConVar("pain_pills_decay_rate");
	
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	
	GameData hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	g_iOffsetMusic = view_as<Address>(hGameData.GetOffset("CMusic"));
	
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "Music::OnSavedFromLedgeHang"))
		SetFailState("Could not load the \"Music::OnSavedFromLedgeHang\" gamedata signature.");
	g_hSDK_OnSavedFromLedgeHang = EndPrepSDKCall();
	if( g_hSDK_OnSavedFromLedgeHang == null )
		SetFailState("Could not prep the \"Music::OnSavedFromLedgeHang\" function.");
	
	SetupDetour(hGameData);
	delete hGameData;
		
	GetCvars();
	
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDelaySetting.AddChangeHook(ConVarChanged_Cvars);
	//g_hCvarForbidInReviving.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReleaseButton.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMessageLevel.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	if( !hDetour_OnLedgeGrabbed.Disable(Hook_Pre, OnLedgeGrabbed) )
		SetFailState("Failed to disable detour \"CTerrorPlayer::OnLedgeGrabbed\".");
}

void SetupDetour(GameData hGameData)
{
	hDetour_OnLedgeGrabbed = DynamicDetour.FromConf(hGameData, "CTerrorPlayer::OnLedgeGrabbed_erf8md");
	if( !hDetour_OnLedgeGrabbed )
		SetFailState("Failed to find \"CTerrorPlayer::OnLedgeGrabbed\" signature.");
	if( !hDetour_OnLedgeGrabbed.Enable(Hook_Pre, OnLedgeGrabbed) )
		SetFailState("Failed to start detour \"CTerrorPlayer::OnLedgeGrabbed\".");
}

public MRESReturn OnLedgeGrabbed(int pThis, DHookParam hParams)
{
	if( 0 < pThis <= MaxClients && IsClientInGame(pThis) )
	{
		SaveHealth(pThis);
	}
	return MRES_Ignored;
}

void InitHook()
{
	static bool bHooked;

	if( g_bEnabled )
	{
		if( !bHooked )
		{
			HookEvent("player_ledge_grab", Event_LedgeGrab);
			HookEvent("player_ledge_release", Event_LedgeRelease);
			HookEvent("player_spawn", Event_PlayerSpawn);
			HookEvent("player_death", Event_Death);
			HookEvent("revive_success", Event_ReviveSuccess);
			HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if( bHooked )
		{
			UnhookEvent("player_ledge_grab", Event_LedgeGrab);
			UnhookEvent("player_ledge_release", Event_LedgeRelease);
			UnhookEvent("player_spawn", Event_PlayerSpawn);
			UnhookEvent("player_death", Event_Death);
			UnhookEvent("revive_success", Event_ReviveSuccess);
			UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

void SaveHealth(int client)
{
	GetHealthInfo(client, g_iHealth[client], g_fTempHealth[client], g_iReviveCount[client], g_iGoingToDie[client]);
	g_fHangedTime[client] = GetGameTime();

	#if DEBUG
		PrintToChat(client, "Saved health: %i, temp: %f, ReviveCount: %i, GoingToDie: %i", g_iHealth[client], g_fTempHealth[client], g_iReviveCount[client], g_iGoingToDie[client]);
	#endif
}

void RestoreHealth(int client)
{
	float fPenalty;

	if( g_hCvarPenalty.BoolValue )
	{
		fPenalty = (GetGameTime() - g_fHangedTime[client]) * g_hCvarDecayRate.FloatValue;
		
		g_fTempHealth[client] -= fPenalty; // firstly, decrease temp hp
		
		if( g_fTempHealth[client] < 0.0 ) // if not enough, decrease basic hp
		{
			g_iHealth[client] += RoundToCeil(g_fTempHealth[client]);
			g_fTempHealth[client] = 0.0;
			
			if( g_iHealth[client] < 1 )
			{
				g_iHealth[client] = 1;
			}
		}
	}
	
	SetHealth(client, g_iHealth[client], g_fTempHealth[client], g_iReviveCount[client], g_iGoingToDie[client]);
	
	#if DEBUG
		PrintToChat(client, "Restored health: %i, temp: %f, ReviveCount: %i, GoingToDie: %i (penalty: %f)", 
			g_iHealth[client], g_fTempHealth[client], g_iReviveCount[client], g_iGoingToDie[client], fPenalty);
	#endif
}

public void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_fDelaySetting = g_hCvarDelaySetting.FloatValue;
	g_bForbidInReviving = true; // g_hCvarForbidInReviving.BoolValue;
	g_iCvarButton = g_hCvarReleaseButton.IntValue;
	g_iMsgLevel = view_as<MSG_LEVEL>(g_hCvarMessageLevel.IntValue);
	InitHook();
}

public void OnMapStart()
{
	Reset();
	// because I saw "not precached" errors in logfile
	PrecacheSound("music/terror/ClingingToHell1.wav", true);
	PrecacheSound("music/terror/ClingingToHell2.wav", true);
	PrecacheSound("music/terror/ClingingToHell3.wav", true);
	PrecacheSound("music/terror/ClingingToHell4.wav", true);
}

void Reset()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bGrabbed[i] = false;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	static float fTime[MAXPLAYERS+1];
	
	if( !g_bGrabbed[client] )
	{
		return Plugin_Continue;
	}
	
	if( buttons & g_iCvarButton && GetEngineTime() - fTime[client] > 2.0 )
	{		
		fTime[client] = GetEngineTime(); // a little button delay because the cmd fires too fast.
		
		if( !IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client) )
		{
			#if DEBUG
			PrintToChat(client, "Incorrect client");
			#endif
			return Plugin_Continue;
		}
		
		if( !IsPlayerIncapped(client) )
		{
			#if DEBUG
			PrintToChat(client, "Not incapped");
			#endif
			return Plugin_Continue;
		}
		
		if( IsFalling(client) )
		{
			#if DEBUG
			PrintToChat(client, "Falling!");
			#endif
			return Plugin_Continue;
		}
		
		if( IsBeingPwnt(client) )
		{
			if( g_iMsgLevel & MSG_WARNING )
			{
				CPrintToChat(client, "%t", "GetOffInfected");
			}
			return Plugin_Continue;
		}
		
		if( g_bForbidInReviving && IsInReviving(client) )
		{
			if( g_iMsgLevel & MSG_WARNING )
			{
				CPrintToChat(client, "%t", "AlreadyReviving");
			}
			return Plugin_Continue;
		}
		
		AcceptEntityInput(client, "DisableLedgeHang");
		
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 0);
		
		StopReviveAction(client);
		RestoreHealth(client);
		StopHangSound(client);
		
		CreateTimer(1.0, Timer_RestoreDrop, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		
		RequestFrame(Frame_CheckStuck, GetClientUserId(client));
	}
	return Plugin_Continue;
}

public void Frame_CheckStuck(int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		if( IsClientStuck(client) )
		{
			bool bShouldTeleport = true;
			float result[3];
			GetVectorOriginInDirection(client, -30.0, true, result);
			
			if( IsClientStuck(client, result) )
			{
				GetVectorOriginInDirection(client, -70.0, true, result);
				if( IsClientStuck(client, result) )
				{
					bShouldTeleport = false;
				}
			}
			if( bShouldTeleport )
			{
				TeleportEntity(client, result, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
}

public Action Timer_RestoreDrop(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	if( client && IsClientInGame(client) )
	{
		AcceptEntityInput(client, "EnableLedgeHang");
	}
	return Plugin_Continue;
}

void StopHangSound(int client)
{
	Address pMusic = GetEntityAddress(client) + g_iOffsetMusic;
	SDKCall(g_hSDK_OnSavedFromLedgeHang, pMusic);
}

// Prevents an accidental freezing of player who tried to revive you
//
void StopReviveAction(int client)
{
	int owner_save = -1;
	int target_save = -1;
	int owner = GetEntPropEnt(client, Prop_Send, "m_reviveOwner"); // when you reviving somebody, this is -1. When somebody revive you, this is somebody's id
	int target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget"); // when you reviving somebody, this is somebody's id. When somebody revive you, this is -1
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropEnt(client, Prop_Send, "m_reviveTarget", -1);
	if( owner != -1 ) // we must reset flag for both - for you, and who you revive
	{
		SetEntPropEnt(owner, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(owner, Prop_Send, "m_reviveTarget", -1);
		owner_save = owner;
	}
	if( target != -1 )
	{
		SetEntPropEnt(target, Prop_Send, "m_reviveOwner", -1);
		SetEntPropEnt(target, Prop_Send, "m_reviveTarget", -1);
		target_save = target;
	}
	
	if( g_bLeft4dead2 )
	{
		owner = GetEntPropEnt(client, Prop_Send, "m_useActionOwner");		// used when healing e.t.c.
		target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");
		SetEntPropEnt(client, Prop_Send, "m_useActionOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_useActionTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_useActionTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_useActionOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_useActionTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
		SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(owner_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iCurrentUseAction", 0);
			SetEntPropFloat(target_save, Prop_Send, "m_flProgressBarDuration", 0.0);
		}
	}
	else {
		owner = GetEntPropEnt(client, Prop_Send, "m_healOwner");		// used when healing
		target = GetEntPropEnt(client, Prop_Send, "m_healTarget");
		SetEntPropEnt(client, Prop_Send, "m_healOwner", -1);
		SetEntPropEnt(client, Prop_Send, "m_healTarget", -1);
		if( owner != -1 )
		{
			SetEntPropEnt(owner, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(owner, Prop_Send, "m_healTarget", -1);
			owner_save = owner;
		}
		if( target != -1 )
		{
			SetEntPropEnt(target, Prop_Send, "m_healOwner", -1);
			SetEntPropEnt(target, Prop_Send, "m_healTarget", -1);
			target_save = target;
		}
		
		SetEntProp(client, Prop_Send, "m_iProgressBarDuration", 0);
		
		if( owner_save != -1 )
		{
			SetEntProp(owner_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
		if( target_save != -1 )
		{
			SetEntProp(target_save, Prop_Send, "m_iProgressBarDuration", 0);
		}
	}
}

public void Event_PlayerSpawn (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public void Event_LedgeGrab (Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);
	g_bGrabbed[client] = true;
	
	if( g_fDelaySetting != 0.0 )
	{
		if( g_iMsgLevel & MSG_ADVERTISEMENT )
		{
			CreateTimer(g_fDelaySetting, Timer_AdvertiseRelease, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void Event_LedgeRelease (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public void Event_ReviveSuccess (Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject"));
	g_bGrabbed[client] = false;
}

public void OnClientPutInServer(int client)
{
	g_bGrabbed[client] = false;
}

public void Event_Death( Event event, const char[] Death_Name, bool dontBroadcast )
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bGrabbed[client] = false;
}

public Action Timer_AdvertiseRelease(Handle timer, any UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if( client && IsClientInGame(client) )
	{
		char sKey[16];
		if( g_iCvarButton & IN_USE )
		{
			sKey = "IN_USE";
		}
		else if( g_iCvarButton & IN_DUCK )
		{
			sKey = "IN_DUCK";
		}
		else if( g_iCvarButton & IN_JUMP )
		{
			sKey = "IN_JUMP";
		}		
		CPrintToChat(client, "%t %t %t", "Press", sKey, "Hint_Release");
	}
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

stock void CPrintToChat(int client, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(client, "\x01%s", buffer);
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock bool IsInReviving(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_reviveOwner") != -1;
}

stock bool IsBeingPwnt(int client)
{
	return GetEntPropEnt(client, Prop_Send, "m_tongueOwner") != -1;
}

stock bool IsFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0;
}

stock bool IsPlayerIncapped(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) == 1;
}

void GetHealthInfo(int client, int &iHealth = 0, float &fTempHealth = 0.0, int &iReviveCount = 0, int &iGoingToDie = 0)
{
	iHealth = GetEntProp(client, Prop_Send, "m_iHealth");
	fTempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	float delta = (GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * g_hCvarDecayRate.FloatValue;
	fTempHealth -= delta;
	if( fTempHealth < 0.0 )
	{
		fTempHealth = 0.0;
	}
	iReviveCount = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	iGoingToDie = GetEntProp(client, Prop_Send, "m_isGoingToDie");
}

void SetHealth(int client, int iHealth, float fTempHealth = -1.0, int iReviveCount = -1, int iGoingToDie = -1, float fBufferTime = 0.0)
{
	SetEntProp(client, Prop_Send, "m_iHealth", iHealth);
	if( fTempHealth >= 0.0 )
	{
		SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", fBufferTime == 0.0 ? GetGameTime() : fBufferTime);
		SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fTempHealth);
	}
	if( iReviveCount != -1 )
	{
		SetEntProp(client, Prop_Send, "m_currentReviveCount", iReviveCount);
	}
	if( iGoingToDie != -1 )
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", iGoingToDie);
	}
}

stock bool IsClientStuck(int iClient, float vOrigin[3] = {0.0, 0.0, 0.0})
{
	static float vMin[3], vMax[3];
	static Handle hTrace;
	static bool bHit;
	bHit = false;
	GetClientMins(iClient, vMin);
	GetClientMaxs(iClient, vMax);
	if( vOrigin[0] == 0.0 && vOrigin[1] == 0.0 && vOrigin[2] == 0.0 )
	{
		GetClientAbsOrigin(iClient, vOrigin);
	}
	hTrace = TR_TraceHullFilterEx(vOrigin, vOrigin, vMin, vMax, MASK_PLAYERSOLID, TraceRayNoPlayers, iClient);
	if (hTrace != INVALID_HANDLE) {
		bHit = TR_DidHit(hTrace);
		CloseHandle(hTrace);
	}
	return bHit;
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
    if( entity == data || (entity >= 1 && entity <= MaxClients) )
    {
        return false;
    }
    return true;
}

/*
	Returns vector origin in direction of eye view angle (optionally ignoring vertical).
	Calculation is started from client origin.

	@client - client index.
	@distance - distance to move the vector forward. Use negative value to move backward.
	@skipXAxis - to ignore vertical coordinate {X, Z, _}.
	@result - float array variable to return result vector to.

*/
stock void GetVectorOriginInDirection(int client, float distance, bool skipXAxis, float result[3])
{
	float vCli[3], vEye[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", vCli);
	GetClientEyeAngles(client, vEye);
	if( skipXAxis ) vEye[0] = 0.0; // prevents objects appearing underground
	GetAngleVectors(vEye, vEye, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vEye, vEye);
	ScaleVector(vEye, distance);
	AddVectors(vCli, vEye, result);
}
