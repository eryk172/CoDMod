#include <amxmodx>
#include <sqlx>
#include <cod>

#define PLUGIN "CoD codClans System"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

enum _:clanInfo { CLAN_ID, CLAN_LEVEL, CLAN_HONOR, CLAN_HEALTH, CLAN_GRAVITY, CLAN_DAMAGE, CLAN_DROP, CLAN_KILLS, CLAN_MEMBERS, Trie:CLAN_STATUS, CLAN_NAME[64] };

enum _:statusInfo { STATUS_NONE, STATUS_MEMBER, STATUS_DEPUTY, STATUS_LEADER };

new const commandClan[][] = { "say /clan", "say_team /clan", "say /codClans", "say_team /codClans", "say /klany", "say_team /klany", "say /klan", "say_team /klan", "klan" };

new cvarLevelCost, cvarNextLevelCost, cvarSkillCost, cvarNextSkillCost, cvarCreateLevel, cvarMembersStart, cvarLevelMax, 
	cvarSkillMax, cvarMembersPerLevel, cvarHealthPerLevel, cvarGravityPerLevel, cvarDamagePerLevel, cvarWeaponDropPerLevel;

new levelCost, nextLevelCost, skillCost, nextSkillCost, createLevel, membersStart, levelMax, 
	skillMax, membersPerLevel, healthPerLevel, gravityPerLevel, damagePerLevel, weaponDropPerLevel;

new playerName[MAX_PLAYERS + 1][64], chosenName[MAX_PLAYERS + 1][64], clan[MAX_PLAYERS + 1], chosenId[MAX_PLAYERS + 1], Handle:sql, Array:codClans;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for(new i; i < sizeof commandClan; i++) register_clcmd(commandClan[i], "show_clan_menu");
	
	register_clcmd("PODAJ_NAZWE_KLANU", "create_clan_handle");
	register_clcmd("PODAJ_NOWA_NAZWE_KLANU", "change_name_handle");
	register_clcmd("WPISZ_ILOSC_HONORU", "deposit_honor_handle");

	cvarLevelCost = register_cvar("cod_clans_level_cost", "1000");
	cvarNextLevelCost = register_cvar("cod_clans_next_level_cost", "1000");
	cvarSkillCost = register_cvar("cod_clans_skill_cost", "500");
	cvarNextSkillCost = register_cvar("cod_clans_next_skill_cost", "500");
	cvarCreateLevel = register_cvar("cod_clans_create_level", "25");
	cvarMembersStart = register_cvar("cod_clans_members_start", "3");
	cvarLevelMax = register_cvar("cod_clans_level_max", "10");
	cvarSkillMax = register_cvar("cod_clans_skill_max", "10");
	cvarMembersPerLevel = register_cvar("cod_clans_members_per_level", "1");
	cvarHealthPerLevel = register_cvar("cod_clans_health_per_level", "1");
	cvarGravityPerLevel = register_cvar("cod_clans_gravity_per_level", "20");
	cvarDamagePerLevel = register_cvar("cod_clans_damage_per_level", "1");
	cvarWeaponDropPerLevel = register_cvar("cod_clans_weapondrop_per_level", "1");
	
	register_message(get_user_msgid("SayText"), "say_text");
	
	codClans = ArrayCreate(clanInfo);
}

public plugin_cfg()
{
	levelCost = get_pcvar_num(cvarLevelCost);
	nextLevelCost = get_pcvar_num(cvarNextLevelCost);
	skillCost = get_pcvar_num(cvarSkillCost);
	nextSkillCost = get_pcvar_num(cvarNextSkillCost);
	createLevel = get_pcvar_num(cvarCreateLevel);
	membersStart = get_pcvar_num(cvarMembersStart);
	levelMax = get_pcvar_num(cvarLevelMax);
	skillMax = get_pcvar_num(cvarSkillMax);
	membersPerLevel = get_pcvar_num(cvarMembersPerLevel);
	healthPerLevel = get_pcvar_num(cvarHealthPerLevel);
	gravityPerLevel = get_pcvar_num(cvarGravityPerLevel);
	damagePerLevel = get_pcvar_num(cvarDamagePerLevel);
	weaponDropPerLevel = get_pcvar_num(cvarWeaponDropPerLevel);

	new codClan[clanInfo];
	
	codClan[CLAN_NAME] = "Brak";
	
	ArrayPushArray(codClans, codClan);

	sql_init();
}

public plugin_end()
{
	SQL_FreeHandle(sql);

	ArrayDestroy(codClans);
}

public client_putinserver(id)
{
	if(is_user_bot(id) || is_user_hltv(id)) return;

	clan[id] = 0;

	get_user_name(id, playerName[id], charsmax(playerName));

	mysql_escape_string(playerName[id], playerName[id], charsmax(playerName));

	load_data(id);
}

public client_disconnected(id)
{
	playerName[id] = "";

	clan[id] = 0;
}

public cod_spawned(id)
{
	if(!clan[id]) return PLUGIN_CONTINUE;

	cod_add_user_gravity(id, -gravityPerLevel * get_clan_info(clan[id], CLAN_GRAVITY));
	
	return PLUGIN_CONTINUE;
}

public cod_damage_post(attacker, victim, Float:damage, damageBits)
{
	if(!clan[attacker]) return PLUGIN_CONTINUE;
	
	cod_inflict_damage(attacker, victim, damage * damagePerLevel * get_clan_info(clan[attacker], CLAN_DAMAGE) / 100.0, 0.0, damageBits);
	
	if(get_clan_info(clan[attacker], CLAN_DROP) && random_num(1, (skillMax * 1.6 - (get_clan_info(clan[attacker], CLAN_DROP) * weaponDropPerLevel)) == 1)) engclient_cmd(victim, "drop");
	
	return PLUGIN_CONTINUE;
}

public cod_killed(killer, victim, weaponId, hitPlace)
{
	if(!clan[killer]) return PLUGIN_CONTINUE;
	
	set_clan_info(clan[killer], CLAN_KILLS, get_clan_info(clan[killer], CLAN_KILLS) + 1);
	
	return PLUGIN_CONTINUE;
}

