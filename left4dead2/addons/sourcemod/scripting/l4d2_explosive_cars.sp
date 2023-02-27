#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define GETVERSION "1.0.4"
#define ARRAY_SIZE 2150

#define TEST_DEBUG 		0
#define TEST_DEBUG_LOG 	0
#define DEBUG 0

static const String:FIRE_PARTICLE[] = 		"gas_explosion_ground_fire";
static const String:EXPLOSION_PARTICLE[] = 	"weapon_pipebomb";
static const String:EXPLOSION_PARTICLE2[] = "weapon_grenade_explosion";
static const String:EXPLOSION_PARTICLE3[] = "explosion_huge_b";
static const String:EXPLOSION_SOUND[] = 	"ambient/explosions/explode_1.wav";
static const String:EXPLOSION_SOUND2[] = 	"ambient/explosions/explode_2.wav";
static const String:EXPLOSION_SOUND3[] = 	"ambient/explosions/explode_3.wav";
static const String:DAMAGE_WHITE_SMOKE[] = 	"minigun_overheat_smoke";
static const String:DAMAGE_BLACK_SMOKE[] = 	"smoke_burning_engine_01";
static const String:DAMAGE_FIRE_SMALL[] = 	"burning_engine_01";
static const String:DAMAGE_FIRE_HUGE[] = 	"fire_window_hotel2";
static const String:FIRE_SOUND[] = 			"ambient/fire/fire_med_loop1.wav";

new bool:g_bLowWreck[ARRAY_SIZE] = false;
new bool:g_bMidWreck[ARRAY_SIZE] = false;
new bool:g_bHighWreck[ARRAY_SIZE] = false;
new bool:g_bCritWreck[ARRAY_SIZE] = false;
new bool:g_bExploded[ARRAY_SIZE] = false;
new bool:g_bHooked[ARRAY_SIZE] = false;
new g_iEntityDamage[ARRAY_SIZE] = 0;
new g_iParticle[ARRAY_SIZE] = -1;

new bool:g_bDisabled = false;
new bool:g_bFindCars = false;

new Handle:g_hGameConf = INVALID_HANDLE;
new Handle:sdkCallPushPlayer = INVALID_HANDLE;
new Handle:g_cvarMaxHealth = INVALID_HANDLE;
new Handle:g_cvarRadius = INVALID_HANDLE;
new Handle:g_cvarPower = INVALID_HANDLE;
new Handle:g_cvarTrace = INVALID_HANDLE;
new Handle:g_cvarPanic = INVALID_HANDLE;
new Handle:g_cvarPanicChance = INVALID_HANDLE;
new Handle:g_cvarInfected = INVALID_HANDLE;
new Handle:g_cvarTankDamage = INVALID_HANDLE;
new Handle:g_cvarBurnTimeout = INVALID_HANDLE;
new Handle:g_cvarUnload = INVALID_HANDLE;
new Handle:g_cvarExplosionDmg = INVALID_HANDLE;
new Handle:g_cvarFireDmgInterval = INVALID_HANDLE;
new Handle:g_cvarDamage = INVALID_HANDLE;
new Handle:g_cvarCarFlyMax = INVALID_HANDLE;
new Handle:g_cvarCarFlyMin = INVALID_HANDLE;
new Handle:g_cvarSelfHurt = INVALID_HANDLE;
new Handle:g_cvarInfernoNum = INVALID_HANDLE;
new Handle:g_cvarFireMulti = INVALID_HANDLE;
new Handle:g_cvarExploMulti = INVALID_HANDLE;

