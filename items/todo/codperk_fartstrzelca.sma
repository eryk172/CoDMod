/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>
#include <codmod>

#define DMG_BULLET (1<<1)

new wartosc_perku[33];
new bool:ma_perk[33];

public plugin_init() 
{
	register_plugin("Fart Strzelca", "1.0", "QTM_Peyote");
	
	cod_register_perk("Fart Strzelca", "Masz 1/LW szans na natychmiastowe zabicie z USP/GLOCK18", 6, 12);
	RegisterHam(Ham_TakeDamage, "player", "TakeDamage")
}

public cod_perk_enabled(id, wartosc)
{
	wartosc_perku[id] = wartosc;
	ma_perk[id] = true;
}

public cod_perk_disabled(id)
	ma_perk[id] = false

public TakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker))
		return HAM_IGNORED;
	
	if(!ma_perk[idattacker])
		return HAM_IGNORED;
	
	if(get_user_team(this) == get_user_team(idattacker))
		return HAM_IGNORED;
		
	if(random_num(1, wartosc_perku[idattacker]) != 1)
		return HAM_IGNORED;
	
	if(!(damagebits & DMG_BULLET))
		return HAM_IGNORED;
	
	new weapon = get_user_weapon(idattacker);
	
	if(weapon != CSW_USP && weapon != CSW_GLOCK18)
		return HAM_IGNORED;
	
	SetHamParamFloat(4, float(get_user_health(this)))
	
	return HAM_IGNORED;
}
