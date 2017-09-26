#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <SteamWorks>
#include <smjansson>

#define PLUGIN_VERSION "0.0.1"
#define FORMAT_VERSION "0.0.2"

new Handle:PostUrl = INVALID_HANDLE;
EngineVersion cEngineVersion;

public Plugin myinfo = {
  name = "smGSI",
  author = "k47s",
  description = "Logs events to a webapi"
};



public void OnPluginStart() {
	
	PrintToServer("Plugin Started");
	
	PrintToServer("Determine engine version");
	cEngineVersion = GetEngineVersion();
	
	PrintToServer("Create config and ConVar");
	PostUrl = CreateConVar("smGSI_PostUrl", "http://localhost:3000/api/GameEvent", "The Url the events will be posted to.");
	AutoExecConfig(true, "smGSI");
	
	// Hook CVars
	//mp_restartgame = FindConVar("mp_restartgame");
	//if (mp_restartgame != null) {
	//  mp_restartgame.AddChangeHook(OnRestartGameChange);
	//}
	PrintToServer("Cvars hooked.");
	
	// Commands
	//AddCommandListener(OnPlayerChat, "say");
	//AddCommandListener(OnPlayerChatTeam, "say_team");
	PrintToServer("Command listeners hooked.");

	// CS Events
	HookEvent("player_death", Event_PlayerDeath);
	//HookEvent("player_hurt", Event_PlayerHurt);
	//HookEvent("item_purchase", Event_ItemPurchase);
	//HookEvent("bomb_beginplant", Event_BombBeginPlant);
	//HookEvent("bomb_abortplant", Event_BombAbortPlant);
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("bomb_exploded", Event_BombExploded);
	//HookEvent("bomb_dropped", Event_BombDropped);
	//HookEvent("bomb_pickup", Event_BombPickup);
	//HookEvent("defuser_dropped", Event_DefuserDropped);
 	//HookEvent("defuser_pickup", Event_DefuserPickup);
	//HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
	//HookEvent("bomb_abortdefuse", Event_BombAbortDefuse);
	//HookEvent("player_radio", Event_PlayerRadio);
	//HookEvent("weapon_fire", Event_WeaponFire);
	//HookEvent("weapon_fire_on_empty", Event_WeaponFireEmpty);
	//HookEvent("weapon_outofammo", Event_WeaponOutOfAmmo);
	//HookEvent("weapon_reload", Event_WeaponReload);
	//HookEvent("weapon_zoom", Event_WeaponZoom);
	//HookEvent("item_pickup", Event_ItemPickup);
	//HookEvent("hegrenade_detonate", Event_HEDetonate);
	//HookEvent("flashbang_detonate", Event_FlashDetonate);
	//HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
	//HookEvent("molotov_detonate", Event_MolotovDetonate);
	//HookEvent("decoy_detonate", Event_DecoyDetonate);
	//HookEvent("cs_win_panel_match", Event_WinPanelMatch);
	//HookEvent("round_start", Event_RoundStart);
	//HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_mvp", Event_RoundMvp);
	//HookEvent("player_blind", Event_PlayerBlind);
	//HookEvent("player_falldamage", Event_PlayerFallDamage);
	//HookEvent("inspect_weapon", Event_InspectWeapon);
	PrintToServer("CS Events hooked.");

	// Generic Events
	//HookEvent("player_score", Event_PlayerScore);
	//HookEvent("player_changename", Event_PlayerChangeName);
	//HookEvent("player_connect", Event_PlayerConnect);
	//HookEvent("player_disconnect", Event_PlayerDisconnect);
	//HookEvent("player_team", Event_PlayerTeam);
	//HookEvent("team_info", Event_TeamInfo);
	//HookEvent("team_score", Event_TeamScore);
	PrintToServer("Generic Events hooked.");
}

