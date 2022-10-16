#pragma semicolon			1
#include <sourcemod>
#include <sdktools>

#define MODEL_FRANCIS		"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS			"models/survivors/survivor_manager.mdl"
#define MODEL_ZOEY			"models/survivors/survivor_teenangst.mdl"
#define MODEL_BILL			"models/survivors/survivor_namvet.mdl"
#define MODEL_NICK			"models/survivors/survivor_gambler.mdl"
#define MODEL_COACH			"models/survivors/survivor_coach.mdl"
#define MODEL_ROCHELLE		"models/survivors/survivor_producer.mdl"
#define MODEL_ELLIS			"models/survivors/survivor_mechanic.mdl"
#define MODEL_STRINGLENGTH	64
#define SURVIVOR_COUNT		8

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		0


public OnPluginStart()
{
	decl String:s_Game[12];
	GetGameFolderName(s_Game, sizeof(s_Game));
	if (!StrEqual(s_Game, "left4dead2"))
		SetFailState("supports Left 4 Dead 2 only!");
	
	HookEvent("item_pickup"/*"*/, EventItemPickup);
	
	InitArray();
}

public OnMapStart()
{
	PrecacheModel(MODEL_FRANCIS, true);
	PrecacheModel(MODEL_LOUIS, true);
	PrecacheModel(MODEL_ZOEY, true);
	PrecacheModel(MODEL_BILL, true);
	PrecacheModel(MODEL_NICK, true);
	PrecacheModel(MODEL_COACH, true);
	PrecacheModel(MODEL_ROCHELLE, true);
	PrecacheModel(MODEL_ELLIS, true);
}

enum data
{
	bool:isPresent,
		survivorChar,
	String:characterModel[MODEL_STRINGLENGTH]
}

static characterArray[SURVIVOR_COUNT][data];

InitArray()
{
	characterArray[0][survivorChar] = 0;
	strcopy(characterArray[0][characterModel], MODEL_STRINGLENGTH, MODEL_NICK);
	characterArray[1][survivorChar] = 1;
	strcopy(characterArray[1][characterModel], MODEL_STRINGLENGTH, MODEL_ROCHELLE);
	characterArray[2][survivorChar] = 2;
	strcopy(characterArray[2][characterModel], MODEL_STRINGLENGTH, MODEL_COACH);
	characterArray[3][survivorChar] = 3;
	strcopy(characterArray[3][characterModel], MODEL_STRINGLENGTH, MODEL_ELLIS);
	characterArray[4][survivorChar] = 4;
	strcopy(characterArray[4][characterModel], MODEL_STRINGLENGTH, MODEL_BILL);
	characterArray[5][survivorChar] = 5;
	strcopy(characterArray[5][characterModel], MODEL_STRINGLENGTH, MODEL_ZOEY);
	characterArray[6][survivorChar] = 6;
	strcopy(characterArray[6][characterModel], MODEL_STRINGLENGTH, MODEL_FRANCIS);
	characterArray[7][survivorChar] = 7;
	strcopy(characterArray[7][characterModel], MODEL_STRINGLENGTH, MODEL_LOUIS);
}

public Action:EventItemPickup(Handle:event, const String:eventname[], bool:b_DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CreateTimer(6.0, delayedCheck, client);
}

public Action:delayedCheck(Handle:timer, any:client)
{
	if (client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		CheckPresentModels();
	}
}

