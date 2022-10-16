#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar rng_sinkroll;
ConVar rng_assaultrifle_max;
ConVar rng_smg_max;
ConVar rng_shotgun_max;
ConVar rng_autoshotgun_max;
ConVar rng_huntingrifle_max;
ConVar rng_sniperrifle_max;
ConVar rng_grenadelauncher_max;
ConVar rng_m60_max;
ConVar rng_baseballbat;
ConVar rng_cricket_bat;
ConVar rng_crowbar;
ConVar rng_electric_guitar;
ConVar rng_fireaxe;
ConVar rng_frying_pan;
ConVar rng_golfclub;
ConVar rng_katana;
ConVar rng_machete;
ConVar rng_tonfa;
ConVar rng_knife;
ConVar rng_pitchfork;
ConVar rng_shovel;
ConVar rng_weapon_chainsaw;
ConVar rng_weapon_adrenaline;
ConVar rng_weapon_defibrillator;
ConVar rng_weapon_first_aid_kit;
ConVar rng_weapon_pain_pills;
ConVar rng_weapon_fireworkcrate;
ConVar rng_weapon_gascan;
ConVar rng_weapon_oxygentank;
ConVar rng_weapon_propanetank;
ConVar rng_weapon_molotov;
ConVar rng_weapon_pipe_bomb;
ConVar rng_weapon_vomitjar;
ConVar rng_weapon_ammo_spawn;
ConVar rng_upgrade_laser_sight;
ConVar rng_weapon_upgradepack_explosive;
ConVar rng_weapon_upgradepack_incendiary;
ConVar rng_weapon_gnome;
ConVar rng_weapon_cola_bottles;
ConVar rng_weapon_pistol;
ConVar rng_weapon_pistol_magnum;
ConVar rng_weapon_autoshotgun;
ConVar rng_weapon_hunting_rifle;
ConVar rng_weapon_pumpshotgun;
ConVar rng_weapon_grenade_launcher;
ConVar rng_weapon_rifle;
ConVar rng_weapon_rifle_ak47;
ConVar rng_weapon_rifle_desert;
ConVar rng_weapon_rifle_m60;
ConVar rng_weapon_rifle_sg552;
ConVar rng_weapon_shotgun_chrome;
ConVar rng_weapon_shotgun_spas;
ConVar rng_weapon_smg;
ConVar rng_weapon_smg_mp5;
ConVar rng_weapon_smg_silenced;
ConVar rng_weapon_sniper_awp;
ConVar rng_weapon_sniper_military;
ConVar rng_weapon_sniper_scout;
ConVar z_rng_custom_2_handed_concrete;
ConVar z_rng_custom_aetherpickaxe;
ConVar z_rng_custom_aethersword;
ConVar z_rng_custom_arm;
ConVar z_rng_custom_b_brokenbottle;
ConVar z_rng_custom_b_foamfinger;
ConVar z_rng_custom_b_legbone;
ConVar z_rng_custom_bajo;
ConVar z_rng_custom_bamboo;
ConVar z_rng_custom_barnacle;
ConVar z_rng_custom_bigoronsword;
ConVar z_rng_custom_bnc;
ConVar z_rng_custom_bottle;
ConVar z_rng_custom_bow;
ConVar z_rng_custom_bt_nail;
ConVar z_rng_custom_bt_sledge;
ConVar z_rng_custom_btorch;
ConVar z_rng_custom_caidao;
ConVar z_rng_custom_chains;
ConVar z_rng_custom_chair;
ConVar z_rng_custom_chair2;
ConVar z_rng_custom_combat_knife;
ConVar z_rng_custom_computer_keyboard;
ConVar z_rng_custom_concrete1;
ConVar z_rng_custom_concrete2;
ConVar z_rng_custom_custom_ammo_pack;
ConVar z_rng_custom_dagger_water;
ConVar z_rng_custom_daxe;
ConVar z_rng_custom_dekustick;
ConVar z_rng_custom_dhoe;
ConVar z_rng_custom_didgeridoo;
ConVar z_rng_custom_doc1;
ConVar z_rng_custom_dshovel;
ConVar z_rng_custom_dsword;
ConVar z_rng_custom_dustpan;
ConVar z_rng_custom_electric_guitar2;
ConVar z_rng_custom_electric_guitar3;
ConVar z_rng_custom_electric_guitar4;
ConVar z_rng_custom_enchsword;
ConVar z_rng_custom_finger;
ConVar z_rng_custom_fishingrod;
ConVar z_rng_custom_flamethrower;
ConVar z_rng_custom_foot;
ConVar z_rng_custom_fubar;
ConVar z_rng_custom_gaxe;
ConVar z_rng_custom_ghoe;
ConVar z_rng_custom_gloves;
ConVar z_rng_custom_gman;
ConVar z_rng_custom_gpickaxe;
ConVar z_rng_custom_gshovel;
ConVar z_rng_custom_guandao;
ConVar z_rng_custom_guitar;
ConVar z_rng_custom_guitarra;
ConVar z_rng_custom_hammer;
ConVar z_rng_custom_hammer_roku;
ConVar z_rng_custom_helms_anduril;
ConVar z_rng_custom_helms_hatchet;
ConVar z_rng_custom_helms_orcrist;
ConVar z_rng_custom_helms_sting;
ConVar z_rng_custom_helms_sword_and_shield;
ConVar z_rng_custom_hylianshield;
ConVar z_rng_custom_iaxe;
ConVar z_rng_custom_ihoe;
ConVar z_rng_custom_ipickaxe;
ConVar z_rng_custom_isword;
ConVar z_rng_custom_katana2;
ConVar z_rng_custom_kitchen_knife;
ConVar z_rng_custom_lamp;
ConVar z_rng_custom_legosword;
ConVar z_rng_custom_leon_knife;
ConVar z_rng_custom_lightsaber;
ConVar z_rng_custom_lobo;
ConVar z_rng_custom_longsword;
ConVar z_rng_custom_lpipe;
ConVar z_rng_custom_m72law;
ConVar z_rng_custom_mace;
ConVar z_rng_custom_mace2;
ConVar z_rng_custom_mastersword;
ConVar z_rng_custom_meleejb;
ConVar z_rng_custom_mirrorshield;
ConVar z_rng_custom_mop;
ConVar z_rng_custom_mop2;
ConVar z_rng_custom_muffler;
ConVar z_rng_custom_nailbat;
ConVar z_rng_custom_onion;
ConVar z_rng_custom_pickaxe;
ConVar z_rng_custom_pipehammer;
ConVar z_rng_custom_platillo;
ConVar z_rng_custom_pot;
ConVar z_rng_custom_riotshield;
ConVar z_rng_custom_rockaxe;
ConVar z_rng_custom_roku_bass;
ConVar z_rng_custom_roku_cymbal;
ConVar z_rng_custom_roku_guitar;
ConVar z_rng_custom_scup;
ConVar z_rng_custom_scythe_roku;
ConVar z_rng_custom_sh2wood;
ConVar z_rng_custom_shavel;
ConVar z_rng_custom_shoe;
ConVar z_rng_custom_skateboard;
ConVar z_rng_custom_slasher;
ConVar z_rng_custom_sledgehammer;
ConVar z_rng_custom_small_knife;
ConVar z_rng_custom_spickaxe;
ConVar z_rng_custom_sshovel;
ConVar z_rng_custom_ssword;
ConVar z_rng_custom_syringe_gun;
ConVar z_rng_custom_thrower;
ConVar z_rng_custom_tireiron;
ConVar z_rng_custom_tonfa_riot;
ConVar z_rng_custom_tramontina;
ConVar z_rng_custom_trashbin;
ConVar z_rng_custom_vampiresword;
ConVar z_rng_custom_wand;
ConVar z_rng_custom_waterpipe;
ConVar z_rng_custom_waxe;
ConVar z_rng_custom_weapon_chalice;
ConVar z_rng_custom_weapon_morgenstern;
ConVar z_rng_custom_weapon_shadowhand;
ConVar z_rng_custom_weapon_sof;
ConVar z_rng_custom_woodbat;
ConVar z_rng_custom_wpickaxe;
ConVar z_rng_custom_wrench;
ConVar z_rng_custom_wshovel;
ConVar z_rng_custom_wsword;
ConVar z_rng_custom_wulinmiji;
ConVar z_rng_custom_zuko;
ConVar z_rng_custom_zuko_knife;

public Plugin myinfo = 
{
	name = "[L4D2] Navigation Loot Spawner",
	author = "BHaType, RainyDagger, Shao",
	description = "Spawn randomly any items anywhere on the nav_mesh.",
	version = "1.1",
	url = ""
};