public void OnPluginEnd() {
  
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {	
	
	int attackerUserId = event.GetInt("attacker");		
	int attackerClientId = GetClientOfUserId(attackerUserId); 
	
	//Only check if attacker is not a bot
	if(attackerClientId > 0 && IsClientInGame(attackerClientId) && IsClientConnected(attackerClientId) && !IsFakeClient(attackerClientId)) 
	{
		int attackerSteamId = GetSteamAccountID(attackerClientId, false);
		decl String:attackerName[64]; 	 	
		GetClientName(attackerClientId, attackerName, sizeof(attackerName));
	
		new Handle:hObj = json_object(); 
		json_object_set_new(hObj, "Name", json_string(attackerName));
		json_object_set_new(hObj, "SteamId", json_integer(attackerSteamId));
		
		
		int victimUserId = event.GetInt("userid");
		int victimClientId = GetClientOfUserId(victimUserId);
		if(victimClientId > 0)
		{
			int victimSteamId = GetSteamAccountID(victimClientId, false);
			decl String:victimName[64]; 	 	
			GetClientName(victimClientId, victimName, sizeof(victimName));
		
			json_object_set_new(hObj, "victim", json_string(victimName));
			json_object_set_new(hObj, "victimSteamId", json_integer(victimSteamId));
		}
		
		int assisterUserId = event.GetInt("assister");  
		int assisterClientId = GetClientOfUserId(assisterUserId);
		if(assisterClientId > 0)
		{
			int assisterSteamId = GetSteamAccountID(assisterClientId, false);
			decl String:assisterName[64]; 	 	
			GetClientName(assisterClientId, assisterName, sizeof(assisterName));
			json_object_set_new(hObj, "assister", json_string(assisterName));
			json_object_set_new(hObj, "assisterSteamId", json_integer(assisterSteamId));	
		}
		
		char weapon[32];
		event.GetString("weapon", weapon, sizeof(weapon));
		
		bool isHeadshot = event.GetBool("headshot");
		int isPenetrated = event.GetInt("penetrated");  

		json_object_set_new(hObj, "weapon", json_string(weapon));
		if(isHeadshot == true)
		{
			json_object_set_new(hObj, "isHeadshot", json_true());
		}
		else
		{
			json_object_set_new(hObj, "isHeadshot", json_false());
		}
		
		if(isPenetrated > 0)
		{
			json_object_set_new(hObj, "isPenetrated", json_true());
		}
		else
		{
			json_object_set_new(hObj, "isPenetrated", json_false());
		}
		
		if(attackerClientId > 0  && victimClientId > 0 && GetClientTeam(attackerClientId) == GetClientTeam(victimClientId))
		{
			json_object_set_new(hObj, "isTeamkill", json_true());
		}
		else
		{
			json_object_set_new(hObj, "isTeamkill", json_false());
		}		
		PostRequest(hObj, name);
   	}
}


public Action Event_BombPlanted(Event event, const char[] name, bool dontBroadcast) {	
	SendUserIdEvent(event, name, "Name", "SteamId");	
}	

public Action Event_BombDefused(Event event, const char[] name, bool dontBroadcast) {	
	SendUserIdEvent(event, name, "Name", "SteamId");
}	

public Action Event_BombExploded(Event event, const char[] name, bool dontBroadcast) {	
	SendUserIdEvent(event, name, "Name", "SteamId");	
}

public Action Event_RoundMvp(Event event, const char[] name, bool dontBroadcast) {	
	SendUserIdEvent(event, name, "Name", "SteamId");	
}
	
	
public void SendUserIdEvent(Event event, const char[] name, const char[] playerNameColumn, const char[] playerSteamIdColumn)
{
	int userId = event.GetInt("userId");		
	int userClientId = GetClientOfUserId(userId); 
	
	if(IsRealPlayer(userClientId)) 
	{
		int userSteamId = GetSteamAccountID(userClientId, false);
		decl String:userName[64]; 	 	
		GetClientName(userClientId, userName, sizeof(userName));
		
		new Handle:hObj = json_object();        	
		json_object_set_new(hObj, playerNameColumn, json_string(userName));
		json_object_set_new(hObj, playerSteamIdColumn, json_integer(userSteamId));
		PostRequest(hObj, name);
	}
}


public void PostRequest(Handle hJson, const char[] eventName) {						
	//Do not log in warmup
	if(GameRules_GetProp("m_bWarmupPeriod") == 1)
	{
		return;		
	}
	
	//Check if json handle is valid
	if(hJson == INVALID_HANDLE)
	{
		LogError("ERROR hJson(%i) is invalid handle.", hJson);
		return;
	}
	
	json_object_set_new(hJson, "event", json_string(eventName));
	
	switch (cEngineVersion)
	{
		case Engine_CSGO:
		{
			json_object_set_new(hJson, "game", json_string("csgo"));
		}
	}

	//Transform the JSON object to a JSON string
	new String:sJSON[16384];
	json_dump(hJson, sJSON, sizeof(sJSON));

	if(PostUrl == INVALID_HANDLE)
	{
		return;
	}
	char sPostUrl[512];
	GetConVarString(PostUrl, sPostUrl, sizeof(sPostUrl));

	//Send HTTP request
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sPostUrl);	
	if(hRequest == INVALID_HANDLE) {
		LogError("ERROR hRequest(%i): %s", hRequest, sPostUrl);
		CloseHandle(hJson);
		return;
	}
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");

	SteamWorks_SetHTTPRequestRawPostBody(hRequest, "application/json", sJSON, strlen(sJSON));
	SteamWorks_SetHTTPCallbacks(hRequest, OnSteamWorksHTTPComplete);
	SteamWorks_SendHTTPRequest(hRequest);
	
	CloseHandle(hJson);
}

public int OnSteamWorksHTTPComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data) {	
	
	if (!bRequestSuccessful && eStatusCode != k_EHTTPStatusCode200OK)
	{	
		char sError[256];
		FormatEx(sError, sizeof(sError), "SteamWorks error (status code %i). Request successful: %s", _:eStatusCode, bRequestSuccessful ? "True" : "False");
		LogError(sError);
	}
	delete hRequest;
}

public bool IsRealPlayer(client)
{
	if(IsClientInGame(client) && IsClientConnected(client) && !IsFakeClient(client))
	{
		return true;
	}
	else
	{
		return false;
	}	
}

