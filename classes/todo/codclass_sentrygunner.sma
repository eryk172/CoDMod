/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <codmod>
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <fun>
#include <xs>

#define MAX_DIST 8192.0
#define MAX 32

#define AUTHOR "cypis"

new const nazwa[]   = "Sentry Gunner";
new const opis[]    = "Raz na runde moze postawic Sentry Guna";
new const bronie    = 1<<CSW_M4A1 | 1<<CSW_DEAGLE;
new const zdrowie   = 0;
new const kondycja  = 0;
new const inteligencja = 0;
new const wytrzymalosc = 0;

new ma_klase[33];

new bool:sentrys[MAX+1];

new ilosc[33];

new ZmienKilla[2];

public plugin_init()
{
	register_plugin(nazwa, "1.0", "BloodMan");
	
	cod_register_class(nazwa, opis, bronie, zdrowie, kondycja, inteligencja, wytrzymalosc);
	
	register_event("HLTV", "NowaRunda", "a", "1=0", "2=0");
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Spawn, "player", "Spawn", 1)
	
	register_think("sentryG","SentryThink");
	
	RegisterHam(Ham_TakeDamage, "func_breakable", "TakeDamage");
	
	register_cvar("zycie_sentry", "2500");
	register_cvar("usun_sentry", "1");
}

public plugin_precache()
{
	precache_model("models/sentrygun_mw2.mdl");
	precache_sound("mw/firemw.wav");
	precache_sound("mw/plant.wav");
	precache_sound("mw/sentrygun_starts.wav");
	precache_sound("mw/sentrygun_stops.wav");
	precache_sound("mw/sentrygun_gone.wav");
	precache_sound("mw/sentrygun_friend.wav");
	precache_sound("mw/sentrygun_enemy.wav");
}

public cod_class_enabled(id)
{
	ilosc[id] = 1;
	ma_klase[id] = true;
}

public cod_class_disabled(id)
{
	ilosc[id] = 0;
	ma_klase[id] = false;
}

public NowaRunda()
{
	new num, players[32];
	get_players(players, num, "gh");
	for(new i = 0; i < num; i++)
	{
		if(task_exists(players[i]+997))
			remove_task(players[i]+997);
	}
	
	if(get_cvar_num("usun_sentry"))
		remove_entity_name("sentryG")
}

public client_disconnect(id)
{
	new ent = -1
	while((ent = find_ent_by_class(ent, "sentryG")))
	{
		if(entity_get_int(ent, EV_INT_iuser2) == id)
			remove_entity(ent);
	}
	return PLUGIN_CONTINUE;
}

public message_DeathMsg()
{
	new killer = get_msg_arg_int(1);
	if(ZmienKilla[1] & (1<<killer))
	{
		set_msg_arg_string(4, "m249");
		return PLUGIN_CONTINUE;
	}
	return PLUGIN_CONTINUE;
}

public Spawn(id)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return PLUGIN_CONTINUE;
	
	if(ma_klase[id])
		ilosc[id] = 1;
	
	return PLUGIN_CONTINUE;
}

public cod_class_skill_used(id)
{
	if(!ilosc[id])
	{
		client_print(id, print_center, "Masz tylko jednego Sentry na runde!");
		return PLUGIN_CONTINUE;
	}
	else
	{
		if (is_user_alive(id))
		{
			
			ilosc[id]--;
			
			CreateSentry(id);
		}
	}
	return PLUGIN_CONTINUE;
}