static const char szWeapons[][] =
{
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"electric_guitar",
	"fireaxe",
	"frying_pan",
	"golfclub",
	"katana",
	"machete",
	"tonfa",
	"knife",
	"pitchfork",
	"shovel",
	"weapon_chainsaw",
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_fireworkcrate",
	"weapon_gascan",
	"weapon_oxygentank",
	"weapon_propanetank",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_ammo_spawn",
	"upgrade_laser_sight",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_gnome",
	"weapon_cola_bottles",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_pumpshotgun",
	"weapon_grenade_launcher",
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_rifle_m60",
	"weapon_rifle_sg552",
	"weapon_shotgun_chrome",
	"weapon_shotgun_spas",
	"weapon_smg",
	"weapon_smg_mp5",
	"weapon_smg_silenced",
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"2_handed_concrete",
	"aetherpickaxe",
	"aethersword",
	"arm",
	"b_brokenbottle",
	"b_foamfinger",
	"b_legbone",
	"bajo",
	"bamboo",
	"barnacle",
	"bigoronsword",
	"bnc",
	"bottle",
	"bow",
	"bt_nail",
	"bt_sledge",
	"btorch",
	"caidao",
	"chains",
	"chair",
	"chair2",
	"combat_knife",
	"computer_keyboard",
	"concrete1",
	"concrete2",
	"custom_ammo_pack",
	"dagger_water",
	"daxe",
	"dekustick",
	"dhoe",
	"didgeridoo",
	"doc1",
	"dshovel",
	"dsword",
	"dustpan",
	"electric_guitar2",
	"electric_guitar3",
	"electric_guitar4",
	"enchsword",
	"finger",
	"fishingrod",
	"flamethrower",
	"foot",
	"fubar",
	"gaxe",
	"ghoe",
	"gloves",
	"gman",
	"gpickaxe",
	"gshovel",
	"guandao",
	"guitar",
	"guitarra",
	"hammer",
	"hammer_roku",
	"helms_anduril",
	"helms_hatchet",
	"helms_orcrist",
	"helms_sting",
	"helms_sword_and_shield",
	"hylianshield",
	"iaxe",
	"ihoe",
	"ipickaxe",
	"isword",
	"katana2",
	"kitchen_knife",
	"lamp",
	"legosword",
	"leon_knife",
	"lightsaber",
	"lobo",
	"longsword",
	"lpipe",
	"m72law",
	"mace",
	"mace2",
	"mastersword",
	"meleejb",
	"mirrorshield",
	"mop",
	"mop2",
	"muffler",
	"nailbat",
	"onion",
	"pickaxe",
	"pipehammer",
	"platillo",
	"pot",
	"riotshield",
	"rockaxe",
	"roku_bass",
	"roku_cymbal",
	"roku_guitar",
	"scup",
	"scythe_roku",
	"sh2wood",
	"shavel",
	"shoe",
	"skateboard",
	"slasher",
	"sledgehammer",
	"small_knife",
	"spickaxe",
	"sshovel",
	"ssword",
	"syringe_gun",
	"thrower",
	"tireiron",
	"tonfa_riot",
	"tramontina",
	"trashbin",
	"vampiresword",
	"wand",
	"waterpipe",
	"waxe",
	"weapon_chalice",
	"weapon_morgenstern",
	"weapon_shadowhand",
	"weapon_sof",
	"woodbat",
	"wpickaxe",
	"wrench",
	"wshovel",
	"wsword",
	"wulinmiji",
	"zuko",
	"zuko_knife"
};

static int gChances[sizeof(szWeapons)];

ConVar g_hLootCount, g_hNavBits, g_hCheckReachable;
bool g_bLoaded, g_alreadyspawned;
Address TheNavAreas;
int TheCount, g_iLootCount, g_iNavFlagsCheck, g_iReachableCheck;
Handle g_hReachableCheck;