public show_clan_menu(id, sound)
{	
	if(!is_user_connected(id) || !cod_check_account(id)) return PLUGIN_HANDLED;
	
	if(!sound) client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new codClan[clanInfo], menuData[128], menu;
	
	if(clan[id])
	{
		ArrayGetArray(codClans, clan[id], codClan);
		
		formatex(menuData, charsmax(menuData), "\wMenu \rKlanu^n\wAktualny Klan:\y %s^n\w(\y%i/%i %s | %i Honoru\w)", codClan[CLAN_NAME], codClan[CLAN_MEMBERS], codClan[CLAN_LEVEL] * membersPerLevel + membersStart, codClan[CLAN_MEMBERS] > 1 ? "Czlonkow" : "Czlonek", codClan[CLAN_HONOR]);
		
		menu = menu_create(menuData, "show_clan_menu_handle");
		
		if(get_user_status(id) > STATUS_MEMBER) menu_additem(menu, "\wZarzadzaj \yKlanem");
		else
		{
			formatex(menuData, charsmax(menuData), "\wStworz \yKlan \r(Wymagany %i Poziom)", createLevel);

			menu_additem(menu, menuData);
		}
	}
	else
	{
		menu = menu_create("\wMenu \rKlanu^n\wAktualny Klan:\y Brak", "show_clan_menu_handle");

		formatex(menuData, charsmax(menuData), "\wStworz \yKlan \r(Wymagany %i Poziom)", createLevel);
		menu_additem(menu, menuData);
	}
	
	new callback = menu_makecallback("show_clan_menu_callback");

	menu_additem(menu, "\wOpusc \yKlan", _, _, callback);
	menu_additem(menu, "\wCzlonkowie \yOnline", _, _, callback);
	menu_additem(menu, "\wWplac \yHonor", _, _, callback);
	menu_additem(menu, "\wTop15 \yKlanow", _, _, callback);

	if(!clan[id]) menu_additem(menu, "\wZloz \yPodanie", _, _, callback);
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public show_clan_menu_callback(id, menu, item)
{
	switch(item)
	{
		case 1, 3, 4: return clan[id] ? ITEM_ENABLED : ITEM_DISABLED;
		case 2: if(get_user_status(id) < STATUS_DEPUTY || ((get_clan_info(clan[id], CLAN_LEVEL) * membersPerLevel) + membersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) return ITEM_DISABLED;
		case 5: return clan[id] ? ITEM_DISABLED: ITEM_ENABLED; 
	}

	return ITEM_ENABLED;
}

public show_clan_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch(item)
	{
		case 0: 
		{
			if(get_user_status(id) > STATUS_MEMBER)
			{
				leader_menu(id);

				return PLUGIN_HANDLED;
			}
			
			if(clan[id])
			{
				cod_print_chat(id, "Nie mozesz utworzyc klanu, jesli w jakims jestes!");

				return PLUGIN_HANDLED;
			}
			
			if(cod_get_user_level(id) < createLevel)
			{
				cod_print_chat(id, "Nie masz wystarczajacego poziomu by stworzyc klan (Wymagany^x03 %i^x01)!", createLevel);

				return PLUGIN_HANDLED;
			}
			
			client_cmd(id, "messagemode PODAJ_NAZWE_KLANU");
		}
		case 1: leave_confim_menu(id);
		case 2: members_online_menu(id);
		case 3:
		{
			client_cmd(id, "messagemode WPISZ_ILOSC_HONORU");

			client_print(id, print_center, "Wpisz ilosc Honoru, ktora chcesz wplacic");

			cod_print_chat(id, "Wpisz ilosc Honoru, ktora chcesz wplacic.");
		}
		case 4: clans_top15(id);
		case 5: application_menu(id);
	}
	
	menu_destroy(menu);

	return PLUGIN_CONTINUE;
}

public create_clan_handle(id)
{
	if(!is_user_connected(id) || !cod_check_account(id)) return PLUGIN_HANDLED;
		
	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

	if(clan[id])
	{
		cod_print_chat(id, "Nie mozesz utworzyc klanu, jesli w jakims jestes!");

		return PLUGIN_HANDLED;
	}
	
	if(cod_get_user_level(id) < createLevel)
	{
		cod_print_chat(id, "Nie masz wystarczajaco wysokiego poziomu (Wymagany: %i)!", createLevel);

		return PLUGIN_HANDLED;
	}
	
	new clanName[64];
	
	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);
	
	if(equal(clanName, ""))
	{
		cod_print_chat(id, "Nie wpisales nazwy klanu.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	if(strlen(clanName) < 3)
	{
		cod_print_chat(id, "Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}
	
	if(check_clan_name(clanName))
	{
		cod_print_chat(id, "Klan z taka nazwa juz istnieje.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	create_clan(id, clanName);
	
	cod_print_chat(id, "Pomyslnie zalozyles klan^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

public leave_confim_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \ropuscic \wklan?", "leave_confim_menu_handle");
	
	menu_additem(menu, "Tak");
	menu_additem(menu, "Nie^n");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leave_confim_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch(item)
	{
		case 0: 
		{
			if(get_user_status(id) == STATUS_LEADER)
			{
				cod_print_chat(id, "Oddaj przywodctwo klanu jednemu z czlonkow zanim go upuscisz.");

				show_clan_menu(id, 1);

				return PLUGIN_HANDLED;
			}

			set_user_clan(id);
			
			cod_print_chat(id, "Opusciles swoj klan.");
			
			show_clan_menu(id, 1);
		}
		case 1: show_clan_menu(id, 1);
	}

	return PLUGIN_HANDLED;
}

public members_online_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new clanName[64], players[32], playersNum, playersAvailable = 0;

	get_players(players, playersNum);
	
	new menu = menu_create("\wCzlonkowie \rOnline:", "members_online_menu_handle");
	
	for(new i = 0, player; i < playersNum; i++)
	{
		player = players[i];
		
		if(clan[id] != clan[player]) continue;
			
		playersAvailable++;
		
		get_user_name(player, clanName, charsmax(clanName));
		
		switch(get_user_status(player))
		{
			case STATUS_MEMBER: add(clanName, charsmax(clanName), " \y[Czlonek]");
			case STATUS_DEPUTY: add(clanName, charsmax(clanName), " \y[Zastepca]");
			case STATUS_LEADER: add(clanName, charsmax(clanName), " \y[Przywodca]");
		}
		menu_additem(menu, clanName);
	}
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	if(!playersAvailable) cod_print_chat(id, "Na serwerze nie ma zadnego czlonka twojego klanu!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public members_online_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	menu_destroy(menu);
	
	members_online_menu(id);
	
	return PLUGIN_HANDLED;
}

public leader_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wZarzadzaj \rKlanem", "leader_menu_handle"), callback = menu_makecallback("leader_menu_callback");

	menu_additem(menu, "\wRozwiaz \yKlan", _, _, callback);
	menu_additem(menu, "\wUlepsz \yUmiejetnosci", _, _, callback);
	menu_additem(menu, "\wZapros \yGracza", _, _, callback);
	menu_additem(menu, "\wZarzadzaj \yCzlonkami", _, _, callback);
	menu_additem(menu, "\wRozpatrz \yPodania", _, _, callback);
	menu_additem(menu, "\wZmien \yNazwe Klanu^n", _, _, callback);
	menu_additem(menu, "\wWroc", _, _, callback);
		
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public leader_menu_callback(id, menu, item)
{
	switch(item)
	{
		case 1: get_user_status(id) == STATUS_LEADER ? ITEM_ENABLED : ITEM_DISABLED;
		case 2, 4: if(((get_clan_info(clan[id], CLAN_LEVEL) * membersPerLevel) + membersStart) <= get_clan_info(clan[id], CLAN_MEMBERS)) return ITEM_DISABLED;
	}

	return ITEM_ENABLED;
}

public leader_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch(item)
	{
		case 0: disband_menu(id);
		case 1: skills_menu(id);
		case 2: invite_menu(id);
		case 3: members_menu(id);
		case 4: applications_menu(id);
		case 5: client_cmd(id, "messagemode PODAJ_NOWA_NAZWE_KLANU");
		case 6: show_clan_menu(id, 1);
	}
	return PLUGIN_HANDLED;
}

public disband_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new menu = menu_create("\wJestes \ypewien\w, ze chcesz \rrozwiazac\w klan?", "disband_menu_handle");
	
	menu_additem(menu, "Tak", "0");
	menu_additem(menu, "Nie^n", "1");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public disband_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	switch(item)
	{
		case 0: 
		{
			cod_print_chat(id, "Rozwiazales swoj klan.");
			
			remove_clan(id);
			
			show_clan_menu(id, 1);
		}
		case 1: show_clan_menu(id, 1);
	}

	menu_destroy(menu);

	return PLUGIN_HANDLED;
}

public skills_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new codClan[clanInfo], menuData[128];

	ArrayGetArray(codClans, clan[id], codClan);
	
	formatex(menuData, charsmax(menuData), "\wMenu \rUmiejetnosci^n\rHonor Klanu: %i", codClan[CLAN_HONOR]);

	new menu = menu_create(menuData, "skills_menu_handle");
	
	formatex(menuData, charsmax(menuData), "Poziom Klanu \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_LEVEL], levelMax, levelCost + nextLevelCost * codClan[CLAN_LEVEL]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Zycie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_HEALTH], skillMax, skillCost + nextSkillCost * codClan[CLAN_HEALTH]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Grawitacja \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_GRAVITY], skillMax, skillCost + nextSkillCost * codClan[CLAN_GRAVITY]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Obrazenia \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_DAMAGE], skillMax, skillCost + nextSkillCost * codClan[CLAN_DAMAGE]);
	menu_additem(menu, menuData);

	formatex(menuData, charsmax(menuData), "Obezwladnienie \w[\rLevel: \y%i/%i\w] [\rKoszt: \y%i AP\w]", codClan[CLAN_DROP], skillMax, skillCost + nextSkillCost * codClan[CLAN_DROP]);
	menu_additem(menu, menuData);
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED;
}

public skills_menu_handle(id, menu, item)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new codClan[clanInfo], upgradedSkill;

	ArrayGetArray(codClans, clan[id], codClan);

	menu_destroy(menu);
	
	switch(item)
	{
		case 0:
		{
			if(codClan[CLAN_LEVEL] == levelMax)
			{
				cod_print_chat(id, "Twoj klan ma juz maksymalny Poziom.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (levelCost + nextLevelCost * codClan[CLAN_LEVEL]);
			
			if(remainingHonor < 0)
			{
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_LEVEL;
			
			codClan[CLAN_LEVEL]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles klan na^x03 %i Poziom^x01!", codClan[CLAN_LEVEL]);
		}
		case 1:
		{
			if(codClan[CLAN_HEALTH] == skillMax)
			{
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (skillCost + nextSkillCost * codClan[CLAN_HEALTH]);
			
			if(remainingHonor < 0)
			{
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_HEALTH;
			
			codClan[CLAN_HEALTH]++;
			codClan[CLAN_HONOR] = remainingHonor;

			cod_set_user_bonus_health(id, cod_get_user_bonus_health(id) + get_clan_info(clan[id], CLAN_HEALTH) * healthPerLevel);
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Predkosc^x01 na^x03 %i^x01 poziom!", codClan[CLAN_HEALTH]);
		}
		case 2:
		{
			if(codClan[CLAN_GRAVITY] == skillMax)
			{
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (skillCost + nextSkillCost * codClan[CLAN_GRAVITY]);
			
			if(remainingHonor < 0)
			{
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_GRAVITY;
			
			codClan[CLAN_GRAVITY]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Grawitacja^x01 na^x03 %i^x01 poziom!", codClan[CLAN_GRAVITY]);
		}
		case 3:
		{
			if(codClan[CLAN_DAMAGE] == skillMax)
			{
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (skillCost + nextSkillCost * codClan[CLAN_DAMAGE]);
			
			if(remainingHonor < 0)
			{
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_DAMAGE;
			
			codClan[CLAN_DAMAGE]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Obrazenia^x01 na^x03 %i^x01 poziom!", codClan[CLAN_DAMAGE]);
		}
		case 4:
		{
			if(codClan[CLAN_DROP] == skillMax)
			{
				cod_print_chat(id, "Twoj klan ma juz maksymalny poziom tej umiejetnosci.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			new remainingHonor = codClan[CLAN_HONOR] - (skillCost + nextSkillCost * codClan[CLAN_DROP]);
			
			if(remainingHonor < 0)
			{
				cod_print_chat(id, "Twoj klan nie ma wystarczajacej ilosci Honoru.");

				skills_menu(id);

				return PLUGIN_HANDLED;
			}
			
			upgradedSkill = CLAN_DROP;
			
			codClan[CLAN_DROP]++;
			codClan[CLAN_HONOR] = remainingHonor;
			
			cod_print_chat(id, "Ulepszyles umiejetnosc^x03 Obezwladnienie^x01 na^x03 %i^x01 poziom!", codClan[CLAN_DROP]);
		}
	}
	
	ArraySetArray(codClans, clan[id], codClan);

	save_clan(clan[id]);
	
	new players[32], playersNum, player, name[32];
	
	get_players(players, playersNum);
	get_user_name(id, name, charsmax(name));
	
	for(new i = 0 ; i < playersNum; i++)
	{
		player = players[i];
		
		if(player == id || clan[player] != clan[id]) continue;

		cod_set_user_bonus_health(player, cod_get_user_bonus_health(player) + get_clan_info(clan[player], CLAN_HEALTH) * healthPerLevel);

		cod_print_chat(player, "^x03 %s^x01 ulepszyl klan na^x03 %i Poziom^x01!", name, codClan[upgradedSkill]);
	}
	
	skills_menu(id);
	
	return PLUGIN_HANDLED;
}

public invite_menu(id)
{	
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
	
	new userName[64], players[32], userId[6], playersNum, playersAvailable = 0;

	get_players(players, playersNum);
	
	new menu = menu_create("\wWybierz \rGracza \wdo zaproszenia:", "invite_menu_handle");
	
	for(new i = 0, player; i < playersNum; i++)
	{
		player = players[i];
		
		if(player == id || clan[player] || is_user_hltv(player) || !is_user_connected(player)) continue;

		playersAvailable++;
		
		get_user_name(player, userName, charsmax(userName));

		num_to_str(player, userId, charsmax(userId));

		menu_additem(menu, userName, userId);
	}	
	
	if(!playersAvailable) cod_print_chat(id, "Na serwerze nie ma gracza, ktorego moglbys zaprosic!");
	else menu_display(id, menu);

	return PLUGIN_HANDLED;
}

public invite_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)  || !clan[id]) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new userName[64], itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), userName, charsmax(userName), itemCallback);
	
	new player = str_to_num(itemData);

	if(!is_user_connected(player))
	{
		cod_print_chat(id, "Wybranego gracza nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	} 
	
	invite_confirm_menu(id, player);

	cod_print_chat(id, "Zaprosiles^x03 %s^x01 do do twojego klanu.", userName);
	
	show_clan_menu(id, 1);
	
	return PLUGIN_HANDLED;
}

public invite_confirm_menu(id, player)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;
		
	client_cmd(player, "spk %s", codSounds[SOUND_SELECT]);
	
	new menuData[128], clanName[64], userName[64], userId[6];
	
	get_user_name(id, userName, charsmax(userName));

	get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));
	
	formatex(menuData, charsmax(menuData), "\r%s\w zaprosil cie do klanu \y%s\w.", userName, clanName);
	
	new menu = menu_create(menuData, "invite_confirm_menu_handle");
	
	num_to_str(id, userId, charsmax(userId));
	
	menu_additem(menu, "Dolacz", userId);
	menu_additem(menu, "Odrzuc");
	
	menu_display(player, menu);	

	return PLUGIN_HANDLED;
}

public invite_confirm_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT || item)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	new player = str_to_num(itemData);
	
	if(!is_user_connected(id))
	{
		cod_print_chat(id, "Gracza, ktory cie zaprosil nie ma juz na serwerze.");

		return PLUGIN_HANDLED;
	}

	client_cmd(player, "spk %s", codSounds[SOUND_SELECT]);
	
	if(clan[id])
	{
		cod_print_chat(id, "Nie mozesz dolaczyc do klanu, jesli nalezysz do innego.");

		return PLUGIN_HANDLED;
	}
	
	if(((get_clan_info(clan[player], CLAN_LEVEL) * membersPerLevel) + membersStart) <= get_clan_info(clan[player], CLAN_MEMBERS))
	{
		cod_print_chat(id, "Niestety, w tym klanie nie ma juz wolnego miejsca.");

		return PLUGIN_HANDLED;
	}

	new clanName[64];

	get_clan_info(clan[player], CLAN_NAME, clanName, charsmax(clanName));
	
	set_user_clan(id, clan[player]);
	
	cod_print_chat(id, "Dolaczyles do klanu^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

public change_name_handle(id)
{
	if(!is_user_connected(id) || !cod_check_account(id) || get_user_status(id) != STATUS_LEADER) return PLUGIN_HANDLED;
		
	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);
	
	new clanName[64];
	
	read_args(clanName, charsmax(clanName));
	remove_quotes(clanName);
	trim(clanName);
	
	if(equal(clanName, ""))
	{
		cod_print_chat(id, "Nie wpisano nowej nazwy klanu.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	if(strlen(clanName) < 3)
	{
		cod_print_chat(id, "Nazwa klanu musi miec co najmniej 3 znaki.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}
	
	if(check_clan_name(clanName))
	{
		cod_print_chat(id, "Klan z taka nazwa juz istnieje.");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	set_clan_info(clan[id], CLAN_NAME, _, clanName, charsmax(clanName));
	
	cod_print_chat(id, "Zmieniles nazwe klanu na^x03 %s^x01.", clanName);
	
	return PLUGIN_CONTINUE;
}

public members_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_members` WHERE clan = '%i' ORDER BY flag DESC", clan[id]);

	SQL_ThreadQuery(sql, "members_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public members_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if(!is_user_connected(id)) return;

	new itemData[64], userName[64], status, menu = menu_create("\wZarzadzaj \rCzlonkami:^n\rWybierz czlonka, aby pokazac mozliwe opcje.", "member_menu_handle");
	
	while(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "flag"));
		
		formatex(itemData, charsmax(itemData), "%s#%i", userName, status);
		
		switch(status)
		{
			case STATUS_MEMBER: add(userName, charsmax(userName), " \y[Czlonek]");
			case STATUS_DEPUTY: add(userName, charsmax(userName), " \y[Zastepca]");
			case STATUS_LEADER: add(userName, charsmax(userName), " \y[Przywodca]");
		}
		
		menu_additem(menu, userName, itemData);

		SQL_NextRow(query);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
}

public member_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new itemData[64], userName[64], tempFlag[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, userName, charsmax(userName), tempFlag, charsmax(tempFlag), '#');
	
	new flag = str_to_num(tempFlag), userId = get_user_index(userName);

	if(userId == id)
	{
		cod_print_chat(id, "Nie mozesz zarzadzac soba!");

		members_menu(id);

		return PLUGIN_HANDLED;
	}
	
	if(clan[userId]) chosenId[id] = get_user_userid(userId);

	if(flag == STATUS_LEADER)
	{
		cod_print_chat(id, "Nie mozna zarzadzac przywodca klanu!");

		members_menu(id);

		return PLUGIN_HANDLED;
	}

	formatex(chosenName[id], charsmax(chosenName), userName);
	
	new menu = menu_create("\wWybierz \rOpcje:", "member_options_menu_handle");
	
	if(get_user_status(id) == STATUS_LEADER)
	{
		menu_additem(menu, "Przekaz \yPrzywodctwo", "1");
		
		if(flag == STATUS_MEMBER) menu_additem(menu, "Mianuj \yZastepce", "2");

		if(flag == STATUS_DEPUTY) menu_additem(menu, "Degraduj \yZastepce", "3");
	}

	menu_additem(menu, "Wyrzuc \yGracza", "4");
	
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public member_options_menu_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		show_clan_menu(id, 1);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	new itemData[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);

	switch(str_to_num(itemData))
	{
		case 1: update_member(id, STATUS_LEADER);
		case 2:	update_member(id, STATUS_DEPUTY);
		case 3:	update_member(id, STATUS_MEMBER);
		case 4: update_member(id, STATUS_NONE);
	}
	
	menu_destroy(menu);
	
	return PLUGIN_CONTINUE;
}

public update_member(id, status)
{
	new players[32], playersNum, player, bool:playerOnline;
	
	get_players(players, playersNum);

	for(new i = 0; i < playersNum; i++)
	{
		player = players[i];

		if(clan[player] != clan[id] || is_user_hltv(player) || !is_user_connected(player)) continue;
	
		if(get_user_userid(player) == chosenId[id])
		{
			switch(status)
			{
				case STATUS_LEADER:
				{
					set_user_status(id, STATUS_DEPUTY);
					set_user_status(player, STATUS_LEADER);

					cod_print_chat(player,  "Zostales mianowany przywodca klanu!");
				}
				case STATUS_DEPUTY:
				{
					set_user_status(player, STATUS_DEPUTY);

					cod_print_chat(player,  "^x01 Zostales zastepca przywodcy klanu!");		
				}
				case STATUS_MEMBER:
				{
					set_user_status(player, STATUS_MEMBER);

					cod_print_chat(player,  "^x01 Zostales zdegradowany do rangi czlonka klanu.");
				}
				case STATUS_NONE:
				{
					set_user_clan(player);

					cod_print_chat(player,  "Zostales wyrzucony z klanu.");
				}
			}

			playerOnline = true;

			continue;
		}
		
		switch(status)
		{
			case STATUS_LEADER: cod_print_chat(player,  "^x03 %s^01 zostal nowym przywodca klanu.", chosenName[id]);
			case STATUS_DEPUTY: cod_print_chat(player,  "^x03 %s^x01 zostal zastepca przywodcy klanu.", chosenName[id]);
			case STATUS_MEMBER: cod_print_chat(player,  "^x03 %s^x01 zostal zdegradowany do rangi czlonka klanu.", chosenName[id]);
			case STATUS_NONE: cod_print_chat(player,  "^x03 %s^01 zostal wyrzucony z klanu.", chosenName[id]);
		}
	}
	
	if(!playerOnline)
	{
		save_member(id, status, _, chosenName[id]);
		
		if(status == STATUS_NONE)
		{
			set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) - 1);
			
			save_clan(clan[id]);
		}
	}
	
	show_clan_menu(id, 1);
	
	return PLUGIN_HANDLED;
}

public applications_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;

	new queryData[256], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.name, (SELECT level FROM `cod_mod` WHERE name = a.name ORDER BY level DESC LIMIT 1) as level FROM `cod_clans_application` a WHERE clan = '%i' ORDER BY a.id", clan[id]);

	SQL_ThreadQuery(sql, "applications_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public applications_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if(!is_user_connected(id)) return;

	new itemName[128], userName[64], level, menu = menu_create("\wWybierz podanie, aby je zatwierdzic lub odrzucic.", "applications_confirm_menu");
	
	while(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		level = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
		
		formatex(itemName, charsmax(itemName), "\w%s y(Najwyzszy poziom: \r%i\y)", userName, level);
		
		menu_additem(menu, itemName, userName);

		SQL_NextRow(query);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
}

public applications_confirm_menu(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	new menuData[128], userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);
	
	menu_destroy(menu);

	formatex(menuData, charsmax(menuData), "Czy chcesz przyjac \y%s \wdo klanu?", userName);
	
	new menu = menu_create(menuData, "applications_confirm_handle");
	
	menu_additem(menu, "Tak", userName);
	menu_additem(menu, "Nie");
	
	menu_display(id, menu);
	
	return PLUGIN_CONTINUE;
}

public applications_confirm_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT || item)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new userName[64], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, userName, charsmax(userName), _, _, itemCallback);
	
	menu_destroy(menu);

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	if(check_user_clan(userName))
	{
		cod_print_chat(id, "Gracz dolaczyl juz do innego klanu!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	accept_application(id, userName);

	cod_print_chat(id, "Zaakceptowales podanie ^x03 %s^01 o dolaczenie do klanu.", userName);
	
	return PLUGIN_HANDLED;
}

public deposit_honor_handle(id)
{
	if(!is_user_connected(id) || !clan[id] || !cod_check_account(id)) return PLUGIN_HANDLED;

	client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);
	
	new honorData[16], honorAmount;
	
	read_args(honorData, charsmax(honorData));
	remove_quotes(honorData);

	honorAmount = str_to_num(honorData);
	
	if(honorAmount <= 0)
	{ 
		cod_print_chat(id, "Nie mozesz wplacic mniej niz^x03 1 honoru^x01!");

		return PLUGIN_HANDLED;
	}
	
	if(cod_get_user_honor(id) < honorAmount) 
	{ 
		cod_print_chat(id, "Nie masz tyle^x03 honoru^x01!");

		return PLUGIN_HANDLED;
	}

	cod_set_user_honor(id, cod_get_user_honor(id) - honorAmount);
	
	set_clan_info(clan[id], CLAN_HONOR, get_clan_info(clan[id], CLAN_HONOR) + honorAmount);
	
	cod_print_chat(id, "Wplaciles^x03 %i^x01 Honoru na rzecz klanu.", honorAmount);
	cod_print_chat(id, "Aktualnie twoj klan ma^x03 %i^x01 Honoru.", get_clan_info(clan[id], CLAN_HONOR));
	
	return PLUGIN_HANDLED;
}

public clans_top15(id)
{
	if(!is_user_connected(id) ) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT clan_name, members, honor, kills, level, health, gravity, weapondrop, damage FROM `cod_clans` ORDER BY kills DESC LIMIT 15");

	SQL_ThreadQuery(sql, "show_clans_top15", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public show_clans_top15(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return PLUGIN_HANDLED;
	}
	
	new id = tempId[0];
	
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	static motdData[2048], clanName[64], motdLength, rank = 0, members = 0, honor = 0, kills = 0, level = 0, health = 0, gravity = 0, drop = 0, damage = 0;
	
	motdLength = format(motdData, charsmax(motdData), "<body bgcolor=#000000><font color=#FFB000><pre>");
	motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1s %-22.22s %4s %8s %6s %8s %9s %12s %11s^n", "#", "Nazwa", "Czlonkowie", "Poziom", "Zabicia", "Honor", "Zycie", "Grawitacja", "Obezwladnienie", "Obrazenia");
	
	while(SQL_MoreResults(query))
	{
		rank++;
		
		SQL_ReadResult(query, 0, clanName, charsmax(clanName));
		replace_all(clanName, charsmax(clanName), "<", "");
		replace_all(clanName,charsmax(clanName), ">", "");
		
		members = SQL_ReadResult(query, 1);
		honor = SQL_ReadResult(query, 2);
		kills = SQL_ReadResult(query, 3);
		level = SQL_ReadResult(query, 4);
		health = SQL_ReadResult(query, 5);
		gravity = SQL_ReadResult(query, 6);
		drop = SQL_ReadResult(query, 7);
		damage = SQL_ReadResult(query, 8);
		
		if(rank >= 10) motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %5d %8d %10d %8d %7d %10d %14d^n", rank, clanName, members, level, kills, honor, health, gravity, drop, damage);
		else motdLength += format(motdData[motdLength], charsmax(motdData) - motdLength, "%1i %22.22s %6d %8d %10d %8d %7d %10d %14d^n", rank, clanName, members, level, kills, honor, health, gravity, drop, damage);

		SQL_NextRow(query);
	}
	
	show_motd(id, motdData, "Top 15 Klanow");
	
	return PLUGIN_HANDLED;
}

public say_text(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);
	
	if(is_user_connected(id))
	{
		new tempMessage[192], message[192], chatPrefix[64];
		
		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		get_clan_info(clan[id], CLAN_NAME, chatPrefix, charsmax(chatPrefix));

		format(chatPrefix, charsmax(chatPrefix), "^x04[%s]", chatPrefix);
		
		if(!equal(tempMessage, "#Cstrike_Chat_All"))
		{
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), " ");
			add(message, charsmax(message), tempMessage);
		}
		else
		{
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), "^x03 %s1^x01 :  %s2");
		}
		
		set_msg_arg_string(2, message);
	}
	
	return PLUGIN_CONTINUE;
}

public application_menu(id)
{
	if(!is_user_connected(id) || !clan[id]) return PLUGIN_HANDLED;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT a.id, a.name as 'clan', b.name FROM `cod_clans` a JOIN `cod_clans_members` b ON a.id = b.clan WHERE flag = '3' ORDER BY a.kills DESC");

	SQL_ThreadQuery(sql, "application_menu_handle", queryData, tempId, sizeof(tempId));
	
	return PLUGIN_HANDLED;
}

public application_menu_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if(!is_user_connected(id)) return;

	new itemName[128], itemData[64], clanName[64], userName[64], clanId, menu = menu_create("\wWybierz \rKlan:^n\wWybierz \rklan\w, do ktorego chcesz zlozyc \ypodanie\w.", "application_handle");
	
	while(SQL_MoreResults(query))
	{
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "clan"), clanName, charsmax(clanName));
		SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), userName, charsmax(userName));

		clanId = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
		
		formatex(itemName, charsmax(itemName), "%s \y(Lider: \r%s\y)", clanName, userName);
		formatex(itemData, charsmax(itemData), "%i#%s", clanId, clanName);
		
		menu_additem(menu, itemName, itemData);

		SQL_NextRow(query);
	}
	
	menu_setprop(menu, MPROP_BACKNAME, "Poprzednie");
	menu_setprop(menu, MPROP_NEXTNAME, "Nastepne");
	menu_setprop(menu, MPROP_EXITNAME, "\wWyjdz");
	
	menu_display(id, menu);
}

public application_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);

	if(clan[id])
	{
		cod_print_chat(id, "Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	new itemData[64], clanName[64], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');

	if(check_applications(id, str_to_num(tempClanId)))
	{
		cod_print_chat(id, "Juz zlozyles podanie do tego klanu!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	new menuData[128];

	formatex(menuData, charsmax(menuData), "Czy na pewno chcesz zlozyc podanie do klanu \y%s\w?", clanName);
	
	new menu = menu_create(menuData, "application_confirm_handle");
	
	menu_additem(menu, "Tak", itemData);
	menu_additem(menu, "Nie");
	
	menu_display(id, menu);	

	return PLUGIN_HANDLED;
}

public application_confirm_handle(id, menu, item)
{
	if(!is_user_connected(id)) return PLUGIN_HANDLED;
	
	if(item == MENU_EXIT || item)
	{
		client_cmd(id, "spk %s", codSounds[SOUND_EXIT]);

		menu_destroy(menu);

		return PLUGIN_HANDLED;
	}
	
	new itemData[64], clanName[64], tempClanId[6], itemAccess, itemCallback;

	menu_item_getinfo(menu, item, itemAccess, itemData, charsmax(itemData), _, _, itemCallback);
	
	menu_destroy(menu);

	strtok(itemData, clanName, charsmax(clanName), tempClanId, charsmax(tempClanId), '#');
	
	new clanId = str_to_num(itemData);

	client_cmd(id, "spk %s", codSounds[SOUND_SELECT]);
	
	if(clan[id])
	{
		cod_print_chat(id, "Nie mozesz zlozyc podania, jesli jestes juz w klanie!");

		show_clan_menu(id, 1);

		return PLUGIN_HANDLED;
	}

	add_application(id, clanId);

	cod_print_chat(id, "Zlozyles podanie do klanu^x03 %s^01.", clanName);
	
	return PLUGIN_HANDLED;
}

stock set_user_clan(id, playerClan = 0, owner = 0)
{
	if(!is_user_connected(id)) return;
	
	if(playerClan == 0)
	{
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) + 1);

		TrieDeleteKey(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id]);
		
		save_member(id, STATUS_NONE);
		
		clan[id] = 0;
	}
	else
	{
		clan[id] = playerClan;
		
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) + 1);

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], owner ? STATUS_LEADER : STATUS_MEMBER);
		
		save_member(id, owner ? STATUS_LEADER : STATUS_MEMBER, 1);

		remove_applications(id);
	}
}

stock set_user_status(id, status)
{
	if(!is_user_connected(id) || !clan[id]) return;

	TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	
	save_member(id, status);
}

stock get_user_status(id)
{
	if(!is_user_connected(id) || !clan[id]) return STATUS_NONE;
	
	new status;

	TrieGetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	
	return status;
}

public sql_init()
{
	new host[32], user[32], pass[32], db[32], queryData[512], error[128], errorNum;
	
	get_cvar_string("cod_sql_host", host, charsmax(host));
	get_cvar_string("cod_sql_user", user, charsmax(user));
	get_cvar_string("cod_sql_pass", pass, charsmax(pass));
	get_cvar_string("cod_sql_db", db, charsmax(db));
	
	sql = SQL_MakeDbTuple(host, user, pass, db);

	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return;
	}
	
	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans` (`id` INT NOT NULL AUTO_INCREMENT, `name` varchar(64) NOT NULL, ");
	add(queryData, charsmax(queryData), "`members` INT NOT NULL, `honor` INT NOT NULL, `kills` INT NOT NULL, `level` INT NOT NULL, `speed` INT NOT NULL, ");
	add(queryData, charsmax(queryData), "`gravity` INT NOT NULL, `damage` INT NOT NULL, `weapondrop` INT NOT NULL, PRIMARY KEY (`id`));");

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans_members` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, `flag` INT NOT NULL, PRIMARY KEY (`name`));");
	
	query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	formatex(queryData, charsmax(queryData), "CREATE TABLE IF NOT EXISTS `cod_clans_applications` (`name` varchar(64) NOT NULL, `clan` INT NOT NULL, PRIMARY KEY (`name`, `clan`));");
	
	query = SQL_PrepareQuery(connectHandle, queryData);

	SQL_Execute(query);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

public ignore_handle(failState, Handle:query, error[], errorNum, data[], dataSize)
{
	if (failState) 
	{
		if(failState == TQUERY_CONNECT_FAILED) log_to_file("cod_mod.log", "Could not connect to SQL database. [%d] %s", errorNum, error);
		else if (failState == TQUERY_QUERY_FAILED) log_to_file("cod_mod.log", "Query failed. [%d] %s", errorNum, error);
	}
	
	return PLUGIN_CONTINUE;
}

public save_clan(clan)
{
	new queryData[256], safeName[64], codClan[clanInfo];
	
	ArrayGetArray(codClans, clan, codClan);

	mysql_escape_string(codClan[CLAN_NAME], safeName, charsmax(safeName));
	
	formatex(queryData, charsmax(queryData), "UPDATE `cod_clans` SET name = '%s', level = '%i', honor = '%i', kills = '%i', members = '%i', speed = '%i', gravity = '%i', weapondrop = '%i', damage = '%i' WHERE clan_name = '%s'", 
	safeName, codClan[CLAN_LEVEL], codClan[CLAN_HONOR], codClan[CLAN_KILLS], codClan[CLAN_MEMBERS], codClan[CLAN_HEALTH], codClan[CLAN_GRAVITY], codClan[CLAN_DROP], codClan[CLAN_DAMAGE], clan);
	
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

public load_data(id)
{
	if(!is_user_connected(id)) return;

	new queryData[128], tempId[1];
	
	tempId[0] = id;

	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_members` a JOIN `cod_clans` b ON a.clan = b.id WHERE a.name = '%s'", playerName[id]);
	SQL_ThreadQuery(sql, "load_data_handle", queryData, tempId, sizeof(tempId));
}

public load_data_handle(failState, Handle:query, error[], errorNum, tempId[], dataSize)
{
	if(failState) 
	{
		log_to_file("cod_mod.log", "SQL Error: %s (%d)", error, errorNum);
		
		return;
	}
	
	new id = tempId[0];
	
	if(!is_user_connected(id)) return;
	
	if(SQL_MoreResults(query))
	{
		new codClan[clanInfo];

		codClan[CLAN_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));

		if(!check_clan_loaded(codClan[CLAN_ID]))
		{
			SQL_ReadResult(query, SQL_FieldNameToNum(query, "name"), codClan[CLAN_NAME], charsmax(codClan[CLAN_NAME]));

			codClan[CLAN_ID] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "id"));
			codClan[CLAN_LEVEL] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "level"));
			codClan[CLAN_HONOR] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "honor"));
			codClan[CLAN_HEALTH] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "health"));
			codClan[CLAN_GRAVITY] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "gravity"));
			codClan[CLAN_DROP] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "weapondrop"));
			codClan[CLAN_DAMAGE] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "damage"));
			codClan[CLAN_KILLS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "kills"));
			codClan[CLAN_MEMBERS] = SQL_ReadResult(query, SQL_FieldNameToNum(query, "members"));
			codClan[CLAN_STATUS] = _:TrieCreate();

			ArrayPushArray(codClans, codClan);
		}
		
		clan[id] = codClan[CLAN_ID];

		new status = SQL_ReadResult(query, SQL_FieldNameToNum(query, "flag"));

		cod_set_user_bonus_health(id, cod_get_user_bonus_health(id) + get_clan_info(clan[id], CLAN_HEALTH) * healthPerLevel);

		TrieSetCell(Trie:get_clan_info(clan[id], CLAN_STATUS), playerName[id], status);
	}
	else
	{
		new queryData[128];

		formatex(queryData, charsmax(queryData), "INSERT IGNORE INTO `cod_clans_members` (`name`) VALUES ('%s');", playerName[id]);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

stock save_member(id, status = 0, change = 0, const name[] = "")
{
	new queryData[128], safeName[64];

	if(strlen(name)) mysql_escape_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	if(status)
	{
		if(change) formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET clan = '%i', flag = '%i' WHERE name = '%s'", change, status, safeName);
		else formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET flag = '%i' WHERE name = '%s'", status, safeName);
	}
	else formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET clan = '0', flag = '0' WHERE name = '%s'", safeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	if(change)
	{
		formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans_applications` WHERE name = '%s'", change, safeName);

		SQL_ThreadQuery(sql, "ignore_handle", queryData);
	}
}

stock add_application(id, clanId)
{
	new queryData[128], userName[32];

	formatex(queryData, charsmax(queryData), "INSERT INTO `cod_clans_applications` (`name`, `clan`) VALUES ('%s', '%i');", playerName[id], clanId);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);

	get_user_name(id, userName, charsmax(userName));

	for(new i = 1; i <= MAX_PLAYERS; i++)
	{
		if(!is_user_connected(id) || is_user_bot(id) || is_user_hltv(id) || clan[id] != clanId || get_user_status(id) <= STATUS_MEMBER) continue;

		client_print_color(i, id, "^x03%s^x01 zlozyl podanie do klanu!", userName);
	}
}

stock accept_application(id, const userName[])
{
	new player = get_user_index(userName);

	if(is_user_connected(player))
	{
		new clanName[64];

		get_clan_info(clan[id], CLAN_NAME, clanName, charsmax(clanName));

		set_user_clan(player, clan[id]);

		client_print_color(player, player, "Zostales przyjety do klanu^x03 %s^x01!", clanName);
	}
	else 
	{
		set_clan_info(clan[id], CLAN_MEMBERS, get_clan_info(clan[id], CLAN_MEMBERS) + 1);
	
		save_clan(clan[id]);
	}

	remove_applications(id, userName);
}

stock check_applications(id, clanId)
{
	new queryData[128], error[128], errorNum, bool:foundApplication;
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_applications` WHERE `name` = '%s' AND clan = '%i'", playerName[id], clanId);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if(SQL_NumResults(query)) foundApplication = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundApplication;
}

stock remove_applications(id, const name[] = "")
{
	new queryData[128], safeName[64];

	if(strlen(name)) mysql_escape_string(name, safeName, charsmax(safeName));
	else copy(safeName, charsmax(safeName), playerName[id]);

	formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans_applications` WHERE name = '%s'", safeName);

	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock check_clan_name(const clanName[])
{
	new queryData[128], safeClanName[64], error[128], errorNum, bool:foundClan;

	mysql_escape_string(clanName, safeClanName, charsmax(safeClanName));
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans` WHERE `clan_name` = '%s'", safeClanName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if(SQL_NumResults(query)) foundClan = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundClan;
}

stock check_user_clan(const userName[])
{
	new queryData[128], safeUserName[64], error[128], errorNum, bool:foundClan;

	mysql_escape_string(userName, safeUserName, charsmax(safeUserName));
	
	formatex(queryData, charsmax(queryData), "SELECT * FROM `cod_clans_members` WHERE `name` = '%s' AND clan > 0", userName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return false;
	}
	
	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	if(SQL_NumResults(query)) foundClan = true;

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
	
	return foundClan;
}

stock create_clan(id, const clanName[])
{
	new codClan[clanInfo], queryData[128], safeClanName[64], error[128], errorNum;

	mysql_escape_string(clanName, safeClanName, charsmax(safeClanName));
	
	formatex(queryData, charsmax(queryData), "INSERT INTO `cod_clans` (`clan_name`) VALUES ('%s');", safeClanName);
	
	new Handle:connectHandle = SQL_Connect(sql, errorNum, error, charsmax(error));
	
	if(errorNum)
	{
		log_to_file("cod_mod.log", "Error: %s", error);
		
		return;
	}

	new Handle:query = SQL_PrepareQuery(connectHandle, queryData);
	
	SQL_Execute(query);
	
	clan[id] = SQL_GetInsertId(query);

	copy(codClan[CLAN_NAME], charsmax(codClan[CLAN_NAME]), clanName);
	codClan[CLAN_STATUS] = _:TrieCreate();
	codClan[CLAN_ID] = clan[id];
	
	ArrayPushArray(codClans, codClan);

	set_user_clan(id, clan[id], 1);
	set_user_status(id, STATUS_LEADER);

	SQL_FreeHandle(query);
	SQL_FreeHandle(connectHandle);
}

stock remove_clan(id)
{
	new players[32], playersNum, player;
	
	get_players(players, playersNum);
	
	for(new i = 0; i < playersNum; i++)
	{
		player = players[i];
		
		if(player == id || is_user_hltv(player) || !is_user_connected(player)) continue;

		if(clan[player] == clan[id])
		{
			clan[player] = 0;
		
			cod_print_chat(player,  "Twoj klan zostal rozwiazany.");
		}

		if(clan[player] > clan[id]) clan[player]--;
	}

	ArrayDeleteItem(codClans, clan[id]);

	clan[id] = 0;

	new queryData[128];
			
	formatex(queryData, charsmax(queryData), "DELETE FROM `cod_clans` WHERE clan_id = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
	
	formatex(queryData, charsmax(queryData), "UPDATE `cod_clans_members` SET flag = '0', clan = '0' WHERE clan = '%i'", clan[id]);
	SQL_ThreadQuery(sql, "ignore_handle", queryData);
}

stock check_clan_loaded(clan)
{
	static codClan[clanInfo];
	
	for(new i = 1; i < ArraySize(codClans); i++)
	{
		ArrayGetArray(codClans, i, codClan);
		
		if(clan == codClan[CLAN_ID]) return true;
	}
	
	return false;
}

stock get_clan_info(clan, info, dataReturn[] = "", dataLength = 0)
{
	static codClan[clanInfo];
	
	ArrayGetArray(codClans, clan, codClan);
	
	if(info == CLAN_NAME)
	{
		copy(dataReturn, dataLength, codClan[info]);
		
		return 0;
	}
	
	return codClan[info];
}

stock set_clan_info(clan, info, value = 0, dataSet[] = "", dataLength = 0)
{
	static codClan[clanInfo];
	
	ArrayGetArray(codClans, clan, codClan);
	
	if(info == CLAN_NAME) formatex(codClan[info], dataLength, dataSet);
	else codClan[info] = value;

	ArraySetArray(codClans, clan, codClan);

	save_clan(clan);
}