/*
Vocalize Admin Commands
Copyright (C) 2014  Buster "Mr. Zero" Nielsen

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Includes */
#include <sourcemod>
#include <sceneprocessor>

#undef REQUIRE_PLUGIN
#tryinclude <adminmenu>
#define REQUIRE_PLUGIN

/* Plugin Information */
public Plugin:myinfo = 
{
	name		= "Vocalize Admin Commands",
	author		= "Buster \"Mr. Zero\" Nielsen",
	description	= "Provide administrators with basic vocalize commands.",
	version		= "1.0.1",
	url		= "https://forums.alliedmods.net/showthread.php?t=241587"
}

/* Globals */

/* Borrowed from L4DStocks ( https://code.google.com/p/l4dstocks/ ) */
enum L4DTeam
{
    L4DTeam_Unassigned              = 0,
    L4DTeam_Spectator               = 1,
    L4DTeam_Survivor                = 2,
    L4DTeam_Infected                = 3
}

new bool:g_IsGagged[MAXPLAYERS + 1]
new bool:g_IsMuted[MAXPLAYERS + 1]

new g_AdminMenuTarget[MAXPLAYERS + 1]

new Handle:g_TopMenuHandle

enum VocalizeType
{
	VocalizeType_Mute,
	VocalizeType_Unmute,
	VocalizeType_Gag,
	VocalizeType_Ungag
}

/* Plugin Functions */
public OnPluginStart()
{
	LoadTranslations("common.phrases")
	LoadTranslations("vocalizeadmincommands.phrases")
	
	RegAdminCmd("sm_vocalizegag", VocalizeGag_Command, ADMFLAG_CHAT, "sm_vocalizegag <#userid|name> - Removes a player's ability to use vocalize.", _, FCVAR_PLUGIN)
	RegAdminCmd("sm_vocalizeungag", VocalizeUngag_Command, ADMFLAG_CHAT, "sm_vocalizeungag <#userid|name> - Restores a player's ability to use vocalize.", _, FCVAR_PLUGIN)
	
	RegAdminCmd("sm_vocalizemute", VocalizeMute_Command, ADMFLAG_CHAT, "sm_vocalizemute <#userid|name> - Removes all vocalize coming from a player.", _, FCVAR_PLUGIN)
	RegAdminCmd("sm_vocalizeunmute", VocalizeUnmute_Command, ADMFLAG_CHAT, "sm_vocalizeunmute <#userid|name> - Restores all vocalize coming from a player.", _, FCVAR_PLUGIN)
	
	RegAdminCmd("sm_vocalize", Vocalize_Command, ADMFLAG_SLAY, "sm_vocalize <#userid|name> <vocalize|scene file> [pre-delay] [pitch] - Forces player to vocalize or perform a scene.", _, FCVAR_PLUGIN)
	
	/* Account for late loading */
	new Handle:topmenu
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu)
	}
}

public OnClientConnected(client)
{
	g_IsGagged[client] = false
	g_IsMuted[client] = false
}

public Action:Vocalize_Command(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vocalize <#userid|name> <vocalize|scene file> [pre-delay] [pitch]")
		return Plugin_Handled
	}
	
	decl String:arg[64]
	GetCmdArg(1, arg, sizeof(arg))
	
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	
	decl String:vocalize[MAX_VOCALIZE_LENGTH]
	GetCmdArg(2, vocalize, sizeof(vocalize))
	StripQuotes(vocalize)
	TrimString(vocalize)
	if (strlen(vocalize) == 0)
	{
		ReplyToCommand(client, "[SM] %t", "Missing vocalize string or scene file")
		return Plugin_Handled
	}
	
	decl String:buffer[128]
	new Float:preDelay = DEFAULT_SCENE_PREDELAY
	if (args >= 3)
	{
		GetCmdArg(3, buffer, sizeof(buffer))
		preDelay = StringToFloat(buffer)
		if (preDelay < 0.0)
		{
			preDelay = 0.0
		}
	}
	
	new Float:pitch = DEFAULT_SCENE_PITCH
	if (args >= 4)
	{
		GetCmdArg(4, buffer, sizeof(buffer))
		pitch = StringToFloat(buffer)
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (L4DTeam:GetClientTeam(target_list[i]) != L4DTeam_Survivor)
		{
			continue
		}
		
		LogAction(client, target_list[i], "\"%L\" forced \"%L\" to vocalize \"%s\" (pre-delay %.2f, pitch %.2f)", client, target_list[i], vocalize, preDelay, pitch)
		PerformSceneEx(target_list[i], vocalize, vocalize, preDelay, pitch)
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Player performing scene", target_name)
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Player performing scene", "_s", target_name)
	}
	
	return Plugin_Handled
}

