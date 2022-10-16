#include <sourcemod>
#include <sdktools>

ConVar replacet2

public Plugin:myinfo =
{
	name = "L4D2 Replace Tier 2 with Tier 1",
	author = "GBR (For base of plugin), Shao, RainyDagger",
	description = "",
	version = "1.2",
	url = ""
}

public OnPluginStart()
{
	replacet2 = CreateConVar("replace_tier2_with_tier1", "1", "1 will replace, 0 will remove.", 0, true, 0.0, true, 1.0);

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_RoundStart, EventHookMode_PostNoCopy);
	
	AutoExecConfig(true, "l4d2_replace_t2");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(2.0, ReWeap);
}

public Action:ReWeap(Handle:timer)
{
	new EntCount = GetEntityCount();
	decl Float:position[3], Float:angle[3];
	for (new i = 0; i <= EntCount; i++)
	{
		if(IsValidEdict(i))
		{
			if (IsValidWeaponT2(i))
			{	
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", position);
				GetEntPropVector(i, Prop_Data, "m_angRotation", angle);
				AcceptEntityInput(i, "Kill");
				
				if(replacet2.BoolValue)
				{
					new iWeapon;
					
					int randomNumber = GetRandomInt(0,6);
					
					switch(randomNumber)
					{
						case 0: iWeapon = CreateEntityByName("weapon_smg");
						case 1: iWeapon = CreateEntityByName("weapon_pumpshotgun");
						case 2: iWeapon = CreateEntityByName("weapon_smg_silenced");
						case 3: iWeapon = CreateEntityByName("weapon_shotgun_chrome"); 
						case 4: iWeapon = CreateEntityByName("weapon_smg_mp5"); 
						case 5: iWeapon = CreateEntityByName("weapon_sniper_scout");
						case 6: iWeapon = CreateEntityByName("weapon_pistol");
					}	
	
					if(IsValidEntity(iWeapon))
					{
						int maxammo = 69;
						
						switch(randomNumber)
						{
							case 0,2,4: maxammo = FindConVar("ammo_smg_max").IntValue;
							case 1,3: 	maxammo = FindConVar("ammo_shotgun_max").IntValue;
							case 5: 	maxammo = FindConVar("ammo_sniperrifle_max").IntValue;
						}
						
						DispatchSpawn(iWeapon);
						SetEntProp(iWeapon, Prop_Send, "m_iExtraPrimaryAmmo", maxammo ,4);
						DispatchKeyValue(iWeapon, "count", "1");
						TeleportEntity(iWeapon, position, angle, NULL_VECTOR);
					}
				}
			}
		}
	}	
}

bool:IsValidWeaponT2(index)
{
	decl String:sClass[128];
	GetEdictClassname(index, sClass, sizeof(sClass));
	if(StrContains(sClass, "weapon_spawn", false) == 0)
	{
		new m_weaponID = GetEntProp(index, Prop_Send, "m_weaponID");
		return (m_weaponID == 4 || m_weaponID == 11 || m_weaponID == 5 || m_weaponID == 26 || m_weaponID == 9 || m_weaponID == 34 || m_weaponID == 10 || m_weaponID == 35 || m_weaponID == 6 || m_weaponID == 32)
	}
	
	return (StrContains(sClass, "weapon_autoshotgun_spawn", false) == 0
	|| StrContains(sClass, "weapon_shotgun_spas_spawn", false) == 0
	|| StrContains(sClass, "weapon_rifle_spawn", false) == 0
	|| StrContains(sClass, "weapon_rifle_ak47_spawn", false) == 0
	|| StrContains(sClass, "weapon_rifle_desert_spawn", false) == 0
	|| StrContains(sClass, "weapon_rifle_sg552_spawn", false) == 0
	|| StrContains(sClass, "weapon_sniper_military_spawn", false) == 0
	|| StrContains(sClass, "weapon_sniper_awp_spawn", false) == 0
	|| StrContains(sClass, "weapon_hunting_rifle_spawn", false) == 0
	|| StrContains(sClass, "weapon_pistol_magnum_spawn", false) == 0);
}