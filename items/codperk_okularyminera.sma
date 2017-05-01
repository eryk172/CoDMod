/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <fakemeta>
#include <codmod>

new const perk_name[] = "Okulary Minera";
new const perk_desc[] = "Widzisz miny z czerwona poswiata";

new bool:ma_perk[33];

new const Float:fColorGlow[3] =
{
	255.0,
	0.0,
	0.0
}

public plugin_init()
 {
	register_plugin(perk_name, "1.0", "O'Zone");
	
	cod_register_perk(perk_name, perk_desc);
	
	register_forward(FM_AddToFullPack, "AddToFullPack", 1)
}

public cod_perk_enabled(id)
	ma_perk[id] = true;

public cod_perk_disabled(id)
	ma_perk[id] = false;

public AddToFullPack(es_handle, e, ent, host, hostflags, player, pSet)
{
	if(!is_user_connected(host) || !ma_perk[host] || !pev_valid(ent))
		return;
	
	new classname[5];
	pev(ent, pev_classname, classname, 4);
	if(equal(classname, "mine"))
	{
		set_es(es_handle, ES_RenderMode, kRenderTransAdd);
		set_es(es_handle, ES_RenderAmt, 255.0);
		set_es(es_handle, ES_RenderColor, fColorGlow);
		set_es(es_handle, ES_RenderMode, kRenderGlow);
		set_es(es_handle, ES_RenderAmt, 16.0);
	}
	
}