new Handle:g_hForward_CarExplode = INVALID_HANDLE;
new Handle:g_tBurning[ARRAY_SIZE+1] = INVALID_HANDLE;
new Handle:sdkDetonateFire = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[L4D2] Explosive Cars",
	author = "honorcode23",
	description = "Cars explode after they take some damage",
	version = GETVERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=138644"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(late)
	{
		g_bFindCars = true;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	//Left 4 dead 2 only
	decl String:sGame[256];
	GetGameFolderName(sGame, sizeof(sGame));
	if (!StrEqual(sGame, "left4dead2", false))
	{
		SetFailState("Explosive Cars supports Left 4 dead 2 only!");
	}
	
	//Convars
	CreateConVar("l4d2_explosive_cars_version", GETVERSION, "Version of the [L4D2] Explosive Cars plugin", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvarMaxHealth = CreateConVar("l4d2_explosive_cars_health", "5000", "Maximum health of the cars", FCVAR_PLUGIN);
	g_cvarRadius = CreateConVar("l4d2_explosive_cars_radius", "420", "Maximum radius of the explosion", FCVAR_PLUGIN);
	g_cvarPower = CreateConVar("l4d2_explosive_cars_power", "300", "Power of the explosion when the car explodes", FCVAR_PLUGIN);
	g_cvarDamage = CreateConVar("l4d2_explosive_cars_damage", "100", "Damage made by the explosion", FCVAR_PLUGIN);
	g_cvarTrace = CreateConVar("l4d2_explosive_cars_trace", "25", "Time before the fire trace left by the explosion expires", FCVAR_PLUGIN);
	g_cvarPanic = CreateConVar("l4d2_explosive_cars_panic", "1", "Should the car explosion cause a panic event? (1: Yes 0: No)", FCVAR_PLUGIN);
	g_cvarPanicChance = CreateConVar("l4d2_explosive_cars_panic_chance", "100", "Chance that the cars explosion might call a horde (%)", FCVAR_PLUGIN);
	g_cvarInfected = CreateConVar("l4d2_explosive_cars_infected", "1", "Should infected trigger the car explosion? (1: Yes 0: No)", FCVAR_PLUGIN);
	g_cvarTankDamage = CreateConVar("l4d2_explosive_cars_tank", "0", "How much damage do the tank deal to the cars? (0: Default, which is 999 from the engine)", FCVAR_PLUGIN);
	g_cvarBurnTimeout = CreateConVar("l4d2_explosive_cars_burntime", "0", "Time to wait before stopping the fire on the exploded car (0: Don't stop)", FCVAR_PLUGIN);
	g_cvarUnload = CreateConVar("l4d2_explosive_cars_unload", "none", "On which maps should the plugin disable itself? (Example: c5m3_cemetery, c5m5_bridge, cmdd_custom)", FCVAR_PLUGIN);
	g_cvarExplosionDmg = CreateConVar("l4d2_explosive_cars_explosion_damage", "1", "Should cars get damaged by another car's explosion?", FCVAR_PLUGIN);
	g_cvarFireDmgInterval = CreateConVar("l4d2_explosive_cars_trace_interval", "0.4", "How often should the fire trace left by the explosion hurt?", FCVAR_PLUGIN);
	g_cvarCarFlyMax = CreateConVar("l4d2_explosive_cars_car_max_height", "2500", "Maximum power when the car is launched", FCVAR_PLUGIN);
	g_cvarCarFlyMin = CreateConVar("l4d2_explosive_cars_car_min_height", "1000", "Minimum power when the car is launched", FCVAR_PLUGIN);
	g_cvarSelfHurt = CreateConVar("l4d2_explosive_cars_fire_selfdamage", "0", "Should the car get damage from its own fire before it explodes? This will eventually end in a explosion", FCVAR_PLUGIN);
	g_cvarInfernoNum = CreateConVar("l4d2_explosive_cars_inferno_count", "2", "How many extra infernos (fire) should be created upon explosion?", FCVAR_PLUGIN);
	g_cvarFireMulti = CreateConVar("l4d2_explosive_cars_fire_multiplier", "2.42", "Multiplier of the damage received by the car from fire (Note: Normal is 8 damage per 0.5 secs)", FCVAR_PLUGIN);
	g_cvarExploMulti = CreateConVar("l4d2_explosive_cars_explosion_multiplier", "45.67", "Multiplier of the damage received by the car from explosions (Pipe bombs, grenade launcher, propane tanks, etc) (Note: Normal is 15-20 damage per shot)", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d2_explosive_cars");
	
	//Events
	HookEvent("round_start_post_nav", Event_RoundStart);
	
	//DEV
	RegAdminCmd("sm_fire", CmdFire, ADMFLAG_ROOT, "Simulates car explosion inferno");
	
	//Signatures
	g_hGameConf = LoadGameConfigFile("l4d2explosivecars");
	if(g_hGameConf == INVALID_HANDLE)
	{
		SetFailState("Unable to find the signatures file. Make sure it is on the 'gamedata' folder");
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CTerrorPlayer_Fling");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	sdkCallPushPlayer = EndPrepSDKCall();
	if(sdkCallPushPlayer == INVALID_HANDLE)
	{
		SetFailState("Unable to find the 'CTerrorPlayer_Fling' signature, check the file version!");
	}
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CMolotovProjectile_Create");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	sdkDetonateFire = EndPrepSDKCall();
	if(sdkDetonateFire == INVALID_HANDLE)
	{
		SetFailState("Unable to find the \"CMolotovProjectile::Detonate(void)\" signature, check the file version!");
	}
	
	if(g_bFindCars)
	{
		FindMapCars();
	}
	g_bFindCars = false;
	
	g_hForward_CarExplode = CreateGlobalForward("OnCarExploded", ET_Event, Param_Cell, Param_Cell);
}

public Action:CmdFire(client, args)
{
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	CreateInferno(client, pos);
	return Plugin_Handled;
}

public OnMapStart()
{
	g_bDisabled = false;
	decl String:sCurrentMap[64], String:sCvarMap[256];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	GetConVarString(g_cvarUnload, sCvarMap, sizeof(sCvarMap));
	if(StrContains(sCvarMap, sCurrentMap) >= 0)
	{
		LogMessage("[Unload] Plugin disabled for this map");
		g_bDisabled = true;
	}
	if(!IsModelPrecached("sprites/muzzleflash4.vmt"))
	{
		PrecacheModel("sprites/muzzleflash4.vmt");
	}
	PrecacheParticle(EXPLOSION_PARTICLE);
	PrecacheParticle(EXPLOSION_PARTICLE2);
	PrecacheParticle(EXPLOSION_PARTICLE3);
	PrecacheParticle(FIRE_PARTICLE);
	PrecacheParticle(DAMAGE_WHITE_SMOKE);
	PrecacheParticle(DAMAGE_BLACK_SMOKE);
	PrecacheParticle(DAMAGE_FIRE_SMALL);
	PrecacheParticle(DAMAGE_FIRE_HUGE);
	for(new i =1 ; i <= ARRAY_SIZE; i++)
	{
		g_tBurning[i] = INVALID_HANDLE;
	}
}

public Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_bDisabled)
	{
		return;
	}
	for(new i=1; i<ARRAY_SIZE; i++)
	{
		g_iEntityDamage[i] = 0;
		g_bLowWreck[i] = false;
		g_bMidWreck[i] = false;
		g_bHighWreck[i] = false;
		g_bCritWreck[i] = false;
		g_bHooked[i] = false;
		g_bExploded[i] = false;
		g_iParticle[i] = -1;
	}
}

//Thanks to AtomicStryker
static FindMapCars()
{
	if(g_bDisabled)
	{
		return;
	}
	new maxEnts = GetMaxEntities();
	decl String:classname[128], String:model[256];
	
	for (new i = MaxClients; i < maxEnts; i++)
	{
		if (!IsValidEdict(i)) continue;
		
		GetEdictClassname(i, classname, sizeof(classname));
		
		if(StrEqual(classname, "prop_physics")
		|| StrEqual(classname, "prop_physics_override"))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model))
			if(StrContains(model, "vehicle", false) != -1 && !g_bHooked[i])
			{
				g_bHooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", i, classname);
			}
		}
		else if(StrEqual(classname, "prop_car_alarm"))
		{
			GetEntPropString(i, Prop_Data, "m_ModelName", model, sizeof(model))
			if(StrContains(model, "vehicle", false) != -1 && !g_bHooked[i])
			{
				g_bHooked[i] = true;
				SDKHook(i, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
				DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", i, classname);
			}
		}
	}
}

