/**
// ====================================================================================================
Change Log:

1.0.0 (04-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Remove Weapons/Carryables Collision"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Changes the collision from all weapons or carryables to collide only with the world and static stuff"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328327"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_remove_item_collision"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_PROP_PHYSICS        "prop_physics"
#define CLASSNAME_PHYSICS_PROP        "physics_prop"

#define COLLISION_GROUP_DEBRIS        1

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bLateLoad;
static bool   g_bCvar_Enabled;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;

    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_remove_item_collision_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_remove_item_collision_enable", "1", "Enables/Disables the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_remove_item_collision", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    if (g_bLateLoad)
        LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(Handle convar, const char[] sOldValue, const char[] sNewValue)
{
    GetCvars();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "weapon_*")) != INVALID_ENT_REFERENCE)
    {
       OnSpawnPost(entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_PROP_PHYSICS)) != INVALID_ENT_REFERENCE)
    {
       if (GetEntProp(entity, Prop_Send, "m_isCarryable", 1) == 1)
            OnSpawnPost(entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_PHYSICS_PROP)) != INVALID_ENT_REFERENCE)
    {
        if (GetEntProp(entity, Prop_Send, "m_isCarryable", 1) == 1)
            OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (StrContains(classname, "weapon_") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
        return;
    }

    if (StrEqual(classname, CLASSNAME_PROP_PHYSICS) || StrEqual(classname, CLASSNAME_PHYSICS_PROP))
    {
        if (GetEntProp(entity, Prop_Send, "m_isCarryable", 1) == 1)
        {
            SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
            return;
        }
    }
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    if (!g_bCvar_Enabled)
        return;

    SetEntProp(entity, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
}

// ====================================================================================================
// Admin Commands - Print to Console
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_remove_item_collision) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_remove_item_collision_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_remove_item_collision_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
}