public CreateSentry(id) 
{
	if(!(entity_get_int(id, EV_INT_flags) & FL_ONGROUND)) 
		return;
	
	new entlist[3];
	if(find_sphere_class(id, "func_bomb_target", 650.0, entlist, 2))
	{
		client_print(id, print_chat, "Jestes zbyt blisko BS'A");
		return;
	}
	if(find_sphere_class(id, "func_buyzone", 650.0, entlist, 2))
	{
		client_print(id, print_chat, "Jestes zbyt blisko Respa");
		return;
	}
	new num, players[32], Float:Origin[3];
	get_players(players, num, "gh");
	for(new a = 0; a < num; a++)
	{
		new i = players[a];
		if(get_user_team(id) != get_user_team(i))
			client_cmd(i, "spk sound/mw/sentrygun_enemy.wav");
		else
			client_cmd(i, "spk sound/mw/sentrygun_friend.wav");
	}
	print_info(id, "Sentry Gun");
	
	entity_get_vector(id, EV_VEC_origin, Origin);
	Origin[2] += 45.0;
	
	new health[12], ent = create_entity("func_breakable");
	get_cvar_string("zycie_sentry",health, charsmax(health));
	
	DispatchKeyValue(ent, "health", health);
	DispatchKeyValue(ent, "material", "6");
	
	entity_set_string(ent, EV_SZ_classname, "sentryG");
	entity_set_model(ent, "models/sentrygun_mw2.mdl");
	
	entity_set_float(ent, EV_FL_takedamage, DAMAGE_YES);
	
	entity_set_size(ent, Float:{-16.0, -16.0, 0.0}, Float:{16.0, 16.0, 48.0});
	
	entity_set_origin(ent, Origin);
	entity_set_int(ent, EV_INT_solid, SOLID_SLIDEBOX);
	entity_set_int(ent, EV_INT_movetype, MOVETYPE_TOSS);
	entity_set_int(ent, EV_INT_iuser2, id);
	entity_set_vector(ent, EV_VEC_angles, Float:{0.0, 0.0, 0.0});
	entity_set_byte(ent, EV_BYTE_controller2, 127);
	
	entity_set_float(ent, EV_FL_nextthink, get_gametime()+1.0);
	
	sentrys[id] = false;
	emit_sound(ent, CHAN_ITEM, "mw/plant.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
}

public SentryThink(ent)
{
	if(!is_valid_ent(ent)) 
		return PLUGIN_CONTINUE;
	
	new Float:SentryOrigin[3], Float:closestOrigin[3];
	entity_get_vector(ent, EV_VEC_origin, SentryOrigin);
	
	new id = entity_get_int(ent, EV_INT_iuser2);
	new target = entity_get_edict(ent, EV_ENT_euser1);
	new firemods = entity_get_int(ent, EV_INT_iuser1);
	
	if(firemods)
	{ 
		if(/*ExecuteHam(Ham_FVisible, target, ent)*/fm_is_ent_visible(target, ent) && is_user_alive(target)) 
		{
			if(UTIL_In_FOV(target,ent))
			{
				goto fireoff;
			}
			
			new Float:TargetOrigin[3];
			entity_get_vector(target, EV_VEC_origin, TargetOrigin);
			
			emit_sound(ent, CHAN_AUTO, "mw/firemw.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			sentry_turntotarget(ent, SentryOrigin, TargetOrigin);
			
			new Float:hitRatio = random_float(0.0, 1.0) - 0.2;
			if(hitRatio <= 0.0)
			{
				UTIL_Kill(id, target, random_float(5.0, 35.0), DMG_BULLET, 1);
				
				message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
				write_byte(TE_TRACER);
				write_coord(floatround(SentryOrigin[0]));
				write_coord(floatround(SentryOrigin[1]));
				write_coord(floatround(SentryOrigin[2]));
				write_coord(floatround(TargetOrigin[0]));
				write_coord(floatround(TargetOrigin[1]));
				write_coord(floatround(TargetOrigin[2]));
				message_end();
			}
			entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.1);
			return PLUGIN_CONTINUE;
		}
		else
		{
			fireoff:
			firemods = 0;
			entity_set_int(ent, EV_INT_iuser1, 0);
			entity_set_edict(ent, EV_ENT_euser1, 0);
			emit_sound(ent, CHAN_AUTO, "mw/sentrygun_stops.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
			
			entity_set_float(ent, EV_FL_nextthink, get_gametime()+1.0);
			return PLUGIN_CONTINUE;
		}
	}
	
	new closestTarget = getClosestPlayer(ent)
	if(closestTarget)
	{
		emit_sound(ent, CHAN_AUTO, "mw/sentrygun_starts.wav", 1.0, ATTN_NORM, 0, PITCH_NORM);
		entity_get_vector(closestTarget, EV_VEC_origin, closestOrigin);
		sentry_turntotarget(ent, SentryOrigin, closestOrigin);
		
		entity_set_int(ent, EV_INT_iuser1, 1);
		entity_set_edict(ent, EV_ENT_euser1, closestTarget);
		
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+1.0);
		return PLUGIN_CONTINUE;
	}
	
	if(!firemods)
	{
		new controler1 = entity_get_byte(ent, EV_BYTE_controller1)+1;
		if(controler1 > 255)
			controler1 = 0;
		entity_set_byte(ent, EV_BYTE_controller1, controler1);
		
		new controler2 = entity_get_byte(ent, EV_BYTE_controller2);
		if(controler2 > 127 || controler2 < 127)
			entity_set_byte(ent, EV_BYTE_controller2, 127);
		
		entity_set_float(ent, EV_FL_nextthink, get_gametime()+0.05);
	}
	return PLUGIN_CONTINUE
}

public sentry_turntotarget(ent, Float:sentryOrigin[3], Float:closestOrigin[3]) 
{
	new newTrip, Float:newAngle = floatatan(((closestOrigin[1]-sentryOrigin[1])/(closestOrigin[0]-sentryOrigin[0])), radian) * 57.2957795;
	
	if(closestOrigin[0] < sentryOrigin[0])
		newAngle += 180.0;
	if(newAngle < 0.0)
		newAngle += 360.0;
	
	sentryOrigin[2] += 35.0
	if(closestOrigin[2] > sentryOrigin[2])
		newTrip = 0;
	if(closestOrigin[2] < sentryOrigin[2])
		newTrip = 255;
	if(closestOrigin[2] == sentryOrigin[2])
		newTrip = 127;
	
	entity_set_byte(ent, EV_BYTE_controller1,floatround(newAngle*0.70833));
	entity_set_byte(ent, EV_BYTE_controller2, newTrip);
	entity_set_byte(ent, EV_BYTE_controller3, entity_get_byte(ent, EV_BYTE_controller3)+20>255? 0: entity_get_byte(ent, EV_BYTE_controller3)+20);
}

public TakeDamage(ent, idinflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED;
	
	new classname[32];
	entity_get_string(ent, EV_SZ_classname, classname, 31);
	
	if(equal(classname, "sentryG")) 
	{
		new id = entity_get_int(ent, EV_INT_iuser2);
		if(get_user_team(attacker) == get_user_team(id))
			return HAM_SUPERCEDE;
		
		if(damage >= entity_get_float(ent, EV_FL_health))
		{
			new Float:Origin[3];
			entity_get_vector(ent, EV_VEC_origin, Origin);	
			new entlist[33];
			new numfound = find_sphere_class(ent, "player", 190.0, entlist, 32);
			
			for(new i=0; i < numfound; i++)
			{		
				new pid = entlist[i];
				
				if(!is_user_alive(pid) || get_user_team(id) == get_user_team(pid))
					continue;
				UTIL_Kill(id, pid, 70.0, (1<<24));
			}
			client_cmd(id, "spk sound/mw/sentrygun_gone.wav");
			
			set_task(1.0, "del_sentry", ent);
		}
	}
	return HAM_IGNORED;
}

public del_sentry(ent)
{	
	remove_entity(ent);
}

stock UTIL_Kill(atakujacy, obrywajacy, Float:damage, damagebits, ile=0)
{
	ZmienKilla[ile] |= (1<<atakujacy);
	ExecuteHam(Ham_TakeDamage, obrywajacy, atakujacy, atakujacy, damage, damagebits);
	ZmienKilla[ile] &= ~(1<<atakujacy);
}

stock print_info(id, const nagroda[], const nazwa[] = "y")
{
	new nick[64];
	get_user_name(id, nick, 63);
	client_print(0, print_chat, "%s wezwan%s przez %s", nagroda, nazwa, nick);
}

stock bool:fm_is_ent_visible(index, entity, ignoremonsters = 0) 
{
	new Float:start[3], Float:dest[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, dest);
	xs_vec_add(start, dest, start);
	
	pev(entity, pev_origin, dest);
	engfunc(EngFunc_TraceLine, start, dest, ignoremonsters, index, 0);
	
	new Float:fraction;
	get_tr2(0, TR_flFraction, fraction);
	if (fraction == 1.0 || get_tr2(0, TR_pHit) == entity)
		return true;
	
	return false;
}

stock bool:UTIL_In_FOV(id,ent)
{
	if((get_pdata_int(id, 510) & (1<<16)) && (Find_Angle(id, ent) > 0.0))
		return true;
	return false;
}

stock getClosestPlayer(ent)
{
	new iClosestPlayer = 0, Float:flClosestDist = MAX_DIST, Float:flDistanse, Float:fOrigin[2][3];
	new num, players[32];
	get_players(players, num, "gh")
	for(new a = 0; a < num; a++)
	{
		new i = players[a];
		if(!is_user_connected(i) || !is_user_alive(i) || /*!ExecuteHam(Ham_FVisible, i, ent)*/!fm_is_ent_visible(i, ent) || get_user_team(i) == get_user_team(entity_get_int(ent, EV_INT_iuser2)))
			continue;
		
		if(UTIL_In_FOV(i, ent))
			continue;
		
		entity_get_vector(i, EV_VEC_origin, fOrigin[0]);
		entity_get_vector(ent, EV_VEC_origin, fOrigin[1]);
		
		flDistanse = get_distance_f(fOrigin[0], fOrigin[1]);
		
		if(flDistanse <= flClosestDist)
		{
			iClosestPlayer = i;
			flClosestDist = flDistanse;
		}
	}
	return iClosestPlayer;
}

stock Float:Find_Angle(id, target)
{
	new Float:Origin[3], Float:TargetOrigin[3];
	pev(id,pev_origin, Origin);
	pev(target,pev_origin,TargetOrigin);
	
	new Float:Angles[3], Float:vec2LOS[3];
	pev(id,pev_angles, Angles);
	
	xs_vec_sub(TargetOrigin, Origin, vec2LOS);
	vec2LOS[2] = 0.0;
	
	new Float:veclength = vector_length(vec2LOS);
	if (veclength <= 0.0)
		vec2LOS[0] = vec2LOS[1] = 0.0;
	else
	{
		new Float:flLen = 1.0 / veclength;
		vec2LOS[0] = vec2LOS[0]*flLen;
		vec2LOS[1] = vec2LOS[1]*flLen;
	}
	engfunc(EngFunc_MakeVectors, Angles);
	
	new Float:v_forward[3];
	get_global_vector(GL_v_forward, v_forward);
	
	new Float:flDot = vec2LOS[0]*v_forward[0]+vec2LOS[1]*v_forward[1];
	if(flDot > 0.5)
		return flDot;
	
	return 0.0;
}
