/*
*	Damaged Grenades Explode
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



#define PLUGIN_VERSION 		"1.7"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Damaged Grenades Explode
*	Author	:	SilverShot (idea by backwards)
*	Descrp	:	Detonates grenades on the ground when damaged: shot, or something nearby explodes or ignites them.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=334500
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (27-Jan-2022)
	- Fixed copy paste mistake from last update sometimes throwing errors.

1.6 (26-Jan-2022)
	- Fixed spawners detonating when no grenades are visible. Thanks to "Shao" for reporting.

1.5 (23-Oct-2021)
	- Fixed error from invalid clients.

1.4 (07-Oct-2021)
	- Fixed not ignoring Boomer explosions. Thanks to "swiftswing1" for reporting.

1.3 (07-Oct-2021)
	- Changed the Boomer detection method to allow Pipe Bombs to explode nearby grenades.
	- Fixed some errors when attacker was invalid. Thanks to "swiftswing1" for reporting.

1.2 (07-Oct-2021)
	- Fixed invalid entity errors. Thanks to "swiftswing1" for reporting.

1.1 (06-Oct-2021)
	- Added cvar "l4d_explode_grenades_boomer" to control if Boomer explosions can explode grenades. Requested by "Shao".
	- Consolidated some code.

1.0 (29-Sep-2021)
	- Initial release.
	- Requires Left4DHooks 1.58 or newer.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define CVAR_FLAGS			FCVAR_NOTIFY

#define	MODEL_GASCAN		"models/props_junk/gascan001a.mdl"
#define MODEL_PROPANE		"models/props_junk/propanecanister001a.mdl"

ConVar g_hCvarAllow, g_hCvarBoom, g_hCvarSpawn, g_hCvarTime, g_hCvarType, g_hCvarTypes, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
bool g_bCvarAllow, g_bLeft4Dead2, g_bMapStarted, g_bCvarBoom, g_bCvarSpawn;
float g_fCvarTime;
int g_iCvarType, g_iCvarTypes;

enum
{
	TYPE_MOLO = 1,
	TYPE_PIPE,
	TYPE_VOMI
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Damage Explodes Grenades",
	author = "SilverShot (idea by backwards)",
	description = "Detonates grenades on the ground when damaged: shot, or something nearby explodes or ignites them.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334500"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =			CreateConVar(	"l4d_explode_grenades_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =			CreateConVar(	"l4d_explode_grenades_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =		CreateConVar(	"l4d_explode_grenades_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =		CreateConVar(	"l4d_explode_grenades_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarBoom =			CreateConVar(	"l4d_explode_grenades_boomer",			"0",			"0=Off. 1=Boomer explosions can also explode grenades.", CVAR_FLAGS );
	g_hCvarSpawn =			CreateConVar(	"l4d_explode_grenades_spawners",		"1",			"0=Off. 1=On. Should _spawn grenades (those which can have multiple grenades in 1 spawn) be allowed to ignite or explode.", CVAR_FLAGS );
	g_hCvarTime =			CreateConVar(	"l4d_explode_grenades_time",			"5.0",			"After how many seconds does an ignited grenade detonate.", CVAR_FLAGS );
	g_hCvarType =			CreateConVar(	"l4d_explode_grenades_type",			"7",			"Which types of grenades can ignite and then detonate. 1=Molotovs, 2=PipeBombs, 4=Vomit Jars. 7=All. Add numbers together.", CVAR_FLAGS );
	g_hCvarTypes =			CreateConVar(	"l4d_explode_grenades_types",			"7",			"Which types of grenades can take damage and detonate. 1=Molotovs, 2=PipeBombs, 4=Vomit Jars. 7=All. Add numbers together.", CVAR_FLAGS );
	CreateConVar(							"l4d_explode_grenades_version",			PLUGIN_VERSION,	"Damaged Grenades Explode plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,					"l4d_explode_grenades");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarBoom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawn.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTime.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarType.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_fire", CmdFire, ADMFLAG_ROOT, "Ignites the aimed entity. For testing");
}

public void OnMapStart()
{
	g_bMapStarted = true;
	PrecacheModel(MODEL_GASCAN);
	PrecacheModel(MODEL_PROPANE);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
}

public Action CmdFire(int client, int args)
{
	int entity = GetClientAimTarget(client, false);
	if( entity > 0 )
	{
		IgniteEntity(entity, 5.0);
	}

	return Plugin_Handled;
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
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

void GetCvars()
{
	g_bCvarBoom = g_hCvarBoom.BoolValue;
	g_bCvarSpawn = g_hCvarSpawn.BoolValue;
	g_fCvarTime = g_hCvarTime.FloatValue;
	g_iCvarType = g_hCvarType.IntValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;

		// Late load/enable - Hook entities
		int entity = -1;

		if( g_iCvarType & TYPE_MOLO || g_iCvarTypes & TYPE_MOLO )
		{
			entity = -1;
			while( (entity = FindEntityByClassname(entity, "weapon_molotov")) != INVALID_ENT_REFERENCE )
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageM);
			}

			if( g_bCvarSpawn )
			{
				entity = -1;
				while( (entity = FindEntityByClassname(entity, "weapon_molotov_spawn")) != INVALID_ENT_REFERENCE )
				{
					SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageM_Spawn);
					SetEntProp(entity, Prop_Data, "m_takedamage", 1);
				}
			}
		}

		if( g_iCvarType & TYPE_PIPE || g_iCvarTypes & TYPE_PIPE )
		{
			entity = -1;
			while( (entity = FindEntityByClassname(entity, "weapon_pipe_bomb")) != INVALID_ENT_REFERENCE )
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageP);
			}

			if( g_bCvarSpawn )
			{
				entity = -1;
				while( (entity = FindEntityByClassname(entity, "weapon_pipe_bomb_spawn")) != INVALID_ENT_REFERENCE )
				{
					SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageP_Spawn);
					SetEntProp(entity, Prop_Data, "m_takedamage", 1);
				}
			}
		}

		if( g_bLeft4Dead2 && (g_iCvarType & TYPE_VOMI || g_iCvarTypes & TYPE_VOMI) )
		{
			entity = -1;
			while( (entity = FindEntityByClassname(entity, "weapon_vomitjar")) != INVALID_ENT_REFERENCE )
			{
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageV);
			}

			if( g_bCvarSpawn )
			{
				entity = -1;
				while( (entity = FindEntityByClassname(entity, "weapon_vomitjar_spawn")) != INVALID_ENT_REFERENCE )
				{
					SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageV_Spawn);
					SetEntProp(entity, Prop_Data, "m_takedamage", 1);
				}
			}
		}
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		// Disable - Unhook entities
		int entity = -1;

		while( (entity = FindEntityByClassname(entity, "weapon_molotov")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageM);
		}

		entity = -1;
		while( (entity = FindEntityByClassname(entity, "weapon_molotov_spawn")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageM_Spawn);
			SetEntProp(entity, Prop_Data, "m_takedamage", 0);
		}

		entity = -1;
		while( (entity = FindEntityByClassname(entity, "weapon_pipe_bomb")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageP);
		}

		entity = -1;
		while( (entity = FindEntityByClassname(entity, "weapon_pipe_bomb_spawn")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageP_Spawn);
			SetEntProp(entity, Prop_Data, "m_takedamage", 0);
		}

		entity = -1;
		while( (entity = FindEntityByClassname(entity, "weapon_vomitjar")) != INVALID_ENT_REFERENCE )
		{
			SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageV);
		}

		entity = -1;
		while( (entity = FindEntityByClassname(entity, "weapon_vomitjar_spawn")) != INVALID_ENT_REFERENCE )
		{
			SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageV_Spawn);
			SetEntProp(entity, Prop_Data, "m_takedamage", 0);
		}

		g_bCvarAllow = false;
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
	if( iCvarModesTog != 0 )
	{
		g_iCurrentMode = L4D_GetGameModeType();

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



// ====================================================================================================
//					TAKE DAMAGE
// ====================================================================================================
public void OnEntityCreated(int entity, const char[] classname)
{
	// Types that can detonate
	if( (g_iCvarType & TYPE_MOLO || g_iCvarTypes & TYPE_MOLO) && strncmp(classname, "weapon_molotov", 14) == 0 )
	{
		if( g_bCvarSpawn || classname[14] == 0 )
		{
			if( classname[14] == 0 )
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageM);
			else
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageM_Spawn);

			if( g_bCvarSpawn && classname[14] != 0 )
				RequestFrame(OnFrameSpawn, EntIndexToEntRef(entity));
		}
	}

	else if( (g_iCvarType & TYPE_PIPE || g_iCvarTypes & TYPE_PIPE) && strncmp(classname, "weapon_pipe_bomb", 16) == 0 )
	{
		if( g_bCvarSpawn || classname[16] == 0 )
		{
			if( classname[16] == 0 )
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageP);
			else
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageP_Spawn);

			if( g_bCvarSpawn && classname[16] != 0 )
				RequestFrame(OnFrameSpawn, EntIndexToEntRef(entity));
		}
	}

	else if( g_bLeft4Dead2 && (g_iCvarType & TYPE_VOMI || g_iCvarTypes & TYPE_VOMI) && strncmp(classname, "weapon_vomitjar", 15) == 0 )
	{
		if( g_bCvarSpawn || classname[15] == 0 )
		{
			if( classname[15] == 0 )
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageV);
			else
				SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamageV_Spawn);

			if( g_bCvarSpawn && classname[15] != 0 )
				RequestFrame(OnFrameSpawn, EntIndexToEntRef(entity));
		}
	}
}

// Frame delay required to enable damage so OnTakeDamage picks up the grenades being shot
public void OnFrameSpawn(int entity)
{
	if( EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		SetEntProp(entity, Prop_Data, "m_takedamage", 1);
}

// Detonate on damage
public Action OnTakeDamageM(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_MOLO);
	return Plugin_Continue;
}

public Action OnTakeDamageP(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_PIPE);
	return Plugin_Continue;
}

public Action OnTakeDamageV(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_VOMI);
	return Plugin_Continue;
}

public Action OnTakeDamageM_Spawn(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int flag = GetEntProp(entity, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) || GetEntProp(entity, Prop_Data, "m_itemCount") >= 1 )
		OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_MOLO);
	return Plugin_Continue;
}

public Action OnTakeDamageP_Spawn(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int flag = GetEntProp(entity, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) || GetEntProp(entity, Prop_Data, "m_itemCount") >= 1 )
		OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_PIPE);
	return Plugin_Continue;
}

public Action OnTakeDamageV_Spawn(int entity, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	int flag = GetEntProp(entity, Prop_Data, "m_spawnflags");
	if( flag & (1<<3) || GetEntProp(entity, Prop_Data, "m_itemCount") >= 1 )
		OnTakeDamageFunction(entity, attacker, inflictor, damagetype, TYPE_VOMI);
	return Plugin_Continue;
}

void OnTakeDamageFunction(int entity, int attacker, int inflictor, int damagetype, int type)
{
	if( damagetype == DMG_CLUB ) return;

	if( damagetype & DMG_BURN && g_iCvarType & type )
	{
		// Not on fire, ignite
		if( GetEntPropEnt(entity, Prop_Send, "m_hEffectEntity") == -1 )
		{
			IgniteEntity(entity, g_fCvarTime);

			DataPack dPack;
			CreateDataTimer(g_fCvarTime, TimerDetonate, dPack, TIMER_FLAG_NO_MAPCHANGE);
			if( attacker > 0 )
			{
				dPack.WriteCell(attacker <= MaxClients ? GetClientUserId(attacker) : EntIndexToEntRef(attacker));
			} else {
				dPack.WriteCell(0);
			}

			dPack.WriteCell(EntIndexToEntRef(entity));
			dPack.WriteCell(type);
		}
	}
	else if( g_iCvarTypes & type )
	{
		// Ignore boomer explosions
		if( !g_bCvarBoom && inflictor > 0 && inflictor <= MaxClients && IsClientInGame(inflictor) && GetClientTeam(inflictor) == 3 && GetEntProp(inflictor, Prop_Send, "m_zombieClass") == 2 )
		{
			return;
		}

		// Unhook
		switch( type )
		{
			case TYPE_MOLO:		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageM);
			case TYPE_PIPE:		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageP);
			case TYPE_VOMI:		SDKUnhook(entity, SDKHook_OnTakeDamage, OnTakeDamageV);
		}

		// Explode
		float vPos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

		ExplodeEntity(attacker, entity, type, vPos);
	}
}

// Ignited detonation after X seconds
public Action TimerDetonate(Handle timer, DataPack dPack)
{
	// Data pack is deleted by the timer
	dPack.Reset();

	// Verify client
	int client = dPack.ReadCell();
	client = GetClientOfUserId(client);

	// Verify entity
	int entity = dPack.ReadCell();
	entity = EntRefToEntIndex(entity);
	if( entity == INVALID_ENT_REFERENCE ) return Plugin_Continue;

	// Read
	int type = dPack.ReadCell();

	float vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	ExplodeEntity(client, entity, type, vPos);

	return Plugin_Continue;
}



// ====================================================================================================
//					DETONATION
// ====================================================================================================
void ExplodeEntity(int client, int grenade, int type, float vPos[3])
{
	if( grenade > MaxClients )
		RemoveEntity(grenade);

	if( client < 0 || client > MaxClients ) client = 0;

	switch( type )
	{
		case TYPE_MOLO:
		{
			CreateExplosion(client, vPos, MODEL_GASCAN);
		}

		case TYPE_PIPE:
		{
			CreateExplosion(client, vPos, MODEL_PROPANE);
		}

		case TYPE_VOMI:
		{
			float vAng[3];
			vAng[2] = -150.0;

			int entity = L4D2_VomitJarPrj(client, vPos, vAng);
			SetEntPropVector(entity, Prop_Send, "m_vInitialVelocity", view_as<float>({0.0, 0.0, 0.0})); // Prevent conflict with "Prototype Grenades" plugin (which will ignore when this is 0,0,0).
		}
	}
}

public Action OnTransmitExplosive(int entity, int client)
{
	return Plugin_Handled;
}

void CreateExplosion(int client, float vPos[3], const char[] sModelName)
{
	int entity = CreateEntityByName("prop_physics");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "model", sModelName);

		// Hide from view (multiple hides still show the gascan for a split second sometimes, but works better than only using 1 of them)
		SDKHook(entity, SDKHook_SetTransmit, OnTransmitExplosive);

		// Hide from view
		int flags = GetEntityFlags(entity);
		SetEntityFlags(entity, flags|FL_EDICT_DONTSEND);

		// Make invisible
		SetEntityRenderMode(entity, RENDER_TRANSALPHAADD);
		SetEntityRenderColor(entity, 0, 0, 0, 0);

		// Prevent collision and movement
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1, 1);
		SetEntityMoveType(entity, MOVETYPE_NONE);

		// Teleport
		vPos[2] += 10.0;
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

		// Spawn
		DispatchSpawn(entity);

		// Set attacker
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetGameTime());

		// Explode
		AcceptEntityInput(entity, "Break");
	}
}