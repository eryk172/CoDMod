/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <hamsandwich>
#include <codmod>
#include <fakemeta>

#define ZADANIE_WSKRZES 6240

new const perk_name[] = "Oczy Katsumoto";
new const perk_desc[] = "Masz 1/LW szans na odrodzenie sie po smierci dostajesz 50 hp mozesz wykonac podwojny skok";

new wartosc_perku[33];
new bool:ma_perk[33];
new bool:moze_skoczyc[33];

public plugin_init()
 {
	register_plugin(perk_name, "1.0", "Pas");
	
	cod_register_perk(perk_name, perk_desc, 1, 4);
	RegisterHam(Ham_Killed, "player", "Killed", 1);
	register_forward(FM_CmdStart, "CmdStart");
}

public cod_perk_enabled(id, wartosc)
{
        client_print(id, print_chat, "Perk %s zostal stworzony przez Pas", perk_name);
	cod_set_user_bonus_health(id, cod_get_user_health(id, 0, 0)+50);
	wartosc_perku[id] = wartosc;
	ma_perk[id] = true;
}

public cod_perk_disabled(id)
{
	cod_set_user_bonus_health(id, cod_get_user_health(id, 0, 0)-50);
	ma_perk[id] = false;
}

public Killed(id)
{
	if(ma_perk[id] && random_num(1, wartosc_perku[id]) == 1)
		set_task(0.1, "Wskrzes", id+ZADANIE_WSKRZES);
}
public CmdStart(id, uc_handle)
{
	if(!is_user_alive(id) || !ma_perk[id])
		return FMRES_IGNORED;
	
	new flags = pev(id, pev_flags);
	
	if((get_uc(uc_handle, UC_Buttons) & IN_JUMP) && !(flags & FL_ONGROUND) && !(pev(id, pev_oldbuttons) & IN_JUMP) && moze_skoczyc[id])
	{
			moze_skoczyc[id] = false;
			new Float:velocity[3];
			pev(id, pev_velocity,velocity);
			velocity[2] = random_float(265.0,285.0);
			set_pev(id, pev_velocity,velocity);
	}
	else if(flags & FL_ONGROUND)
		moze_skoczyc[id] = true;
		
	return FMRES_IGNORED;
}
public Wskrzes(id)
	ExecuteHamB(Ham_CS_RoundRespawn, id-ZADANIE_WSKRZES);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
