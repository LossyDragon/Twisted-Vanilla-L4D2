#include <sourcemod>
#include <sdktools>

#define VERSION "1.4"

ConVar hClearMedkits, hReplacePills, hSafeRoomKits, hClearDefibs, hClearAmmo, hClearAmmopile, hClearLaser, hClearPills, hClearAdrenaline, hClearMelee, hClearPistol, hClearMagnum, hClearM60, hClearChainSaws, hClearWhump, hLimitThrows, hClearFire, hClearPipe, hClearBile, g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
int iClearMedkits, iReplacePills, iSafeRoomKits, iClearDefibs, iClearAmmo, iClearAmmopile, iClearLaser, iClearPills, iClearAdrenaline, iClearMelee, iClearPistol, iClearMagnum, iClearM60, iClearChainSaws, iClearWhump, iLimitThrows, iClearFire, iClearPipe, iClearBile;
float Saferoom[3];

public Plugin:myinfo = 
{
	name = "Crow's Annoying Item Remover",
	author = "Crow's Nest HarbingTarbl",
	description = "Removes annoying items :3",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	hClearMedkits		=		CreateConVar(	"annoy_medkits",			"1",			"Remove medkits", CVAR_FLAGS );
	hClearAmmo			=		CreateConVar(	"annoy_ammo",				"1",			"Remove ammo upgrades", CVAR_FLAGS );
	hClearAmmopile		=		CreateConVar(	"annoy_ammopile",			"1",			"Remove ammo piles", CVAR_FLAGS );
	hClearLaser			=		CreateConVar(	"annoy_laser",				"1",			"Remove laser sights", CVAR_FLAGS );
	hClearPills			=		CreateConVar(	"annoy_pills",				"1",			"Remove pain pills", CVAR_FLAGS );
	hClearAdrenaline	=		CreateConVar(	"annoy_adrenaline",			"1",			"Remove adrenaline", CVAR_FLAGS );
	hClearMelee			=		CreateConVar(	"annoy_melee",				"1",			"Remove melees", CVAR_FLAGS );
	hClearPistol		=		CreateConVar(	"annoy_pistols",			"1",			"Remove pistols", CVAR_FLAGS );
	hClearMagnum		=		CreateConVar(	"annoy_magnum",				"1",			"Remove magnums", CVAR_FLAGS );
	hClearM60			=		CreateConVar(	"annoy_m60",				"1",			"Remove m60", CVAR_FLAGS );
	hClearChainSaws		=		CreateConVar(	"annoy_chainsaw",			"1",			"Remove Chainsaws", CVAR_FLAGS );
	hSafeRoomKits		=		CreateConVar(	"annoy_saferoom",			"1",			"Keeps safe room first aid kits", CVAR_FLAGS );
	hClearDefibs		=		CreateConVar(	"annoy_defibs",				"1",			"Remove defibs", CVAR_FLAGS );
	hClearWhump			=		CreateConVar(	"annoy_launcher",			"1",			"Remove grenade launchers", CVAR_FLAGS );
	hReplacePills		=		CreateConVar(	"annoy_pill_replace",		"1",			"Replaces removed medkits with pills(Requires annoy_medkits 1)", CVAR_FLAGS );
	hLimitThrows		=		CreateConVar(	"annoy_limit_throws",		"0",			"Enable the limiting of throwable items to director spawned only", CVAR_FLAGS );
	hClearFire			=		CreateConVar(	"annoy_limit_moly",			"1",			"Limit Moly's to director spawned only", CVAR_FLAGS );
	hClearBile			=		CreateConVar(	"annoy_limit_bile",			"1",			"Limit Bile Bombs to director spawned only", CVAR_FLAGS );
	hClearPipe			=		CreateConVar(	"annoy_limit_pipe",			"1",			"Limit Pips to director spawned only", CVAR_FLAGS );
	g_hCvarAllow		=		CreateConVar(	"annoy_enable",				"1",			"Enable or disable Crow's Annoying Item Remover", CVAR_FLAGS );
	g_hCvarModes		=		CreateConVar(	"annoy_limit_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff		=		CreateConVar(	"annoy_limit_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog		=		CreateConVar(	"annoy_limit_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	CreateConVar							(	"annoy",					"VERSION",		"Crow's Annoying Item Remover Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	AutoExecConfig							(	true, 						"CrowAnnoyingItemRemover" );
	
	hClearMedkits.AddChangeHook(ConVarChanged_Cvars);
	hClearAmmo.AddChangeHook(ConVarChanged_Cvars);
	hClearAmmopile.AddChangeHook(ConVarChanged_Cvars);
	hClearLaser.AddChangeHook(ConVarChanged_Cvars);
	hClearPills.AddChangeHook(ConVarChanged_Cvars);
	hClearAdrenaline.AddChangeHook(ConVarChanged_Cvars);
	hClearMelee.AddChangeHook(ConVarChanged_Cvars);
	hClearPistol.AddChangeHook(ConVarChanged_Cvars);
	hClearMagnum.AddChangeHook(ConVarChanged_Cvars);
	hClearM60.AddChangeHook(ConVarChanged_Cvars);
	hClearChainSaws.AddChangeHook(ConVarChanged_Cvars);
	hSafeRoomKits.AddChangeHook(ConVarChanged_Cvars);
	hClearDefibs.AddChangeHook(ConVarChanged_Cvars);
	hClearWhump.AddChangeHook(ConVarChanged_Cvars);
	hReplacePills.AddChangeHook(ConVarChanged_Cvars);
	hLimitThrows.AddChangeHook(ConVarChanged_Cvars);
	hClearFire.AddChangeHook(ConVarChanged_Cvars);
	hClearBile.AddChangeHook(ConVarChanged_Cvars);
	hClearPipe.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
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
	iClearMedkits		= hClearMedkits.BoolValue;
	iReplacePills		= hReplacePills.BoolValue;
	iSafeRoomKits		= hSafeRoomKits.BoolValue;
	iClearDefibs		= hClearDefibs.BoolValue;
	iClearAmmo			= hClearAmmo.BoolValue;
	iClearAmmopile		= hClearAmmopile.BoolValue;
	iClearLaser			= hClearLaser.BoolValue;
	iClearPills			= hClearPills.BoolValue;
	iClearAdrenaline	= hClearAdrenaline.BoolValue;
	iClearMelee			= hClearMelee.BoolValue;
	iClearPistol		= hClearPistol.BoolValue;
	iClearMagnum		= hClearMagnum.BoolValue;
	iClearM60			= hClearM60.BoolValue;
	iClearChainSaws		= hClearChainSaws.BoolValue;
	iClearWhump			= hClearWhump.BoolValue;
	iLimitThrows		= hLimitThrows.BoolValue;
	iClearFire			= hClearFire.BoolValue;
	iClearPipe			= hClearBile.BoolValue;
	iClearBile			= hClearPipe.BoolValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
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

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.5, RemoveItems);
}

public Action:RemoveItems(Handle:timer)
{	
	if (GetConVarInt(g_hCvarAllow) == 1)
	{
		new EntCount = GetEntityCount();
		new String:EdictName[128];
		
		if (GetConVarInt(hSafeRoomKits) == 1)
		{
			new String:Map[32];
			GetCurrentMap(Map, 32);
			if (StrContains(Map, "c1m1") != -1)
			{
				Saferoom[0] = 430.946594;
				Saferoom[1] = 5744.847168;
				Saferoom[2] = 2882.982178;
			}
			else if (StrContains(Map, "c1m2") != -1)
			{
				Saferoom[0] = 2397.798584;
				Saferoom[1] = 4966.103027;
				Saferoom[2] = 478.224670;
			}
			else if (StrContains(Map, "c1m3") != -1)
			{
				Saferoom[0] = 6532.310059;
				Saferoom[1] = -1473.890015;
				Saferoom[2] = 59.001575;
			}
			else if (StrContains(Map, "c1m4") != -1)
			{
				Saferoom[0] = -2201.226807;
				Saferoom[1] = -4692.452637;
				Saferoom[2] = 571.226318;
			}
			else if (StrContains(Map, "c2m1") != -1)
			{
				Saferoom[0] = 10671.254883;
				Saferoom[1] = 7857.397461;
				Saferoom[2] = -540.156860;
			}
			else if (StrContains(Map, "c2m2") != -1)
			{
				Saferoom[0] = 1724.968750;
				Saferoom[1] = 2889.561523;
				Saferoom[2] = 39.232277;
			}
			else if (StrContains(Map, "c2m3") != -1)
			{
				Saferoom[0] = 4106.663574;
				Saferoom[1] = 2159.387451;
				Saferoom[2] = -28.767725;
			}
			else if (StrContains(Map, "c2m4") != -1)
			{
				Saferoom[0] = 2925.554199;
				Saferoom[1] = 3855.020020;
				Saferoom[2] = -187.968750;
			}
			else if (StrContains(Map, "c2m5") != -1)
			{
				Saferoom[0] = -653.677185;
				Saferoom[1] = 2220.736572;
				Saferoom[2] = -220.998734;
			}
			else if (StrContains(Map, "c3m1") != -1)
			{
				Saferoom[0] = -12465.958984;
				Saferoom[1] = 10524.093750;
				Saferoom[2] = 275.434265;
			}
			else if (StrContains(Map, "c3m2") != -1)
			{
				Saferoom[0] = -8213.431641;
				Saferoom[1] = 7622.576172;
				Saferoom[2] = 44.810654;
			}
			else if (StrContains(Map, "c3m3") != -1)
			{
				Saferoom[0] = -5697.970703;
				Saferoom[1] = 1999.031250;
				Saferoom[2] = 171.226288;
			}
			else if (StrContains(Map, "c3m4") != -1)
			{
				Saferoom[0] = -5019.223145;
				Saferoom[1] = -1568.031250;
				Saferoom[2] = -64.564751;
			}
			else if (StrContains(Map, "c4m1") != -1)
			{
				Saferoom[0] = -6012.471680;
				Saferoom[1] = 7385.575684;
				Saferoom[2] = 148.909729;
			}
			else if (StrContains(Map, "c4m2") != -1)
			{
				Saferoom[0] = 3781.565186;
				Saferoom[1] = -1668.598145;
				Saferoom[2] = 262.723663;
			}
			else if (StrContains(Map, "c4m3") != -1)
			{
				Saferoom[0] = -1804.286743;
				Saferoom[1] = -13777.250977;
				Saferoom[2] = 130.031250;
			}
			else if (StrContains(Map, "c4m4") != -1)
			{
				Saferoom[0] = 4039.968750;
				Saferoom[1] = -1551.401123;
				Saferoom[2] = 262.473663;
			}
			else if (StrContains(Map, "c4m5") != -1)
			{
				Saferoom[0] = -3383.520996;
				Saferoom[1] = 7791.185059;
				Saferoom[2] = 120.031250;
			}
			else if (StrContains(Map, "c5m1") != -1)
			{
				Saferoom[0] = 735.921692;
				Saferoom[1] = 729.955750;
				Saferoom[2] = -481.968750;
			}
			else if (StrContains(Map, "c5m2") != -1)
			{
				Saferoom[0] = -4335.529785;
				Saferoom[1] = -1127.393677;
				Saferoom[2] = -343.968750;
			}
			else if (StrContains(Map, "c5m3") != -1)
			{
				Saferoom[0] = 6289.354492;
				Saferoom[1] = 8212.956055;
				Saferoom[2] = 35.232281;
			}
			else if (StrContains(Map, "c5m4") != -1)
			{
				Saferoom[0] = -3058.571045;
				Saferoom[1] = 4778.432617;
				Saferoom[2] = 103.226173;
			}
			else if (StrContains(Map, "c5m5") != -1)
			{
				Saferoom[0] = -11924.932617;
				Saferoom[1] = 5981.550293;
				Saferoom[2] = 547.226318;
			}
		}
		for (new i = 0; i <= EntCount; i++)
		{
			if (IsValidEntity(i))
			{
				GetEdictClassname(i, EdictName, sizeof(EdictName));
				if (GetConVarInt(hClearMedkits) == 1)
				{
					if (StrContains(EdictName, "weapon_first_aid_kit", false) != -1)
					{
						new Float:Location[3];
						GetEntPropVector(i, Prop_Send, "m_vecOrigin", Location);
						if ( (GetConVarInt(hSafeRoomKits) == 0) || (GetVectorDistance(Location, Saferoom, false) > 200))
						{
							if (GetConVarInt(hReplacePills) == 1)
							{
								new index = CreateEntityByName("weapon_pain_pills_spawn");
								if ( index != -1)
								{
									new Float:Angle[3];
									GetEntPropVector(i, Prop_Send, "m_angRotation", Angle);
									TeleportEntity(index, Location, Angle, NULL_VECTOR);
									DispatchSpawn(index);
								}
							}
							AcceptEntityInput(i, "Kill");
						}
						continue;
					}
				}
				if (GetConVarInt(hClearDefibs) == 1)
				{
					if (StrContains(EdictName, "weapon_defibrillator_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearLaser) == 1)
				{
					if (StrContains(EdictName, "upgrade_laser_sight", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearPills) == 1)
				{
					if (StrContains(EdictName, "weapon_pain_pills_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearAdrenaline) == 1)
				{
					if (StrContains(EdictName, "weapon_adrenaline_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearMelee) == 1)
				{
					if (StrContains(EdictName, "weapon_melee_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearPistol) == 1)
				{
					if (StrContains(EdictName, "weapon_pistol_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearMagnum) == 1)
				{
					if (StrContains(EdictName, "weapon_pistol_magnum_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearM60) == 1)
				{
					if (StrContains(EdictName, "weapon_rifle_m60_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearAmmo) == 1)
				{
					if (StrContains(EdictName, "weapon_upgradepack_explosive_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearAmmopile) == 1)
				{
					if (StrContains(EdictName, "weapon_ammo", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearAmmo) == 1)
				{
					if (StrContains(EdictName, "weapon_upgradepack_incendiary_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearChainSaws) == 1)
				{
					if (StrContains(EdictName, "weapon_chainsaw_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hClearWhump) == 1)
				{
					if (StrContains(EdictName, "weapon_grenade_launcher_spawn", false) != -1)
					{
						AcceptEntityInput(i, "Kill");
						continue;
					}
				}
				if (GetConVarInt(hLimitThrows) == 1)
				{
					if (GetConVarInt(hClearPipe) == 1)
					{
						if (strcmp(EdictName, "weapon_pipe_bomb_spawn", false) == 0)
						{
							AcceptEntityInput(i, "Kill");
							continue;
						}
					}
					if(GetConVarInt(hClearFire) == 1)
					{
						if (strcmp(EdictName, "weapon_molotov_spawn", false) == 0)
						{
							AcceptEntityInput(i, "Kill");
							continue;
						}
					}
					if(GetConVarInt(hClearBile) == 1)
					{
						if (strcmp(EdictName, "weapon_vomitjar_spawn") == 0)
						{
							AcceptEntityInput(i, "Kill");
							continue;
						}
					}
				}
			}
		}
	}
}