public OnEntityDestroyed(entity)
{
	if(g_bDisabled)
	{
		return;
	}
	if(entity > 0 && entity < ARRAY_SIZE)
	{
		g_bHooked[entity] = false;
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(g_bDisabled)
	{
		return;
	}
	if(StrEqual(classname, "prop_physics") || StrEqual(classname, "prop_physics_override") && !g_bHooked[entity])
	{
		CreateTimer(0.1, timerCheckHook, entity, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if(StrEqual(classname, "prop_car_alarm") && !g_bHooked[entity])
	{
		SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
		g_bHooked[entity] = true;
		DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i, class %s", entity, classname);
	}
	
	#if DEBUG
	if(StrEqual(classname, "molotov_projectile"))
	{
		PrintToChatAll("\x05[DEBUG] \x01Molotov Projectile Created");
		PrintToChatAll("\x05[DEBUG] \x01Comencing Dump");
		PrintToChatAll("\x05[DEBUG] \x01m_flDamage -> %f", GetEntPropFloat(entity, Prop_Send, "m_flDamage"));
		PrintToChatAll("\x05[DEBUG] \x01m_DmgRadius -> %f", GetEntPropFloat(entity, Prop_Send, "m_DmgRadius"));
		PrintToChatAll("\x05[DEBUG] \x01m_bIsLive -> %b", GetEntProp(entity, Prop_Send, "m_bIsLive"));
		PrintToChatAll("\x05[DEBUG] \x01m_fFlags -> %i", GetEntProp(entity, Prop_Send, "m_fFlags"));
		CreateTimer(0.1, timerCheckChanges, entity);
	}
	#endif
	
}

public Action:timerCheckChanges(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		PrintToChatAll("\x05[POST] \x01Molotov Projectile Created");
		PrintToChatAll("\x05[POST] \x01Comencing Dump");
		PrintToChatAll("\x05[POST] \x01m_flDamage -> %f", GetEntPropFloat(entity, Prop_Send, "m_flDamage"));
		PrintToChatAll("\x05[POST] \x01m_DmgRadius -> %f", GetEntPropFloat(entity, Prop_Send, "m_DmgRadius"));
		PrintToChatAll("\x05[POST] \x01m_bIsLive -> %b", GetEntProp(entity, Prop_Send, "m_bIsLive"));
		PrintToChatAll("\x05[POST] \x01m_fFlags -> %i", GetEntProp(entity, Prop_Send, "m_fFlags"));
	}
}

public Action:timerCheckHook(Handle:timer, any:entity)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEntity(entity))
	{
		decl String:model[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model))
		if(StrContains(model, "vehicle", false) != -1)
		{
			SDKHook(entity, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
			g_bHooked[entity] = true;
			DebugPrintToAll("Activated Explosive Car Damage Hook on entity %i", entity);
		}
	}
}