CheckPresentModels()
{
	DebugPrintToAll("AllSurvivors: Player spawned 6 seconds ago, checking all models now");
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		characterArray[i][isPresent] = false;
	}

	decl String:curModel[MODEL_STRINGLENGTH];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i)
		&& GetClientTeam(i) == 2)
		{
			GetClientModel(i, curModel, sizeof(curModel));
			new curSurvivor = getIntFromModel(curModel);
			DebugPrintToAll("AllSurvivors: Spots player %N wearing %i, model %s", i, curSurvivor, curModel);
			if (curSurvivor >= 0 && !characterArray[curSurvivor][isPresent])
			{
				characterArray[curSurvivor][isPresent] = true;
				DebugPrintToAll("AllSurvivors: player %N is an original!", i);
			}
			else if (curSurvivor >= 0 && characterArray[curSurvivor][isPresent] && areCharactersFree())
			{
				new setSurvivor = getFreeSurvivor();
				if (setSurvivor >= 0)
				{
					DebugPrintToAll("AllSurvivors: Thinks %N should rather be %i, setting model %s", i, setSurvivor, characterArray[setSurvivor][characterModel]);
					SetEntityModel(i, characterArray[setSurvivor][characterModel]);
					SetEntProp(i, Prop_Send, "m_survivorCharacter", characterArray[setSurvivor][survivorChar]);
					
					if(IsFakeClient(i))
					{
						switch( i )
						{
							case 0: SetClientName(i, "Nick");
							case 1: SetClientName(i, "Rochelle");
							case 2: SetClientName(i, "Coach");
							case 3: SetClientName(i, "Ellis");
							case 4: SetClientName(i, "Bill");
							case 5: SetClientName(i, "Zoey");
							case 6: SetClientName(i, "Francis");
							case 7: SetClientName(i, "Louis");
						}
					}
					ReEquipWeapons(i);
				}
			}
		}
	}
}

getIntFromModel(const String:model[])
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (StrEqual(model, characterArray[i][characterModel]))
		{
			return i;
		}
	}
	
	return -1;
}

getFreeSurvivor()
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (!characterArray[i][isPresent])
		{
			return i;
		}
	}
	return -1;
}

