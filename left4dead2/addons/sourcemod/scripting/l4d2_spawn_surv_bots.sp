#define PLUGIN_NAME "[L4D2] Spawn Survivor Bots Command (NOT A BOT MANAGER)"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Spawn survivor bots with sm_survbot"
#define PLUGIN_VERSION "1.0.1"
#define PLUGIN_URL ""
#define PLUGIN_NAME_SHORT "Spawn Survivor Bots Command"
#define PLUGIN_NAME_TECH "spawn_survbot"

#include <sourcemod>
#include <sdktools>
//#include <sdkhooks>
//#include <adminmenu>

#pragma semicolon 1
#pragma newdecls required

#define TEAM_SURVIVOR 2
#define TEAM_PASSING 4

#define AUTOEXEC_CFG "spawn_surv_bots"

static char survivor_names[8][] = { "Nick", "Rochelle", "Coach", "Ellis", "Bill", "Zoey", "Francis", "Louis"};
static char survivor_mdls[8][] = { "gambler", "producer", "coach", "mechanic", "namvet", "teenangst", "biker", "manager"};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev = GetEngineVersion();
	if (ev == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

static ConVar cvarTempBots = null;
//static ConVar cvarEnforceSet = null;
bool g_bTempBots;
//bool g_bEnforceSet;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

#define PREVENTSELECT_OFF 0
#define PREVENTSELECT_DEFAULT 1
#define PREVENTSELECT_ISBILL 2
static int g_stored[MAXPLAYERS + 1] = { PREVENTSELECT_OFF };
static bool g_isTempBot[MAXPLAYERS + 1] =  { false };

public void OnPluginStart()
{
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_temp", PLUGIN_NAME_TECH);
	cvarTempBots = CreateConVar(cmd_str, "0.0", "Kick the spawned bots as soon as they die.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	//Format(cmd_str, sizeof(cmd_str), "sm_%s_missionset", PLUGIN_NAME_TECH);
	//cvarEnforceSet = CreateConVar(cmd_str, "0.0", "Only spawn the L4D1 survivors when L4D1 survivor set is active?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	
	cvarTempBots.AddChangeHook(ConVarChanged_Cvars);
	//cvarEnforceSet.AddChangeHook(ConVarChanged_Cvars);
	
	HookEvent("player_death", player_death, EventHookMode_Post);
	
	RegAdminCmd("sm_survbot", Command_SpawnSurvBot, ADMFLAG_CHEATS, "sm_survbot <char> <team> - Spawn a survivor bot.");
	RegAdminCmd("sm_fakebot", Command_SpawnFake, ADMFLAG_ROOT, "sm_fakebot <char> <team> - Spawn a survivor bot from CreateFakeClient.");
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", player_death, EventHookMode_Post);
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bTempBots = cvarTempBots.BoolValue;
	//g_bEnforceSet = cvarEnforceSet.BoolValue;
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	bool isTempBot = g_isTempBot[client];
	if (isTempBot)
	{ g_isTempBot[client] = false; }
	
	if (!IsValidClient(client) || (!IsSurvivor(client) && !IsPassingSurvivor(client)) || !IsFakeClient(client)) return;
	
	if (!isTempBot) return;
	
	CreateTimer(1.0, KickBot, client, TIMER_FLAG_NO_MAPCHANGE);
}
Action KickBot(Handle timer, int client)
{
	if (!IsValidClient(client) || !IsFakeClient(client)) return Plugin_Handled;
	KickClient(client);
	return Plugin_Handled;
}

Action Command_SpawnSurvBot(int client, int args)
{
	if (GetClientCount(false) >= MaxClients - 1)
	{
        return Plugin_Handled;
    }
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_survbot <char> <team>");
		return Plugin_Handled;
	}
	
	static char arg1[10], arg2[10];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int arg2_int = StringToInt(arg2);
	
	if (arg2_int != TEAM_SURVIVOR && arg2_int != TEAM_PASSING) arg2_int = TEAM_SURVIVOR;
	
	int arg1_int = ConvertStrToSurvChar(arg1);
	if (arg1_int <= -1)
	{
		arg1_int = StringToInt(arg1);
		// if arg1 is not empty or, arg1 is not 0 and arg1_int is lesser than rochelle, but higher than louis then
		if (arg1[0] == '\0' || (arg1[0] != '0' && (arg1_int < 1 || arg1_int > 7)))
		{
			arg1_int = GetRandomInt(0, 7);
		}
	}
	
	float origin[3], angles[3];
	origin = view_as<float>({0.0, 0.0, 0.0}); angles = view_as<float>({0.0, 0.0, 0.0});
	if (IsValidClient(client))
	{
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i) || (!IsSurvivor(i) && !IsPassingSurvivor(i))) continue;
			
			GetClientAbsOrigin(i, origin);
			GetClientAbsAngles(i, angles);
			break;
		}
	}
	
	int bot = CreateSurvivorBot(origin, angles, arg2_int, arg1_int);
	if (IsValidClient(bot) && IsFakeClient(bot))
	{
		if (g_bTempBots)
		{
			g_isTempBot[bot] = true;
		}
		if (GetClientTeam(bot) == TEAM_PASSING)
		{
			SetVariantInt(0);
			AcceptEntityInput(bot, "SetGlowEnabled");
		}
	}
	return Plugin_Handled;
}

