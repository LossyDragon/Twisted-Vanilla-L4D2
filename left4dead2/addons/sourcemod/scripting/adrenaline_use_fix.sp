#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <weaponhandling>

#pragma semicolon 1

#pragma newdecls required

#define PLUGIN_VERSION "1.0"

static float g_fadrenaline_use_fix;

static ConVar hCvar_adrenaline_use_fix;

public Plugin myinfo =
{
	name = "Adrenaline Use Fix",
	author = "Shao, RainyDagger",
	description = "Modifies the use speed.",
	version = PLUGIN_VERSION,
	url = ""
};


public void OnPluginStart()
{
	CreateConVar("adrenaline_use_fix_version", PLUGIN_VERSION, "1.0", FCVAR_DONTRECORD|FCVAR_NOTIFY);

	hCvar_adrenaline_use_fix = CreateConVar("adrenaline_use_fix", "1.0", "Choose the multiplier when adrenaline is used.", FCVAR_NOTIFY, true, 0.0001, true, 100.0);

	hCvar_adrenaline_use_fix.AddChangeHook(eConvarChanged);

	g_fadrenaline_use_fix = hCvar_adrenaline_use_fix.FloatValue;

	AutoExecConfig(true, "adrenaline_use_fix");
}

public void eConvarChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	g_fadrenaline_use_fix = hCvar_adrenaline_use_fix.FloatValue;
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
	if(weapontype == L4D2WeaponType_Adrenaline && hCvar_adrenaline_use_fix)
	{
		speedmodifier = speedmodifier * g_fadrenaline_use_fix;
	}
}