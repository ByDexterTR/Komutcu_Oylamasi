#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <warden>

int KomSayisi = 0, Sure = -1;
bool Komal[65] =  { false, ... }, Kovuldu[65] =  { false, ... };
bool Oylama = false;

ConVar ConVar_KomSayiSinir = null, ConVar_KomAlimSure = null, ConVar_KomOylamaSure = null, ConVar_CikanGiremesin = null;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Komutçu Oylaması", 
	author = "ByDexter", 
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/ByDexterTR - ByDexter#5494"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_komaday", Command_Komaday, "sm_komaday");
	RegConsoleCmd("sm_komkatil", Command_Komaday, "sm_komkatil");
	RegConsoleCmd("sm_komadaysil", Command_Komadaysil, "sm_komadaysil");
	RegConsoleCmd("sm_komayril", Command_Komadaysil, "sm_komayril");
	RegAdminCmd("sm_komal", Command_Komal, ADMFLAG_BAN, "sm_komal");
	RegAdminCmd("sm_komoyla", Command_Komal, ADMFLAG_BAN, "sm_komoyla");
	RegAdminCmd("sm_komsil", Command_Komsil, ADMFLAG_BAN, "sm_komsil <Hedef>");
	RegAdminCmd("sm_komiptal", Command_Komoylaiptal, ADMFLAG_BAN, "sm_komiptal");
	
	ConVar_KomSayiSinir = CreateConVar("sm_komutcu-oylamasi_katilimci_sayi", "5", "En Fazla kaç kişi katılsın ?", 0, true, 1.0, true, 6.0);
	ConVar_KomAlimSure = CreateConVar("sm_komutcu-oylamasi_alim_sure", "15", "Kaç saniye boyunca oylamaya katılabilsinler ?", 0, true, 15.0, true, 60.0);
	ConVar_KomOylamaSure = CreateConVar("sm_komutcu-oylamasi_oylama_sure", "30", "Kaç saniye olsun oylama", 0, true, 15.0, true, 60.0);
	ConVar_CikanGiremesin = CreateConVar("sm_komutcu-oylamasi_cikan", "1", "Çıkan tekrar katılabilsin mi ? [ 0 = Hayır | 1 = Evet ]", 0, true, 0.0, true, 1.0);
	AutoExecConfig(true, "Komal", "ByDexter");
}

public Action Command_Komsil(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] \x01Kullanım: sm_komsil <Hedef>");
		return Plugin_Handled;
	}
	char arg1[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true, true);
	if (target == COMMAND_TARGET_NONE || target == COMMAND_TARGET_AMBIGUOUS || target == COMMAND_FILTER_NO_IMMUNITY)
	{
		ReplyToTargetError(client, target);
		return Plugin_Handled;
	}
	if (!IsClientInGame(target))
	{
		ReplyToCommand(client, "[SM] \x01Bu hedef geçirsiz.");
		return Plugin_Handled;
	}
	if (!Komal[target])
	{
		ReplyToCommand(client, "[SM] \x01Bu hedef Komutçu Oylamasına katılmamış.");
		return Plugin_Handled;
	}
	PrintToChat(target, "[SM] \x01Oylamadan atıldın.");
	Kovuldu[target] = true;
	Komal[target] = false;
	SetClientListeningFlags(client, VOICE_MUTED);
	KomSayisi--;
	return Plugin_Handled;
}

public Action Command_Komaday(int client, int args)
{
	if (!Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylama başlatılmamış.");
		return Plugin_Handled;
	}
	if (Komal[client])
	{
		ReplyToCommand(client, "[SM] \x01Zaten Komutçu Oylamasına katılmışsın.");
		return Plugin_Handled;
	}
	if (KomSayisi >= ConVar_KomSayiSinir.IntValue)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylama katılımcı limiti dolmuş.");
		return Plugin_Handled;
	}
	if (Sure == -1)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması başlamış.");
		return Plugin_Handled;
	}
	if (Kovuldu[client])
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylamasından Kovulduğun/Çıktığın için tekrar katılamazsın.");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasına katıldın.");
	Komal[client] = true;
	SetClientListeningFlags(client, VOICE_NORMAL);
	KomSayisi++;
	return Plugin_Handled;
}

public Action Command_Komadaysil(int client, int args)
{
	if (!Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması başlatılmamış.");
		return Plugin_Handled;
	}
	if (!Komal[client])
	{
		ReplyToCommand(client, "[SM] \x01Zaten Oylamaya katılmamışsın.");
		return Plugin_Handled;
	}
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasından ayrıldın.");
	Komal[client] = false;
	SetClientListeningFlags(client, VOICE_MUTED);
	KomSayisi--;
	return Plugin_Handled;
}

