#pragma semicolon 1
#pragma newdecls required

//Including
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

//Define Plugin Info
#define NAME 					"L4D2 Custom Reserve Ammo Plugin | L4D2自定义后备子弹插件" //定义插件名字
#define AUTHOR 					"ZZH | 凌凌漆" //定义作者
#define DESCRIPTION 			"L4D2 Custom Reserve Ammo Plugin | L4D2自定义后备子弹插件"	//定义插件描述
#define	VERSION 				"1.0.0.0" //定义插件版本
#define URL 					"https://steamcommunity.com/id/ChengChiHou/" //定义作者联系地址

char g_szFilePath[512];

StringMap g_smWeaponReserveAmmo;

bool g_bWeaponReserveAmmoSet[2048] = false;

int g_iPrimaryWeaponReserveAmmoCount[2048] = 0;

//Plugin Info
public Plugin myinfo =
{
	name			=	NAME,
	author			=	AUTHOR,
	description		=	DESCRIPTION,
	version			=	VERSION,
	url				=	URL
};

public void OnPluginStart()
{
	BuildPath(Path_SM, g_szFilePath, sizeof(g_szFilePath), "configs/L4D2_ReserverAmmo.cfg");

	g_smWeaponReserveAmmo = new StringMap();

	ResetAllWeapon();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && !IsFakeClient(i))
		{
			OnClientPutInServer(i);
		}
	}

	HookEvent("player_use", Event_PlayerUse, EventHookMode_Post);
}

public void OnMapStart()
{
	ResetAllWeapon();
}

public void OnConfigsExecuted()
{
	LoadConfigs();
}

