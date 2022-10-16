#pragma semicolon 1
#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "0.5"

enum OS
{
	OS_Windows,
	OS_Linux
}

OS os_RetVal;

Address aDCF[4];

int iPlayer;
bool bCriteriaFix;

static int iOriginalBytes_DCF[28] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This is for L4D2 only");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Dialogue Criteria Fix",
	author = "cravenge",
	description = "Resolves issues with bugged talker criteria",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335875"
};

public void OnPluginStart()
{
	os_RetVal = GetServerOS();
	
	GameData gd_Temp = FetchGameData("dialogue_criteria_fix-l4d2");
	if (gd_Temp == null)
	{
		SetFailState("Game data file not found!");
	}
	
	int iTemp;
	
	Address aTemp = gd_Temp.GetAddress("ModifyOrAppendGlobalCriteria");
	if (aTemp != Address_Null)
	{
		iTemp = gd_Temp.GetOffset("ModifyOrAppendGlobalCriteria_TeamNumberCondition");
		if (iTemp != -1)
		{
			aDCF[0] = aTemp + view_as<Address>(iTemp);
			
			if (LoadFromAddress(aDCF[0], NumberType_Int8) != 0x02)
			{
				SetFailState("Offset for \"ModifyOrAppendGlobalCriteria_TeamNumberCondition\" is incorrect!");
			}
			
			StoreToAddress(aDCF[0], 0x03, NumberType_Int8);
			if (os_RetVal == OS_Linux)
			{
				StoreToAddress(aDCF[0] + view_as<Address>(2), 0x85, NumberType_Int8);
			}
			else
			{
				StoreToAddress(aDCF[0] + view_as<Address>(1), 0x74, NumberType_Int8);
			}
			
			PrintToServer("[FIX] Patched all \"IsAlive\" criteria to be appended for the Passing team as well");
		}
		else
		{
			SetFailState("Offset for \"ModifyOrAppendGlobalCriteria_TeamNumberCondition\" is missing!");
		}
		
		iTemp = gd_Temp.GetOffset("ModifyOrAppendGlobalCriteria_CharacterCondition");
		if (iTemp != -1)
		{
			aDCF[1] = aTemp + view_as<Address>(iTemp);
			
			if (LoadFromAddress(aDCF[1], NumberType_Int8) != 0x03)
			{
				SetFailState("Offset for \"ModifyOrAppendGlobalCriteria_CharacterCondition\" is incorrect!");
			}
			
			StoreToAddress(aDCF[1], 0x07, NumberType_Int8);
			
			PrintToServer("[FIX] Patched the L4D1 \"IsAlive\" criteria to be appended for the L4D2 survivor set as well");
		}
		else
		{
			SetFailState("Offset for \"ModifyOrAppendGlobalCriteria_CharacterCondition\" is missing!");
		}
	}
	else
	{
		SetFailState("Address for \"ModifyOrAppendGlobalCriteria\" is missing!");
	}
	
	aTemp = gd_Temp.GetAddress("ModifyOrAppendCriteria_CTP");
	if (aTemp != Address_Null)
	{
		char sTemp[64];
		for (int i = 0; i < 2; i++)
		{
			FormatEx(sTemp, sizeof(sTemp), "CTPModifyOrAppendCriteria_%sCall", (i != 0) ? "SurvivorSet" : "TeamNumber");
			
			iTemp = gd_Temp.GetOffset(sTemp);
			if (iTemp != -1)
			{
				aDCF[i + 2] = aTemp + view_as<Address>(iTemp);
				
				for (iTemp = 0; iTemp < 14; iTemp++)
				{
					iOriginalBytes_DCF[iTemp + 14 * i] = LoadFromAddress(aDCF[i + 2] + view_as<Address>(iTemp), NumberType_Int8);
					if (iTemp == 0 && iOriginalBytes_DCF[14 * i] != 0xE8)
					{
						SetFailState("Offset for \"%s\" is incorrect!", sTemp);
					}
					
					StoreToAddress(aDCF[i + 2] + view_as<Address>(iTemp), 0x90, NumberType_Int8);
				}
				
				PrintToServer("[FIX] Patched %s \"DistTo\" criteria to no longer check for the current %s", (i != 1) ? "all" : "the L4D1", (i == 1) ? "survivor set" : "team");
			}
			else
			{
				SetFailState("Offset for \"%s\" is missing!", sTemp);
			}
		}
	}
	else
	{
		SetFailState("Address for \"ModifyOrAppendCriteria_CTP\" returned NULL!");
	}
	
	DynamicDetour dd_Temp = DynamicDetour.FromConf(gd_Temp, "UTIL_PlayerByIndex");
	if (dd_Temp != null)
	{
		if (!dd_Temp.Enable(Hook_Post, dtrPlayerByIndex_Post))
		{
			SetFailState("Failed to make a post detour of \"UTIL_PlayerByIndex\"!");
		}
		
		PrintToServer("[FIX] Post detour of \"UTIL_PlayerByIndex\" has been successfully made!");
	}
	else
	{
		SetFailState("Signature for \"UTIL_PlayerByIndex\" is broken!");
	}
	
	dd_Temp = DynamicDetour.FromConf(gd_Temp, "AI_CriteriaSet::AppendCriteria");
	if (dd_Temp != null)
	{
		if (!dd_Temp.Enable(Hook_Pre, dtrAppendCriteriaPre))
		{
			SetFailState("Failed to make a pre-detour of \"AI_CriteriaSet::AppendCriteria\"!");
		}
		
		PrintToServer("[FIX] Pre-detour of \"AI_CriteriaSet::AppendCriteria\" has been successfully made!");
	}
	else
	{
		SetFailState("Signature for \"AI_CriteriaSet::AppendCriteria\" is broken!");
	}
	
	dd_Temp = DynamicDetour.FromConf(gd_Temp, "ModifyOrAppendGlobalCriteria");
	if (dd_Temp.Enable(Hook_Pre, dtrModifyOrAppendGlobalCriteria_Pre))
	{
		PrintToServer("[FIX] Pre-detour of \"ModifyOrAppendGlobalCriteria\" has been successfully made!");
	}
	else
	{
		SetFailState("Failed to make a pre-detour of \"ModifyOrAppendGlobalCriteria\"!");
	}

	
	dd_Temp = DynamicDetour.FromConf(gd_Temp, "CTerrorPlayer::ModifyOrAppendCriteria");
	if (dd_Temp.Enable(Hook_Pre, dtrModifyOrAppendCriteria_Pre))
	{
		PrintToServer("[FIX] Pre-detour of \"CTerrorPlayer::ModifyOrAppendCriteria\" has been successfully made!");
	}
	else
	{
		SetFailState("Failed to make a pre-detour of \"CTerrorPlayer::ModifyOrAppendCriteria\"!");
	}
	
	dd_Temp = DynamicDetour.FromConf(gd_Temp, "SurvivorResponseCachedInfo::GetClosestSurvivorTo");
	if (dd_Temp != null)
	{
		if (!dd_Temp.Enable(Hook_Pre, dtrGetClosestSurvivorTo_Pre))
		{
			SetFailState("Failed to make a pre-detour of \"SurvivorResponseCachedInfo::GetClosestSurvivorTo\"!");
		}
		
		PrintToServer("[FIX] Pre-detour of \"SurvivorResponseCachedInfo::GetClosestSurvivorTo\" has been successfully made!");
		
		delete dd_Temp;
		delete gd_Temp;
	}
	else
	{
		SetFailState("Signature for \"SurvivorResponseCachedInfo::GetClosestSurvivorTo\" is broken!");
	}
	
	CreateConVar("dialogue_criteria_fix-l4d2_ver", PLUGIN_VERSION, "Version of the plug-in", FCVAR_NOTIFY);
}

