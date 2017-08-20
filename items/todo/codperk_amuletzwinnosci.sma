/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <codmod>
#include <fakemeta>

#define AUTHOR "J River"

new nazwa[] = "Amulet Zwinnosci";
new opis[] = "Dostajesz 100 kondycji";

public plugin_init() 
{
	register_plugin(nazwa, "1.0", AUTHOR);
	
	cod_register_perk(nazwa, opis);
}

public cod_perk_enabled(id)
{
	cod_set_user_bonus_trim(id, cod_get_user_trim(id, 0, 0)+100);
	client_print(id, print_chat, "Perk stworzony przez J River")
	return COD_CONTINUE;
}

public cod_perk_disabled(id)
	cod_set_user_bonus_trim(id, cod_get_user_trim(id, 0, 0)-100);
