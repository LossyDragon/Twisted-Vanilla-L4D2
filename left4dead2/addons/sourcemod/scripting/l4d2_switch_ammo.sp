/*
*	Switch Upgrade Ammo Types
*	Copyright (C) 2022 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION 		"1.15"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Switch Upgrade Ammo Types
*	Author	:	SilverShot
*	Descrp	:	Switch between normal bullets and upgraded ammo types.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=325300
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.15 (15-Aug-2022)
	- Added GameData file and new feature to reload the gun when changing ammo types. Requested by "Shao".
	- Added cvar "l4d2_switch_ammo_guns" to control if the "Grenade Launcher" or "Rifle M60" ammo can be switched.
	- Changed cvar "l4d2_switch_ammo_reload" to control if weapons should be reloaded when changing ammo types.

1.14 (12-Aug-2022)
	- Added cvar "l4d2_switch_ammo_reload" to wait for reloading to finish before switch ammo type. Requested by "Shao".

1.13 (16-Jun-2022)
	- Fixed a bug where you couldn't switch to stock ammo. Thanks to "Toranks" for reporting.

1.12 (13-May-2022)
	- Fixed invalid entity error. Thanks to "sonic155" for reporting.

1.11 (02-May-2022)
	- Fixed late loading (turning the plugin off and on again) from not detecting stock ammo when upgrade ammo is equipped.
	- Fixed gaining ammo issue. Thanks to "Toranks" for reporting and testing.
	- Weapon now switches to upgrade ammo if available when no stock ammo remains.

1.10 (20-Mar-2022)
	- Added Spanish translations. Thanks to "Toranks" for providing.
	- Changes to fix warnings when compiling on SM 1.11.

1.9 (15-Sep-2021)
	- Now uses the new forward provided by "Save Weapon" plugin modified by "HarryPotter". Requires version "5.4" or newer.
	- For compatibility with both plugins to work together. Thanks to "HarryPotter" for supporting.
	- Supported plugin can be found here: https://github.com/fbef0102/L4D2-Plugins/tree/master/l4d2_ty_saveweapons

1.8 (13-Sep-2021)
	- Added support for "L4D2 coop save weapon" version by "HarryPotter".
	- Removed support for [l4d2] Save Weapon (Co-op)" plugin by "maks".
	- Changes to prevent giving upgraded ammo when someone respawns.

1.7 (12-Sep-2021)
	- Fixed not restoring map transitioned ammo on round restart. Thanks to "swiftswing1" for reporting.

1.6 (11-Sep-2021)
	- Fixed not saving ammo on map transition. Thanks to "swiftswing1" for reporting.

1.5 (30-Aug-2021)
	- Fixed the plugin breaking in modes other than coop. Thanks to "swiftswing1" for reporting and testing.

1.4 (17-Aug-2021)
	- Now automatically detects "[l4d2] Save Weapon (Co-op)" plugin by "maks" to fix giving upgrade ammo to players after map transition.

1.3 (15-Aug-2021)
	- Added cvar "l4d2_switch_ammo_hint" to display a message when taking upgrade ammo about how to use the plugin.
	- Added file "switch_ammo.phrases.txt" to display hints.
	- Fix for "[l4d2] Save Weapon (Co-op)" plugin by "maks". Thanks to "swiftswing1" for reporting.

1.2 (21-Aug-2020)
	- Fixed the last update accidentally enabling unlimited usage of upgrade ammo piles.

1.1 (18-Aug-2020)
	- Blocked the M60 and Grenade Launcher from being able to switch ammo types.

1.0 (16-Jun-2020)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define GAMEDATA			"l4d2_switch_ammo"

#define TYPE_FIRES			(1<<0)
#define TYPE_EXPLO			(1<<1)
#define TYPE_STOCK			3

// Setting to 1 re-creates the upgrade packs after use, for constant testing
#define DEBUG_PLUGIN		0


ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarGuns, g_hCvarHint, g_hCvarReload;//, g_hCvarSaveWeapon;
bool g_bCvarAllow, g_bTranslation, g_bMapStarted;
int g_iCvarGuns, g_iCvarHint, g_iCvarReload, g_iOffsetAmmo, g_iPrimaryAmmoType;
int g_iAmmoCount[2048][4];				// Upgrade ammo [0]=UserId. [1]=Incendiary. [2]=Explosives. [3]=Stock
int g_iAmmoBugFix[2048];				// Weapons reserve ammo.

bool g_bPlayerDied[MAXPLAYERS+1];
float g_fSwitched[MAXPLAYERS+1];
int g_iLastWeapon[MAXPLAYERS+1];
int g_iTransition[MAXPLAYERS+1][4];
char g_sTransition[MAXPLAYERS+1][32];

Handle g_hSDK_Call_Reload;

StringMap g_hClipSize;
char g_sWeapons[][] =
{
	"weapon_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_rifle_sg552",
	"weapon_rifle_desert",
	"weapon_rifle_ak47",
	"weapon_smg_silenced",
	"weapon_smg_mp5",
	"weapon_shotgun_spas",
	"weapon_sniper_scout",
	"weapon_sniper_military",
	"weapon_sniper_awp",
	"weapon_grenade_launcher",
	"weapon_rifle_m60"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Switch Upgrade Ammo Types",
	author = "SilverShot",
	description = "Switch between normal bullets and upgraded ammo types.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=325300"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

// public void OnAllPluginsLoaded()
// {
	// g_hCvarSaveWeapon = FindConVar("l4d2_hx_health");
// }

public void OnPluginStart()
{
	// ====================================================================================================
	// TRANSLATIONS
	// ====================================================================================================
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/switch_ammo.phrases.txt");

	if( !FileExists(sPath) )
		g_bTranslation = false;
	else
	{
		LoadTranslations("switch_ammo.phrases");
		g_bTranslation = true;
	}

	// ====================================================================================================
	// CVARS
	// ====================================================================================================
	g_hCvarAllow =		CreateConVar(	"l4d2_switch_ammo_allow",			"1",				"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarGuns =		CreateConVar(	"l4d2_switch_ammo_guns",			"0",				"0=Neither. 1=Allow to use on the Grenade Launcher. 2=Allow to use on the M60. 3=Both.", CVAR_FLAGS );
	g_hCvarHint =		CreateConVar(	"l4d2_switch_ammo_hint",			"1",				"Display a hint when taking upgrade ammo about how to use the plugin. 0=Off. 1=Print to Chat. 2=Hint text.", CVAR_FLAGS );
	g_hCvarReload =		CreateConVar(	"l4d2_switch_ammo_reload",			"1",				"0=Off. 1=Reload the weapon when changing ammo types. 2=Reload shotguns from an empty clip when changing ammo types.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_switch_ammo_modes",			"",					"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_switch_ammo_modes_off",		"",					"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_switch_ammo_modes_tog",		"0",				"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar(						"l4d2_switch_ammo_version",			PLUGIN_VERSION,		"Switch Ammo Types plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_switch_ammo");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarGuns.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarReload.AddChangeHook(ConVarChanged_Cvars);

	// =========================
	// GAMEDATA
	// =========================
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(sPath) == false )
	{
		// SetFailState("\n==========\nMissing required file: \"%s\".\nRead installation instructions again.\n==========", sPath);

		File hFile = OpenFile(sPath, "w");
		hFile.WriteLine("\"Games\"");
		hFile.WriteLine("{");
		hFile.WriteLine("	\"left4dead2\"");
		hFile.WriteLine("	{");
		hFile.WriteLine("		\"Offsets\"");
		hFile.WriteLine("		{");
		hFile.WriteLine("			\"CTerrorGun::Reload\"");
		hFile.WriteLine("			{");
		hFile.WriteLine("				\"windows\"	\"281\"");
		hFile.WriteLine("				\"linux\"		\"282\"");
		hFile.WriteLine("			}");
		hFile.WriteLine("		}");
		hFile.WriteLine("	}");
		hFile.WriteLine("}");
		delete hFile;
	}

	GameData hGameData = new GameData(GAMEDATA);
	if( hGameData == null ) SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Entity);
	if( PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CTerrorGun::Reload") == false )
		SetFailState("Failed to find offset: CTerrorGun::Reload");
	g_hSDK_Call_Reload = EndPrepSDKCall();
	if( g_hSDK_Call_Reload == null )
		SetFailState("Failed to create SDKCall: CTerrorGun::Reload");

	// ====================================================================================================
	// OFFSETS
	// ====================================================================================================
	g_iOffsetAmmo = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	AddCommandListener(CommandListener, "give");

	// ====================================================================================================
	// LATE LOAD
	// ====================================================================================================
	int weapon;
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && GetClientTeam(i) == 2 )
		{
			weapon = GetPlayerWeaponSlot(i, 0);
			if( weapon != -1 )
			{
				g_iLastWeapon[i] = EntIndexToEntRef(weapon);
				g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(i, weapon);
				g_iAmmoCount[weapon][TYPE_STOCK] = GetEntProp(weapon, Prop_Send, "m_iClip1");
			}
		}
	}

	#if DEBUG_PLUGIN
	RegAdminCmd("sm_sa", CmdSA, ADMFLAG_ROOT, "For debugging Switch Ammo plugin.");
	#endif
}

#if DEBUG_PLUGIN
Action CmdSA(int client, int args)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	GetOrSetPlayerAmmo(client, weapon, 11);
	g_iAmmoBugFix[weapon] = 11;
	g_iAmmoCount[weapon][TYPE_STOCK] = 3;
	SetEntProp(weapon, Prop_Send, "m_iClip1", 3);
	return Plugin_Handled;
}
#endif

Action CommandListener(int client, const char[] command, int args)
{
	if( args > 0 )
	{
		char buffer[6];
		GetCmdArg(1, buffer, sizeof(buffer));

		if( strcmp(buffer, "ammo") == 0 )
		{
			RequestFrame(OnFrameEquip, GetClientUserId(client));
		}
	}

	return Plugin_Continue;
}

void OnFrameEquip(int client)
{
	client = GetClientOfUserId(client);
	if( client )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if( weapon != -1 )
		{
			g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon);
			if( g_iAmmoBugFix[weapon] < 0 ) g_iAmmoBugFix[weapon] = 0;
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnMapStart()
{
	g_bMapStarted = true;

	// Get weapons max clip size, does not support any servers that dynamically change during gameplay.
	delete g_hClipSize;
	g_hClipSize = new StringMap();

	int index, entity;
	while( index < sizeof(g_sWeapons) - 1 )
	{
		entity = CreateEntityByName(g_sWeapons[index]);
		DispatchSpawn(entity);

		g_hClipSize.SetValue(g_sWeapons[index], GetEntProp(entity, Prop_Send, "m_iClip1"));
		RemoveEdict(entity);
		index++;
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetVars();
}

void ResetVars()
{
	for( int i = 1; i < 2048; i++ )
	{
		g_iAmmoCount[i][0] = 0;
		g_iAmmoCount[i][1] = 0;
		g_iAmmoCount[i][2] = 0;
		g_iAmmoCount[i][3] = 0;
	}
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarGuns = g_hCvarGuns.IntValue;
	g_iCvarHint = g_hCvarHint.IntValue;
	g_iCvarReload = g_hCvarReload.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		#if DEBUG_PLUGIN
		HookEvent("upgrade_pack_added",		upgrade_pack_added);
		#endif
		HookEvent("map_transition",			Event_Transition);
		HookEvent("round_start",			Event_RoundStart);
		HookEvent("player_death",			Event_PlayerDeath);
		HookEvent("player_spawn",			Event_PlayerSpawn);
		HookEvent("weapon_fire",			Event_WeaponFire);
		HookEvent("receive_upgrade",		Event_GetUpgraded);
		HookEvent("ammo_pickup",			Event_AmmoPickup);

		// Late load
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
			{
				SDKHook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);

				int weapon = GetPlayerWeaponSlot(i, 0);
				if( weapon != -1 )
				{
					g_iLastWeapon[i] = EntIndexToEntRef(weapon);
					g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(i, weapon);
					g_iAmmoCount[weapon][TYPE_STOCK] = GetEntProp(weapon, Prop_Send, "m_iClip1");
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;

		#if DEBUG_PLUGIN
		UnhookEvent("upgrade_pack_added",	upgrade_pack_added);
		#endif
		UnhookEvent("map_transition",		Event_Transition);
		UnhookEvent("round_start",			Event_RoundStart);
		UnhookEvent("player_spawn",			Event_PlayerSpawn);
		UnhookEvent("player_death",			Event_PlayerDeath);
		UnhookEvent("weapon_fire",			Event_WeaponFire);
		UnhookEvent("receive_upgrade",		Event_GetUpgraded);
		UnhookEvent("ammo_pickup",			Event_AmmoPickup);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) )
			{
				SDKUnhook(i, SDKHook_WeaponEquipPost, OnWeaponEquip);
			}
		}

		ResetVars();
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	if( g_bMapStarted == false )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;

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

	if( iCvarModesTog != 0 )
	{
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
// Re-create upgrade_pack for testing:
#if DEBUG_PLUGIN
void upgrade_pack_added(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !IsFakeClient(client) )
	{
		int entity = event.GetInt("upgradeid");

		char class[32];
		float vOrigin[3], vAngles[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
		GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
		GetEdictClassname(entity, class, sizeof(class));
		RemoveEntity(entity);
		
		if( strcmp(class, "upgrade_ammo_incendiary") == 0 )
			entity = CreateEntityByName("upgrade_ammo_incendiary");
		else if( strcmp(class, "upgrade_ammo_explosive") == 0 )
			entity = CreateEntityByName("upgrade_ammo_explosive");
		
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		DispatchSpawn(entity);
	}
}
#endif

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_bPlayerDied[i] = false;
	}
}

void Event_Transition(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iCurrentMode == 1 ) // Coop only
	{
		int weapon;

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsFakeClient(i) )
			{
				weapon = GetPlayerWeaponSlot(i, 0);
				if( weapon != -1 )
				{
					GetEdictClassname(weapon, g_sTransition[i], sizeof(g_sTransition[]));
					g_iTransition[i][0] = GetClientUserId(i);
					g_iTransition[i][1] = g_iAmmoCount[weapon][1];
					g_iTransition[i][2] = g_iAmmoCount[weapon][2];
					g_iTransition[i][3] = g_iAmmoCount[weapon][3];
				}
			}
		}
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if( client )
	{
		g_bPlayerDied[client] = true;
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if( client && !g_bPlayerDied[client] )
	{
		if( IsFakeClient(client) ) return;

		SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquip);

		g_fSwitched[client] = 0.0;
		g_iLastWeapon[client] = 0;

		// Spawned after map transition:
		if( g_iCurrentMode == 1 && g_sTransition[client][0] ) //&& g_hCvarSaveWeapon == null )
		{
			// "L4D2 coop save weapon" uses 1.0 timer, due to some late loading clients 5.0 seems better.
			CreateTimer(5.0, TimerDelayDone, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

Action TimerDelayDone(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		if( IsPlayerAlive(client) && GetClientTeam(client) == 2 )
		{
			OnClientSpawn(userid);
		}
	}

	return Plugin_Continue;
}

void OnClientSpawn(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && userid == g_iTransition[client][0] )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		if( weapon != -1 )
		{
			char sTemp[32];
			GetEdictClassname(weapon, sTemp, sizeof(sTemp));

			if( strcmp(g_sTransition[client], sTemp) == 0 )
			{
				g_iAmmoCount[weapon][0] = EntIndexToEntRef(weapon);
				g_iAmmoCount[weapon][TYPE_FIRES] = g_iTransition[client][TYPE_FIRES];
				g_iAmmoCount[weapon][TYPE_EXPLO] = g_iTransition[client][TYPE_EXPLO];
				g_iAmmoCount[weapon][TYPE_STOCK] = g_iTransition[client][TYPE_STOCK];
			}
		}
	}
}

// Compatibility for "Save Weapon" plugin modified by "HarryPotter".
public void L4D2_OnSaveWeaponHxGiveC(int client)
{
	client = GetClientOfUserId(client);
	OnClientSpawn(client);
}

// Main plugin logic stuff
void OnWeaponEquip(int client, int weapon)
{
	int main = GetPlayerWeaponSlot(client, 0);
	if( main != -1 && (g_iLastWeapon[client] == 0 || EntRefToEntIndex(g_iLastWeapon[client]) != main) )
	{
		g_iLastWeapon[client] = EntIndexToEntRef(main);
		RequestFrame(OnFrameEquip, GetClientUserId(client));
		g_iAmmoCount[weapon][TYPE_STOCK] = GetEntProp(weapon, Prop_Send, "m_iClip1");
	}
}

// Fix ammo bug
void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( client < 1 || IsFakeClient(client) ) return;

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	// Has upgraded ammo
	if( weapon != -1 && weapon == GetPlayerWeaponSlot(client, 0) )
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
		if( ammo )
		{
			// Using fire type, switch to explosive
			int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

			if( type & TYPE_FIRES ) type = TYPE_FIRES;
			else if( type & TYPE_EXPLO ) type = TYPE_EXPLO;
			else type = 0;

			if( type )
			{
				if( ammo == 1 )
				{
					ammo = GetMaxClip(weapon);

					if( GetOrSetPlayerAmmo(client, weapon) > ammo )
					{
						GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon] + ammo - GetEntProp(weapon, Prop_Send, "m_iClip1") + 1);
					} else {
						GetOrSetPlayerAmmo(client, weapon, g_iAmmoCount[weapon][TYPE_STOCK]);
					}

					g_iAmmoCount[weapon][type] = 0;
					GetEntProp(weapon, Prop_Send, "m_iClip1", g_iAmmoCount[weapon][TYPE_STOCK]);
				}
				else
				{
					g_iAmmoCount[weapon][type] = ammo - 1;
					GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
				}
			}
		}
		else
		{
			ammo = GetMaxClip(weapon);
			ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
			g_iAmmoCount[weapon][TYPE_STOCK] = GetEntProp(weapon, Prop_Send, "m_iClip1") - 1;

			if( ammo < 0 ) ammo = 0;
			g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon) - ammo - 1;
			if( g_iAmmoBugFix[weapon] < 0 ) g_iAmmoBugFix[weapon] = 0;

			if( GetEntProp(weapon, Prop_Send, "m_iClip1") == 1 && GetOrSetPlayerAmmo(client, weapon) == 0 )
			{
				if( g_iAmmoCount[weapon][TYPE_FIRES] )
				{
					SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", TYPE_FIRES);
					SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", g_iAmmoCount[weapon][TYPE_FIRES]);
					SetEntProp(weapon, Prop_Send, "m_iClip1", g_iAmmoCount[weapon][TYPE_FIRES]);
				}
				else if( g_iAmmoCount[weapon][TYPE_EXPLO] )
				{
					SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", TYPE_EXPLO);
					SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", g_iAmmoCount[weapon][TYPE_EXPLO]);
					SetEntProp(weapon, Prop_Send, "m_iClip1", g_iAmmoCount[weapon][TYPE_EXPLO]);
				}
			}
		}
	}
}

void Event_GetUpgraded(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) return;

	char sTemp[4];
	event.GetString("upgrade", sTemp, sizeof(sTemp));

	if( sTemp[0] == 'E' || sTemp[0] == 'I' )
	{
		int weapon = GetPlayerWeaponSlot(client, 0);
		int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

		if( type & TYPE_FIRES ) type = TYPE_FIRES;
		else if( type & TYPE_EXPLO ) type = TYPE_EXPLO;
		else type = 0;

		if( type )
		{
			// Hint
			if( g_iCvarHint )
			{
				static char sBuffer[256];

				if( g_bTranslation )
				{
					if( g_iCvarHint == 1 )
					{
						Format(sBuffer, sizeof(sBuffer), "\x04[\x01Switch Ammo\x04]\x01 %T", "About_Switch_Ammo", client);
						CPrintToChat(client, sBuffer);
					}
					else
					{
						Format(sBuffer, sizeof(sBuffer), "[Switch Ammo] %T", "About_Switch_Ammo", client);
						CPrintHintText(client, sBuffer);
					}
				}
				else
				{
					if( g_iCvarHint == 1 )
					{
						Format(sBuffer, sizeof(sBuffer), "\x04[\x01Switch Ammo\x04]\x01 Press \x04SHIFT \x01+ \x04RELOAD \x01to switch between upgraded and normal ammo.");
						PrintToChat(client, sBuffer);
					}
					else
					{
						Format(sBuffer, sizeof(sBuffer), "[Switch Ammo] Press SHIFT + RELOAD to switch between upgraded and normal ammo.");
						PrintHintText(client, sBuffer);
					}
				}
			}

			// Stuff
			int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");

			if( g_iAmmoCount[weapon][0] == 0 || EntRefToEntIndex(g_iAmmoCount[weapon][0]) != weapon )
			{
				g_iAmmoCount[weapon][0] = EntIndexToEntRef(weapon);
				g_iAmmoCount[weapon][1] = 0;
				g_iAmmoCount[weapon][2] = 0;
			}

			g_iAmmoCount[weapon][type] = ammo;

			GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
		}
	}
}

void Event_AmmoPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( IsFakeClient(client) ) return;

	int weapon = GetPlayerWeaponSlot(client, 0);
	if( weapon != -1 )
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");

		if( ammo )
		{
			g_iAmmoCount[weapon][TYPE_STOCK] = ammo;
			ammo = GetOrSetPlayerAmmo(client, weapon) - ammo;
			g_iAmmoBugFix[weapon] = ammo - (GetMaxClip(weapon) - GetEntProp(weapon, Prop_Send, "m_iClip1"));
		} else {
			g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon);
			if( g_iAmmoBugFix[weapon] < 0 ) g_iAmmoBugFix[weapon] = 0;
			GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon]);
		}
	}
}



// ====================================================================================================
//					FUNCTION
// ====================================================================================================
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if( g_bCvarAllow && buttons & IN_SPEED && buttons & IN_RELOAD && GetGameTime() > g_fSwitched[client] )
	{
		g_fSwitched[client] = GetGameTime() + 0.5;

		// Validate Survivor
		if( IsPlayerAlive(client) && GetClientTeam(client) == 2 && !IsFakeClient(client) )
		{
			weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			if( weapon > 0 )
			{
				// Validate primary weapon
				if( weapon == GetPlayerWeaponSlot(client, 0) && GetEntPropFloat(weapon, Prop_Data, "m_flNextPrimaryAttack") < GetGameTime() )
				{
					// Validate not reloading, or allowed
					if( GetEntProp(weapon, Prop_Send, "m_bInReload") == 0 )
					{
						if( g_iCvarGuns != 3 )
						{
							static char classname[32];
							GetEdictClassname(weapon, classname, sizeof(classname));

							// Ignore these classes
							if( g_iCvarGuns == 1 && strcmp(classname[7], "rifle_m60") == 0 ) return Plugin_Continue;
							if( g_iCvarGuns == 2 && strcmp(classname[7], "grenade_launcher") == 0 ) return Plugin_Continue;
						}

						int ammo = GetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded");
						int type = GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");

						// Has upgraded ammo
						if( ammo )
						{
							// Using fire type, switch to explosive
							if( type & TYPE_FIRES )
								g_iAmmoCount[weapon][TYPE_FIRES] = ammo;
							else
								g_iAmmoCount[weapon][TYPE_EXPLO] = ammo;

							if( type & TYPE_FIRES && g_iAmmoCount[weapon][TYPE_EXPLO] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_EXPLO];

								type &= ~TYPE_FIRES;
								type |= TYPE_EXPLO;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);

								ReloadWeapon(client, weapon);
							}
							// No explosive, reset to stock
							else
							{
								// Verify has stock ammo to switch to
								if( g_iAmmoCount[weapon][TYPE_STOCK] || g_iAmmoBugFix[weapon] - ammo > 0 )
								{
									// Ammo bug fix
									ammo = GetMaxClip(weapon);
									ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
									if( ammo < 0 ) ammo = 0;

									GetOrSetPlayerAmmo(client, weapon, g_iAmmoBugFix[weapon] + ammo);

									if( g_iAmmoBugFix[weapon] == 0 )
									{
										SetEntProp(weapon, Prop_Send, "m_iClip1", g_iAmmoCount[weapon][TYPE_STOCK]);
									}

									// Reset to stock ammo
									type &= ~TYPE_FIRES;
									type &= ~TYPE_EXPLO;
									SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
									SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 0);

									ReloadWeapon(client, weapon);
								}
							}
						}
						// No upgraded ammo, switch to one
						else
						{
							// Ammo bug fix
							ammo = GetMaxClip(weapon);
							ammo = ammo - GetEntProp(weapon, Prop_Send, "m_iClip1");
							g_iAmmoCount[weapon][TYPE_STOCK] = GetEntProp(weapon, Prop_Send, "m_iClip1");
	
							if( ammo < 0 ) ammo = 0;
							g_iAmmoBugFix[weapon] = GetOrSetPlayerAmmo(client, weapon) - ammo;
							if( g_iAmmoBugFix[weapon] < 0 ) g_iAmmoBugFix[weapon] = 0;
		
							// Set upgrade ammo
							if( g_iAmmoCount[weapon][TYPE_FIRES] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_FIRES];
								type |= TYPE_FIRES;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);
								SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);

								ReloadWeapon(client, weapon);
							}
							else if( g_iAmmoCount[weapon][TYPE_EXPLO] )
							{
								ammo = g_iAmmoCount[weapon][TYPE_EXPLO];
								type |= TYPE_EXPLO;
								SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", type);
								SetEntProp(weapon, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", ammo);
								SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);

								ReloadWeapon(client, weapon);
							}
						}
					}
				}
			}
		}
	}

	return Plugin_Continue;
}

void ReloadWeapon(int client, int weapon)
{
	if( g_iCvarReload )
	{
		// Save ammo
		int ammo;
		int reserve = GetOrSetPlayerAmmo(client, weapon);

		// Shotgun ammo bug fix
		static char classname[32];
		GetEdictClassname(weapon, classname, sizeof(classname));
		if( strcmp(classname[7], "pumpshotgun") == 0 || strcmp(classname[7], "shotgun_chrome") == 0 || strcmp(classname[7], "autoshotgun") == 0 || strcmp(classname[7], "shotgun_spas") == 0 )
		{
			if( g_iCvarReload == 2 )
			{
				reserve = reserve + GetEntProp(weapon, Prop_Send, "m_iClip1");
				ammo = 0;

				DataPack dPack = new DataPack();
				dPack.WriteCell(GetClientUserId(client));
				dPack.WriteCell(EntIndexToEntRef(weapon));
				CreateTimer(0.1, TimerReload, dPack, TIMER_REPEAT);
			}
			else
			{
				return;
			}
		}
		else
		{
			ammo = GetEntProp(weapon, Prop_Send, "m_iClip1");
		}

		// Set for reload
		GetOrSetPlayerAmmo(client, weapon, 1);
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);

		// Reload
		SDKCall(g_hSDK_Call_Reload, weapon);

		// Restore next frame
		DataPack dPack = new DataPack();
		dPack.WriteCell(GetClientUserId(client));
		dPack.WriteCell(EntIndexToEntRef(weapon));
		dPack.WriteCell(ammo);
		dPack.WriteCell(reserve);
		RequestFrame(OnFrameReload, dPack);

		// Restore ammo
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);
		GetOrSetPlayerAmmo(client, weapon, reserve);
	}
}

// Have to delay by 1 frame or the reserve ammo never resets
Action TimerReload(Handle timer, DataPack dPack)
{
	dPack.Reset();
	int client = dPack.ReadCell();
	int weapon = dPack.ReadCell();

	// Validate weapon
	weapon = EntRefToEntIndex(weapon);
	if( weapon != INVALID_ENT_REFERENCE )
	{
		// Validate client and active weapon is one to reload
		client = GetClientOfUserId(client);
		if( client && IsClientInGame(client) && GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon )
		{
			// If still reloading continue waiting
			if( GetEntProp(weapon, Prop_Send, "m_bInReload") == 1 )
			{
				return Plugin_Continue;
			}
			else
			{
				SDKCall(g_hSDK_Call_Reload, weapon);
			}
		}
	}

	delete dPack;
	return Plugin_Stop;
}

void OnFrameReload(DataPack dPack)
{
	dPack.Reset();

	int client = dPack.ReadCell();
	int weapon = dPack.ReadCell();

	weapon = EntRefToEntIndex(weapon);
	if( weapon != INVALID_ENT_REFERENCE )
	{
		// Set clip ammo
		int ammo = dPack.ReadCell();
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo);

		// Set reserve ammo
		client = GetClientOfUserId(client);
		if( client && IsClientInGame(client) )
		{
			ammo = dPack.ReadCell();
			GetOrSetPlayerAmmo(client, weapon, ammo);
		}
	}

	delete dPack;
}

int GetMaxClip(int weapon)
{
	int ammo;
	static char sClass[32];
	GetEdictClassname(weapon, sClass, sizeof(sClass));
	g_hClipSize.GetValue(sClass, ammo);
	return ammo;
}

int GetOrSetPlayerAmmo(int client, int iWeapon, int iAmmo = -1)
{
	int offset = GetEntData(iWeapon, g_iPrimaryAmmoType) * 4; // Thanks to "Root" or whoever for this method of not hard-coding offsets: https://github.com/zadroot/AmmoManager/blob/master/scripting/ammo_manager.sp

	// Get/Set
	if( offset )
	{
		if( iAmmo != -1 ) SetEntData(client, g_iOffsetAmmo + offset, iAmmo);
		else return GetEntData(client, g_iOffsetAmmo + offset);
	}

	return 0;
}



// ====================================================================================================
//					COLORS.INC REPLACEMENT
// ====================================================================================================
void CPrintToChat(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"\x01");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"\x03");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"\x03");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"\x04");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"\x04"); // Actually orange in L4D2, but replicating colors.inc behaviour
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"\x05");
	PrintToChat(client, buffer);
}

void CPrintHintText(int client, char[] message, any ...)
{
	static char buffer[256];
	VFormat(buffer, sizeof(buffer), message, 3);

	ReplaceString(buffer, sizeof(buffer), "{default}",		"");
	ReplaceString(buffer, sizeof(buffer), "{white}",		"");
	ReplaceString(buffer, sizeof(buffer), "{cyan}",			"");
	ReplaceString(buffer, sizeof(buffer), "{lightgreen}",	"");
	ReplaceString(buffer, sizeof(buffer), "{orange}",		"");
	ReplaceString(buffer, sizeof(buffer), "{green}",		"");
	ReplaceString(buffer, sizeof(buffer), "{olive}",		"");
	PrintHintText(client, buffer);
}