public OnTakeDamagePost(victim, attacker, inflictor, Float:damage, damagetype)
{
	if(g_bDisabled)
	{
		return;
	}
	decl String:class[256];
	GetEdictClassname(inflictor, class, sizeof(class));
	
	new MaxDamageHandle = GetConVarInt(g_cvarMaxHealth)/5;
	
	if(StrEqual(class, "weapon_melee"))
	{
		damage = 5.0;
	}
	else if(StrEqual(class, "env_explosion") && !GetConVarBool(g_cvarExplosionDmg))
	{
		damage = 0.0;
	}
	else if((StrEqual(class, "player") && attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 3) && !GetConVarBool(g_cvarInfected))
	{
		damage = 0.0;
	}
	else if(StrEqual(class, "tank_rock") || StrEqual(class, "weapon_tank_claw"))
	{
		if(!GetConVarBool(g_cvarInfected))
		{
			damage = 0.0;
		}
		new Float:tank_damage = GetConVarFloat(g_cvarTankDamage)
		if(tank_damage > 0.0 && GetConVarBool(g_cvarInfected))
		{
			damage = tank_damage;
		}
	}
	else if(StrEqual(class, "inferno") || (StrEqual(class, "trigger_hurt") && (damagetype == 8 || damagetype == 2056)))
	{
		damage*=GetConVarFloat(g_cvarFireMulti);
	}
	else if(StrEqual(class, "pipe_bomb_projectile") || StrEqual(class, "grenade_launcher_projectile"))
	{
		damage*=GetConVarFloat(g_cvarExploMulti);
	}
	
	g_iEntityDamage[victim]+= RoundToFloor(damage);
	new tdamage = g_iEntityDamage[victim];
	//PrintHintTextToAll("%i damaged by <%N>(%i) (inflictor: <%s>%d) for %f damage (Type: %d)", victim, attacker, attacker, class, inflictor, damage, damagetype);
	
	if(tdamage >= MaxDamageHandle
	&& tdamage < MaxDamageHandle*2
	&& !g_bLowWreck[victim])
	{
		g_bLowWreck = true;
		AttachParticle(victim, DAMAGE_WHITE_SMOKE);
	}
	else if(tdamage >= MaxDamageHandle*2
	&& tdamage < MaxDamageHandle*3
	&& !g_bMidWreck[victim])
	{
		g_bMidWreck = true;
		AttachParticle(victim, DAMAGE_BLACK_SMOKE);
	}
	
	else if(tdamage >= MaxDamageHandle*3
	&& tdamage < MaxDamageHandle*4
	&& !g_bHighWreck[victim])
	{
		g_bHighWreck = true;
		if(!IsSoundPrecached(FIRE_SOUND))
		{
			PrecacheSound(FIRE_SOUND);
		}
		EmitSoundToAll(FIRE_SOUND, victim);
		AttachParticle(victim, DAMAGE_FIRE_SMALL);
		if(GetConVarBool(g_cvarSelfHurt))
		{
			if(g_tBurning[victim] == INVALID_HANDLE)
			{
				g_tBurning[victim] = CreateTimer(0.2, timerHurtCar, victim, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
	
	else if(tdamage >= MaxDamageHandle*4
	&& tdamage < MaxDamageHandle*5
	&& !g_bCritWreck[victim])
	{
		g_bCritWreck = true;
		AttachParticle(victim, DAMAGE_FIRE_HUGE);
	}
	
	else if(tdamage > MaxDamageHandle*5
	&& !g_bExploded[victim])
	{
		g_bExploded[victim] = true;
		decl Float:carPos[3];
		GetEntPropVector(victim, Prop_Data, "m_vecOrigin", carPos);
		if(attacker > MaxClients)
		{
			attacker = 0;
		}
		CreateExplosion(carPos, attacker);
		EditCar(victim);
		LaunchCar(victim);
		Forward_CarExplode(attacker, victim);
	}
}

public Action:timerHurtCar(Handle:timer, any:car)
{
	g_tBurning[car] = INVALID_HANDLE;
	if(!IsValidEntity(car) || g_bExploded[car])
	{
		return;
	}
	new damage = 8;
	decl String:sDamage[11], String:sTarget[16];
	IntToString(damage, sDamage, sizeof(sDamage));
	IntToString(car+25, sTarget, sizeof(sTarget));
	new iDmgEntity = CreateEntityByName("point_hurt");
	DispatchKeyValue(car, "targetname", sTarget);
	DispatchKeyValue(iDmgEntity, "DamageTarget", sTarget);
	DispatchKeyValue(iDmgEntity, "Damage", sDamage);
	DispatchKeyValue(iDmgEntity, "DamageType", "8");
	DispatchSpawn(iDmgEntity);
	AcceptEntityInput(iDmgEntity, "Hurt", car);
	RemoveEdict(iDmgEntity);
	if(g_tBurning[car] == INVALID_HANDLE)
	{
		g_tBurning[car] = CreateTimer(0.2, timerHurtCar, car, TIMER_FLAG_NO_MAPCHANGE);
	}
}

stock EditCar(car)
{
	SetEntityRenderColor(car, 0, 0, 0, 255);
	decl String:sModel[256];
	GetEntPropString(car, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if(StrEqual(sModel, "models/props_vehicles/cara_82hatchback.mdl"))
	{
		if(!IsModelPrecached("models/props_vehicles/cara_82hatchback_wrecked.mdl"))
		{
			PrecacheModel("models/props_vehicles/cara_82hatchback_wrecked.mdl");
		}
		SetEntityModel(car, "models/props_vehicles/cara_82hatchback_wrecked.mdl");
	}
	else if(StrEqual(sModel, "models/props_vehicles/cara_95sedan.mdl"))
	{
		if(!IsModelPrecached("models/props_vehicles/cara_95sedan_wrecked.mdl"))
		{
			PrecacheModel("models/props_vehicles/cara_95sedan_wrecked.mdl");
		}
		SetEntityModel(car, "models/props_vehicles/cara_95sedan_wrecked.mdl");
	}
}

stock LaunchCar(car)
{
	if(g_bDisabled)
	{
		return;
	}
	decl Float:vel[3];
	GetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
	vel[0]+= GetRandomFloat(50.0, 300.0);
	vel[1]+= GetRandomFloat(50.0, 300.0);
	vel[2]+= GetRandomFloat(GetConVarFloat(g_cvarCarFlyMin), GetConVarFloat(g_cvarCarFlyMax));
	
	TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	CreateTimer(2.5, timerNormalVelocity, car, TIMER_FLAG_NO_MAPCHANGE);
	new Float:burnTime = GetConVarFloat(g_cvarBurnTimeout);
	if(burnTime > 0.0)
	{
		CreateTimer(burnTime, timerRemoveCarFire, car, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerNormalVelocity(Handle:timer, any:car)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEntity(car))
	{
		new Float:vel[3];
		SetEntPropVector(car, Prop_Data, "m_vecVelocity", vel);
		TeleportEntity(car, NULL_VECTOR, NULL_VECTOR, vel);
	}
}

public Action:timerRemoveCarFire(Handle:timer, any:car)
{
	if(g_bDisabled)
	{
		return;
	}
	new Particle = g_iParticle[car];
	if(Particle > 0 && IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}

stock CreateExplosion(Float:carPos[3], attacker = 0)
{
	if(g_bDisabled)
	{
		return;
	}
	decl String:sRadius[16], String:sPower[16], String:sDamage[11], String:sInterval[11];
	new Float:flMxDistance = GetConVarFloat(g_cvarRadius);
	new Float:power = GetConVarFloat(g_cvarPower);
	new iDamage = GetConVarInt(g_cvarDamage);
	new Float:flInterval = GetConVarFloat(g_cvarFireDmgInterval);
	FloatToString(flInterval, sInterval, sizeof(sInterval));
	IntToString(GetConVarInt(g_cvarRadius), sRadius, sizeof(sRadius));
	IntToString(GetConVarInt(g_cvarPower), sPower, sizeof(sPower));
	IntToString(iDamage, sDamage, sizeof(sDamage));
	new exParticle2 = CreateEntityByName("info_particle_system");
	new exParticle3 = CreateEntityByName("info_particle_system");
	new exTrace = CreateEntityByName("info_particle_system");
	new exPhys = CreateEntityByName("env_physexplosion");
	new exHurt = CreateEntityByName("point_hurt");
	new exParticle = CreateEntityByName("info_particle_system");
	new exEntity = CreateEntityByName("env_explosion");
	/*new exPush = CreateEntityByName("point_push");*/
	
	//Set up the particle explosion
	DispatchKeyValue(exParticle, "effect_name", EXPLOSION_PARTICLE);
	DispatchSpawn(exParticle);
	ActivateEntity(exParticle);
	TeleportEntity(exParticle, carPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle2, "effect_name", EXPLOSION_PARTICLE2);
	DispatchSpawn(exParticle2);
	ActivateEntity(exParticle2);
	TeleportEntity(exParticle2, carPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exParticle3, "effect_name", EXPLOSION_PARTICLE3);
	DispatchSpawn(exParticle3);
	ActivateEntity(exParticle3);
	TeleportEntity(exParticle3, carPos, NULL_VECTOR, NULL_VECTOR);
	
	DispatchKeyValue(exTrace, "effect_name", FIRE_PARTICLE);
	DispatchSpawn(exTrace);
	ActivateEntity(exTrace);
	TeleportEntity(exTrace, carPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up explosion entity
	DispatchKeyValue(exEntity, "fireballsprite", "sprites/muzzleflash4.vmt");
	DispatchKeyValue(exEntity, "iMagnitude", "150");
	DispatchKeyValue(exEntity, "iRadiusOverride", sRadius);
	DispatchKeyValue(exEntity, "spawnflags", "828");
	DispatchSpawn(exEntity);
	TeleportEntity(exEntity, carPos, NULL_VECTOR, NULL_VECTOR);
	
	//Set up physics movement explosion
	DispatchKeyValue(exPhys, "radius", sRadius);
	DispatchKeyValue(exPhys, "magnitude", sPower);
	DispatchSpawn(exPhys);
	TeleportEntity(exPhys, carPos, NULL_VECTOR, NULL_VECTOR);
	
	
	//Set up hurt point
	DispatchKeyValue(exHurt, "DamageRadius", sRadius);
	DispatchKeyValue(exHurt, "DamageDelay", sInterval);
	DispatchKeyValue(exHurt, "Damage", "1");
	DispatchKeyValue(exHurt, "DamageType", "8");
	DispatchSpawn(exHurt);
	TeleportEntity(exHurt, carPos, NULL_VECTOR, NULL_VECTOR);
	
	CreateInferno(attacker, carPos);
	new iInfernos = GetConVarInt(g_cvarInfernoNum);
	for(new i = 1; i <= iInfernos; i++)
	{
		CreateInferno(attacker, carPos);
	}
	
	switch(GetRandomInt(1,3))
	{
		case 1:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND))
			{
				PrecacheSound(EXPLOSION_SOUND);
			}
			EmitSoundToAll(EXPLOSION_SOUND);
		}
		case 2:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND2))
			{
				PrecacheSound(EXPLOSION_SOUND2);
			}
			EmitSoundToAll(EXPLOSION_SOUND2);
		}
		case 3:
		{
			if(!IsSoundPrecached(EXPLOSION_SOUND3))
			{
				PrecacheSound(EXPLOSION_SOUND3);
			}
			EmitSoundToAll(EXPLOSION_SOUND3);
		}
	}
	
	if(GetConVarBool(g_cvarPanic))
	{
		new luck = GetConVarInt(g_cvarPanicChance);
		if(GetRandomInt(1, 100) <= luck)
		{
			PanicEvent();
			PrintToChatAll("\x04[SM] \x03The car triggered a panic event, get ready!");
			PrintHintTextToAll("\x04[SM] \x03The car triggered a panic event, get ready!");
			//ClientCommandAll("play music/the_end/finalnail.wav");
		}
	}
	
	//BOOM!
	AcceptEntityInput(exParticle, "Start");
	AcceptEntityInput(exParticle2, "Start");
	AcceptEntityInput(exParticle3, "Start");
	AcceptEntityInput(exTrace, "Start");
	AcceptEntityInput(exEntity, "Explode");
	AcceptEntityInput(exPhys, "Explode");
	AcceptEntityInput(exHurt, "TurnOn");
	
	new Handle:pack2 = CreateDataPack();
	WritePackCell(pack2, exParticle);
	WritePackCell(pack2, exParticle2);
	WritePackCell(pack2, exParticle3);
	WritePackCell(pack2, exTrace);
	WritePackCell(pack2, exEntity);
	WritePackCell(pack2, exPhys);
	WritePackCell(pack2, exHurt);
	CreateTimer(GetConVarFloat(g_cvarTrace)+1.5, timerDeleteParticles, pack2, TIMER_FLAG_NO_MAPCHANGE);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, exTrace);
	WritePackCell(pack, exHurt);
	CreateTimer(GetConVarFloat(g_cvarTrace), timerStopFire, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	decl Float:survivorPos[3], Float:traceVec[3], Float:resultingFling[3], Float:currentVelVec[3];
	for(new i=1; i<=MaxClients; i++)
	{
		if(!IsClientInGame(i) || !IsPlayerAlive(i))
		{
			continue;
		}

		GetEntPropVector(i, Prop_Data, "m_vecOrigin", survivorPos);
		
		//Vector and radius distance calcs by AtomicStryker!
		if(GetVectorDistance(carPos, survivorPos) <= flMxDistance)
		{
			MakeVectorFromPoints(carPos, survivorPos, traceVec);				// draw a line from car to Survivor
			GetVectorAngles(traceVec, resultingFling);							// get the angles of that line
			
			resultingFling[0] = Cosine(DegToRad(resultingFling[1])) * power;	// use trigonometric magic
			resultingFling[1] = Sine(DegToRad(resultingFling[1])) * power;
			resultingFling[2] = power;
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", currentVelVec);		// add whatever the Survivor had before
			resultingFling[0] += currentVelVec[0];
			resultingFling[1] += currentVelVec[1];
			resultingFling[2] += currentVelVec[2];
			
			if(GetClientTeam(i) == 2)
			{
				FlingPlayer(i, resultingFling, i);
			}
			else if(GetClientTeam(i) == 3)
			{
				TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resultingFling);
				if(attacker > 0)
				{
					HurtPlayer(i, attacker);
				}
			}
		}
	}
}

public Action:timerStopFire(Handle:timer, Handle:pack)
{
	if(g_bDisabled)
	{
		return;
	}
	ResetPack(pack);
	new particle = ReadPackCell(pack);
	new hurt = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(IsValidEntity(particle))
	{
		AcceptEntityInput(particle, "Stop");
	}
	if(IsValidEntity(hurt))
	{
		AcceptEntityInput(hurt, "TurnOff");
	}
}

public Action:timerDeleteParticles(Handle:timer, Handle:pack)
{
	if(g_bDisabled)
	{
		return;
	}
	ResetPack(pack);
	
	new entity;
	for (new i = 1; i <= 7; i++)
	{
		entity = ReadPackCell(pack);
		
		if(IsValidEntity(entity))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	CloseHandle(pack);
}

stock FlingPlayer(target, Float:vector[3], attacker, Float:stunTime = 3.0)
{
	if(g_bDisabled)
	{
		return;
	}
	SDKCall(sdkCallPushPlayer, target, vector, 76, attacker, stunTime);
}

stock PrecacheParticle(const String:ParticleName[])
{
	if(g_bDisabled)
	{
		return;
	}
	new Particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(Particle) && IsValidEdict(Particle))
	{
		DispatchKeyValue(Particle, "effect_name", ParticleName);
		DispatchSpawn(Particle);
		ActivateEntity(Particle);
		AcceptEntityInput(Particle, "start");
		CreateTimer(0.3, timerRemovePrecacheParticle, Particle, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:timerRemovePrecacheParticle(Handle:timer, any:Particle)
{
	if(g_bDisabled)
	{
		return;
	}
	if(IsValidEdict(Particle))
	{
		AcceptEntityInput(Particle, "Kill");
	}
}

stock AttachParticle(car, const String:Particle_Name[])
{
	if(g_bDisabled)
	{
		return;
	}
	decl Float:carPos[3], String:sName[64], String:sTargetName[64];
	new Particle = CreateEntityByName("info_particle_system");
	if(g_iParticle[car] > 0 && IsValidEntity(g_iParticle[car]))
	{
		AcceptEntityInput(g_iParticle[car], "Kill");
		g_iParticle[car] = -1;
	}
	g_iParticle[car] = Particle;
	GetEntPropVector(car, Prop_Data, "m_vecOrigin", carPos);
	TeleportEntity(Particle, carPos, NULL_VECTOR, NULL_VECTOR);
	DispatchKeyValue(Particle, "effect_name", Particle_Name);
	
	new userid = car;
	Format(sName, sizeof(sName), "%d", userid+25);
	DispatchKeyValue(car, "targetname", sName);
	GetEntPropString(car, Prop_Data, "m_iName", sName, sizeof(sName));
	
	Format(sTargetName, sizeof(sTargetName), "%d", userid+1000);
	DispatchKeyValue(Particle, "targetname", sTargetName);
	DispatchKeyValue(Particle, "parentname", sName);
	DispatchSpawn(Particle);
	DispatchSpawn(Particle);
	SetVariantString(sName);
	AcceptEntityInput(Particle, "SetParent", Particle, Particle);
	ActivateEntity(Particle);
	AcceptEntityInput(Particle, "start");
}

stock PanicEvent()
{
	if(g_bDisabled)
	{
		return;
	}
	new Director = CreateEntityByName("info_director");
	DispatchSpawn(Director);
	AcceptEntityInput(Director, "ForcePanicEvent");
	AcceptEntityInput(Director, "Kill");
}

stock DebugPrintToAll(const String:format[], any:...)
{
	if(g_bDisabled)
	{
		return;
	}
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[EC] %s", buffer);
	PrintToConsole(0, "[EC] %s", buffer);
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


#if 0
//Stops a sound from all channels - Unused right now
stock StopSoundPerm(client, String:sound[])
{
	if(g_bDisabled)
	{
		return;
	}
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}
#endif

public Forward_CarExplode(attacker, car)
{
	new bool:result;
	Call_StartForward(g_hForward_CarExplode);
	Call_PushCell(attacker);
	Call_PushCell(car);
	Call_Finish(_:result);
	return result;
}

stock HurtPlayer(victim, attacker)
{
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, victim);
	WritePackCell(pack, attacker);
	CreateTimer(0.1, timerHurtSurv, pack);
}

public Action:timerHurtSurv(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new attacker = ReadPackCell(pack);
	CloseHandle(pack);
	IncapSurvivor(client, attacker);
}

//Force incapacitation -> Force damage (Modified)
stock IncapSurvivor(client, attacker)
{
	if(IsValidEntity(client))
	{
		decl String:sUser[256];
		IntToString(GetClientUserId(client)+25, sUser, sizeof(sUser));
		new iDmgEntity = CreateEntityByName("point_hurt");
		DispatchKeyValue(client, "targetname", sUser);
		DispatchKeyValue(iDmgEntity, "DamageTarget", sUser);
		DispatchKeyValue(iDmgEntity, "Damage", "700");
		DispatchKeyValue(iDmgEntity, "DamageType", "8");
		DispatchSpawn(iDmgEntity);
		AcceptEntityInput(iDmgEntity, "Hurt", attacker);
		AcceptEntityInput(iDmgEntity, "Kill");
	}
}

stock ClientCommandAll(String:command[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidEntity(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			ClientCommand(i, command);
		}
	}
}

stock CreateInferno(attacker, Float:pos[3])
{
	if(attacker <= 0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidEntity(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				attacker = i;
				break;
			}
		}
	}
	pos[2]+=32.0;
	new Float:vel[3], Float:vec[3], Float:ang[3];
	vel[2] = -300.0
	vel[0] = GetRandomFloat(100.0, 250.0);
	vel[1] = GetRandomFloat(100.0, 250.0);
	ang[0] = GetRandomFloat(0.0, 360.0);
	ang[1] = GetRandomFloat(0.0, 360.0);
	ang[2] = GetRandomFloat(-45.0, 45.0);
	SDKCall(sdkDetonateFire, pos, vec, vel, vec, attacker);
}