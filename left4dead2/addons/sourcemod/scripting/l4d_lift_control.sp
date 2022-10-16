#define PLUGIN_VERSION		"1.5"

/*=======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Elevator Control
*	Author	:	SilverShot
*	Descrp	:	Allows admins to control elevators.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=306441
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.5 (18-May-2020)
	- Fixed the last updating breaking the plugin. Thanks to "DrDarkTempler" for reporting.

1.4 (10-May-2020)
	- Various changes to tidy up code.

1.3 (18-Jun-2018)
	- Added support for "c3m1_plankcountry" ferry crossing, as requested by "Pyc".

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1 (12-Apr-2018)
	- New Syntax - Thanks to "Visual77"
	- Added "Stop" elevator option.
	- Fixed not working after round restart.

1.0 (31-Mar-2018)
	- Initial release.
	- Originally created on 17-Apr-2011.

======================================================================================*/


#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

bool g_bLateLoad;
int g_iMapType, g_iPlayerSpawn, g_iRoundStart;

enum
{
	C1M1 = 1,
	C1M4,
	C3M1,
	C4M2,
	C4M3,
	C6M3,
	C8M4
}



// ====================================================================================================
//					PLUGIN INFO / START
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Elevator Control",
	author = "SilverShot",
	description = ".",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306441"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_lift", CmdLift, ADMFLAG_ROOT);

	CreateConVar("l4d_lift_version", PLUGIN_VERSION, "Elevator Control plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	if( g_bLateLoad )
	{
		g_bLateLoad = false;
		LoadStuff();
	}
}

