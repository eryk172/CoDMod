/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <codmod>
#include <fun>


new const perk_name[] = "Kamizelka NASA";
new const perk_desc[] = "Dostajesz 30 wytrzymalosci";


public plugin_init() 
{
	register_plugin(perk_name, "1.0", "QTM_Peyote");
	
	cod_register_perk(perk_name, perk_desc);
}

public cod_perk_enabled(id)
	cod_set_user_bonus_stamina(id, cod_get_user_stamina(id, 0, 0)+30);
	
public cod_perk_disabled(id)
	cod_set_user_bonus_stamina(id, cod_get_user_stamina(id, 0, 0)-30);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
