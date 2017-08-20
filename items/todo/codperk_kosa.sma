/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <fakemeta> 
#include <fun>
#include <hamsandwich> 
#include <cstrike>
#include <amxmisc>
#include <codmod> 

#define AUTHOR "J River"

#define DMG_BULLET (1<<1)

new const perk_name[] = "Platynowa Kosa";
new const perk_desc[] = "1/LW na natychmiastowe zabicie z noza twoja widocznosc spadado 60";

new bool:ma_perk[33], wartosc_perku[33];

public plugin_init() 
{
	register_plugin(perk_name, "1.0", AUTHOR);
	
	cod_register_perk(perk_name, perk_desc, 1, 3);
	RegisterHam(Ham_TakeDamage, "player","fwTakeDamage",0);
	
}
public cod_perk_enabled(id, wartosc)
{
	cod_give_weapon(id, CSW_KNIFE);
	set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 60);
	ma_perk[id] = true;
	client_print(id, print_chat, "Perk stworzony przez J River")
	wartosc_perku[id] = wartosc;
}
public cod_perk_disabled(id)
{
	set_rendering(id,kRenderFxGlowShell,0,0,0 ,kRenderTransAlpha, 255);
	cod_take_weapon(id, CSW_KNIFE);
	ma_perk[id] = false;
}	
public fwTakeDamage(this, idinflictor, idattacker, Float:damage, damagebits)
{
	if(!is_user_connected(idattacker))
		return HAM_IGNORED;
		
	new iWeapons[32], iNum, bron
	bron = get_user_weapons(idattacker,iWeapons,iNum)
	
	if(!ma_perk[idattacker])
		return HAM_IGNORED;
		
	if((get_user_button(idattacker) & IN_ATTACK2) && bron&(1<<CSW_KNIFE) && random_num(1, wartosc_perku[idattacker]) == 1)
	{
		new zycie = get_user_health(this) + 1
		SetHamParamFloat(4,float(zycie))
	}
	return HAM_HANDLED;
}