public MRESReturn dtrPlayerByIndex_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (!bCriteriaFix)
	{
		return MRES_Ignored;
	}
	
	if (hParams.Get(1) >= MaxClients)
	{
		bCriteriaFix = false;
	}
	
	int iReturn = hReturn.Value;
	if (iReturn != -1 && IsClientInGame(iReturn) && (GetClientTeam(iReturn) == 1 || GetEntProp(iReturn, Prop_Send, "m_survivorCharacter") < 0))
	{
		hReturn.Value = -1;
		return MRES_Override;
	}
	
	return HandlePlayerResponses(iReturn);
}

public MRESReturn dtrAppendCriteriaPre(DHookReturn hReturn, DHookParam hParams)
{
	static char sParam[24];
	hParams.GetString(1, sParam, sizeof(sParam));
	if (strncmp(sParam, "Is", 2) != 0 && strncmp(sParam, "DistTo", 6) != 0)
	{
		return MRES_Ignored;
	}
	
	int iCharacter;
	if (strncmp(sParam[strlen(sParam) - 5], "Alive", 5) == 0)
	{
		switch (sParam[5])
		{
			case 'b': iCharacter = 0;
			case 'd': iCharacter = 1;
			case 'c': iCharacter = 2;
			case 'h': iCharacter = 3;
			case 'V': iCharacter = 4;
			case 'n': iCharacter = 5;
			case 'e': iCharacter = 6;
			case 'a': iCharacter = 7;
		}
	}
	else
	{
		switch (sParam[9])
		{
			case 'a': iCharacter = 7;
			case 'e': iCharacter = 6;
			case 'n': iCharacter = 5;
			case 'V': iCharacter = 4;
			case 'h': iCharacter = 3;
			case 'c': iCharacter = 2;
			case 'd': iCharacter = 1;
			case 'b': iCharacter = 0;
			default: iCharacter = -1;
		}
	}
	
	float fTemp;
	int iTemp = GetNearestAliveSurvivor(iPlayer, fTemp, iCharacter);
	
	static char sNewParam[16];
	if (sParam[0] == 'D')
	{
		FormatEx(sNewParam, sizeof(sNewParam), "%.1f", fTemp);
	}
	else
	{
		FormatEx(sNewParam, sizeof(sNewParam), "%i", (iTemp == 0 && (GetEntProp(iPlayer, Prop_Send, "m_survivorCharacter") != iCharacter || !IsPlayerAlive(iPlayer))) ? "0" : "1");
	}
	
	hParams.SetString(2, sNewParam);
	return MRES_ChangedHandled;
}