Action Command_SpawnFake(int client, int args)
{
	if (GetClientCount(false) >= MaxClients - 1)
	{
        return Plugin_Handled;
    }
	if (args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fakebot <char> <team>");
		return Plugin_Handled;
	}
	
	static char arg1[10], arg2[10];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	int arg2_int = StringToInt(arg2);
	
	if (arg2_int < 1 || arg2_int > 4) arg2_int = TEAM_SURVIVOR;
	
	int arg1_int = ConvertStrToSurvChar(arg1);
	if (arg1_int <= -1)
	{
		arg1_int = StringToInt(arg1);
		// if arg1 is not empty or, arg1 is not 0 and arg1_int is lesser than rochelle, but higher than louis then
		if (arg1[0] == '\0' || (arg1[0] != '0' && (arg1_int < 1 || arg1_int > 7)))
		{
			arg1_int = GetRandomInt(0, 7);
		}
	}
	
	float origin[3], angles[3];
	origin = view_as<float>({0.0, 0.0, 0.0}); angles = view_as<float>({0.0, 0.0, 0.0});
	if (IsValidClient(client))
	{
		GetClientAbsOrigin(client, origin);
		GetClientAbsAngles(client, angles);
	}
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsValidClient(i) || !IsPlayerAlive(i) || (!IsSurvivor(i) && !IsPassingSurvivor(i))) continue;
			
			GetClientAbsOrigin(i, origin);
			GetClientAbsAngles(i, angles);
			break;
		}
	}
	
	int bot = CreateFakeClient("Bot");
	if (IsValidClient(bot))
	{
		ChangeClientTeam(bot, arg2_int);
		if (arg2_int == TEAM_SURVIVOR || arg2_int == TEAM_PASSING)
		{
			SetSurvivorChar(bot, arg1_int, true);
		}
    }
	return Plugin_Handled;
}