public Action Command_Komal(int client, int args)
{
	if (Oylama)
	{
		ReplyToCommand(client, "[SM] \x01Komutçu Oylaması zaten başlatılmış.");
		return Plugin_Handled;
	}
	if (!ConVar_CikanGiremesin.BoolValue)
	{
		Kovuldu[client] = true;
	}
	Oylama = true;
	KomSayisi = 0;
	Sure = ConVar_KomAlimSure.IntValue;
	CreateTimer(1.0, MenuKontrolEt, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	return Plugin_Handled;
}

public Action Command_Komoylaiptal(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
	{
		Kovuldu[i] = false;
		Komal[i] = false;
	}
	Oylama = false;
	Sure = -1;
	KomSayisi = 0;
	ReplyToCommand(client, "[SM] \x01Komutçu Oylamasını iptal ettin.");
	PrintToChatAll("[SM] \x01\x10%N \x01tarafından Komutçu Oylaması iptal edildi.", client);
	return Plugin_Handled;
}

public Action MenuKontrolEt(Handle timer, any data)
{
	if (Oylama)
	{
		if (Sure > 0)
		{
			Sure--;
			Menu menu = new Menu(Menu_CallBack);
			menu.SetTitle("★ Komutçu Oylaması <%d/%d> ★\n➜ %d Saniye Sonra Oylama başlayacaktır.\n \n➜ !komkatil - !komaday Oylama katılabilirsiniz.\n➜ !komayril - !komadaysil Oylamadan ayrılabilirsiniz.\n➜ !komsil <Hedef> Oylamadan çıkartabilirsiniz.\n➜ !komiptal Oylamayı durdur.\n \n➜ Katılımcılar:", KomSayisi, ConVar_KomSayiSinir.IntValue, Sure);
			if (KomSayisi == 0)
			{
				menu.AddItem("X", "Kimse Katılmadı!", ITEMDRAW_DISABLED);
			}
			else
			{
				char ClientName[128];
				for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && Komal[i])
				{
					GetClientName(i, ClientName, sizeof(ClientName));
					menu.AddItem("X", ClientName, ITEMDRAW_DISABLED);
				}
			}
			menu.ExitBackButton = false;
			menu.ExitButton = false;
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
			{
				menu.Display(i, 1);
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && Kovuldu[i])
			{
				Kovuldu[i] = false;
			}
			Sure = -1;
			if (KomSayisi <= 0)
			{
				Oylama = false;
				KomSayisi = 0;
				PrintToChatAll("[SM] \x01Komutçu oylamasına kimse katılmadı.");
			}
			else if (KomSayisi == 1)
			{
				Oylama = false;
				KomSayisi = 0;
				for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && Komal[i])
				{
					if (IsPlayerAlive(i))
					{
						int wepIdx;
						for (int xz; xz < 12; xz++)
						{
							while ((wepIdx = GetPlayerWeaponSlot(i, xz)) != -1)
							{
								RemovePlayerItem(i, wepIdx);
								RemoveEntity(wepIdx);
							}
						}
						ForcePlayerSuicide(i);
					}
					Komal[i] = false;
					ChangeClientTeam(i, CS_TEAM_CT);
					warden_set(i);
					PrintToChatAll("[SM] \x01Komutçu Oylamasını \x10%N \x01Kazandı.", i);
				}
			}
			else
			{
				if (IsVoteInProgress())
				{
					CancelVote();
				}
				Menu menu2 = new Menu(VoteMenu_CallBack);
				menu2.SetTitle("★ Kim Komutçu Olsun ? ★\n ");
				int userid;
				char ClientName[128], ClientUserId[16];
				for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i) && Komal[i])
				{
					userid = GetClientUserId(i);
					FormatEx(ClientUserId, sizeof(ClientUserId), "➜ %d", userid);
					GetClientName(i, ClientName, sizeof(ClientName));
					menu2.AddItem(ClientUserId, ClientName);
				}
				menu2.ExitBackButton = false;
				menu2.ExitButton = false;
				menu2.DisplayVoteToAll(ConVar_KomOylamaSure.IntValue);
			}
			return Plugin_Stop;
		}
	}
	else
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public int Menu_CallBack(Menu menu, MenuAction action, int client, int position)
{
	if (action == MenuAction_End)
		delete menu;
}

public int VoteMenu_CallBack(Menu menu2, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu2;
	}
	else if (action == MenuAction_VoteEnd)
	{
		for (int i = 1; i <= MaxClients; i++)if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Komal[i] = false;
		}
		Sure = -1;
		Oylama = false;
		KomSayisi = 0;
		char Buneamk[128];
		menu2.GetItem(param1, Buneamk, sizeof(Buneamk));
		int client = GetClientOfUserId(StringToInt(Buneamk));
		if (IsPlayerAlive(client))
		{
			int wepIdx;
			for (int i; i < 12; i++)
			{
				while ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
				{
					RemovePlayerItem(client, wepIdx);
					RemoveEntity(wepIdx);
				}
			}
			ForcePlayerSuicide(client);
		}
		ChangeClientTeam(client, CS_TEAM_CT);
		warden_set(client);
		char Names[128];
		GetClientName(client, Names, sizeof(Names));
		PrintToChatAll("[SM] \x01Komutçu Oylamasını \x10%s \x01Kazandı.", Names);
	}
} 