public void OnMapEnd()
{
	ResetPlugin();
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action tmrStart(Handle timer)
{
	LoadStuff();
}

void ResetPlugin()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void LoadStuff()
{
	g_iMapType = 0;
	char sMap[32];
	GetCurrentMap(sMap, sizeof(sMap));

	if( strcmp(sMap, "c1m1_hotel") == 0 )
	{
		g_iMapType = C1M1;
		CreateFloor( view_as<float>({ 2168.0, 5848.0, 2461.0 }), "topfloor" ); // Create a top floor since it's missing.
	}
	else if( strcmp(sMap, "c1m4_atrium") == 0 )
	{
		g_iMapType = C1M4;
		CreateFloor( view_as<float>({ -3946.0, -3445.06, 536.99 }), "topfloor" ); // Create a top floor since it's missing.
	}
	else if( strcmp(sMap, "c6m3_port") == 0 )
	{
		g_iMapType = C6M3;
		CreateFloor( view_as<float>({ -768.0, -580.0, 316.0 }), "elevator_top" ); // Create a top floor since it's missing.
	}
	else if( strcmp(sMap, "c3m1_plankcountry") == 0 ) g_iMapType = C3M1;
	else if( strcmp(sMap, "c4m2_sugarmill_a") == 0 ) g_iMapType = C4M2;
	else if( strcmp(sMap, "c4m3_sugarmill_b") == 0 ) g_iMapType = C4M3;
	else if( strcmp(sMap, "c8m4_interior") == 0 ) g_iMapType = C8M4;
}

void CreateFloor(float vPos[3], const char[] sFloor)
{
	int ent = CreateEntityByName("info_elevator_floor");
	if( ent != -1 )
	{
		TeleportEntity(ent, vPos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(ent, "targetname", sFloor);
		DispatchSpawn(ent);
	}
}



// -----------------------------------------------------------------------
// FUNCTIONS
// -----------------------------------------------------------------------
public Action CmdLift(int client, int args)
{
	ShowLifts(client);
	return Plugin_Handled;
}

void ShowLifts(int client)
{
	if( g_iMapType > 0 && client && IsClientInGame(client) )
	{
		Menu menu = new Menu(LiftMenuHandler);

		menu.AddItem("1", "Open Doors");
		menu.AddItem("2", "Close Doors");
		menu.AddItem("3", "Move Up");
		menu.AddItem("4", "Move Down");
		menu.AddItem("5", "Stop");

		menu.SetTitle("Lift Operations:");
		menu.ExitButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int LiftMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Select )
	{
		int ent;

		if( index != 4 || (index == 4 && g_iMapType == C3M1) )
		{
			ent = CreateEntityByName("logic_relay");
		}

		if( ent == -1 )
		{
			PrintToChat(client, "[LIFT] Creating logic_relay failed");
			ShowLifts(client);
			return;
		}

		// -----------------------------------------------------------------------
		// OPEN DOORS
		// -----------------------------------------------------------------------
		if( index == 0 )
		{
			switch( g_iMapType )
			{
				case C1M1:
				{
					SetVariantString("OnUser1 elevator_1_door1:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_1_door2:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_clip:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C1M4:
				{
					SetVariantString("OnUser1 door_elevator_top:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevator_inside:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevator:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C3M1:
				{
					SetVariantString("OnUser1 ferry_door_left_entrance:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_right_entrance:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_left_exit:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_right_exit:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C4M2, C4M3:
				{
					SetVariantString("OnUser1 prop_elevator_gate_top:SetAnimation:open:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 prop_elevator_gate_bottom:SetAnimation:open:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_move:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_door_bot_close:playsound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C8M4:
				{
					SetVariantString("OnUser1 door_elev:Open::0.1:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevouterlow:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevouterhigh:Open::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
			}
		}

		// -----------------------------------------------------------------------
		// CLOSE DOORS
		// -----------------------------------------------------------------------
		else if( index == 1 )
		{
			switch( g_iMapType )
			{
				case C1M1:
				{
					SetVariantString("OnUser1 elevator_1_door1:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_1_door2:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_clip:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C1M4:
				{
					SetVariantString("OnUser1 door_elevator_top:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevator_inside:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevator:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C3M1:
				{
					SetVariantString("OnUser1 ferry_door_left_entrance:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_right_entrance:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_left_exit:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_door_right_exit:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C4M2, C4M3:
				{
					SetVariantString("OnUser1 prop_elevator_gate_top:SetAnimation:Close:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 prop_elevator_gate_bottom:SetAnimation:Close:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_move:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_door_bot_close:playsound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C8M4:
				{
					SetVariantString("OnUser1 door_elev:Close::0.1:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevouterlow:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 door_elevouterhigh:Close::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
			}
		}

		// -----------------------------------------------------------------------
		// LIFT UP
		// -----------------------------------------------------------------------
		else if( index == 2 )
		{
			switch( g_iMapType )
			{
				case C1M1:
				{
					SetVariantString("OnUser1 elevator_1:MoveToFloor:topfloor:1:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_clip:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C1M4:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:top:1:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C3M1:
				{
					SetVariantString("OnUser1 ferry_tram:StartBackward::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 swamp_nav_blocker:UnblockNav::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_winch_start:Trigger::0.1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_move_sound:Volume:3:0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_tram_button_model:SetAnimation:idleOn:0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_tram_incap_trigger:Disable::2:-1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C4M2, C4M3:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:top:2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_move:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_door_bot_close:playsound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C6M3:
				{
					SetVariantString("OnUser1 generator_elevator:MoveToFloor:elevator_top:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 generator_elevator_button_sound:PlaySound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C8M4:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:top::1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_pulley:Start:::-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_pulley2:Start:::-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_inside_number_relay:Skin::1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevbuttonoutsidefront:Trigger::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator panel:Skin:1:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_number_relay:Trigger::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_ragdoll_fader:Enable::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_breakwalls*:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_game_event:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_hurt_trigger:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_ragdoll_fader:Kill::5:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_door_ghost_blocker:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
			}
		}

		// -----------------------------------------------------------------------
		// LIFT DOWN
		// -----------------------------------------------------------------------
		else if( index == 3 )
		{
			switch( g_iMapType )
			{
				case C1M1:
				{
					SetVariantString("OnUser1 elevator_1:MoveToFloor:stop1:1:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_clip:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C1M4:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:bottom:1:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C3M1:
				{
					SetVariantString("OnUser1 ferry_tram:StartForward::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_winch_stop:Trigger::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_tram:SetSpeed:.5:2:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_tram_push:Kill::60:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 rental_breakable1_clip:Kill::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_winch_start:Trigger::0.1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 swamp_clip_brush:Kill::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_tram_incap_trigger:Enable::75:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_sign_trigger:Enable::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_winch:SetAnimation:start:0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_winch_run:Trigger::0.85:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 ferry_move_sound:PlaySound::0:-1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C4M2, C4M3:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:bottom:2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_move:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::2:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_door_bot_close:playsound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C6M3:
				{
					SetVariantString("OnUser1 generator_elevator:MoveToFloor:elevator_bottom:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 generator_elevator_button_sound:PlaySound::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
				case C8M4:
				{
					SetVariantString("OnUser1 elevator:MoveToFloor:bottom::1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator:MoveToFloor:bottom::1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_pulley:Start::1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_pulley2:Start::1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_inside_number_relay:Skin::1:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevbuttonoutsidefront:Trigger::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator panel:Skin:1:0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 sound_elevator_startup:PlaySound::0:-1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_number_relay:Trigger::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_breakwalls*:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_game_event:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_ragdoll_fader:Enable::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_hurt_trigger:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_ragdoll_fader:Kill::1:1");
					AcceptEntityInput(ent, "AddOutput");
					SetVariantString("OnUser1 elevator_door_ghost_blocker:Kill::0:1");
					AcceptEntityInput(ent, "AddOutput");
				}
			}
		}

		// -----------------------------------------------------------------------
		// LIFT STOP
		// -----------------------------------------------------------------------
		if( index == 4 && g_iMapType != C3M1 )
		{
			float vPos[3];
			ent = FindEntityByClassname(-1, "func_elevator");

			if( g_iMapType == C6M3 ) // C6M3 has 2 elevators
			{
				char sName[32];
				GetEntPropString(ent, Prop_Data, "m_iName", sName, sizeof(sName));
				if( strcmp(sName, "generator_elevator") ) // Does not match correct one, continue find
				{
					ent = FindEntityByClassname(ent, "func_elevator");
				}
			}

			if( ent != -1 )
			{
				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vPos);
				SetEntPropFloat(ent, Prop_Send, "m_movementStartTime", GetGameTime());
				SetEntPropFloat(ent, Prop_Send, "m_movementStartZ", vPos[2]);
				SetEntPropFloat(ent, Prop_Send, "m_destinationFloorPosition", vPos[2]);
				SetEntProp(ent, Prop_Send, "m_isMoving", 0);
			}
		} else {
			if( index == 4 && g_iMapType == C3M1 )
			{
				SetVariantString("OnUser1 ferry_tram_button_model:SetAnimation:idleOn:0:-1");
				AcceptEntityInput(ent, "AddOutput");
				SetVariantString("OnUser1 ferry_stop_sound:PlaySound::0:-1");
				AcceptEntityInput(ent, "AddOutput");
				SetVariantString("OnUser1 ferry_move_sound:StopSound::0:-1");
				AcceptEntityInput(ent, "AddOutput");
				SetVariantString("OnUser1 ferry_winch_stop:Trigger::0:-1");
				AcceptEntityInput(ent, "AddOutput");
				SetVariantString("OnUser1 ferry_tram:SetSpeed:0:0:-1");
				AcceptEntityInput(ent, "AddOutput");
			}

			// Fire other inputs
			AcceptEntityInput(ent, "FireUser1");
			SetVariantString("OnUser2 !self:kill::2:1");
			AcceptEntityInput(ent, "AddOutput");
			AcceptEntityInput(ent, "FireUser2");
		}

		ShowLifts(client);
	}
}