// CreateSurvivorBot
void PreventSelect(int client)
{
	g_stored[client] = PREVENTSELECT_OFF;
	if (!IsValidClient(client)) return;
	if (!IsSurvivor(client) && !IsPassingSurvivor(client)) return;
	
	int Prop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if (Prop == 4)
	{
		g_stored[client] = PREVENTSELECT_ISBILL;
		SetEntProp(client, Prop_Send, "m_survivorCharacter", 0);
	}
	else
	{
		g_stored[client] = PREVENTSELECT_DEFAULT;
	}
}
void ReallowSelect(int client)
{
	bool isBill = (g_stored[client] == PREVENTSELECT_ISBILL);
	g_stored[client] = PREVENTSELECT_OFF;
	
	if (!IsValidClient(client)) return;
	if (!IsSurvivor(client) && !IsPassingSurvivor(client)) return;
	
	int Prop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if (Prop == 0 && isBill)
	{
		SetEntProp(client, Prop_Send, "m_survivorCharacter", 4);
	}
}
/*Action timer_RestoreBills(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		ReallowSelect(i);
	}
}*/
int CreateSurvivorBot(const float origin[3], const float angles[3], int team = TEAM_SURVIVOR, int character = 4)
{
	int spawn = CreateEntityByName("info_l4d1_survivor_spawn");
	DispatchKeyValue(spawn, "character", "4");
	DispatchKeyValueVector(spawn, "origin", origin);
	DispatchKeyValueVector(spawn, "angles", angles);
	//DispatchKeyValue(spawn, "targetname", TRICKERY_SPAWNBOT_NAME);
	DispatchSpawn(spawn);
	ActivateEntity(spawn);
	AcceptEntityInput(spawn, "Kill");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		PreventSelect(i);
	}
	AcceptEntityInput(spawn, "SpawnSurvivor");
	
	int result = -1;
	float spawn_origin[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPassingSurvivor(i) || !IsFakeClient(i)) continue;
		if (g_stored[i] != PREVENTSELECT_OFF) continue;
		
		GetClientAbsOrigin(i, spawn_origin);
		
		//if (spawn_origin[0] == origin[0] && spawn_origin[1] == origin[1] && spawn_origin[2] == origin[2])
		//{
		result = i;
		//g_stored[i] = PREVENTSELECT_DEFAULT;
		break;
		//}
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		ReallowSelect(i);
	}
	
	if (!IsValidClient(result)) return -1;
	
	ChangeClientTeam(result, team);
	SetSurvivorChar(result, character, true);
	
	if (!IsPlayerAlive(result))
	{ RespawnSurvivor(result, origin, angles); }
	
	TeleportEntity(result, origin, angles, NULL_VECTOR);
	
	return result;
}
void RespawnSurvivor(int client, const float origin[3], const float angles[3])
{
	// We respawn the player via rescue entity; we don't need a signature at all!
	int rescue_ent = CreateEntityByName("info_survivor_rescue");
	if (!RealValidEntity(rescue_ent))
	{ return; }
	AcceptEntityInput(rescue_ent, "Kill");
	
	TeleportEntity(rescue_ent, origin, angles, NULL_VECTOR);
	
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	SetEntityModel(rescue_ent, cl_model);
	
	DispatchSpawn(rescue_ent);
	ActivateEntity(rescue_ent);
	
	DispatchKeyValue(rescue_ent, "nextthink", "10.0");
	
	SetEntPropEnt(rescue_ent, Prop_Send, "m_survivor", client);
	AcceptEntityInput(rescue_ent, "Rescue");
	
	SetEntityHealth(client, GetEntProp(client, Prop_Send, "m_iMaxHealth"));
}
//GENDER_NAMVET           =  3,
//GENDER_TEENGIRL         =  4,
//GENDER_BIKER            =  5,
//GENDER_MANAGER          =  6,
//GENDER_GAMBLER          =  7,
//GENDER_PRODUCER         =  8,
//GENDER_COACH            =  9,
//GENDER_MECHANIC         = 10,
void SetSurvivorChar(int client, int character, bool setMdl = false)
{
	if (IsFakeClient(client))  SetClientName(client, survivor_names[character]);
	SetEntProp(client, Prop_Send, "m_survivorCharacter", character);
	if (!setMdl) return;
	
	// on second thought, gender isn't changed, f
	/*int gender = GetEntProp(client, Prop_Send, "m_Gender");
	if (character >= 0 && character <= 3 && gender != (7 + character))
	{
		switch (character)
		{
			case 0:
			{ character = 4; }
			case 1:
			{ character = 5; }
			case 2:
			{ character = 7; }
			case 3:
			{ character = 6; }
		}
	}*/
	
	static char temp_str[PLATFORM_MAX_PATH+1];
	Format(temp_str, sizeof(temp_str), "models/survivors/survivor_%s.mdl", survivor_mdls[character]);
	if (!IsModelPrecached(temp_str))
	{ PrecacheModel(temp_str); }
	SetEntityModel(client, temp_str);
}
// CreateSurvivorBot end

int ConvertStrToSurvChar(const char[] str)
{
	switch (CharToLower(str[0]))
	{
		case 'n': // Nick
		{ return 0; }
		case 'r': // Rochelle
		{ return 1; }
		case 'c': // Coach
		{ return 2; }
		case 'e': // Ellis
		{ return 3; }
		case 'b': // Bill
		{ return 4; }
		case 'z': // Zoey Bandicoot
		{ return 5; }
		case 'f': // Francis
		{ return 6; }
		case 'l': // Louis
		{ return 7; }
	}
	return -1;
}

bool IsSurvivor(int client)
{ return (GetClientTeam(client) == TEAM_SURVIVOR || GetClientTeam(client) == TEAM_PASSING); }

//bool IsGameSurvivor(int client)
//{ return (GetClientTeam(client) == TEAM_SURVIVOR); }

//bool IsInfected(int client)
//{ return (GetClientTeam(client) == 3); }

bool IsPassingSurvivor(int client)
{ return (GetClientTeam(client) == TEAM_PASSING); }

bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

/*bool IsIncapacitated(int client, int hanging = 2)
{
	bool isIncap = view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
	bool isHanging = view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge"));
	
	switch (hanging)
	{
		// if hanging is 2, don't care about hanging
		case 2:
			return (isIncap);
		// if 1, check for hanging too
		case 1:
			return (isIncap && isHanging);
		// otherwise, must just be incapped to return true
		case 0:
			return (isIncap && !isHanging);
	}
	return false;
}*/

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

/*int GetInfectedAbility(int client)
{
	if (!IsInfected(client)) return -1;
	
	int ability_ent = -1;
	if (HasEntProp(client, Prop_Send, "m_customAbility"))
	{
		ability_ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	}
	return ability_ent;
}*/