public void LoadConfigs()
{
	if(FileExists(g_szFilePath))
	{
		KeyValues kv = new KeyValues("CustomReserveAmmo");
		kv.ImportFromFile(g_szFilePath);
		kv.Rewind();
		kv.JumpToKey("WeaponClass", false);
		if(kv.GotoFirstSubKey(false))
		{
			do
			{
				int iReserveAmmo = 0;
				char WeaponClassname[512], szReserveAmmo[512];
				kv.GetSectionName(WeaponClassname, sizeof(WeaponClassname));
				kv.GetString(NULL_STRING, szReserveAmmo, sizeof(szReserveAmmo), "");
				iReserveAmmo = StringToInt(szReserveAmmo);
				g_smWeaponReserveAmmo.SetValue(WeaponClassname, iReserveAmmo);
			} while (kv.GotoNextKey(false));
		}
		delete kv;
	}
	else
	{
		KeyValues kv = new KeyValues("CustomReserveAmmo");
		kv.Rewind();
		kv.JumpToKey("WeaponClass", true);
		kv.SetString("weapon_rifle", "1024");
		kv.SetString("weapon_rifle_ak47", "1000");
		kv.SetString("weapon_rifle_desert", "360");
		kv.SetString("weapon_rifle_sg552", "360");
		kv.SetString("weapon_smg", "999");
		kv.SetString("weapon_smg_silenced", "999");
		kv.SetString("weapon_smg_mp5", "999");
		kv.SetString("weapon_sniper_military", "300");
		kv.SetString("weapon_hunting_rifle", "200");
		kv.SetString("weapon_sniper_awp", "300");
		kv.SetString("weapon_sniper_scout", "300");
		kv.SetString("weapon_shotgun_spas", "200");
		kv.SetString("weapon_autoshotgun", "200");
		kv.SetString("weapon_shotgun_chrome", "160");
		kv.SetString("weapon_pumpshotgun", "160");
		kv.Rewind();
		kv.ExportToFile(g_szFilePath);
		delete kv;
		CreateTimer(0.0, Timer_ReloadConfigs, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_ReloadConfigs(Handle Timer)
{
	LoadConfigs();
}

public void OnClientPutInServer(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		int slot0 = GetPlayerWeaponSlot(client, 0);
		if(slot0 != -1)
		{
			if(g_bWeaponReserveAmmoSet[slot0])
			{
				g_iPrimaryWeaponReserveAmmoCount[slot0] = GetPrimaryWeaponReserveAmmo(client, slot0);
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	if(IsValidClient(client) && !IsFakeClient(client))
	{
		SDKUnhook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
	}
}

public void OnWeaponEquipPost(int client, int weapon)
{
	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if(IsValidEdict(weapon) && IsValidEntity(weapon))
		{
			if(!g_bWeaponReserveAmmoSet[weapon])
			{
				SetReserveAmmo(client, weapon, false);
			}
			else
			{
				SetLastReserveAmmo(client, weapon);
			}
		}
	}
}

public Action Timer_SetPrimaryReserveAmmo(Handle Timer, DataPack pack)
{
	int client, AmmoType, AmmoValue, weapon;
	pack.Reset();
	client = GetClientOfUserId(pack.ReadCell());
	AmmoType = pack.ReadCell();
	AmmoValue = pack.ReadCell();
	weapon = pack.ReadCell();
	g_bWeaponReserveAmmoSet[weapon] = true;

	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", AmmoValue, 4, AmmoType);
	}
}

public Action Timer_SetPrimaryWeaponReserveAmmo(Handle Timer, DataPack pack)
{
	int client, AmmoType, ReserveAmmoCount;
	pack.Reset();
	client = GetClientOfUserId(pack.ReadCell());
	AmmoType = pack.ReadCell();
	ReserveAmmoCount = pack.ReadCell();

	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		SetEntProp(client, Prop_Send, "m_iAmmo", ReserveAmmoCount, 4, AmmoType);
	}
}

public Action Event_PlayerUse(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	int entity = hEvent.GetInt("targetid");
	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if(IsValidEdict(entity) && IsValidEntity(entity))
		{
			SetReserveAmmo(client, entity, true);
		}
	}
}

stock void ResetAllWeapon()
{
	for(int i = 0; i < 2048; i++)
	{
		if(g_bWeaponReserveAmmoSet[i])
		{
			g_bWeaponReserveAmmoSet[i] = false;
		}
	}
}

//Check If Valid Client
stock bool IsValidClient(int client, bool AllowBot = true, bool AllowDeath = true, bool AllowSpectator = true, bool AllowReplay = true)
{
	if(client < 1 || client > MaxClients) //判断服务器是否不存在玩家或满员
	{
		return false;
	}
	if(!IsClientConnected(client) || !IsClientInGame(client)) //判断玩家是否没有连接服务器成功或没有进入游戏
	{
		return false;
	}
	if(!AllowReplay) //是否允许玩家是GOTV或回放机器人？
	{
		if(IsClientSourceTV(client) || IsClientReplay(client))
		{
			return false;
		}
	}
	return true;
}

stock void SetReserveAmmo(int client, int weapon, bool playeruse)
{
	char classname[256], SlotClass[256];
	GetEdictClassname(weapon, classname, sizeof(classname));
	if(playeruse)
	{
		if(StrEqual(classname, "weapon_ammo_spawn", false))
		{
			int slot0 = GetPlayerWeaponSlot(client, 0);
			if(slot0 != -1)
			{
				if(g_bWeaponReserveAmmoSet[slot0])
				{
					int AmmoType = 0, AmmoValue = 0;
					AmmoType = GetEntProp(slot0, Prop_Send, "m_iPrimaryAmmoType");
					GetEdictClassname(slot0, SlotClass, sizeof(SlotClass));
					g_smWeaponReserveAmmo.GetValue(SlotClass, AmmoValue);
					if(AmmoType != -1)
					{
						if(GetEntProp(client, Prop_Send, "m_iAmmo", 4, AmmoType) != AmmoValue)
						{
							DataPack pack = new DataPack();
							CreateDataTimer(0.0, Timer_SetPrimaryReserveAmmo, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
							pack.WriteCell(GetClientUserId(client));
							pack.WriteCell(AmmoType);
							pack.WriteCell(AmmoValue);
							pack.WriteCell(slot0);
						}
					}
				}
			}
		}
	}
	else
	{
		int slot0 = GetPlayerWeaponSlot(client, 0);
		if(slot0 != -1)
		{
			if(!g_bWeaponReserveAmmoSet[slot0])
			{
				int AmmoType = 0, AmmoValue = 0;
				AmmoType = GetEntProp(slot0, Prop_Send, "m_iPrimaryAmmoType");
				GetEdictClassname(slot0, SlotClass, sizeof(SlotClass));
				g_smWeaponReserveAmmo.GetValue(SlotClass, AmmoValue);
				if(AmmoType != -1)
				{
					if(GetEntProp(client, Prop_Send, "m_iAmmo", 4, AmmoType) != AmmoValue)
					{
						DataPack pack = new DataPack();
						CreateDataTimer(0.0, Timer_SetPrimaryReserveAmmo, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
						pack.WriteCell(GetClientUserId(client));
						pack.WriteCell(AmmoType);
						pack.WriteCell(AmmoValue);
						pack.WriteCell(slot0);
					}
				}
			}
		}
	}
}

stock void SetLastReserveAmmo(int client, int weapon)
{
	int AmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	if(GetEntProp(client, Prop_Send, "m_iAmmo", 4, AmmoType) != g_iPrimaryWeaponReserveAmmoCount[weapon])
	{
		DataPack pack = new DataPack();
		CreateDataTimer(0.0, Timer_SetPrimaryWeaponReserveAmmo, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_DATA_HNDL_CLOSE);
		pack.WriteCell(GetClientUserId(client));
		pack.WriteCell(AmmoType);
		pack.WriteCell(g_iPrimaryWeaponReserveAmmoCount[weapon]);
	}
}

stock int GetPrimaryWeaponReserveAmmo(int client, int weapon)
{
	if(IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
	{
		if(g_bWeaponReserveAmmoSet[weapon])
		{
			int AmmoType = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
			return GetEntProp(client, Prop_Send, "m_iAmmo", 4, AmmoType);
		}
	}
	return 0;
}