public void OnPluginStart()
{
	g_hLootCount 						= CreateConVar("sm_nav_loot_spawner_count", 			"30", "How much items do we spawn?", FCVAR_NONE);
	g_hNavBits 							= CreateConVar("sm_nav_loot_spawn_flags",				"0", "Should we spawn items in flags zones?", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCheckReachable 					= CreateConVar("sm_nav_loot_check_position_reachable", 	"0", "Should we check if position is reachable? (Windows only)", FCVAR_NONE, true, 0.0, true, 1.0);
	
	rng_sinkroll 						= CreateConVar("rng_sinkroll_enabled", 					"0", "Chance of not spawning anything?", FCVAR_NONE, true, 0.0, true, 100.0);
	rng_assaultrifle_max 				= CreateConVar("rng_spawnweapon_assaultammo", 			"180", "How much Ammo for AK74, M4A1, SG552 and Desert Rifle.", 0);
	rng_smg_max 						= CreateConVar("rng_spawnweapon_smgammo", 				"325", "How much Ammo for SMG, Silenced SMG and MP5", 0);
	rng_shotgun_max 					= CreateConVar("rng_spawnweapon_shotgunammo", 			"36", "How much Ammo for Shotgun and Chrome Shotgun.", 0);
	rng_autoshotgun_max 				= CreateConVar("rng_spawnweapon_autoshotgunammo",		"45", "How much Ammo for Autoshotgun and SPAS.", 0);
	rng_huntingrifle_max 				= CreateConVar("rng_spawnweapon_huntingrifleammo", 		"75", "How much Ammo for the Hunting Rifle.", 0);
	rng_sniperrifle_max 				= CreateConVar("rng_spawnweapon_sniperrifleammo", 		"90", "How much Ammo for the Military Sniper Rifle, AWP and Scout.", 0);
	rng_grenadelauncher_max 			= CreateConVar("rng_spawnweapon_grenadelauncherammo", 	"30", "How much Ammo for the Grenade Launcher.", 0);
	rng_m60_max 						= CreateConVar("rng_spawnweapon_m60ammo", 				"100", "How much Ammo for the M60.", 0);
	rng_baseballbat 					= CreateConVar("rng_chance_baseballbat", 				"50", "Chances to spawn a Baseball Bat", 0);
	rng_cricket_bat 					= CreateConVar("rng_chance_cricket_bat", 				"50", "Chances to spawn a Cricket Bat", 0);
	rng_crowbar							= CreateConVar("rng_chance_crowbar", 					"50", "Chances to spawn a Crowbar", 0);
	rng_electric_guitar					= CreateConVar("rng_chance_electric_guitar", 			"50", "Chances to spawn a Electric Guitar", 0);
	rng_fireaxe							= CreateConVar("rng_chance_fireaxe", 					"50", "Chances to spawn a Fireaxe", 0);
	rng_frying_pan						= CreateConVar("rng_chance_frying_pan", 				"50", "Chances to spawn a Frying Pan", 0);
	rng_golfclub						= CreateConVar("rng_chance_golfclub", 					"50", "Chances to spawn a Golf Club", 0);
	rng_katana							= CreateConVar("rng_chance_katana", 					"50", "Chances to spawn a Katana", 0);
	rng_machete							= CreateConVar("rng_chance_machete", 					"50", "Chances to spawn a Machete", 0);
	rng_tonfa							= CreateConVar("rng_chance_tonfa", 						"50", "Chances to spawn a Tonfa", 0);
	rng_knife							= CreateConVar("rng_chance_knife", 						"50", "Chances to spawn a Knife", 0);
	rng_pitchfork						= CreateConVar("rng_chance_pitchfork", 					"50", "Chances to spawn a Pitchfork", 0);
	rng_shovel							= CreateConVar("rng_chance_shovel", 					"50", "Chances to spawn a Shovel", 0);
	rng_weapon_chainsaw					= CreateConVar("rng_chance_chainsaw", 					"50", "Chances to spawn a Chainsaw", 0);
	rng_weapon_adrenaline				= CreateConVar("rng_chance_adrenaline", 				"50", "Chances to spawn a Adrenaline", 0);
	rng_weapon_defibrillator			= CreateConVar("rng_chance_defibrillator", 				"50", "Chances to spawn a Defibrillator", 0);
	rng_weapon_first_aid_kit			= CreateConVar("rng_chance_first_aid_kit", 				"50", "Chances to spawn a First Aid Kit", 0);
	rng_weapon_pain_pills				= CreateConVar("rng_chance_pain_pills", 				"50", "Chances to spawn a Pain Pills", 0);
	rng_weapon_fireworkcrate			= CreateConVar("rng_chance_fireworkcrate", 				"50", "Chances to spawn a Firework Crate", 0);
	rng_weapon_gascan					= CreateConVar("rng_chance_gascan", 					"50", "Chances to spawn a Gascan", 0);
	rng_weapon_oxygentank				= CreateConVar("rng_chance_oxygentank", 				"50", "Chances to spawn a Oxygen Tank", 0);
	rng_weapon_propanetank				= CreateConVar("rng_chance_propanetank", 				"50", "Chances to spawn a Propane Tank", 0);
	rng_weapon_molotov					= CreateConVar("rng_chance_molotov", 					"50", "Chances to spawn a Molotov", 0);
	rng_weapon_pipe_bomb				= CreateConVar("rng_chance_pipe_bomb", 					"50", "Chances to spawn a Pipe Bomb", 0);
	rng_weapon_vomitjar					= CreateConVar("rng_chance_vomitjar", 					"50", "Chances to spawn a Vomit Jar", 0);
	rng_weapon_ammo_spawn				= CreateConVar("rng_chance_ammo_spawn", 				"50", "Chances to spawn a Ammo Pile", 0);
	rng_upgrade_laser_sight				= CreateConVar("rng_chance_upgrade_laser_sight", 		"50", "Chances to spawn a Laser Sight Box", 0);
	rng_weapon_upgradepack_explosive 	= CreateConVar("rng_chance_upgradepack_explosive", 		"50", "Chances to spawn a Explosive Ammo Box", 0);
	rng_weapon_upgradepack_incendiary	= CreateConVar("rng_chance_upgradepack_incendiary", 	"50", "Chances to spawn a Incendiary Ammo Box", 0);
	rng_weapon_gnome					= CreateConVar("rng_chance_gnome", 						"50", "Chances to spawn a Gnome", 0);
	rng_weapon_cola_bottles				= CreateConVar("rng_chance_cola_bottles", 				"50", "Chances to spawn a Cola Bottles", 0);
	rng_weapon_pistol					= CreateConVar("rng_chance_pistol", 					"50", "Chances to spawn a Pistol", 0);
	rng_weapon_pistol_magnum			= CreateConVar("rng_chance_pistol_magnum", 				"50", "Chances to spawn a Magnum", 0);
	rng_weapon_autoshotgun				= CreateConVar("rng_chance_autoshotgun", 				"50", "Chances to spawn a Autoshotgun", 0);
	rng_weapon_hunting_rifle			= CreateConVar("rng_chance_hunting_rifle", 				"50", "Chances to spawn a Hunting Rifle", 0);
	rng_weapon_pumpshotgun				= CreateConVar("rng_chance_pumpshotgun", 				"50", "Chances to spawn a Pumpshotgun", 0);
	rng_weapon_grenade_launcher			= CreateConVar("rng_chance_grenade_launcher", 			"50", "Chances to spawn a Grenade Launcher", 0);
	rng_weapon_rifle					= CreateConVar("rng_chance_rifle", 						"50", "Chances to spawn a M16 Rifle", 0);
	rng_weapon_rifle_ak47				= CreateConVar("rng_chance_rifle_ak47", 				"50", "Chances to spawn a AK47 Rifle", 0);
	rng_weapon_rifle_desert				= CreateConVar("rng_chance_rifle_desert", 				"50", "Chances to spawn a Desert Rifle", 0);
	rng_weapon_rifle_m60				= CreateConVar("rng_chance_rifle_m60", 					"50", "Chances to spawn a M60 Rifle", 0);
	rng_weapon_rifle_sg552				= CreateConVar("rng_chance_rifle_sg552", 				"50", "Chances to spawn a SG552 Rifle", 0);
	rng_weapon_shotgun_chrome			= CreateConVar("rng_chance_shotgun_chrome", 			"50", "Chances to spawn a Chrome Shotgun", 0);
	rng_weapon_shotgun_spas				= CreateConVar("rng_chance_shotgun_spas", 				"50", "Chances to spawn a Spas Shotgun", 0);
	rng_weapon_smg						= CreateConVar("rng_chance_smg", 						"50", "Chances to spawn a SMG", 0);
	rng_weapon_smg_mp5					= CreateConVar("rng_chance_smg_mp5", 					"50", "Chances to spawn a MP5", 0);
	rng_weapon_smg_silenced				= CreateConVar("rng_chance_smg_silenced", 				"50", "Chances to spawn a Silenced SMG", 0);
	rng_weapon_sniper_awp				= CreateConVar("rng_chance_sniper_awp", 				"50", "Chances to spawn a AWP", 0);
	rng_weapon_sniper_military			= CreateConVar("rng_chance_sniper_military", 			"50", "Chances to spawn a Autosniper", 0);
	rng_weapon_sniper_scout				= CreateConVar("rng_chance_sniper_scout", 				"50", "Chances to spawn a Scout", 0);
	z_rng_custom_2_handed_concrete		= CreateConVar("z_rng_custom_2_handed_concrete", 		"0", "Chances to spawn a 2_handed_concrete", 0);
	z_rng_custom_aetherpickaxe			= CreateConVar("z_rng_custom_aetherpickaxe", 			"0", "Chances to spawn a aetherpickaxe", 0);
	z_rng_custom_aethersword			= CreateConVar("z_rng_custom_aethersword", 				"0", "Chances to spawn a aethersword", 0);
	z_rng_custom_arm					= CreateConVar("z_rng_custom_arm", 						"0", "Chances to spawn a arm", 0);
	z_rng_custom_b_brokenbottle			= CreateConVar("z_rng_custom_b_brokenbottle", 			"0", "Chances to spawn a b_brokenbottle", 0);
	z_rng_custom_b_foamfinger			= CreateConVar("z_rng_custom_b_foamfinger", 			"0", "Chances to spawn a b_foamfinger", 0);
	z_rng_custom_b_legbone				= CreateConVar("z_rng_custom_b_legbone", 				"0", "Chances to spawn a b_legbone", 0);
	z_rng_custom_bajo					= CreateConVar("z_rng_custom_bajo", 					"0", "Chances to spawn a bajo", 0);
	z_rng_custom_bamboo					= CreateConVar("z_rng_custom_bamboo", 					"0", "Chances to spawn a bamboo", 0);
	z_rng_custom_barnacle				= CreateConVar("z_rng_custom_barnacle", 				"0", "Chances to spawn a barnacle", 0);
	z_rng_custom_bigoronsword			= CreateConVar("z_rng_custom_bigoronsword", 			"0", "Chances to spawn a bigoronsword", 0);
	z_rng_custom_bnc					= CreateConVar("z_rng_custom_bnc", 						"0", "Chances to spawn a bnc", 0);
	z_rng_custom_bottle					= CreateConVar("z_rng_custom_bottle", 					"0", "Chances to spawn a bottle", 0);
	z_rng_custom_bow					= CreateConVar("z_rng_custom_bow", 						"0", "Chances to spawn a bow", 0);
	z_rng_custom_bt_nail				= CreateConVar("z_rng_custom_bt_nail", 					"0", "Chances to spawn a bt_nail", 0);
	z_rng_custom_bt_sledge				= CreateConVar("z_rng_custom_bt_sledge", 				"0", "Chances to spawn a bt_sledge", 0);
	z_rng_custom_btorch					= CreateConVar("z_rng_custom_btorch", 					"0", "Chances to spawn a btorch", 0);
	z_rng_custom_caidao					= CreateConVar("z_rng_custom_caidao", 					"0", "Chances to spawn a caidao", 0);
	z_rng_custom_chains					= CreateConVar("z_rng_custom_chains", 					"0", "Chances to spawn a chains", 0);
	z_rng_custom_chair					= CreateConVar("z_rng_custom_chair", 					"0", "Chances to spawn a chair", 0);
	z_rng_custom_chair2					= CreateConVar("z_rng_custom_chair2", 					"0", "Chances to spawn a chair2", 0);
	z_rng_custom_combat_knife			= CreateConVar("z_rng_custom_combat_knife", 			"0", "Chances to spawn a combat_knife", 0);
	z_rng_custom_computer_keyboard		= CreateConVar("z_rng_custom_computer_keyboard", 		"0", "Chances to spawn a computer_keyboard", 0);
	z_rng_custom_concrete1				= CreateConVar("z_rng_custom_concrete1", 				"0", "Chances to spawn a concrete1", 0);
	z_rng_custom_concrete2				= CreateConVar("z_rng_custom_concrete2", 				"0", "Chances to spawn a concrete2", 0);
	z_rng_custom_custom_ammo_pack		= CreateConVar("z_rng_custom_custom_ammo_pack", 		"0", "Chances to spawn a custom_ammo_pack", 0);
	z_rng_custom_dagger_water			= CreateConVar("z_rng_custom_dagger_water", 			"0", "Chances to spawn a dagger_water", 0);
	z_rng_custom_daxe					= CreateConVar("z_rng_custom_daxe", 					"0", "Chances to spawn a daxe", 0);
	z_rng_custom_dekustick				= CreateConVar("z_rng_custom_dekustick", 				"0", "Chances to spawn a dekustick", 0);
	z_rng_custom_dhoe					= CreateConVar("z_rng_custom_dhoe", 					"0", "Chances to spawn a dhoe", 0);
	z_rng_custom_didgeridoo				= CreateConVar("z_rng_custom_didgeridoo", 				"0", "Chances to spawn a didgeridoo", 0);
	z_rng_custom_doc1					= CreateConVar("z_rng_custom_doc1", 					"0", "Chances to spawn a doc1", 0);
	z_rng_custom_dshovel				= CreateConVar("z_rng_custom_dshovel", 					"0", "Chances to spawn a dshovel", 0);
	z_rng_custom_dsword					= CreateConVar("z_rng_custom_dsword", 					"0", "Chances to spawn a dsword", 0);
	z_rng_custom_dustpan				= CreateConVar("z_rng_custom_dustpan", 					"0", "Chances to spawn a dustpan", 0);
	z_rng_custom_electric_guitar2		= CreateConVar("z_rng_custom_electric_guitar2", 		"0", "Chances to spawn a electric_guitar2", 0);
	z_rng_custom_electric_guitar3		= CreateConVar("z_rng_custom_electric_guitar3", 		"0", "Chances to spawn a electric_guitar3", 0);
	z_rng_custom_electric_guitar4		= CreateConVar("z_rng_custom_electric_guitar4", 		"0", "Chances to spawn a electric_guitar4", 0);
	z_rng_custom_enchsword				= CreateConVar("z_rng_custom_enchsword", 				"0", "Chances to spawn a enchsword", 0);
	z_rng_custom_finger					= CreateConVar("z_rng_custom_finger", 					"0", "Chances to spawn a finger", 0);
	z_rng_custom_fishingrod				= CreateConVar("z_rng_custom_fishingrod", 				"0", "Chances to spawn a fishingrod", 0);
	z_rng_custom_flamethrower			= CreateConVar("z_rng_custom_flamethrower", 			"0", "Chances to spawn a flamethrower", 0);
	z_rng_custom_foot					= CreateConVar("z_rng_custom_foot", 					"0", "Chances to spawn a foot", 0);
	z_rng_custom_fubar					= CreateConVar("z_rng_custom_fubar", 					"0", "Chances to spawn a fubar", 0);
	z_rng_custom_gaxe					= CreateConVar("z_rng_custom_gaxe", 					"0", "Chances to spawn a gaxe", 0);
	z_rng_custom_ghoe					= CreateConVar("z_rng_custom_ghoe", 					"0", "Chances to spawn a ghoe", 0);
	z_rng_custom_gloves					= CreateConVar("z_rng_custom_gloves", 					"0", "Chances to spawn a gloves", 0);
	z_rng_custom_gman					= CreateConVar("z_rng_custom_gman", 					"0", "Chances to spawn a gman", 0);
	z_rng_custom_gpickaxe				= CreateConVar("z_rng_custom_gpickaxe", 				"0", "Chances to spawn a gpickaxe", 0);
	z_rng_custom_gshovel				= CreateConVar("z_rng_custom_gshovel", 					"0", "Chances to spawn a gshovel", 0);
	z_rng_custom_guandao				= CreateConVar("z_rng_custom_guandao", 					"0", "Chances to spawn a guandao", 0);
	z_rng_custom_guitar					= CreateConVar("z_rng_custom_guitar", 					"0", "Chances to spawn a guitar", 0);
	z_rng_custom_guitarra				= CreateConVar("z_rng_custom_guitarra", 				"0", "Chances to spawn a guitarra", 0);
	z_rng_custom_hammer					= CreateConVar("z_rng_custom_hammer", 					"0", "Chances to spawn a hammer", 0);
	z_rng_custom_hammer_roku			= CreateConVar("z_rng_custom_hammer_roku", 				"0", "Chances to spawn a hammer_roku", 0);
	z_rng_custom_helms_anduril			= CreateConVar("z_rng_custom_helms_anduril", 			"0", "Chances to spawn a helms_anduril", 0);
	z_rng_custom_helms_hatchet			= CreateConVar("z_rng_custom_helms_hatchet", 			"0", "Chances to spawn a helms_hatchet", 0);
	z_rng_custom_helms_orcrist			= CreateConVar("z_rng_custom_helms_orcrist", 			"0", "Chances to spawn a helms_orcrist", 0);
	z_rng_custom_helms_sting			= CreateConVar("z_rng_custom_helms_sting", 				"0", "Chances to spawn a helms_sting", 0);
	z_rng_custom_helms_sword_and_shield	= CreateConVar("z_rng_custom_helms_sword_and_shield", 	"0", "Chances to spawn a helms_sword_and_shield", 0);
	z_rng_custom_hylianshield			= CreateConVar("z_rng_custom_hylianshield", 			"0", "Chances to spawn a hylianshield", 0);
	z_rng_custom_iaxe					= CreateConVar("z_rng_custom_iaxe", 					"0", "Chances to spawn a iaxe", 0);
	z_rng_custom_ihoe					= CreateConVar("z_rng_custom_ihoe", 					"0", "Chances to spawn a ihoe", 0);
	z_rng_custom_ipickaxe				= CreateConVar("z_rng_custom_ipickaxe", 				"0", "Chances to spawn a ipickaxe", 0);
	z_rng_custom_isword					= CreateConVar("z_rng_custom_isword", 					"0", "Chances to spawn a isword", 0);
	z_rng_custom_katana2				= CreateConVar("z_rng_custom_katana2", 					"0", "Chances to spawn a katana2", 0);
	z_rng_custom_kitchen_knife			= CreateConVar("z_rng_custom_kitchen_knife", 			"0", "Chances to spawn a kitchen_knife", 0);
	z_rng_custom_lamp					= CreateConVar("z_rng_custom_lamp", 					"0", "Chances to spawn a lamp", 0);
	z_rng_custom_legosword				= CreateConVar("z_rng_custom_legosword", 				"0", "Chances to spawn a legosword", 0);
	z_rng_custom_leon_knife				= CreateConVar("z_rng_custom_leon_knife", 				"0", "Chances to spawn a leon_knife", 0);
	z_rng_custom_lightsaber				= CreateConVar("z_rng_custom_lightsaber", 				"0", "Chances to spawn a lightsaber", 0);
	z_rng_custom_lobo					= CreateConVar("z_rng_custom_lobo", 					"0", "Chances to spawn a lobo", 0);
	z_rng_custom_longsword				= CreateConVar("z_rng_custom_longsword", 				"0", "Chances to spawn a longsword", 0);
	z_rng_custom_lpipe					= CreateConVar("z_rng_custom_lpipe", 					"0", "Chances to spawn a lpipe", 0);
	z_rng_custom_m72law					= CreateConVar("z_rng_custom_m72law", 					"0", "Chances to spawn a m72law", 0);
	z_rng_custom_mace					= CreateConVar("z_rng_custom_mace", 					"0", "Chances to spawn a mace", 0);
	z_rng_custom_mace2					= CreateConVar("z_rng_custom_mace2", 					"0", "Chances to spawn a mace2", 0);
	z_rng_custom_mastersword			= CreateConVar("z_rng_custom_mastersword", 				"0", "Chances to spawn a mastersword", 0);
	z_rng_custom_meleejb				= CreateConVar("z_rng_custom_meleejb", 					"0", "Chances to spawn a meleejb", 0);
	z_rng_custom_mirrorshield			= CreateConVar("z_rng_custom_mirrorshield", 			"0", "Chances to spawn a mirrorshield", 0);
	z_rng_custom_mop					= CreateConVar("z_rng_custom_mop", 						"0", "Chances to spawn a mop", 0);
	z_rng_custom_mop2					= CreateConVar("z_rng_custom_mop2", 					"0", "Chances to spawn a mop2", 0);
	z_rng_custom_muffler				= CreateConVar("z_rng_custom_muffler", 					"0", "Chances to spawn a muffler", 0);
	z_rng_custom_nailbat				= CreateConVar("z_rng_custom_nailbat", 					"0", "Chances to spawn a nailbat", 0);
	z_rng_custom_onion					= CreateConVar("z_rng_custom_onion", 					"0", "Chances to spawn a onion", 0);
	z_rng_custom_pickaxe				= CreateConVar("z_rng_custom_pickaxe", 					"0", "Chances to spawn a pickaxe", 0);
	z_rng_custom_pipehammer				= CreateConVar("z_rng_custom_pipehammer", 				"0", "Chances to spawn a pipehammer", 0);
	z_rng_custom_platillo				= CreateConVar("z_rng_custom_platillo", 				"0", "Chances to spawn a platillo", 0);
	z_rng_custom_pot					= CreateConVar("z_rng_custom_pot", 						"0", "Chances to spawn a pot", 0);
	z_rng_custom_riotshield				= CreateConVar("z_rng_custom_riotshield", 				"0", "Chances to spawn a riotshield", 0);
	z_rng_custom_rockaxe				= CreateConVar("z_rng_custom_rockaxe", 					"0", "Chances to spawn a rockaxe", 0);
	z_rng_custom_roku_bass				= CreateConVar("z_rng_custom_roku_bass", 				"0", "Chances to spawn a roku_bass", 0);
	z_rng_custom_roku_cymbal			= CreateConVar("z_rng_custom_roku_cymbal", 				"0", "Chances to spawn a roku_cymbal", 0);
	z_rng_custom_roku_guitar			= CreateConVar("z_rng_custom_roku_guitar", 				"0", "Chances to spawn a roku_guitar", 0);
	z_rng_custom_scup					= CreateConVar("z_rng_custom_scup", 					"0", "Chances to spawn a scup", 0);
	z_rng_custom_scythe_roku			= CreateConVar("z_rng_custom_scythe_roku", 				"0", "Chances to spawn a scythe_roku", 0);
	z_rng_custom_sh2wood				= CreateConVar("z_rng_custom_sh2wood", 					"0", "Chances to spawn a sh2wood", 0);
	z_rng_custom_shavel					= CreateConVar("z_rng_custom_shavel", 					"0", "Chances to spawn a shavel", 0);
	z_rng_custom_shoe					= CreateConVar("z_rng_custom_shoe", 					"0", "Chances to spawn a shoe", 0);
	z_rng_custom_skateboard				= CreateConVar("z_rng_custom_skateboard", 				"0", "Chances to spawn a skateboard", 0);
	z_rng_custom_slasher				= CreateConVar("z_rng_custom_slasher", 					"0", "Chances to spawn a slasher", 0);
	z_rng_custom_sledgehammer			= CreateConVar("z_rng_custom_sledgehammer", 			"0", "Chances to spawn a sledgehammer", 0);
	z_rng_custom_small_knife			= CreateConVar("z_rng_custom_small_knife", 				"0", "Chances to spawn a small_knife", 0);
	z_rng_custom_spickaxe				= CreateConVar("z_rng_custom_spickaxe", 				"0", "Chances to spawn a spickaxe", 0);
	z_rng_custom_sshovel				= CreateConVar("z_rng_custom_sshovel", 					"0", "Chances to spawn a sshovel", 0);
	z_rng_custom_ssword					= CreateConVar("z_rng_custom_ssword", 					"0", "Chances to spawn a ssword", 0);
	z_rng_custom_syringe_gun			= CreateConVar("z_rng_custom_syringe_gun", 				"0", "Chances to spawn a syringe_gun", 0);
	z_rng_custom_thrower				= CreateConVar("z_rng_custom_thrower", 					"0", "Chances to spawn a thrower", 0);
	z_rng_custom_tireiron				= CreateConVar("z_rng_custom_tireiron", 				"0", "Chances to spawn a tireiron", 0);
	z_rng_custom_tonfa_riot				= CreateConVar("z_rng_custom_tonfa_riot", 				"0", "Chances to spawn a tonfa_riot", 0);
	z_rng_custom_tramontina				= CreateConVar("z_rng_custom_tramontina", 				"0", "Chances to spawn a tramontina", 0);
	z_rng_custom_trashbin				= CreateConVar("z_rng_custom_trashbin", 				"0", "Chances to spawn a trashbin", 0);
	z_rng_custom_vampiresword			= CreateConVar("z_rng_custom_vampiresword", 			"0", "Chances to spawn a vampiresword", 0);
	z_rng_custom_wand					= CreateConVar("z_rng_custom_wand", 					"0", "Chances to spawn a wand", 0);
	z_rng_custom_waterpipe				= CreateConVar("z_rng_custom_waterpipe", 				"0", "Chances to spawn a waterpipe", 0);
	z_rng_custom_waxe					= CreateConVar("z_rng_custom_waxe", 					"0", "Chances to spawn a waxe", 0);
	z_rng_custom_weapon_chalice			= CreateConVar("z_rng_custom_weapon_chalice", 			"0", "Chances to spawn a weapon_chalice", 0);
	z_rng_custom_weapon_morgenstern		= CreateConVar("z_rng_custom_weapon_morgenstern", 		"0", "Chances to spawn a weapon_morgenstern", 0);
	z_rng_custom_weapon_shadowhand		= CreateConVar("z_rng_custom_weapon_shadowhand", 		"0", "Chances to spawn a weapon_shadowhand", 0);
	z_rng_custom_weapon_sof				= CreateConVar("z_rng_custom_weapon_sof", 				"0", "Chances to spawn a weapon_sof", 0);
	z_rng_custom_woodbat				= CreateConVar("z_rng_custom_woodbat", 					"0", "Chances to spawn a woodbat", 0);
	z_rng_custom_wpickaxe				= CreateConVar("z_rng_custom_wpickaxe", 				"0", "Chances to spawn a wpickaxe", 0);
	z_rng_custom_wrench					= CreateConVar("z_rng_custom_wrench", 					"0", "Chances to spawn a wrench", 0);
	z_rng_custom_wshovel				= CreateConVar("z_rng_custom_wshovel", 					"0", "Chances to spawn a wshovel", 0);
	z_rng_custom_wsword					= CreateConVar("z_rng_custom_wsword", 					"0", "Chances to spawn a wsword", 0);
	z_rng_custom_wulinmiji				= CreateConVar("z_rng_custom_wulinmiji", 				"0", "Chances to spawn a wulinmiji", 0);
	z_rng_custom_zuko					= CreateConVar("z_rng_custom_zuko", 					"0", "Chances to spawn a zuko", 0);
	z_rng_custom_zuko_knife				= CreateConVar("z_rng_custom_zuko_knife", 				"0", "Chances to spawn a zuko_knife", 0);

	g_hLootCount.AddChangeHook(OnConVarChanged);
	g_hNavBits.AddChangeHook(OnConVarChanged);
	g_hCheckReachable.AddChangeHook(OnConVarChanged);
	rng_sinkroll.AddChangeHook(OnConVarChanged);
	rng_assaultrifle_max.AddChangeHook(OnConVarChanged);
	rng_smg_max.AddChangeHook(OnConVarChanged);
	rng_shotgun_max.AddChangeHook(OnConVarChanged);
	rng_autoshotgun_max.AddChangeHook(OnConVarChanged);
	rng_huntingrifle_max.AddChangeHook(OnConVarChanged);
	rng_sniperrifle_max.AddChangeHook(OnConVarChanged);
	rng_grenadelauncher_max.AddChangeHook(OnConVarChanged);
	rng_m60_max.AddChangeHook(OnConVarChanged);
	rng_baseballbat.AddChangeHook(OnConVarChanged);
	rng_cricket_bat.AddChangeHook(OnConVarChanged);
	rng_crowbar.AddChangeHook(OnConVarChanged);
	rng_electric_guitar.AddChangeHook(OnConVarChanged);
	rng_fireaxe.AddChangeHook(OnConVarChanged);
	rng_frying_pan.AddChangeHook(OnConVarChanged);
	rng_golfclub.AddChangeHook(OnConVarChanged);
	rng_katana.AddChangeHook(OnConVarChanged);
	rng_machete.AddChangeHook(OnConVarChanged);
	rng_tonfa.AddChangeHook(OnConVarChanged);
	rng_knife.AddChangeHook(OnConVarChanged);
	rng_pitchfork.AddChangeHook(OnConVarChanged);
	rng_shovel.AddChangeHook(OnConVarChanged);
	rng_weapon_chainsaw.AddChangeHook(OnConVarChanged);
	rng_weapon_adrenaline.AddChangeHook(OnConVarChanged);
	rng_weapon_defibrillator.AddChangeHook(OnConVarChanged);
	rng_weapon_first_aid_kit.AddChangeHook(OnConVarChanged);
	rng_weapon_pain_pills.AddChangeHook(OnConVarChanged);
	rng_weapon_fireworkcrate.AddChangeHook(OnConVarChanged);
	rng_weapon_gascan.AddChangeHook(OnConVarChanged);
	rng_weapon_oxygentank.AddChangeHook(OnConVarChanged);
	rng_weapon_propanetank.AddChangeHook(OnConVarChanged);
	rng_weapon_molotov.AddChangeHook(OnConVarChanged);
	rng_weapon_pipe_bomb.AddChangeHook(OnConVarChanged);
	rng_weapon_vomitjar.AddChangeHook(OnConVarChanged);
	rng_weapon_ammo_spawn.AddChangeHook(OnConVarChanged);
	rng_upgrade_laser_sight.AddChangeHook(OnConVarChanged);
	rng_weapon_upgradepack_explosive.AddChangeHook(OnConVarChanged);
	rng_weapon_upgradepack_incendiary.AddChangeHook(OnConVarChanged);
	rng_weapon_gnome.AddChangeHook(OnConVarChanged);
	rng_weapon_cola_bottles.AddChangeHook(OnConVarChanged);
	rng_weapon_pistol.AddChangeHook(OnConVarChanged);
	rng_weapon_pistol_magnum.AddChangeHook(OnConVarChanged);
	rng_weapon_autoshotgun.AddChangeHook(OnConVarChanged);
	rng_weapon_hunting_rifle.AddChangeHook(OnConVarChanged);
	rng_weapon_pumpshotgun.AddChangeHook(OnConVarChanged);
	rng_weapon_grenade_launcher.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_ak47.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_desert.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_m60.AddChangeHook(OnConVarChanged);
	rng_weapon_rifle_sg552.AddChangeHook(OnConVarChanged);
	rng_weapon_shotgun_chrome.AddChangeHook(OnConVarChanged);
	rng_weapon_shotgun_spas.AddChangeHook(OnConVarChanged);
	rng_weapon_smg.AddChangeHook(OnConVarChanged);
	rng_weapon_smg_mp5.AddChangeHook(OnConVarChanged);
	rng_weapon_smg_silenced.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_awp.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_military.AddChangeHook(OnConVarChanged);
	rng_weapon_sniper_scout.AddChangeHook(OnConVarChanged);
	z_rng_custom_2_handed_concrete.AddChangeHook(OnConVarChanged);
	z_rng_custom_aetherpickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_aethersword.AddChangeHook(OnConVarChanged);
	z_rng_custom_arm.AddChangeHook(OnConVarChanged);
	z_rng_custom_b_brokenbottle.AddChangeHook(OnConVarChanged);
	z_rng_custom_b_foamfinger.AddChangeHook(OnConVarChanged);
	z_rng_custom_b_legbone.AddChangeHook(OnConVarChanged);
	z_rng_custom_bajo.AddChangeHook(OnConVarChanged);
	z_rng_custom_bamboo.AddChangeHook(OnConVarChanged);
	z_rng_custom_barnacle.AddChangeHook(OnConVarChanged);
	z_rng_custom_bigoronsword.AddChangeHook(OnConVarChanged);
	z_rng_custom_bnc.AddChangeHook(OnConVarChanged);
	z_rng_custom_bottle.AddChangeHook(OnConVarChanged);
	z_rng_custom_bow.AddChangeHook(OnConVarChanged);
	z_rng_custom_bt_nail.AddChangeHook(OnConVarChanged);
	z_rng_custom_bt_sledge.AddChangeHook(OnConVarChanged);
	z_rng_custom_btorch.AddChangeHook(OnConVarChanged);
	z_rng_custom_caidao.AddChangeHook(OnConVarChanged);
	z_rng_custom_chains.AddChangeHook(OnConVarChanged);
	z_rng_custom_chair.AddChangeHook(OnConVarChanged);
	z_rng_custom_chair2.AddChangeHook(OnConVarChanged);
	z_rng_custom_combat_knife.AddChangeHook(OnConVarChanged);
	z_rng_custom_computer_keyboard.AddChangeHook(OnConVarChanged);
	z_rng_custom_concrete1.AddChangeHook(OnConVarChanged);
	z_rng_custom_concrete2.AddChangeHook(OnConVarChanged);
	z_rng_custom_custom_ammo_pack.AddChangeHook(OnConVarChanged);
	z_rng_custom_dagger_water.AddChangeHook(OnConVarChanged);
	z_rng_custom_daxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_dekustick.AddChangeHook(OnConVarChanged);
	z_rng_custom_dhoe.AddChangeHook(OnConVarChanged);
	z_rng_custom_didgeridoo.AddChangeHook(OnConVarChanged);
	z_rng_custom_doc1.AddChangeHook(OnConVarChanged);
	z_rng_custom_dshovel.AddChangeHook(OnConVarChanged);
	z_rng_custom_dsword.AddChangeHook(OnConVarChanged);
	z_rng_custom_dustpan.AddChangeHook(OnConVarChanged);
	z_rng_custom_electric_guitar2.AddChangeHook(OnConVarChanged);
	z_rng_custom_electric_guitar3.AddChangeHook(OnConVarChanged);
	z_rng_custom_electric_guitar4.AddChangeHook(OnConVarChanged);
	z_rng_custom_enchsword.AddChangeHook(OnConVarChanged);
	z_rng_custom_finger.AddChangeHook(OnConVarChanged);
	z_rng_custom_fishingrod.AddChangeHook(OnConVarChanged);
	z_rng_custom_flamethrower.AddChangeHook(OnConVarChanged);
	z_rng_custom_foot.AddChangeHook(OnConVarChanged);
	z_rng_custom_fubar.AddChangeHook(OnConVarChanged);
	z_rng_custom_gaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_ghoe.AddChangeHook(OnConVarChanged);
	z_rng_custom_gloves.AddChangeHook(OnConVarChanged);
	z_rng_custom_gman.AddChangeHook(OnConVarChanged);
	z_rng_custom_gpickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_gshovel.AddChangeHook(OnConVarChanged);
	z_rng_custom_guandao.AddChangeHook(OnConVarChanged);
	z_rng_custom_guitar.AddChangeHook(OnConVarChanged);
	z_rng_custom_guitarra.AddChangeHook(OnConVarChanged);
	z_rng_custom_hammer.AddChangeHook(OnConVarChanged);
	z_rng_custom_hammer_roku.AddChangeHook(OnConVarChanged);
	z_rng_custom_helms_anduril.AddChangeHook(OnConVarChanged);
	z_rng_custom_helms_hatchet.AddChangeHook(OnConVarChanged);
	z_rng_custom_helms_orcrist.AddChangeHook(OnConVarChanged);
	z_rng_custom_helms_sting.AddChangeHook(OnConVarChanged);
	z_rng_custom_helms_sword_and_shield.AddChangeHook(OnConVarChanged);
	z_rng_custom_hylianshield.AddChangeHook(OnConVarChanged);
	z_rng_custom_iaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_ihoe.AddChangeHook(OnConVarChanged);
	z_rng_custom_ipickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_isword.AddChangeHook(OnConVarChanged);
	z_rng_custom_katana2.AddChangeHook(OnConVarChanged);
	z_rng_custom_kitchen_knife.AddChangeHook(OnConVarChanged);
	z_rng_custom_lamp.AddChangeHook(OnConVarChanged);
	z_rng_custom_legosword.AddChangeHook(OnConVarChanged);
	z_rng_custom_leon_knife.AddChangeHook(OnConVarChanged);
	z_rng_custom_lightsaber.AddChangeHook(OnConVarChanged);
	z_rng_custom_lobo.AddChangeHook(OnConVarChanged);
	z_rng_custom_longsword.AddChangeHook(OnConVarChanged);
	z_rng_custom_lpipe.AddChangeHook(OnConVarChanged);
	z_rng_custom_m72law.AddChangeHook(OnConVarChanged);
	z_rng_custom_mace.AddChangeHook(OnConVarChanged);
	z_rng_custom_mace2.AddChangeHook(OnConVarChanged);
	z_rng_custom_mastersword.AddChangeHook(OnConVarChanged);
	z_rng_custom_meleejb.AddChangeHook(OnConVarChanged);
	z_rng_custom_mirrorshield.AddChangeHook(OnConVarChanged);
	z_rng_custom_mop.AddChangeHook(OnConVarChanged);
	z_rng_custom_mop2.AddChangeHook(OnConVarChanged);
	z_rng_custom_muffler.AddChangeHook(OnConVarChanged);
	z_rng_custom_nailbat.AddChangeHook(OnConVarChanged);
	z_rng_custom_onion.AddChangeHook(OnConVarChanged);
	z_rng_custom_pickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_pipehammer.AddChangeHook(OnConVarChanged);
	z_rng_custom_platillo.AddChangeHook(OnConVarChanged);
	z_rng_custom_pot.AddChangeHook(OnConVarChanged);
	z_rng_custom_riotshield.AddChangeHook(OnConVarChanged);
	z_rng_custom_rockaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_roku_bass.AddChangeHook(OnConVarChanged);
	z_rng_custom_roku_cymbal.AddChangeHook(OnConVarChanged);
	z_rng_custom_roku_guitar.AddChangeHook(OnConVarChanged);
	z_rng_custom_scup.AddChangeHook(OnConVarChanged);
	z_rng_custom_scythe_roku.AddChangeHook(OnConVarChanged);
	z_rng_custom_sh2wood.AddChangeHook(OnConVarChanged);
	z_rng_custom_shavel.AddChangeHook(OnConVarChanged);
	z_rng_custom_shoe.AddChangeHook(OnConVarChanged);
	z_rng_custom_skateboard.AddChangeHook(OnConVarChanged);
	z_rng_custom_slasher.AddChangeHook(OnConVarChanged);
	z_rng_custom_sledgehammer.AddChangeHook(OnConVarChanged);
	z_rng_custom_small_knife.AddChangeHook(OnConVarChanged);
	z_rng_custom_spickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_sshovel.AddChangeHook(OnConVarChanged);
	z_rng_custom_ssword.AddChangeHook(OnConVarChanged);
	z_rng_custom_syringe_gun.AddChangeHook(OnConVarChanged);
	z_rng_custom_thrower.AddChangeHook(OnConVarChanged);
	z_rng_custom_tireiron.AddChangeHook(OnConVarChanged);
	z_rng_custom_tonfa_riot.AddChangeHook(OnConVarChanged);
	z_rng_custom_tramontina.AddChangeHook(OnConVarChanged);
	z_rng_custom_trashbin.AddChangeHook(OnConVarChanged);
	z_rng_custom_vampiresword.AddChangeHook(OnConVarChanged);
	z_rng_custom_wand.AddChangeHook(OnConVarChanged);
	z_rng_custom_waterpipe.AddChangeHook(OnConVarChanged);
	z_rng_custom_waxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_weapon_chalice.AddChangeHook(OnConVarChanged);
	z_rng_custom_weapon_morgenstern.AddChangeHook(OnConVarChanged);
	z_rng_custom_weapon_shadowhand.AddChangeHook(OnConVarChanged);
	z_rng_custom_weapon_sof.AddChangeHook(OnConVarChanged);
	z_rng_custom_woodbat.AddChangeHook(OnConVarChanged);
	z_rng_custom_wpickaxe.AddChangeHook(OnConVarChanged);
	z_rng_custom_wrench.AddChangeHook(OnConVarChanged);
	z_rng_custom_wshovel.AddChangeHook(OnConVarChanged);
	z_rng_custom_wsword.AddChangeHook(OnConVarChanged);
	z_rng_custom_wulinmiji.AddChangeHook(OnConVarChanged);
	z_rng_custom_zuko.AddChangeHook(OnConVarChanged);
	z_rng_custom_zuko_knife.AddChangeHook(OnConVarChanged);
	
	AutoExecConfig(true, "l4d2_nav_loot_spawner");
}

public void OnConVarChanged(Handle hConVar, const char[] oldValue, const char[] newValue)
{
	g_iLootCount = g_hLootCount.IntValue;
	g_iNavFlagsCheck = g_hNavBits.IntValue;
	g_iReachableCheck = g_hCheckReachable.IntValue;
	
	gChancesUpdate();
}

public void gChancesUpdate()
{
	gChances[0] = rng_baseballbat.IntValue;
	gChances[1] = rng_cricket_bat.IntValue;
	gChances[2] = rng_crowbar.IntValue;
	gChances[3] = rng_electric_guitar.IntValue;
	gChances[4] = rng_fireaxe.IntValue;
	gChances[5] = rng_frying_pan.IntValue;
	gChances[6] = rng_golfclub.IntValue;
	gChances[7] = rng_katana.IntValue;
	gChances[8] = rng_machete.IntValue;
	gChances[9] = rng_tonfa.IntValue;
	gChances[10] = rng_knife.IntValue;
	gChances[11] = rng_pitchfork.IntValue;
	gChances[12] = rng_shovel.IntValue;
	gChances[13] = rng_weapon_chainsaw.IntValue;
	gChances[14] = rng_weapon_adrenaline.IntValue;
	gChances[15] = rng_weapon_defibrillator.IntValue;
	gChances[16] = rng_weapon_first_aid_kit.IntValue;
	gChances[17] = rng_weapon_pain_pills.IntValue;
	gChances[18] = rng_weapon_fireworkcrate.IntValue;
	gChances[19] = rng_weapon_gascan.IntValue;
	gChances[20] = rng_weapon_oxygentank.IntValue;
	gChances[21] = rng_weapon_propanetank.IntValue;
	gChances[22] = rng_weapon_molotov.IntValue;
	gChances[23] = rng_weapon_pipe_bomb.IntValue;
	gChances[24] = rng_weapon_vomitjar.IntValue;
	gChances[25] = rng_weapon_ammo_spawn.IntValue;
	gChances[26] = rng_upgrade_laser_sight.IntValue;
	gChances[27] = rng_weapon_upgradepack_explosive.IntValue;
	gChances[28] = rng_weapon_upgradepack_incendiary.IntValue;
	gChances[29] = rng_weapon_gnome.IntValue;
	gChances[30] = rng_weapon_cola_bottles.IntValue;
	gChances[31] = rng_weapon_pistol.IntValue;
	gChances[32] = rng_weapon_pistol_magnum.IntValue;
	gChances[33] = rng_weapon_autoshotgun.IntValue;
	gChances[34] = rng_weapon_hunting_rifle.IntValue;
	gChances[35] = rng_weapon_pumpshotgun.IntValue;
	gChances[36] = rng_weapon_grenade_launcher.IntValue;
	gChances[37] = rng_weapon_rifle.IntValue;
	gChances[38] = rng_weapon_rifle_ak47.IntValue;
	gChances[39] = rng_weapon_rifle_desert.IntValue;
	gChances[40] = rng_weapon_rifle_m60.IntValue;
	gChances[41] = rng_weapon_rifle_sg552.IntValue;
	gChances[42] = rng_weapon_shotgun_chrome.IntValue;
	gChances[43] = rng_weapon_shotgun_spas.IntValue;
	gChances[44] = rng_weapon_smg.IntValue;
	gChances[45] = rng_weapon_smg_mp5.IntValue;
	gChances[46] = rng_weapon_smg_silenced.IntValue;
	gChances[47] = rng_weapon_sniper_awp.IntValue;
	gChances[48] = rng_weapon_sniper_military.IntValue;
	gChances[49] = rng_weapon_sniper_scout.IntValue;
	gChances[50] = z_rng_custom_2_handed_concrete.IntValue;
	gChances[51] = z_rng_custom_aetherpickaxe.IntValue;
	gChances[52] = z_rng_custom_aethersword.IntValue;
	gChances[53] = z_rng_custom_arm.IntValue;
	gChances[54] = z_rng_custom_b_brokenbottle.IntValue;
	gChances[55] = z_rng_custom_b_foamfinger.IntValue;
	gChances[56] = z_rng_custom_b_legbone.IntValue;
	gChances[57] = z_rng_custom_bajo.IntValue;
	gChances[58] = z_rng_custom_bamboo.IntValue;
	gChances[59] = z_rng_custom_barnacle.IntValue;
	gChances[60] = z_rng_custom_bigoronsword.IntValue;
	gChances[61] = z_rng_custom_bnc.IntValue;
	gChances[62] = z_rng_custom_bottle.IntValue;
	gChances[63] = z_rng_custom_bow.IntValue;
	gChances[64] = z_rng_custom_bt_nail.IntValue;
	gChances[65] = z_rng_custom_bt_sledge.IntValue;
	gChances[66] = z_rng_custom_btorch.IntValue;
	gChances[67] = z_rng_custom_caidao.IntValue;
	gChances[68] = z_rng_custom_chains.IntValue;
	gChances[69] = z_rng_custom_chair.IntValue;
	gChances[70] = z_rng_custom_chair2.IntValue;
	gChances[71] = z_rng_custom_combat_knife.IntValue;
	gChances[72] = z_rng_custom_computer_keyboard.IntValue;
	gChances[73] = z_rng_custom_concrete1.IntValue;
	gChances[74] = z_rng_custom_concrete2.IntValue;
	gChances[75] = z_rng_custom_custom_ammo_pack.IntValue;
	gChances[76] = z_rng_custom_dagger_water.IntValue;
	gChances[77] = z_rng_custom_daxe.IntValue;
	gChances[78] = z_rng_custom_dekustick.IntValue;
	gChances[79] = z_rng_custom_dhoe.IntValue;
	gChances[80] = z_rng_custom_didgeridoo.IntValue;
	gChances[81] = z_rng_custom_doc1.IntValue;
	gChances[82] = z_rng_custom_dshovel.IntValue;
	gChances[83] = z_rng_custom_dsword.IntValue;
	gChances[84] = z_rng_custom_dustpan.IntValue;
	gChances[85] = z_rng_custom_electric_guitar2.IntValue;
	gChances[86] = z_rng_custom_electric_guitar3.IntValue;
	gChances[87] = z_rng_custom_electric_guitar4.IntValue;
	gChances[88] = z_rng_custom_enchsword.IntValue;
	gChances[89] = z_rng_custom_finger.IntValue;
	gChances[90] = z_rng_custom_fishingrod.IntValue;
	gChances[91] = z_rng_custom_flamethrower.IntValue;
	gChances[92] = z_rng_custom_foot.IntValue;
	gChances[93] = z_rng_custom_fubar.IntValue;
	gChances[94] = z_rng_custom_gaxe.IntValue;
	gChances[95] = z_rng_custom_ghoe.IntValue;
	gChances[96] = z_rng_custom_gloves.IntValue;
	gChances[97] = z_rng_custom_gman.IntValue;
	gChances[98] = z_rng_custom_gpickaxe.IntValue;
	gChances[99] = z_rng_custom_gshovel.IntValue;
	gChances[100] = z_rng_custom_guandao.IntValue;
	gChances[101] = z_rng_custom_guitar.IntValue;
	gChances[102] = z_rng_custom_guitarra.IntValue;
	gChances[103] = z_rng_custom_hammer.IntValue;
	gChances[104] = z_rng_custom_hammer_roku.IntValue;
	gChances[105] = z_rng_custom_helms_anduril.IntValue;
	gChances[106] = z_rng_custom_helms_hatchet.IntValue;
	gChances[107] = z_rng_custom_helms_orcrist.IntValue;
	gChances[108] = z_rng_custom_helms_sting.IntValue;
	gChances[109] = z_rng_custom_helms_sword_and_shield.IntValue;
	gChances[110] = z_rng_custom_hylianshield.IntValue;
	gChances[111] = z_rng_custom_iaxe.IntValue;
	gChances[112] = z_rng_custom_ihoe.IntValue;
	gChances[113] = z_rng_custom_ipickaxe.IntValue;
	gChances[114] = z_rng_custom_isword.IntValue;
	gChances[115] = z_rng_custom_katana2.IntValue;
	gChances[116] = z_rng_custom_kitchen_knife.IntValue;
	gChances[117] = z_rng_custom_lamp.IntValue;
	gChances[118] = z_rng_custom_legosword.IntValue;
	gChances[119] = z_rng_custom_leon_knife.IntValue;
	gChances[120] = z_rng_custom_lightsaber.IntValue;
	gChances[121] = z_rng_custom_lobo.IntValue;
	gChances[122] = z_rng_custom_longsword.IntValue;
	gChances[123] = z_rng_custom_lpipe.IntValue;
	gChances[124] = z_rng_custom_m72law.IntValue;
	gChances[125] = z_rng_custom_mace.IntValue;
	gChances[126] = z_rng_custom_mace2.IntValue;
	gChances[127] = z_rng_custom_mastersword.IntValue;
	gChances[128] = z_rng_custom_meleejb.IntValue;
	gChances[129] = z_rng_custom_mirrorshield.IntValue;
	gChances[130] = z_rng_custom_mop.IntValue;
	gChances[131] = z_rng_custom_mop2.IntValue;
	gChances[132] = z_rng_custom_muffler.IntValue;
	gChances[133] = z_rng_custom_nailbat.IntValue;
	gChances[134] = z_rng_custom_onion.IntValue;
	gChances[135] = z_rng_custom_pickaxe.IntValue;
	gChances[136] = z_rng_custom_pipehammer.IntValue;
	gChances[137] = z_rng_custom_pot.IntValue;
	gChances[138] = z_rng_custom_platillo.IntValue;
	gChances[139] = z_rng_custom_riotshield.IntValue;
	gChances[140] = z_rng_custom_rockaxe.IntValue;
	gChances[141] = z_rng_custom_roku_bass.IntValue;
	gChances[142] = z_rng_custom_roku_cymbal.IntValue;
	gChances[143] = z_rng_custom_roku_guitar.IntValue;
	gChances[144] = z_rng_custom_scup.IntValue;
	gChances[145] = z_rng_custom_scythe_roku.IntValue;
	gChances[146] = z_rng_custom_sh2wood.IntValue;
	gChances[147] = z_rng_custom_shavel.IntValue;
	gChances[148] = z_rng_custom_shoe.IntValue;
	gChances[149] = z_rng_custom_skateboard.IntValue;
	gChances[150] = z_rng_custom_slasher.IntValue;
	gChances[151] = z_rng_custom_sledgehammer.IntValue;
	gChances[152] = z_rng_custom_small_knife.IntValue;
	gChances[153] = z_rng_custom_spickaxe.IntValue;
	gChances[154] = z_rng_custom_sshovel.IntValue;
	gChances[155] = z_rng_custom_ssword.IntValue;
	gChances[156] = z_rng_custom_syringe_gun.IntValue;
	gChances[157] = z_rng_custom_thrower.IntValue;
	gChances[158] = z_rng_custom_tireiron.IntValue;
	gChances[159] = z_rng_custom_tonfa_riot.IntValue;
	gChances[160] = z_rng_custom_tramontina.IntValue;
	gChances[161] = z_rng_custom_trashbin.IntValue;
	gChances[162] = z_rng_custom_vampiresword.IntValue;
	gChances[163] = z_rng_custom_wand.IntValue;
	gChances[164] = z_rng_custom_waterpipe.IntValue;
	gChances[165] = z_rng_custom_waxe.IntValue;
	gChances[166] = z_rng_custom_weapon_chalice.IntValue;
	gChances[167] = z_rng_custom_weapon_morgenstern.IntValue;
	gChances[168] = z_rng_custom_weapon_shadowhand.IntValue;
	gChances[169] = z_rng_custom_weapon_sof.IntValue;
	gChances[170] = z_rng_custom_woodbat.IntValue;
	gChances[171] = z_rng_custom_wpickaxe.IntValue;
	gChances[172] = z_rng_custom_wrench.IntValue;
	gChances[173] = z_rng_custom_wshovel.IntValue;
	gChances[174] = z_rng_custom_wsword.IntValue;
	gChances[175] = z_rng_custom_wulinmiji.IntValue;
	gChances[176] = z_rng_custom_zuko.IntValue;
	gChances[177] = z_rng_custom_zuko_knife.IntValue;
}

public void OnMapStart()
{
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32);
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "SurvivorBot::IsReachable");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hReachableCheck = EndPrepSDKCall();
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount || g_hReachableCheck == null)
		SetFailState("[Navigation Spawner] Bad data, please check your gamedata");
	
	HookEvent("player_left_safe_area", eEvent);
	
	g_bLoaded = true;
}

