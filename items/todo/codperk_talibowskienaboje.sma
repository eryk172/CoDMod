/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <codmod>

#define AUTHOR "J River"

#define DMG_BULLET (1<<1)

new const perk_name[] = "Talibowskie Naboje";
new const perk_desc[] = "1/LW na natychmiastowe zabicie z USP";

new bool:ma_perk[33], wartosc_perku[33];

public plugin_init() 
{
	register_plugin(perk_name, "1.0", AUTHOR);
	
	cod_register_perk(perk_name, perk_desc, 2, 6);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage");
}
public cod_perk_enabled(id, wartosc)
{
	cod_give_weapon(id, CSW_USP);
	ma_perk[id] = true;
	wartosc_perku[id] = wartosc;
	client_print(id, print_chat, "Perk stworzony przez J River")
}
public cod_perk_disabled(id)
{
	cod_take_weapon(id, CSW_USP);
	ma_perk[id] = false;
}	
public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker))
		return HAM_IGNORED;
	
	if(!ma_perk[idattacker])
		return HAM_IGNORED;
		
	if(get_user_team(this) != get_user_team(idattacker) && get_user_weapon(idattacker) == CSW_USP && damagebits & DMG_BULLET && random_num(1, wartosc_perku[idattacker]) == 1)
		cod_inflict_damage(idattacker, this, float(get_user_health(this))-damage+1.0, 0.0, idinflictor, damagebits);
	
	return HAM_IGNORED;
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/