public MRESReturn dtrModifyOrAppendGlobalCriteria_Pre(DHookReturn hReturn, DHookParam hParams)
{
	bCriteriaFix = true;
	return MRES_Ignored;
}

public MRESReturn dtrModifyOrAppendCriteria_Pre(int pThis, DHookReturn hReturn, DHookParam hParams)
{
	return HandlePlayerResponses(pThis);
}

public MRESReturn dtrGetClosestSurvivorTo_Pre(DHookReturn hReturn, DHookParam hParams)
{
	int iClosestSurvivor = GetNearestAliveSurvivor(iPlayer), iParam = hParams.Get(1),
		iCharacter = GetEntProp(iPlayer, Prop_Send, "m_survivorCharacter");
	
	hReturn.Value = (iClosestSurvivor == 0) ? ((iCharacter != iParam) ? iCharacter : iParam) : GetEntProp(iClosestSurvivor, Prop_Send, "m_survivorCharacter");
	return MRES_Supercede;
}

public void OnPluginEnd()
{
	int iTemp;
	for (int i = 3; i > -1; --i)
	{
		if (aDCF[i] == Address_Null)
		{
			continue;
		}
		
		if (1 < i)
		{
			PrintToServer("[FIX] Restoring the %s check for %s \"DistTo\" criteria...", (i != 3) ? "team" : "survivor set", (i != 2) ? "the L4D1" : "all");
			
			for (iTemp = 13; iTemp > -1; --iTemp)
			{
				StoreToAddress(aDCF[i] + view_as<Address>(iTemp), iOriginalBytes_DCF[iTemp + 14 * (i - 2)], NumberType_Int8);
				
				iOriginalBytes_DCF[iTemp + 14 * (i - 2)] = -1;
			}
		}
		else
		{
			if (i)
			{
				PrintToServer("[FIX] Detaching the L4D1 \"IsAlive\" criteria from the L4D2 survivor set...");
				
				StoreToAddress(aDCF[i], 0x03, NumberType_Int8);
			}
			else
			{
				PrintToServer("[FIX] Detaching all \"IsAlive\" criteria from the Passing team...");
				
				if (os_RetVal == OS_Windows)
				{
					StoreToAddress(aDCF[i] + view_as<Address>(1), 0x75, NumberType_Int8);
				}
				else
				{
					StoreToAddress(aDCF[i] + view_as<Address>(2), 0x84, NumberType_Int8);
				}
				StoreToAddress(aDCF[i], 0x02, NumberType_Int8);
			}
		}
	}
}

