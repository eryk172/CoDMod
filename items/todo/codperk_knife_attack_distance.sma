/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <fakemeta>
#include <codmod>
#include <xs>

new const nazwa[] = "Knife attack distance";
new const opis[] = "Wiekszy zasieg noza (+int)";

new bool:ma_perk[33], g_knatt[33];

public plugin_init() 
{
	register_plugin(nazwa, "1.0", "QTM_Peyote");
	cod_register_perk(nazwa, opis);
	
	register_forward(FM_TraceLine, "fw_TraceLine");
	register_forward(FM_TraceHull, "fw_TraceHull");
}

public cod_perk_enabled(id)
{
	client_print(id, print_chat, "[AMXX.PL] Perk %s zostal stworzony przez creepMP3", nazwa);
	ma_perk[id] = true;
}

public cod_perk_disabled(id)
{	
	ma_perk[id] = false;
	g_knatt[id] = 0
}

public fw_TraceLine(Float:vecStart[3], Float:vecEnd[3], conditions, id, ptr)
{
	if (!ma_perk[id]) return FMRES_IGNORED;

	static Float:flFraction, wead_id;
	wead_id = get_user_weapon(id);

	if (wead_id != CSW_KNIFE) return FMRES_IGNORED;

	static Float:vecAngles[3], Float:vecForward[3], attack_mod, Float:Distance;
	pev(id, pev_v_angle, vecAngles);
	engfunc(EngFunc_MakeVectors, vecAngles);

	global_get(glb_v_forward, vecForward);

	attack_mod = floatround((vecStart[0]-vecEnd[0])/vecForward[0]);

	if (attack_mod == -48) Distance = 500+(cod_get_user_intelligence(id)*5.0)
	else if (attack_mod == -32) Distance = 500+(cod_get_user_intelligence(id)*5.0)
	else
	{
		g_knatt[id] = 0;
		return FMRES_IGNORED;
	}

	if (Distance == 0) return FMRES_IGNORED;

	if ((attack_mod == -48 && Distance < 48.0) || (attack_mod == -32 && Distance < 32.0))
		g_knatt[id] = 2;
	else g_knatt[id] = 1;

	get_tr2(ptr, TR_flFraction, flFraction);

	if ((g_knatt[id] == 1 && flFraction >= 1.0) || g_knatt[id] == 2)
	{
		xs_vec_mul_scalar(vecForward, Distance, vecForward);
		xs_vec_add(vecStart, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecStart, vecEnd, conditions, id, ptr);
		return FMRES_SUPERCEDE;
	}
	else g_knatt[id] = 0;

	return FMRES_SUPERCEDE;
}
public fw_TraceHull(Float:vecStart[3], Float:vecEnd[3], conditions, hull, id, ptr)
{
	if (!ma_perk[id]) return FMRES_IGNORED;

	if (g_knatt[id])
	{
		if (g_knatt[id] == 1) return FMRES_IGNORED;
		else return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}