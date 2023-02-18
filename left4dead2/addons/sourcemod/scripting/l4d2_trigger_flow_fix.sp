#pragma semicolon 1
#define PLUGIN_VERSION "1.0"  
#define PLUGIN_NAME "Trigger Flow Fix"

#include <sourcemod>  
#include <left4dhooks>

// LEFT 4 DEAD 1
#define MODEL_BILL "models/survivors/survivor_namvet.mdl" 
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl" 
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl" 
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl" 

// LEFT 4 DEAD 2
#define MODEL_NICK "models/survivors/survivor_gambler.mdl" 
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl" 
#define MODEL_COACH "models/survivors/survivor_coach.mdl" 
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl" 

// BASE CHARACTER IDs
#define     NICK     		0
#define     ROCHELLE    	1
#define     COACH     		2
#define     ELLIS     		3

// L4D1 CHARACTER IDs
#define     BILL     		4
#define     ZOEY     		5
#define     FRANCIS     	6
#define     LOUIS     		7

ConVar	g_cvarEnabled;

bool 	g_bIsL4D1 = false;

public Plugin myinfo =  
{  
	name = PLUGIN_NAME,  
	author = "Gabu",  
	description = "Prevents custom maps from softlocking due to a poorly made trigger flow. Also fixes a lot of oddities on official maps.",  
	version = PLUGIN_VERSION,
	url = "https://github.com/gabuch2"
}  

public void OnPluginStart()  
{  
	g_cvarEnabled = CreateConVar("sm_l4d2_triggerflowfix_enabled", "1", "Enable the Plugin", FCVAR_DONTRECORD | FCVAR_NOTIFY);
}  

public void OnConfigsExecuted()
{
	if(GetConVarBool(g_cvarEnabled))
	{
		HookEntityOutput("filter_activator_model", "OnPass", OnCheckActivatorModel);
		HookEntityOutput("filter_activator_model", "OnFail", OnCheckActivatorModel);

		g_bIsL4D1 = L4D2_GetSurvivorSetMap() == 2 ? false : true;
	}
}

public Action OnCheckActivatorModel(const char[] output, int iCaller, int iActivator, float fDelay)
{
	if(0 == iActivator || MaxClients < iActivator)
		return Plugin_Continue; //I don't care about non-players
	
	int iTeam = GetClientTeam(iActivator);
	if(iTeam != 2 && iTeam != 4)
		return Plugin_Continue; //I don't care about infected

	int iEnt = EntRefToEntIndex(iCaller);

	char sModelName[PLATFORM_MAX_PATH];
	bool bNegated = GetEntProp(iEnt, Prop_Data, "m_bNegated") == 1 ? true : false;
	GetEntPropString(iEnt, Prop_Data, "m_iFilterModel", sModelName, sizeof(sModelName));

	bool bShouldTriggerSurvivor = false;
	if(StrEqual("OnPass", output))
	{
		//prevent players from activating something exclusive to the holdoout team
		if(iTeam == 2)
		{
			if(StrEqual(sModelName, g_bIsL4D1 ? MODEL_BILL : MODEL_NICK, false) || StrEqual(sModelName, g_bIsL4D1 ? MODEL_LOUIS : MODEL_COACH, false) || StrEqual(sModelName, g_bIsL4D1 ? MODEL_FRANCIS : MODEL_ELLIS, false) || StrEqual(sModelName, g_bIsL4D1 ? MODEL_ZOEY : MODEL_ROCHELLE, false))
				bShouldTriggerSurvivor = true;
		}
		else if(iTeam == 4)
		{
			if(StrEqual(sModelName, !g_bIsL4D1 ? MODEL_BILL : MODEL_NICK, false) || StrEqual(sModelName, !g_bIsL4D1 ? MODEL_LOUIS : MODEL_COACH, false) || StrEqual(sModelName, !g_bIsL4D1 ? MODEL_FRANCIS : MODEL_ELLIS, false) || StrEqual(sModelName, !g_bIsL4D1 ? MODEL_ZOEY : MODEL_ROCHELLE, false))
				bShouldTriggerSurvivor = true;
		}
		
		bShouldTriggerSurvivor = bNegated ? !bShouldTriggerSurvivor : bShouldTriggerSurvivor;

		if(bShouldTriggerSurvivor)
			return Plugin_Continue;
		else
			return Plugin_Handled;
	}
	else if(StrEqual("OnFail", output))
	{
		//check failed
		//check if the player is a survivor or holdout
		//and and make the check pass if applicable
		if(iTeam == 2)
		{
			switch(GetEntProp(iActivator, Prop_Send, "m_survivorCharacter"))
			{
				case FRANCIS, ELLIS:
				{
					if(StrEqual(sModelName, g_bIsL4D1 ? MODEL_FRANCIS : MODEL_ELLIS, false))
						bShouldTriggerSurvivor = true;
				}
				case LOUIS, COACH:
				{
					if(StrEqual(sModelName, g_bIsL4D1 ? MODEL_LOUIS : MODEL_COACH, false))
						bShouldTriggerSurvivor = true;
				}
				case ZOEY, ROCHELLE:
				{
					if(StrEqual(sModelName, g_bIsL4D1 ? MODEL_ZOEY : MODEL_ROCHELLE, false))
						bShouldTriggerSurvivor = true;
				}
				default:
				{
					//bill, nick, or custom survivors
					if(StrEqual(sModelName, g_bIsL4D1 ? MODEL_BILL : MODEL_NICK, false))
						bShouldTriggerSurvivor = true;
				}
			}
		}
		else if(iTeam == 4)
		{
			//the same as above, but flipped
			switch(GetEntProp(iActivator, Prop_Send, "m_survivorCharacter"))
			{
				case FRANCIS, ELLIS:
				{
					if(StrEqual(sModelName, !g_bIsL4D1 ? MODEL_FRANCIS : MODEL_ELLIS, false))
						bShouldTriggerSurvivor = true;
				}
				case LOUIS, COACH:
				{
					if(StrEqual(sModelName, !g_bIsL4D1 ? MODEL_LOUIS : MODEL_COACH, false))
						bShouldTriggerSurvivor = true;
				}
				case ZOEY, ROCHELLE:
				{
					if(StrEqual(sModelName, !g_bIsL4D1 ? MODEL_ZOEY : MODEL_ROCHELLE, false))
						bShouldTriggerSurvivor = true;
				}
				default:
				{
					//bill, nick, or custom survivors
					if(StrEqual(sModelName, !g_bIsL4D1 ? MODEL_BILL : MODEL_NICK, false))
						bShouldTriggerSurvivor = true;
				}
			}
		}

		bShouldTriggerSurvivor = bNegated ? !bShouldTriggerSurvivor : bShouldTriggerSurvivor;

		if(bShouldTriggerSurvivor)
		{
			FireEntityOutput(iCaller, "OnPass", iActivator, fDelay);
			return Plugin_Handled;
		}
		else
			return Plugin_Continue;
	}
	else
		return Plugin_Continue;
}