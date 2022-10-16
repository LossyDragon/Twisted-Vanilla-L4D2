#define PLUGIN_VERSION "1.1.2"

/*
 *	v1.0 just released; 2-6-22
 *	v1.0.1 fix issue 'double buff gain under 100 health'; 2-6-22
 *	v1.0.2 fix issue 'switch weapon quickly before pills use will cause wrong health record'; 2-7-22
 *	v1.1 add feature 'First Aid support', now name change to 'medicines no more limited', thanks my best friend i want heal for him; 2-9-22
 *	v1.1.1 overflow temp health of first aid causes also can turn to health; 2-9-22
 *	v1.1.2 optional to stop player wasted pills when health reached cap 'medicines_unlimited_allow_fail', plugin switch and unload work better now; 2-9-22
 */
#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

#define EventPills "pills_used"
#define EventAdrenaline "adrenaline_used"

ConVar Enabled;
ConVar Pills_decay;			float pills_decay;
ConVar Pills_cap;
ConVar Pills_buff;			float pills_buff;
ConVar Adrenaline_buff;		float adrenaline_buff;
ConVar Health_max;			float health_max;
ConVar Overflow_turn;		float overflow_turn;
ConVar First_aid_percent;	float first_aid_health;
ConVar First_aid_cap;
ConVar Allow_fail;			bool allow_fail;

enum L4DWeaponSlot
{
	L4DWeaponSlot_Primary			= 0,
	L4DWeaponSlot_Secondary			= 1,
	L4DWeaponSlot_Grenade			= 2,
	L4DWeaponSlot_FirstAid			= 3,
	L4DWeaponSlot_Pills				= 4
}

public Plugin myinfo = {
	name = "[L4D & L4D2] Medicines No More Limited",
	author = "NoroHime",
	description = "ate more pills and gets more pain",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {
	CreateConVar("medicines_unlimited_version", PLUGIN_VERSION, "Version of 'Medicines No More Limited'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = CreateConVar("medicines_unlimited_enable", "1", "Enable 'Medicines No More Limited'", FCVAR_NOTIFY);
	Health_max = CreateConVar("medicines_unlimited_health_max", "300", "health cap, well we dont really need player actually unlimited", FCVAR_NOTIFY, true, 100.0);
	Overflow_turn = CreateConVar("medicines_unlimited_overflow_turn", "0.5", "rate of turn the overflow temp health to real health when reached max, 0.5: turn as half 0: disable 1: completely turn", FCVAR_NOTIFY, true, 0.0);
	Pills_decay = FindConVar("pain_pills_decay_rate");
	Pills_cap = FindConVar("pain_pills_health_threshold");
	Pills_buff = FindConVar("pain_pills_health_value");
	Adrenaline_buff = FindConVar("adrenaline_health_buffer");
	First_aid_percent = FindConVar("first_aid_heal_percent");
	First_aid_cap = FindConVar("first_aid_kit_max_heal");
	Allow_fail = CreateConVar("medicines_unlimited_allow_fail", "0", "allow pain pills uses even health reached cap, but just turning temp to health during use, set 0 to stop player wasted pills", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d_medicines_unlimited");

	Enabled.AddChangeHook(Event_ConVarChanged);
	Pills_decay.AddChangeHook(Event_ConVarChanged);
	Pills_cap.AddChangeHook(Event_ConVarChanged);
	Pills_buff.AddChangeHook(Event_ConVarChanged);
	Adrenaline_buff.AddChangeHook(Event_ConVarChanged);
	Health_max.AddChangeHook(Event_ConVarChanged);
	Overflow_turn.AddChangeHook(Event_ConVarChanged);
	First_aid_percent.AddChangeHook(Event_ConVarChanged);
	First_aid_cap.AddChangeHook(Event_ConVarChanged);
	Allow_fail.AddChangeHook(Event_ConVarChanged);
	
	ApplyCvars();
}

public void OnPluginEnd() {
	ResetControlledCvars();
}

public void ResetControlledCvars() {
	ResetConVar(Pills_cap);
	ResetConVar(First_aid_cap);
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		HookEvent("pills_used_fail", Event_PillsUsedFail);
		HookEvent("weapon_fire", Event_WeaponFire);
		HookEvent(EventAdrenaline, Event_BuffingPre, EventHookMode_Pre);
		HookEvent(EventPills, Event_BuffingPre, EventHookMode_Pre);
		HookEvent("heal_begin", Event_HealBegin);
		HookEvent("heal_end", Event_HealEnd, EventHookMode_Pre);
		HookEvent("heal_success", Event_HealSucessPre, EventHookMode_Pre); //pre hook for better thirparty plugin support

		hooked = true;

	} else if (!enabled && hooked) {

		UnhookEvent("pills_used_fail", Event_PillsUsedFail);
		UnhookEvent("weapon_fire", Event_WeaponFire);
		UnhookEvent(EventAdrenaline, Event_BuffingPre, EventHookMode_Pre);
		UnhookEvent(EventPills, Event_BuffingPre, EventHookMode_Pre); //seems unhook not twice needed
		UnhookEvent("heal_begin", Event_HealBegin);
		UnhookEvent("heal_end", Event_HealEnd, EventHookMode_Pre);
		UnhookEvent("heal_success", Event_HealSucessPre, EventHookMode_Pre);

		hooked = false;
	}

	pills_decay = Pills_decay.FloatValue;
	health_max = Health_max.FloatValue;
	pills_buff = Pills_buff.FloatValue;
	adrenaline_buff = Adrenaline_buff.FloatValue;
	overflow_turn = Overflow_turn.FloatValue;
	first_aid_health = First_aid_percent.FloatValue * 100;

	if (enabled){
		Pills_cap.SetFloat(health_max - 1);
		First_aid_cap.SetFloat(health_max - 1);
	} else 
		ResetControlledCvars();
	
}


static int remaining_health[MAXPLAYERS + 1]; //recording for proper health
static float remaining_buffer[MAXPLAYERS + 1];

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	char weapon_name[32];
	event.GetString("weapon", weapon_name, sizeof(weapon_name));

	bool isAdrenaline = strcmp(weapon_name, "adrenaline") == 0;
	bool isPills = strcmp(weapon_name, "pain_pills") == 0;

	if (isAdrenaline || isPills)
		RecordHealth(client);
}


static int healing[MAXPLAYERS + 1]; //event 'Heal_End' wrong data, fix it by plugin

public void Event_HealBegin(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));
	healing[client] = subject; //record healing target
}