public Action:VocalizeGag_Command(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vocalizegag <#userid|name>")
		return Plugin_Handled
	}
	
	decl String:arg[64]
	GetCmdArg(1, arg, sizeof(arg))
	
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (!g_IsGagged[target_list[i]])
		{
			LogAction(client, target_list[i], "\"%L\" vocalize gagged \"%L\"", client, target_list[i])
		}
		g_IsGagged[target_list[i]] = true
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize gagged target", target_name)
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize gagged target", "_s", target_name)
	}
	
	return Plugin_Handled
}

public Action:VocalizeUngag_Command(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vocalizeungag <#userid|name>")
		return Plugin_Handled
	}
	
	decl String:arg[64]
	GetCmdArg(1, arg, sizeof(arg))
	
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (g_IsGagged[target_list[i]])
		{
			LogAction(client, target_list[i], "\"%L\" vocalize ungagged \"%L\"", client, target_list[i])
		}
		g_IsGagged[target_list[i]] = false
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize ungagged target", target_name)
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize ungagged target", "_s", target_name)
	}
	
	return Plugin_Handled
}

public Action:VocalizeMute_Command(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vocalizemute <#userid|name>")
		return Plugin_Handled
	}
	
	decl String:arg[64]
	GetCmdArg(1, arg, sizeof(arg))
	
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (!g_IsMuted[target_list[i]])
		{
			LogAction(client, target_list[i], "\"%L\" vocalize muted \"%L\"", client, target_list[i])
		}
		g_IsMuted[target_list[i]] = true
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize muted target", target_name)
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize muted target", "_s", target_name)
	}
	
	return Plugin_Handled
}

public Action:VocalizeUnmute_Command(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vocalizeunmute <#userid|name>")
		return Plugin_Handled
	}
	
	decl String:arg[64]
	GetCmdArg(1, arg, sizeof(arg))
	
	decl String:target_name[MAX_TARGET_LENGTH]
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count)
		return Plugin_Handled
	}
	
	for (new i = 0; i < target_count; i++)
	{
		if (g_IsMuted[target_list[i]])
		{
			LogAction(client, target_list[i], "\"%L\" vocalize unmuted \"%L\"", client, target_list[i])
		}
		g_IsMuted[target_list[i]] = false
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize unmuted target", target_name)
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Vocalize unmuted target", "_s", target_name)
	}
	
	return Plugin_Handled
}

public OnSceneStageChanged(scene, SceneStages:stage)
{
	switch (stage)
	{
		case SceneStage_Spawned:
		{
			new client = GetActorFromScene(scene)
			
			if (client <= 0 || client > MaxClients)
			{
				return
			}
			
			new initiator = GetSceneInitiator(scene)
			
			if ((initiator != SCENE_INITIATOR_PLUGIN && g_IsMuted[client]) || 
				initiator == client && g_IsGagged[client])
			{
				CancelScene(scene)
				return
			}
		}
	}
}

public Action:OnVocalizeCommand(client, const String:vocalize[], initiator)
{
	return ((g_IsGagged[client] && initiator == client) || (g_IsMuted[client] && initiator != SCENE_INITIATOR_PLUGIN) ? Plugin_Stop : Plugin_Continue)
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_TopMenuHandle)
	{
		return
	}
	
	g_TopMenuHandle = topmenu
	
	new TopMenuObject:player_commands = FindTopMenuCategory(topmenu, ADMINMENU_PLAYERCOMMANDS)
	
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(topmenu, 
		"sm_vocalizegag",
		TopMenuObject_Item,
		AdminMenu_VocalizeGag,
		player_commands,
		"sm_vocalizegag",
		ADMFLAG_CHAT)
	}
}

