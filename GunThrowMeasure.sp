#include <sourcemod>
#include <sdkhooks>

#define EFL_NO_THINK_FUNCTION (1<<22)
#define WEAPON_NOT_CARRIED 0

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "GunThrowMeasure",
	author = "technyk",
	description = "A plugin made to measure the distance of gun throws",
	version = "1.0",
	url = "https://github.com/technyk"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_CSGO)
	{
		SetFailState("This plugin was made for use with Counter-Strike: Global Offensive only.");
	}
}

public void OnPluginStart()
{
	for (int client = 1; client <= MaxClients; client++) {
		if (IsClientInGame(client)) {
			OnClientPutInServer(client);
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponDropPost, OnWeaponDropped);
}

void OnWeaponDropped(int client, int weapon)
{
	if (!IsValidEntity(weapon) || !IsClientInGame(client)) {
		return;
	}
	
	float clientPosition[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsOrigin", clientPosition);
	
	DataPack data = new DataPack();
	data.WriteCell(GetClientSerial(client));
	data.WriteCell(EntIndexToEntRef(weapon));
	data.WriteCell(GetTime() + 5);
	data.WriteFloatArray(clientPosition, 3);
	RequestFrame(Frame_CheckGround, data);
}

void Frame_CheckGround(DataPack data)
{
	
	data.Reset();
	int clientSerial = data.ReadCell();
	int weaponRef = data.ReadCell();
	int maxThinkTime = data.ReadCell();
	
	float clientPosition[3];
	data.ReadFloatArray(clientPosition, 3);
	
	int client = GetClientFromSerial(clientSerial);
	int weapon = EntRefToEntIndex(weaponRef);
	if (weapon == -1 || !client || GetTime() > maxThinkTime)
	{
		delete data;
		return;
	}
	
	int flags = GetEntProp(weapon, Prop_Data, "m_iEFlags");

	
	if (flags & EFL_NO_THINK_FUNCTION && GetWeaponState(weapon) == WEAPON_NOT_CARRIED)
	{
		
		float gunPosition[3];
		GetEntPropVector(weapon, Prop_Data, "m_vecAbsOrigin", gunPosition);
		
		float distance = GetVectorDistance(clientPosition, gunPosition);
		
		char plrName[64];
		GetClientName(client, plrName, sizeof(plrName));
		
		PrintToChatAll(" \x04%s \x01hodil zbraň do dálky \x04%.2f \x01jednotek", plrName, distance);
		
		
		delete data;
		return;
	}
	
	RequestFrame(Frame_CheckGround, data);
}

int GetWeaponState(int weapon)
{
	return GetEntProp(weapon, Prop_Data, "m_iState");
} 