public Action tSpawn (Handle timer)
{
	if(!g_alreadyspawned) 
	{
		CreateRandomLoot(g_iLootCount);
		g_alreadyspawned = true;
	}
}

public void OnMapEnd()
{
	g_bLoaded = false;
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	if (!g_bLoaded)
		return;
	g_alreadyspawned = false;
	gChancesUpdate();
	CreateTimer(1.0, tSpawn);
}

void CreateRandomLoot (int count)
{
	Address iRandomArea;
	int entity;
	float vMins[3], vMaxs[3], vOrigin[3], vAngles[3];
	bool bContinue;
	
	int sum = 0;
		
	for (int g = 0; g < sizeof gChances; g++)
	{
		PrintToServer("%i - %i : %s", sum, (sum+gChances[g]),szWeapons[g]);
		sum += gChances[g];
	}
	
	for (int i = 0; i < count; i++)
	{
		if(rng_sinkroll.FloatValue >= GetRandomInt(1,100))
			return;
		
		PrintToServer("VALUE Count: %i i: %i", count, i);
		iRandomArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * GetRandomInt(0, TheCount)), NumberType_Int32));
		
		if (iRandomArea == Address_Null || (g_iNavFlagsCheck && LoadFromAddress(iRandomArea + view_as<Address>(84), NumberType_Int32) != 0x20000000))
			continue;
		
		
		vMins[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(4), NumberType_Int32));
		vMins[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(8), NumberType_Int32));
		vMins[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(12), NumberType_Int32));
		
		vMaxs[0] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(16), NumberType_Int32));
		vMaxs[1] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(20), NumberType_Int32));
		vMaxs[2] = view_as<float>(LoadFromAddress(iRandomArea + view_as<Address>(24), NumberType_Int32));

		AddVectors(vMins, vMaxs, vOrigin);
		ScaleVector(vOrigin, 0.5);
		
		if (g_iReachableCheck)
		{
			for (int l = 1; l <= MaxClients; l++) 
			{
				if (!IsClientInGame(l) || GetClientTeam(l) != 2 || !IsFakeClient(l))
					continue;
					
				if (SDKCall(g_hReachableCheck, l, vOrigin) != 1)
					bContinue = true;
				break;
			}
			
			if (bContinue)
				continue;
		}
		
		vAngles[1] = GetRandomFloat(-179.0, 179.0);
		
		int iRandom;
		
		int zWeapon = GetRandomInt(1,sum);
		PrintToServer("%i", zWeapon);
		
		for (int k = 0; zWeapon > 0; k++)
		{
			zWeapon -= gChances[k];
			iRandom = k;
		}
		PrintToServer("%s, %i", szWeapons[iRandom], iRandom);
		
		if (iRandom != 25 || iRandom != 26)
			vOrigin[2] += 21.0;
		else vOrigin[2] -= 100.0;

		if (iRandom <= 12 || iRandom >= 50)
		{
			Melee(szWeapons[iRandom], vOrigin, vAngles);
			continue;
		}
		
		entity = CreateEntityByName(szWeapons[iRandom]);
		
		if(!IsValidEntity(entity))
			return;

		int maxammo = 69;
		
		if (StrEqual(szWeapons[iRandom], "weapon_rifle", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_ak47", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_desert", false) || StrEqual(szWeapons[iRandom], "weapon_rifle_sg552", false))
		{
			maxammo = GetConVarInt(rng_assaultrifle_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_smg", false) || StrEqual(szWeapons[iRandom], "weapon_smg_silenced", false) || StrEqual(szWeapons[iRandom], "weapon_smg_mp5", false))
		{
			maxammo = GetConVarInt(rng_smg_max);
		}		
		else if (StrEqual(szWeapons[iRandom], "weapon_pumpshotgun", false) || StrEqual(szWeapons[iRandom], "weapon_shotgun_chrome", false))
		{
			maxammo = GetConVarInt(rng_shotgun_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_autoshotgun", false) || StrEqual(szWeapons[iRandom], "weapon_shotgun_spas", false))
		{
			maxammo = GetConVarInt(rng_autoshotgun_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_hunting_rifle", false) || StrEqual(szWeapons[iRandom], "weapon_sniper_military", false))
		{
			maxammo = GetConVarInt(rng_huntingrifle_max);
		}
		else if  (StrEqual(szWeapons[iRandom], "weapon_sniper_awp", false) || StrEqual(szWeapons[iRandom], "weapon_sniper_scout", false))
		{
			maxammo = GetConVarInt(rng_sniperrifle_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_grenade_launcher", false))
		{
			maxammo = GetConVarInt(rng_grenadelauncher_max);
		}
		else if (StrEqual(szWeapons[iRandom], "weapon_rifle_m60", false))
		{
			maxammo = GetConVarInt(rng_m60_max);
		}
		
		DispatchSpawn(entity);
		
		if (iRandom > 32)
		{
			SetEntProp(entity, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4);
		}
		
		if (entity <= MaxClients)
			continue;
		
		TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
		
		PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
	}
}

void Melee(const char[] szMelee, float vOrigin[3], float vAngles[3])
{
	int iWeapon = CreateEntityByName("weapon_melee");
	
	if (iWeapon <= MaxClients)
		return;
	
	DispatchKeyValue(iWeapon, "melee_script_name", szMelee);
	DispatchSpawn(iWeapon);
	TeleportEntity(iWeapon, vOrigin, vAngles, NULL_VECTOR);
	
	char szName[PLATFORM_MAX_PATH];
	GetEntPropString(iWeapon, Prop_Data, "m_strMapSetScriptName", szName, sizeof szName); 
	
	if (StrContains(szName, "hunter") != -1)
		AcceptEntityInput(iWeapon, "kill");
		
	PrintToServer("Spawned weapon at %f %f %f", vOrigin[0], vOrigin[1], vOrigin[2]);
}