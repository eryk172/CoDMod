#include <amxmodx>
#include <cod>

#define PLUGIN "CoD VIP"
#define VERSION "1.2.1"
#define AUTHOR "O'Zone"

new Array:listVIPs, vip;

new const commandVIP[][] = { "say /vip", "say_team /vip", "say /vip", "say_team /vip", "vip" };
new const commandVIPs[][] = { "say /vips", "say_team /vips", "say /vipy", "say_team /vipy", "vipy" };

forward amxbans_admin_connect(id);
forward client_admin(id);

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i; i < sizeof commandVIP; i++) register_clcmd(commandVIP[i], "show_vip_motd");
	for (new i; i < sizeof commandVIPs; i++) register_clcmd(commandVIPs[i], "show_vips");

	register_message(get_user_msgid("SayText"), "say_text");
	register_message(get_user_msgid("ScoreAttrib"), "vip_status");

	listVIPs = ArrayCreate(MAX_NAME, MAX_PLAYERS);
}

public plugin_natives()
{
	register_native("cod_get_user_vip", "_cod_get_user_vip", 1);
	register_native("cod_set_user_vip", "_cod_set_user_vip", 1);
}

public plugin_end()
	ArrayDestroy(listVIPs);

public amxbans_admin_connect(id)
	client_authorized_post(id);

public client_authorized(id)
	client_authorized_post(id);

public client_admin(id)
	client_authorized_post(id);
	
public client_authorized_post(id)
{
	if (get_user_flags(id) & ADMIN_LEVEL_H) {
		set_bit(id, vip);

		new name[MAX_NAME], tempName[MAX_NAME], size = ArraySize(listVIPs);

		get_user_name(id, name, charsmax(name));

		for (new i = 0; i < size; i++) {
			ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

			if (equal(name, tempName)) return PLUGIN_CONTINUE;
		}

		ArrayPushString(listVIPs, name);
	}

	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if (get_bit(id, vip)) {
		rem_bit(id, vip);

		new name[MAX_NAME], tempName[MAX_NAME], size = ArraySize(listVIPs);

		get_user_name(id, name,charsmax(name));

		for (new i = 0; i < size; i++) {
			ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

			if (equal(tempName, name)) {
				ArrayDeleteItem(listVIPs, i);

				break;
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public client_infochanged(id)
{
	if (get_bit(id, vip)) {
		new name[MAX_NAME], newName[MAX_NAME];

		get_user_info(id, "name", name, charsmax(name));

		get_user_name(id, newName,charsmax(newName));

		if (!equal(name, newName)) {
			ArrayPushString(listVIPs, name);

			new tempName[MAX_NAME], size = ArraySize(listVIPs);

			for (new i = 0; i < size; i++) {
				ArrayGetString(listVIPs, i, tempName, charsmax(tempName));

				if (equal(tempName, newName)) {
					ArrayDeleteItem(listVIPs,i);

					break;
				}
			}
		}
	}

	return PLUGIN_CONTINUE;
}

public show_vip_motd(id)
	show_motd(id, "vip.txt", "Informacje o VIPie");

public show_vips(id)
{
	new message[192], name[MAX_NAME], size = ArraySize(listVIPs);

	for (new i = 0; i < size; i++) {
		ArrayGetString(listVIPs, i, name, charsmax(name));

		add(message, charsmax(message), name);

		if (i == size - 1) add(message, charsmax(message), ".");
		else add(message, charsmax(message), ", ");
	}

	cod_print_chat(id, "^x03VIPy^x01 na serwerze:^x04 %s", message);

	return PLUGIN_CONTINUE;
}

public cod_class_changed(id, class)
{
	if (get_bit(id, vip) && is_user_alive(id)) {
		cod_give_weapon(id, CSW_HEGRENADE);
		cod_give_weapon(id, CSW_FLASHBANG, 2);
		cod_give_weapon(id, CSW_SMOKEGRENADE);
	}
}

public cod_spawned(id, respawn)
{
	if (get_bit(id, vip) && is_user_alive(id)) {
		cod_give_weapon(id, CSW_HEGRENADE);
		cod_give_weapon(id, CSW_FLASHBANG, 2);
		cod_give_weapon(id, CSW_SMOKEGRENADE);
	}
}

public cod_damage_post(attacker, victim, weapon, Float:damage, damageBits, hitPlace)
{
	if (!get_bit(attacker, vip)) return PLUGIN_CONTINUE;

	cod_inflict_damage(attacker, victim, damage * 0.05, 0.0, damageBits);

	return PLUGIN_CONTINUE;
}

public cod_killed(killer, victim, weaponId, hitPlace)
{
	if (!get_bit(killer, vip)) return PLUGIN_CONTINUE;

	new bool:hs = hitPlace == HIT_HEAD;

	cod_add_user_health(killer, hs ? 15 : 10);

	if (hs) cod_show_hud(killer, TYPE_DHUD, 38, 218, 116, -1.0, 0.35, 0, 0.0, 1.0, 0.0, 0.0, "HeadShot! +15HP");
	else cod_show_hud(killer, TYPE_DHUD, 255, 212, 0, -1.0, 0.31, 0, 0.0, 1.0, 0.0, 0.0, "Zabiles! +10HP");

	return PLUGIN_CONTINUE;
}

public vip_status()
{
	new id = get_msg_arg_int(1);

	if (is_user_alive(id) && get_bit(id, vip)) set_msg_arg_int(2, ARG_BYTE, get_msg_arg_int(2) | 4);
}

public say_text(msgId, msgDest, msgEnt)
{
	new id = get_msg_arg_int(1);

	if (is_user_connected(id) && get_bit(id, vip)) {
		new tempMessage[192], message[192], chatPrefix[64], playerName[MAX_NAME];

		get_msg_arg_string(2, tempMessage, charsmax(tempMessage));

		formatex(chatPrefix, charsmax(chatPrefix), "^x04[VIP]");

		if (!equal(tempMessage, "#Cstrike_Chat_All")) {
			add(message, charsmax(message), chatPrefix);
			add(message, charsmax(message), " ");
			add(message, charsmax(message), tempMessage);
		} else {
	        get_user_name(id, playerName, charsmax(playerName));

	        get_msg_arg_string(4, tempMessage, charsmax(tempMessage));
	        set_msg_arg_string(4, "");

	        add(message, charsmax(message), chatPrefix);
	        add(message, charsmax(message), "^x03 ");
	        add(message, charsmax(message), playerName);
	        add(message, charsmax(message), "^x01 :  ");
	        add(message, charsmax(message), tempMessage);
		}

		set_msg_arg_string(2, message);
	}

	return PLUGIN_CONTINUE;
}

public _cod_get_user_vip(id)
	return get_bit(id, vip);

public _cod_set_user_vip(id)
	client_authorized(id, "");
