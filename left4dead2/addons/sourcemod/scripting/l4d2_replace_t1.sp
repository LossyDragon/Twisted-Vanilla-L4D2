#include <sourcemod>
#include <sdktools>

ConVar replacet1

public Plugin:myinfo =
{
	name = "L4D2 Replace Tier 1 with Tier 2",
	author = "GBR (For base of plugin), Shao, RainyDagger",
	description = "",
	version = "1.2",
	url = ""
}

public OnPluginStart()
{
	replacet1 = CreateConVar("replace_tier1_with_tier2", "1", "1 will replace, 0 will remove.", 0, true, 0.0, true, 1.0);
	
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_RoundStart, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true, "l4d2_replace_t1");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(2.5, ReWeap);
}

public Action:ReWeap(Handle:timer)
{
	new EntCount = GetEntityCount();
	decl Float:position[3], Float:angle[3];
	for (new i = 0; i <= EntCount; i++)
	{
		if(IsValidEdict(i))
		{
			if (IsValidWeaponT1(i))
			{	
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
				GetEntPropVector(i, Prop_Data, "m_angRotation", angle);
				AcceptEntityInput(i, "Kill");
				
				if(replacet1.BoolValue)
				{
					new iWeapon;
					
					int randomNumber = GetRandomInt(0,9);
					
					switch(randomNumber)
					{
						case 0: iWeapon = CreateEntityByName("weapon_autoshotgun");
						case 1: iWeapon = CreateEntityByName("weapon_shotgun_spas");
						case 2: iWeapon = CreateEntityByName("weapon_rifle_spawn");
						case 3: iWeapon = CreateEntityByName("weapon_rifle_ak47"); 
						case 4: iWeapon = CreateEntityByName("weapon_rifle_desert"); 
						case 5: iWeapon = CreateEntityByName("weapon_rifle_sg552");
						case 6: iWeapon = CreateEntityByName("weapon_sniper_military");
						case 7: iWeapon = CreateEntityByName("weapon_sniper_awp"); 
						case 8: iWeapon = CreateEntityByName("weapon_hunting_rifle");
						case 9: iWeapon = CreateEntityByName("weapon_pistol_magnum");
					}	
	
					if(IsValidEntity(iWeapon))
					{
						int maxammo = 69;
						
						switch(randomNumber)
						{
							case 0,1: 		maxammo = FindConVar("ammo_autoshotgun_max").IntValue;
							case 2,3,4,5:	maxammo = FindConVar("ammo_rifle_max").IntValue;
							case 6,7: 		maxammo = FindConVar("ammo_sniperrifle_max").IntValue;
							case 8:			maxammo = FindConVar("ammo_huntingrifle_max").IntValue;
							
						}
						
						DispatchSpawn(iWeapon);
						SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4);
						DispatchKeyValue(iWeapon, "count", "6");
						TeleportEntity(iWeapon, position, angle, NULL_VECTOR);
					}
				}
			}
		}
	}	
}

bool:IsValidWeaponT1(index)
{
	decl String:sClass[128];
	GetEdictClassname(index, sClass, sizeof(sClass));
	if(StrContains(sClass, "weapon_spawn", false) == 0)
	{
		new m_weaponID = GetEntProp(index, Prop_Send, "m_weaponID");
		return (m_weaponID == 2 || m_weaponID == 7 || m_weaponID == 33 || m_weaponID == 3 || m_weaponID == 8 || m_weaponID == 36 || m_weaponID == 1)
	}
	
	return (StrContains(sClass, "weapon_smg_spawn", false) == 0
	|| StrContains(sClass, "weapon_smg_silenced_spawn", false) == 0
	|| StrContains(sClass, "weapon_smg_mp5_spawn", false) == 0
	|| StrContains(sClass, "weapon_pumpshotgun_spawn", false) == 0
	|| StrContains(sClass, "weapon_shotgun_chrome_spawn", false) == 0
	|| StrContains(sClass, "weapon_sniper_scout_spawn", false) == 0
	|| StrContains(sClass, "weapon_pistol_spawn", false) == 0);
}