bool:areCharactersFree()
{
	for (new i = 0; i < SURVIVOR_COUNT; i++)
	{
		if (!characterArray[i][isPresent])
		{
			return true;
		}
	}
	return false;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[8SURV] %s", buffer);
	PrintToConsole(0, "[8SURV] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}

// *********************************************************************************
// Reequip weapons functions
// *********************************************************************************

enum()
{
	iClip = 0,
	iAmmo,
	iUpgrade,
	iUpAmmo,
};

// ------------------------------------------------------------------
// Save weapon details, remove weapon, create new weapons with exact same properties
// Needed otherwise there will be animation bugs after switching characters due to different weapon mount points
// ------------------------------------------------------------------
void ReEquipWeapons(int client)
{
	int i_Weapon = GetEntDataEnt2(client, FindSendPropInfo("CBasePlayer", "m_hActiveWeapon"));
	
	// Don't bother with the weapon fix if dead or unarmed
	if (!IsPlayerAlive(client) || !IsValidEdict(i_Weapon) || !IsValidEntity(i_Weapon))  return;

	int iSlot0 = GetPlayerWeaponSlot(client, 0);  	int iSlot1 = GetPlayerWeaponSlot(client, 1);	
	int iSlot2 = GetPlayerWeaponSlot(client, 2);  	int iSlot3 = GetPlayerWeaponSlot(client, 3);
	int iSlot4 = GetPlayerWeaponSlot(client, 4);  	

	
	char sWeapon[64];
	GetClientWeapon(client, sWeapon, sizeof(sWeapon));
	
	//  Protection against grenade duplication exploit (throwing grenade then quickly changing character)
	if (iSlot2 > 0 && strcmp(sWeapon, "weapon_vomitjar", true) && strcmp(sWeapon, "weapon_pipe_bomb", true) && strcmp(sWeapon, "weapon_molotov", true ))
	{
		GetEdictClassname(iSlot2, sWeapon, 64);
		DeletePlayerSlot(client, iSlot2);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot3 > 0)
	{
		GetEdictClassname(iSlot3, sWeapon, 64);
		DeletePlayerSlot(client, iSlot3);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot4 > 0)
	{
		GetEdictClassname(iSlot4, sWeapon, 64);
		DeletePlayerSlot(client, iSlot4);
		CheatCommand(client, "give", sWeapon, "");
	}
	if (iSlot1 > 0) ReEquipSlot1(client, iSlot1);
	if (iSlot0 > 0) ReEquipSlot0(client, iSlot0);
}

// --------------------------------------
// Extra work to save/load ammo details
// --------------------------------------	
void ReEquipSlot0(int client, int iSlot0)
{
	int iWeapon0[4];
	char sWeapon[64];
	
	GetEdictClassname(iSlot0, sWeapon, 64);
		
	iWeapon0[iClip] = GetEntProp(iSlot0, Prop_Send, "m_iClip1", 4);
	iWeapon0[iAmmo] = GetClientAmmo(client, sWeapon);
	iWeapon0[iUpgrade] = GetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", 4);
	iWeapon0[iUpAmmo]  = GetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", 4);
		
	DeletePlayerSlot(client, iSlot0);
	CheatCommand(client, "give", sWeapon, "");
		
	iSlot0 = GetPlayerWeaponSlot(client, 0);
	if (iSlot0 > 0)
	{
		SetEntProp(iSlot0, Prop_Send, "m_iClip1", iWeapon0[iClip], 4);
		SetClientAmmo(client, sWeapon, iWeapon0[iAmmo]);
		SetEntProp(iSlot0, Prop_Send, "m_upgradeBitVec", iWeapon0[iUpgrade], 4);
		SetEntProp(iSlot0, Prop_Send, "m_nUpgradedPrimaryAmmoLoaded", iWeapon0[iUpAmmo], 4);
	}			
}

// --------------------------------------
// Extra work to identify melee weapon, & save/load ammo details
// --------------------------------------
void ReEquipSlot1(int client, int iSlot1)
{
	char className[64];
	char modelName[64];
	
	char sWeapon[64]; 	sWeapon[0] = '\0'  ;
	int Ammo = -1;
	int iSlot = -1;
	
	GetEdictClassname(iSlot1, className, sizeof(className));
	
	// Try to find weapon name without models
	if 		(!strcmp(className, "weapon_melee", true))   GetEntPropString(iSlot1, Prop_Data, "m_strMapSetScriptName", sWeapon, 64);
	else if (strcmp(className, "weapon_pistol", true))   GetEdictClassname(iSlot1, sWeapon, 64);
	
	// IF model checking is required
	if (sWeapon[0] == '\0')
	{
		GetEntPropString(iSlot1, Prop_Data, "m_ModelName", modelName, sizeof(modelName));

		if 		(StrContains(modelName, "v_pistolA.mdl",         true) != -1)	sWeapon = "weapon_pistol";
		else if (StrContains(modelName, "v_dual_pistolA.mdl",    true) != -1)	sWeapon = "dual_pistol";
		else if (StrContains(modelName, "v_desert_eagle.mdl",    true) != -1)	sWeapon = "weapon_pistol_magnum";
		else if (StrContains(modelName, "v_bat.mdl",             true) != -1)	sWeapon = "baseball_bat";
		else if (StrContains(modelName, "v_cricket_bat.mdl",     true) != -1)	sWeapon = "cricket_bat";
		else if (StrContains(modelName, "v_crowbar.mdl",         true) != -1)	sWeapon = "crowbar";
		else if (StrContains(modelName, "v_fireaxe.mdl",         true) != -1)	sWeapon = "fireaxe";
		else if (StrContains(modelName, "v_katana.mdl",          true) != -1)	sWeapon = "katana";
		else if (StrContains(modelName, "v_golfclub.mdl",        true) != -1)	sWeapon = "golfclub";
		else if (StrContains(modelName, "v_machete.mdl",         true) != -1)	sWeapon = "machete";
		else if (StrContains(modelName, "v_tonfa.mdl",           true) != -1)	sWeapon = "tonfa";
		else if (StrContains(modelName, "v_electric_guitar.mdl", true) != -1)	sWeapon = "electric_guitar";
		else if (StrContains(modelName, "v_frying_pan.mdl",      true) != -1)	sWeapon = "frying_pan";
		else if (StrContains(modelName, "v_knife_t.mdl",         true) != -1)	sWeapon = "knife";
		else if (StrContains(modelName, "v_chainsaw.mdl",        true) != -1)	sWeapon = "weapon_chainsaw";
		else if (StrContains(modelName, "v_riotshield.mdl",      true) != -1)	sWeapon = "alliance_shield";
		else if (StrContains(modelName, "v_fubar.mdl",           true) != -1)	sWeapon = "fubar";
		else if (StrContains(modelName, "v_paintrain.mdl",       true) != -1)	sWeapon = "nail_board";
		else if (StrContains(modelName, "v_sledgehammer.mdl",    true) != -1)	sWeapon = "sledgehammer";
	}

	// IF Weapon properly identified, save then delete then reequip
	if (sWeapon[0] != '\0')
	{
		// IF Weapon uses ammo, save it
		if (!strcmp(sWeapon, "dual_pistol", true)   || !strcmp(sWeapon, "weapon_pistol", true)
		|| !strcmp(sWeapon, "weapon_pistol_magnum", true) || !strcmp(sWeapon, "weapon_chainsaw", true))
		{
			Ammo = GetEntProp(iSlot1, Prop_Send, "m_iClip1", 4);
		}	
	
		DeletePlayerSlot(client, iSlot1);
		
		// Reequip weapon (special code for dual pistols)
		if (!strcmp(sWeapon, "dual_pistol", true))
		{
			 CheatCommand(client, "give", "weapon_pistol", "");
			 CheatCommand(client, "give", "weapon_pistol", "");
		}
		else CheatCommand(client, "give", sWeapon, "");
		
		// Restore ammo
		if (Ammo >= 0)
		{
			iSlot = GetPlayerWeaponSlot(client, 1);
			if (iSlot > 0) SetEntProp(iSlot, Prop_Send, "m_iClip1", Ammo, 4);
		}
	}
}

void DeletePlayerSlot(int client, int weapon)
{		
	if(RemovePlayerItem(client, weapon)) AcceptEntityInput(weapon, "Kill");
}

void CheatCommand(int client, const char[] command, const char[] argument1, const char[] argument2)
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, argument1, argument2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

// *********************************************************************************
// Get/Set ammo
// *********************************************************************************

int GetClientAmmo(int client, char[] weapon)
{
	int weapon_offset = GetWeaponOffset(weapon);
	int iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	return weapon_offset > 0 ? GetEntData(client, iAmmoOffset+weapon_offset) : 0;
}

void SetClientAmmo(int client, char[] weapon, int count)
{
	int weapon_offset = GetWeaponOffset(weapon);
	int iAmmoOffset = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
	
	if (weapon_offset > 0) SetEntData(client, iAmmoOffset+weapon_offset, count);
}

int GetWeaponOffset(char[] weapon)
{
	int weapon_offset;

	if (StrEqual(weapon, "weapon_rifle") || StrEqual(weapon, "weapon_rifle_sg552") || StrEqual(weapon, "weapon_rifle_desert") || StrEqual(weapon, "weapon_rifle_ak47"))
	{
		weapon_offset = 12;
	}
	else if (StrEqual(weapon, "weapon_rifle_m60"))
	{
		weapon_offset = 24;
	}
	else if (StrEqual(weapon, "weapon_smg") || StrEqual(weapon, "weapon_smg_silenced") || StrEqual(weapon, "weapon_smg_mp5"))
	{
		weapon_offset = 20;
	}
	else if (StrEqual(weapon, "weapon_pumpshotgun") || StrEqual(weapon, "weapon_shotgun_chrome"))
	{
		weapon_offset = 28;
	}
	else if (StrEqual(weapon, "weapon_autoshotgun") || StrEqual(weapon, "weapon_shotgun_spas"))
	{
		weapon_offset = 32;
	}
	else if (StrEqual(weapon, "weapon_hunting_rifle"))
	{
		weapon_offset = 36;
	}
	else if (StrEqual(weapon, "weapon_sniper_scout") || StrEqual(weapon, "weapon_sniper_military") || StrEqual(weapon, "weapon_sniper_awp"))
	{
		weapon_offset = 40;
	}
	else if (StrEqual(weapon, "weapon_grenade_launcher"))
	{
		weapon_offset = 68;
	}

	return weapon_offset;
}