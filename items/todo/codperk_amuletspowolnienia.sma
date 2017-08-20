/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <engine>
#include <fakemeta> 
#include <fun>
#include <cstrike>
#include <amxmisc>
#include <codmod>

#define AUTHOR "J River"

new const perk_name[] = "Amulet Spowolnienia";
new const perk_desc[] = "Masz 1\LW szans na spowolnienie przeciwnika";

new bool:ma_perk[33]
new player_b_bless[33] = 0       //Bless for speed

public plugin_init() 
{
	register_plugin(perk_name, "1.0", AUTHOR);
	
	cod_register_perk(perk_name, perk_desc, 2, 6);
	
	register_event("Damage", "Damage", "b", "2!0")
	
	register_think("Effect_Slow","Set_Slow_Think")
	
}
public cod_perk_enabled(id, wartosc)
{
	client_print(id, print_chat, "Perk stworzony przez J River")
	ma_perk[id] = true;
	player_b_bless[id] = wartosc;
}
public cod_perk_disabled(id)
{
	player_b_bless[id] = 0
	ma_perk[id] = false;
}
public Damage(id)
{
	if (is_user_connected(id))
	{
		new weapon
		new bodypart
		new attacker_id = get_user_attacker(id,weapon,bodypart) 
		if (is_user_connected(attacker_id) && attacker_id != id)
			add_bonus_slow(attacker_id,id)
	}
}
public add_bonus_slow(attacker_id,id)
{
	if(player_b_bless[id] > 0)
	if((random_num(1,player_b_bless[id]) == 1) && get_user_team(attacker_id) != get_user_team(id)){
		slow_make(id,7)
	}
}
/* ==================================================================================================== */

//True slow

stock slow_make(id,seconds)
{		
	new ent = Spawn_Ent("info_target")
	set_pev(ent,pev_classname,"Effect_Slow")
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_ltime, halflife_time() + seconds + 0.1)
	set_pev(ent,pev_solid,SOLID_NOT)
	set_pev(ent,pev_nextthink, halflife_time() + 0.1)			
}
public Set_Slow_Think(ent)
{
	new id = pev(ent,pev_owner)
	if (pev(ent,pev_ltime) < halflife_time() || !is_user_alive(id))
	{
		Display_Icon(id,255,0,0,"dmg_chem",0)	
		set_user_maxspeed(id,252.0+cod_get_user_trim(id))
		remove_entity(ent)
		return PLUGIN_CONTINUE
	}
	
	set_user_maxspeed(id,245.0-230)
	Display_Icon(id,255,0,0,"dmg_chem",1)	
	set_pev(ent,pev_nextthink, halflife_time() + 1.0)
	return PLUGIN_CONTINUE
}
stock Display_Icon(id,red,green,blue,name[], enable)
{
	if (!pev_valid(id))
	{
		return PLUGIN_HANDLED
	}
	
	message_begin( MSG_ONE, get_user_msgid("StatusIcon"), {0,0,0}, id ) 
	write_byte( enable ) 	
	write_string( name ) 
	write_byte( red ) // red 
	write_byte( green ) // green 
	write_byte( blue ) // blue 
	message_end()
	
	return PLUGIN_CONTINUE
}
stock Spawn_Ent(const classname[]) 
{
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classname))
	set_pev(ent, pev_origin, {0.0, 0.0, 0.0})    
	dllfunc(DLLFunc_Spawn, ent)
	return ent
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
