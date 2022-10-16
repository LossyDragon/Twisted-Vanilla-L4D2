#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

new parenting[MAXPLAYERS+1];
new bool:buttondelay[MAXPLAYERS+1];
new bool:blockattack;
new String:EntityName[MAXPLAYERS+1][64];
new bool:l4d2=false;
static Handle:sm_movableminigunblock;
static Handle:sm_movableminigunspeed;
static Handle:sm_movableminigundist;
new Float:MSpeed = 1.0;
new Float:Dist = 0.0;
new Float:clientspeed[MAXPLAYERS + 1];
public Plugin:myinfo = 
{
	name = "Movable Machine Gun",
	author = "hihi1210",
	description = "Movable Machine Gun by pressing Shift + Mouse Right Click",
	version = "1.0.6",
	url = ""
}

public OnPluginStart()
{
	decl String:stGame[32];
	GetGameFolderName(stGame, 32);
	if (StrEqual(stGame, "left4dead2", false)==true )
	{
		l4d2=true;
	}
	else if (StrEqual(stGame, "left4dead", false)==true)
	{
		l4d2=false;
	}
	else
	{
		SetFailState("Movable Machine Gun only supports L4D 1 or 2.");
	}
	CreateConVar("l4d2_moveablemachinegun", "1.0.6", "L4D Movable Machine Gun Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	sm_movableminigunblock = CreateConVar("l4d2_movablemachinegun_block", "0","Block The Attack button when moving a minigun",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	sm_movableminigundist = CreateConVar("l4d2_movablemachinegun_distance", "200.0","Block The Deploy of minigun within the range  (0.0 to disable)",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 999999999.0);
	sm_movableminigunspeed = CreateConVar("l4d2_movablemachinegun_speed", "0.8","The Walking speed when moving a minigun    1.0 = normal speed , < 0 = do not modify",FCVAR_PLUGIN|FCVAR_NOTIFY);
	RegAdminCmd("sm_minigun", SpawnMini, ADMFLAG_GENERIC, "Allows admins to spawn a minigun sm_minigun <type> 0 for l4d1 minigun 1 for l4d2 minigun");
	RegAdminCmd("sm_removeminigun", RemoveMini, ADMFLAG_GENERIC, "Remove the minigun you aimed at");
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_BotReplacedPlayer);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookConVarChange(sm_movableminigunblock, ConVarChanged_Block);
	HookConVarChange(sm_movableminigunspeed, ConVarChanged_Speed);
	HookConVarChange(sm_movableminigundist, ConVarChanged_Distance);
	AutoExecConfig( true, "l4d2_movablemachinegun");
}
public OnMapStart()
{
	if (l4d2)
	{
		PrecacheModel("models/w_models/weapons/50cal.mdl", true);
	}
	PrecacheModel("models/w_models/weapons/w_minigun.mdl", true);
}
public OnConfigsExecuted()
{
	blockattack = GetConVarBool(sm_movableminigunblock);
	MSpeed = GetConVarFloat(sm_movableminigunspeed);
	Dist = GetConVarFloat(sm_movableminigundist);
}
public ConVarChanged_Block(Handle:convar, const String:oldValue[], const String:newValue[])
{
	blockattack = GetConVarBool(sm_movableminigunblock);
}
public ConVarChanged_Speed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MSpeed = GetConVarFloat(sm_movableminigunspeed);
}
public ConVarChanged_Distance(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Dist = GetConVarFloat(sm_movableminigundist);
}
public OnClientPutInServer(client)
{
	clientspeed[client] =1.0;
	SDKHook(client, SDKHook_PreThink, PreThink);
	SDKHook(client, SDKHook_PostThink, PostThink);
}
public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "prop_minigun")||StrEqual(classname, "prop_minigun_l4d1"))
	{
		SDKHook(entity, SDKHook_Use, OnEntityUse);
	}
}
public Action:OnEntityUse(entity, activator, caller, UseType:type, Float:value)
{
	if (type ==Use_Toggle)
	{
		PrintToChat(caller,"\x01[\x03MMG\x01]\x03You can move the Minigun by \x04Aiming the minigun\x03 and Pressing \x04Shift + Mouse Right Click \x03Button Together");
	}
}
stock FindEntityByClassname2(startEnt, const String:classname[])
{
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	
	return FindEntityByClassname(startEnt, classname);
}
public PreThink(client)
{
	if (blockattack)
	{
		new iButtons = GetClientButtons(client);
		if (parenting[client]!=0)
		{
			if(iButtons & IN_ATTACK)
			{
				iButtons &= ~IN_ATTACK;
				SetEntProp(client, Prop_Data, "m_nButtons", iButtons);
			}
		}
	}
}
public PostThink(client)
{
	new buttons = GetClientButtons(client);
	if (IsDedicatedServer() && client ==0 || client < 0) return;
	if (!IsClientConnected(client)) return;
	if (!IsClientInGame(client)) return;
	if (IsFakeClient(client)) return;
	if (GetClientTeam(client)!=2) return;
	if (buttons & IN_SPEED && buttons & IN_ATTACK2)
	{
		if (buttondelay[client]) return;
		buttondelay[client]=true;
		CreateTimer(1.0,ResetDelay,client);
		if (parenting[client]!=0)
		{
			if (!(GetEntityFlags(client) & (FL_ONGROUND))) return;	
			if (Dist >0.0)
			{
				decl Float:PVec[3];
				decl Float:MVec[3];
				GetClientAbsOrigin(client, PVec);
				new gun = -1;
				while ((gun = FindEntityByClassname2(gun, "prop_minigun")) != -1)
				{
					GetEntPropVector(gun, Prop_Data, "m_vecOrigin", MVec);
					if (GetVectorDistance(PVec, MVec)<= Dist)
					{
						PrintToChat(client,"\x01[\x03MMG\x01]\x03You are too close to another machine gun, stay away from it to deploy your machine gun (%f/%f)",GetVectorDistance(PVec, MVec),Dist);
						return;
					}
				}
				if (l4d2)
				{
					gun = -1;
					while ((gun = FindEntityByClassname2(gun, "prop_minigun_l4d1")) != -1)
					{
						GetEntPropVector(gun, Prop_Data, "m_vecOrigin", MVec);
						if (GetVectorDistance(PVec, MVec)<= Dist)
						{
							PrintToChat(client,"\x01[\x03MMG\x01]\x03You are too close to another machine gun, stay away from it to deploy your machine gun (%f/%f)",GetVectorDistance(PVec, MVec),Dist);
							return;
						}
					}
				}
			}
			if (IsValidEntRef(parenting[client]))
			{
				AcceptEntityInput(parenting[client], "kill");
			}
			parenting[client]=0;
			if (StrEqual(EntityName[client], "prop_minigun") )
			{
				if (!l4d2)
				{
					CreateMiniGun(client,0);
				}
				else
				{
					CreateMiniGun(client,1);
				}
			}
			else
			{
				CreateMiniGun(client,0);
			}
			Format(EntityName[client], 64, "");
			if (MSpeed >=0.0 )
			{
				new Float:cspeed;
				cspeed = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
				if (cspeed == MSpeed)
				{
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", clientspeed[client]);
				}
			}
			return;
		}
		new target = GetClientAimTarget(client,false);
		decl String:model[128];
		decl String:item[64];
		if(target != -1) {
			if (IsValidEntRef(target))
			{
				decl Float:PlayerVec[3];
				GetClientAbsOrigin(client, PlayerVec);
				decl Float:LockerVec[3];
				GetEntPropVector(target, Prop_Data, "m_vecOrigin", LockerVec);
				if (GetVectorDistance(PlayerVec, LockerVec) <= 100)
				{
					GetEntPropString(target, Prop_Data, "m_ModelName", model, sizeof(model));
					GetEdictClassname(target, item, sizeof(item));
					if (StrEqual(item, "prop_minigun") || StrEqual(item, "prop_minigun_l4d1") )
					{
						new Owner=GetEntPropEnt(target, Prop_Send, "m_owner");
						if (Owner ==0 && IsDedicatedServer() || Owner <0 ||Owner > GetMaxClients())
						{
							Format(EntityName[client], 64, item);
							if (parenting[client]!=0) return;
							AcceptEntityInput(target, "kill");
							decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
							new index = CreateEntityByName ( "prop_dynamic");
							if (index == -1)
							{
								ReplyToCommand(client, "[SM] Failed to create minigun!");
								return;
							}
							if (StrEqual(item, "prop_minigun") )
							{
								if (l4d2)
								{
									SetEntityModel (index, "models/w_models/weapons/50cal.mdl");
								}
								else
								{
									SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
								}
							}
							else
							{
								SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
							}
							DispatchSpawn(index);
							GetClientAbsOrigin(client, VecOrigin);
							GetClientEyeAngles(client, VecAngles);
							GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
							VecOrigin[0] += VecDirection[0] * 32;
							VecOrigin[1] += VecDirection[1] * 32;
							VecOrigin[2] += VecDirection[2] * 1;   
							VecAngles[0] = 0.0;
							VecAngles[2] = 0.0;
							DispatchKeyValueVector(index, "Angles", VecAngles);
							TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
							SetEntProp(index, Prop_Data, "m_CollisionGroup", 2);
							SetEntityRenderMode(index, RenderMode:3);
							SetEntityRenderColor(index, 255, 0, 0, 150);
							decl String:sTemp[64];
							Format(sTemp, sizeof(sTemp), "mmg%d%d", index, client);
							DispatchKeyValue(client, "targetname", sTemp);
							SetVariantString(sTemp);
							AcceptEntityInput(index, "SetParent", index, index, 0);
							SetVariantString("eyes");
							AcceptEntityInput(index, "SetParentAttachment");
							VecOrigin[0]=0.0;
							VecOrigin[1]=0.0;
							VecOrigin[2]=-10.0;
							TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
							parenting[client]=index;
							if (MSpeed >=0.0)
							{
								clientspeed[client] = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");
								SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", MSpeed);
							}
							return;
						}
					}
				}
			}
		}
	}
	return;
}
public Action:SpawnMini(client, args) 
{
	if (IsDedicatedServer() && client ==0 ) return Plugin_Continue;
	new type;
	decl String:types[32];
	if (args ==1)
	{
		GetCmdArg(1, types, sizeof(types));
		type = StringToInt(types);
	}
	else
	{
		type=GetRandomInt(0,1)
	}
	if (!l4d2)
	{
		type = 0;
	}
	CreateMiniGun(client,type);
	return Plugin_Continue;
}
public Action:RemoveMini(client, args) 
{
	if (IsDedicatedServer() && client ==0 ) return Plugin_Continue;
	new target = GetClientAimTarget(client,false);
	decl String:item[64];
	if(target != -1) {
		if (IsValidEntRef(target))
		{
			GetEdictClassname(target, item, sizeof(item));
			if (StrEqual(item, "prop_minigun") || StrEqual(item, "prop_minigun_l4d1") )
			{
				AcceptEntityInput(target, "kill");
			}
		}
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new iCid=1; iCid<=GetMaxClients(); iCid++)
	{
		if (parenting[iCid] !=0)
		{
			if( IsValidEntRef(parenting[iCid] ))
			AcceptEntityInput(parenting[iCid], "kill");
		}
		parenting[iCid]=0;
		Format(EntityName[iCid], 64, "");
	}
	return Plugin_Continue;
}
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsDedicatedServer() && client ==0 || client < 0) return Plugin_Continue;
	if (client >GetMaxClients()) return Plugin_Continue;
	if (parenting[client]!=0)
	{
		if (IsValidEntRef(parenting[client]))
		{
			AcceptEntityInput(parenting[client], "kill");
		}
		parenting[client]=0;
		Format(EntityName[client], 64, "");
	}
	return Plugin_Continue;
}
CreateMiniGun(client,type)
{
	new index;
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3];
	if (type == 1)
	{
		index = CreateEntityByName ("prop_minigun");
	}
	else if (type == 0)
	{
		if (!l4d2)
		{
			index = CreateEntityByName ("prop_minigun");
		}
		else
		{
			index = CreateEntityByName ("prop_minigun_l4d1");
		}
		
	}
	if (index == -1)
	{
		ReplyToCommand(client, "[SM] Failed to create minigun!");
		return;
	}
	DispatchKeyValue(index, "model", "Minigun_1");
	
	if (type==1)
	{
		SetEntityModel (index, "models/w_models/weapons/50cal.mdl");
	}
	else if (type==0)
	{
		SetEntityModel (index, "models/w_models/weapons/w_minigun.mdl");
	}


	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 90.00);
	DispatchSpawn(index);
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 32;
	VecOrigin[1] += VecDirection[1] * 32;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	DispatchSpawn(index);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	return;
}
public Action:Event_BotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsDedicatedServer() && client ==0 || client < 0) return Plugin_Continue;
	if (client >GetMaxClients()) return Plugin_Continue;
	if (parenting[client]!=0)
	{
		if (IsValidEntRef(parenting[client]))
		{
			AcceptEntityInput(parenting[client], "kill");
		}
		parenting[client]=0;
		if (StrEqual(EntityName[client], "prop_minigun") )
		{
			if (!l4d2)
			{
				CreateMiniGun(bot,0);
			}
			else
			{
				CreateMiniGun(bot,1);
			}
		}
		else
		{
			CreateMiniGun(bot,0);
		}
		if (MSpeed >=0.0 )
		{
			new Float:cspeed;
			cspeed = GetEntPropFloat(bot, Prop_Data, "m_flLaggedMovementValue");
			if (cspeed == MSpeed)
			{
				SetEntPropFloat(bot, Prop_Data, "m_flLaggedMovementValue", 1.0);
			}
		}
		Format(EntityName[client], 64, "");
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
bool:IsValidEntRef(iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
	return true;
	return false;
}

public Action:ResetDelay(Handle:Timer, any:client)
{
	buttondelay[client]=false;
}