public AdminMenu_VocalizeGag(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Vocalize gag/mute player", param)
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayVocalizeGagPlayerMenu(param)
	}
}

DisplayVocalizeGagPlayerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_VocalizeGagPlayer)

	decl String:title[100]
	Format(title, sizeof(title), "%T:", "Vocalize gag/mute player", client)
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	AddTargetsToMenu(menu, client, true, false)

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_VocalizeGagPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_TopMenuHandle != INVALID_HANDLE)
		{
			DisplayTopMenu(g_TopMenuHandle, param1, TopMenuPosition_LastCategory)
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		new userid, target

		GetMenuItem(menu, param2, info, sizeof(info))
		userid = StringToInt(info)

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available")
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target")
		}
		else
		{
			g_AdminMenuTarget[param1] = GetClientOfUserId(userid)
			DisplayVocalizeTypesMenu(param1)
		}
	}
}

DisplayVocalizeTypesMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_VocalizeTypes)

	decl String:title[100]
	Format(title, sizeof(title), "%T: %N", "Choose Type", client, g_AdminMenuTarget[client])
	SetMenuTitle(menu, title)
	SetMenuExitBackButton(menu, true)

	new target = g_AdminMenuTarget[client]

	decl String:buffer[128]
	if (!g_IsMuted[target])
	{
		Format(buffer, sizeof(buffer), "%T", "Vocalize mute player", client)
		AddMenuItem(menu, "0", buffer)
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "Vocalize unmute player", client)
		AddMenuItem(menu, "1", buffer)
	}

	if (!g_IsGagged[target])
	{
		Format(buffer, sizeof(buffer), "%T", "Vocalize gag player", client)
		AddMenuItem(menu, "2", buffer)
	}
	else
	{
		Format(buffer, sizeof(buffer), "%T", "Vocalize ungag player", client)
		AddMenuItem(menu, "3", buffer)
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public MenuHandler_VocalizeTypes(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu)
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && g_TopMenuHandle != INVALID_HANDLE)
		{
			DisplayTopMenu(g_TopMenuHandle, param1, TopMenuPosition_LastCategory)
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32]
		new VocalizeType:type

		GetMenuItem(menu, param2, info, sizeof(info))
		type = VocalizeType:StringToInt(info)

		decl String:name[MAX_NAME_LENGTH]
		GetClientName(g_AdminMenuTarget[param1], name, sizeof(name))

		switch (type)
		{
			case VocalizeType_Mute:
			{
				g_IsMuted[g_AdminMenuTarget[param1]] = true
				LogAction(param1, g_AdminMenuTarget[param1], "\"%L\" vocalize muted \"%L\"", param1, g_AdminMenuTarget[param1])
				ShowActivity2(param1, "[SM] ", "%t", "Vocalize muted target", "_s", name)
			}
			case VocalizeType_Unmute:
			{
				g_IsMuted[g_AdminMenuTarget[param1]] = false
				LogAction(param1, g_AdminMenuTarget[param1], "\"%L\" vocalize unmuted \"%L\"", param1, g_AdminMenuTarget[param1])
				ShowActivity2(param1, "[SM] ", "%t", "Vocalize unmuted target", "_s", name)
			}
			case VocalizeType_Gag:
			{
				g_IsGagged[g_AdminMenuTarget[param1]] = true
				LogAction(param1, g_AdminMenuTarget[param1], "\"%L\" vocalize gagged \"%L\"", param1, g_AdminMenuTarget[param1])
				ShowActivity2(param1, "[SM] ", "%t", "Vocalize gagged target", "_s", name)
			}
			case VocalizeType_Ungag:
			{
				g_IsGagged[g_AdminMenuTarget[param1]] = false
				LogAction(param1, g_AdminMenuTarget[param1], "\"%L\" vocalize ungagged \"%L\"", param1, g_AdminMenuTarget[param1])
				ShowActivity2(param1, "[SM] ", "%t", "Vocalize ungagged target", "_s", name)
			}
		}
	}
}
