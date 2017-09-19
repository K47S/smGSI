#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <SteamWorks>

#define PLUGIN_VERSION "0.0.1"
#define FORMAT_VERSION "0.0.2"

public Plugin myinfo = {
  name = "sourcemodgsi",
  author = "k47s",
  description = "Logs events to a webapi"
};

public void OnPluginStart() {
	
	PrintToServer("Plugin Started");
	
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
	//HookEvent("bomb_planted", Event_BombPlanted);
	//HookEvent("bomb_defused", Event_BombDefused);
	//HookEvent("bomb_exploded", Event_BombExploded);
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
	//HookEvent("round_mvp", Event_RoundMvp);
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
	
	PrintToServer("Send keep alive.");
	KeyValues kv = new KeyValues("PostParams");
	PostRequest(kv, "keepAlive");
	PrintToServer("Keep alive send");
	
}

public void OnPluginEnd() {
  
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {	
	
	int attacker = event.GetInt("attacker");	
	if( ( IsClientInGame( attacker ) && IsClientConnected( attacker ) ) && !IsFakeClient( attacker ) ) {
    		char weapon[32];
		event.GetString("weapon", weapon, sizeof(weapon));
		int killedClient = event.GetInt("userid");
    		int assister = event.GetInt("assister");    
		bool isHeadshot = event.GetBool("headshot");
		int isPenetrated = event.GetInt("penetrated");  
		//TODO send Request
		
		KeyValues kv = new KeyValues("PostParams");
		kv.SetString("attacker", attacker);
		kv.SetString("weapon", weapon);
		kv.SetString("killedClient", killedClient);
		kv.SetString("assister", assister);
		kv.SetString("isHeadshot", isHeadshot);
		kv.SetString("isPenetrated", isPenetrated);
		PostRequest(kv);
   	}
}

public void PostRequest(KeyValues kv, char[] eventName) {
	// Create params
	char sRedirect[] = "http://localhost:3000/";
	
	Handle hRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sRedirect);
	if(hRequest == INVALID_HANDLE) {
		LogError("ERROR hRequest(%i): %s", hRequest, sRedirect);
		return;
	}
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Pragma", "no-cache");
	SteamWorks_SetHTTPRequestHeaderValue(hRequest, "Cache-Control", "no-cache");

	SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, "event", eventName);
	do
	{		
		if (kv.GetDataType(NULL_STRING) != KvData_None)
		{
			char keyName[255];
			kv.GetSectionName(keyName, sizeof(keyName));
			
			char keyValue[255];
			kv.GetString(NULL_STRING, keyValue, sizeof(keyValue));
			
			SteamWorks_SetHTTPRequestGetOrPostParameter(hRequest, keyName, keyValue);
		}
		else
		{
			// Found an empty sub section. It can be handled here if necessary.
		}		
	} while (kv.GotoNextKey(false));

	SteamWorks_SetHTTPCallbacks(hRequest, OnSteamWorksHTTPComplete);
	SteamWorks_SendHTTPRequest(hRequest);
	
	delete kv;
}

public int OnSteamWorksHTTPComplete(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, any data) {	
	
	if (!bRequestSuccessful && !eStatusCode == k_EHTTPStatusCode200OK) 
	{	
		char sError[256];
		FormatEx(sError, sizeof(sError), "SteamWorks error (status code %i). Request successful: %s", _:eStatusCode, bRequestSuccessful ? "True" : "False");
		LogError(sError);
	}
	delete hRequest;
}