OS GetServerOS()
{
	static char sCmdLine[4];
	GetCommandLine(sCmdLine, sizeof(sCmdLine));
	return (sCmdLine[0] == '.') ? OS_Linux : OS_Windows;
}

GameData FetchGameData(const char[] file)
{
	char sFilePath[128];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/%s.txt", file);
	if (!FileExists(sFilePath))
	{
		File fileTemp = OpenFile(sFilePath, "w");
		if (fileTemp == null)
		{
			SetFailState("Something went wrong while creating the game data file!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ModifyOrAppendGlobalCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"ModifyOrAppendGlobalCriteria\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ModifyOrAppendCriteria_CTP\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"CTerrorPlayer::ModifyOrAppendCriteria\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Functions\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("				\"callconv\"				\"cdecl\"");
		fileTemp.WriteLine("				\"return\"				\"cbaseentity\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"AI_CriteriaSet::AppendCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"AI_CriteriaSet::AppendCriteria\"");
		fileTemp.WriteLine("				\"callconv\"				\"thiscall\"");
		fileTemp.WriteLine("				\"return\"				\"int\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"charptr\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a2\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"charptr\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("					\"a3\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"float\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ModifyOrAppendGlobalCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"signature\"			\"ForEachSurvivor<SurvivorAliveCritFunctor>\"");
		fileTemp.WriteLine("					\"return\"			\"bool\"");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("				\"linux\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"signature\"			\"ModifyOrAppendGlobalCriteria\"");
		fileTemp.WriteLine("					\"return\"			\"int\"");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("				\"callconv\"				\"cdecl\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CTerrorPlayer::ModifyOrAppendCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"CTerrorPlayer::ModifyOrAppendCriteria\"");
		fileTemp.WriteLine("				\"callconv\"				\"thiscall\"");
		fileTemp.WriteLine("				\"return\"				\"int\"");
		fileTemp.WriteLine("				\"this\"					\"entity\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"SurvivorResponseCachedInfo::GetClosestSurvivorTo\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"SurvivorResponseCachedInfo::GetClosestSurvivorTo\"");
		fileTemp.WriteLine("				\"callconv\"				\"thiscall\"");
		fileTemp.WriteLine("				\"return\"				\"int\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ModifyOrAppendGlobalCriteria_TeamNumberCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"1264\"");
		fileTemp.WriteLine("				\"linux\"		\"274\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ModifyOrAppendGlobalCriteria_CharacterCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"18\"");
		fileTemp.WriteLine("				\"linux\"		\"986\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CTPModifyOrAppendCriteria_TeamNumberCall\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"2281\"");
		fileTemp.WriteLine("				\"linux\"		\"3517\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CTPModifyOrAppendCriteria_SurvivorSetCall\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"2839\"");
		fileTemp.WriteLine("				\"linux\"		\"5844\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ModifyOrAppendGlobalCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZL28ModifyOrAppendGlobalCriteriaP14AI_CriteriaSet\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x56\\x57\\x8B\\x2A\\x8B\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x83\"");
		fileTemp.WriteLine("				/* 55 8B ? 56 57 8B ? 8B ? ? 8B ? ? ? ? ? 83 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CTerrorPlayer::ModifyOrAppendCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN13CTerrorPlayer22ModifyOrAppendCriteriaER14AI_CriteriaSet\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x83\\x2A\\x2A\\x55\\x8B\\x2A\\x2A\\x89\\x2A\\x2A\\x2A\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x33\\x2A\\x89\\x2A\\x2A\\x56\\x8B\\x2A\\x2A\\x33\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? 83 ? ? 83 ? ? 55 8B ? ? 89 ? ? ? 8B ? 81 ? ? ? ? ? A1 ? ? ? ? 33 ? 89 ? ? 56 8B ? ? 33 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_Z18UTIL_PlayerByIndexi\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x57\\x33\\x2A\\x85\\x2A\\x7E\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x3B\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? 57 33 ? 85 ? 7E ? 8B ? ? ? ? ? 3B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"AI_CriteriaSet::AppendCriteria\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN14AI_CriteriaSet14AppendCriteriaEPKcS1_f\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x56\\x8B\\x2A\\x50\\x8D\\x2A\\x2A\\x51\\xB9\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? 56 8B ? 50 8D ? ? 51 B9 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<SurvivorAliveCritFunctor>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\xBF\\x2A\\x2A\\x2A\\x2A\\x39\\x2A\\x2A\\x7C\\x2A\\x8B\\x2A\\x2A\\x57\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x83\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x2B\\x2A\\x2A\\xC1\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xFF\\x2A\\x84\\x2A\\x74\\x2A\\x83\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x75\\x2A\\x56\\x8B\\x2A\\xE8\\x05\\xFB\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? ? 53 56 57 BF ? ? ? ? 39 ? ? 7C ? 8B ? ? 57 E8 ? ? ? ? 8B ? 83 ? ? 85 ? 74 ? 8B ? ? 85 ? 74 ? 8B ? ? ? ? ? 2B ? ? C1 ? ? 85 ? 74 ? 8B ? 8B ? ? ? ? ? 8B ? FF ? 84 ? 74 ? 83 ? ? ? ? ? ? 74 ? 8B ? E8 ? ? ? ? 83 ? ? 75 ? 56 8B ? E8 05 FB */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"SurvivorResponseCachedInfo::GetClosestSurvivorTo\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN26SurvivorResponseCachedInfo20GetClosestSurvivorToE21SurvivorCharacterType\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xC1\\x2A\\x2A\\x03\\x2A\\x57\\xB9\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? ? 8B ? C1 ? ? 03 ? 57 B9 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(file);
}

MRESReturn HandlePlayerResponses(int client)
{
	iPlayer = client;
	return MRES_Ignored;
}

int GetNearestAliveSurvivor(int client, float &dist = 0.0, int character = -1)
{
	int iRetVal, iTeam;
	float fPos[2][3], fDist, fMinDist = 1000000000.0;
	
	GetClientAbsOrigin(client, fPos[0]);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || i == client)
		{
			continue;
		}
		
		iTeam = GetClientTeam(i);
		if (iTeam == 2 || iTeam == 4)
		{
			if (!IsPlayerAlive(i) || (character != -1 && GetEntProp(i, Prop_Send, "m_survivorCharacter") != character))
			{
				continue;
			}
			
			GetClientAbsOrigin(i, fPos[1]);
			
			fDist = GetVectorDistance(fPos[0], fPos[1]);
			if (fMinDist == 1000000000.0 || fDist < fMinDist)
			{
				fMinDist = fDist;
				
				iRetVal = i;
			}
		}
	}
	
	dist = fMinDist;
	return iRetVal;
}