public void Event_HealEnd(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid")); //subject data always itself, just read from healer
	RecordHealth(healing[client]); //record health for proper target
}

public void Event_HealSucessPre(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("subject"));
	RestoreHealth(client);
	AddHealth(client, first_aid_health);
	AddBuffer(client, 0.0);
}

public void Event_BuffingPre(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (remaining_health[client] > 0 || remaining_buffer[client] > 0) {

		RestoreHealth(client);

		if (strcmp(name, EventPills) == 0)
			AddBuffer(client, pills_buff);

		if (strcmp(name, EventAdrenaline) == 0)
			AddBuffer(client, adrenaline_buff);
	}
}

public Action Event_PillsUsedFail(Event event, const char[] name, bool dontBroadcast) {

	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);

	bool isPills = IsValidEntity(GetPlayerWeaponSlot(client, view_as<int>(L4DWeaponSlot_Pills)));

	if (isPills && allow_fail) {

		AddBuffer(client, pills_buff);
		L4D_RemoveWeaponSlot(client, L4DWeaponSlot_Pills);

		Event ate = CreateEvent("pills_used");
		if (ate) {
			ate.SetInt("userid", userid);
			ate.SetInt("subject", userid);
			ate.Fire();
		}

		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void RecordHealth(int client) {
	remaining_health[client] = GetClientHealth(client);
	remaining_buffer[client] = GetTempHealth(client);
	// PrintToChatAll("record %N temp %.1f hp %d", client,  GetTempHealth(client), GetClientHealth(client));
}

void RestoreHealth(int client) {
	SetEntityHealth(client, remaining_health[client]); //read reacord to prevent game health modify
	remaining_health[client] = 0;

	SetTempHealth(client, remaining_buffer[client]);
	remaining_buffer[client] = 0.0;
}

void AddHealth(int client, float health) {
	int healthing = GetClientHealth(client);

	if (healthing + health > health_max)
		SetEntityHealth(client, RoundToFloor(health_max));
	else
		SetEntityHealth(client, healthing + RoundToFloor(health));
}

void AddBuffer(int client, float buff) {

	float buffing = GetTempHealth(client);
	int health = GetClientHealth(client);

	if (health + buffing + buff > health_max) {

		if (overflow_turn > 0) {

			float overflow = FloatAbs(health_max - health - buffing - buff) * overflow_turn;

			if (health + overflow > health_max) {

				SetEntityHealth(client, RoundToFloor(health_max));
				SetTempHealth(client, 0.0);

			} else {

				SetEntityHealth(client, health + RoundToFloor(overflow));
				SetTempHealth(client, health_max - health - overflow);
			}
		} else 
			SetTempHealth(client, health_max - health);
		
	} else 
		SetTempHealth(client, buffing + buff);
}

// ====================================================================================================
//										STOCKS - HEALTH (left4dhooks.sp)
// ====================================================================================================
float GetTempHealth(int client)
{
	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * pills_decay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}

/**
 * Removes the weapon from a client's weapon slot
 *
 * @param client		Player's index.
 * @param slot			Slot index.
 * @noreturn
 * @error				Invalid client or lack of mod support.
 */

stock void L4D_RemoveWeaponSlot(int client, L4DWeaponSlot slot)
{
	int weaponIndex;
	while ((weaponIndex = GetPlayerWeaponSlot(client, view_as<int>(slot))) != -1)
	{
		RemovePlayerItem(client, weaponIndex);
		RemoveEdict(weaponIndex);
	}
}
