/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <colorchat>
#include <codmod>
#include <hamsandwich>

#define POKAZ_STATUS 2895
#define MINIMUM_FALL_SPEED 300
#define MAXIMUM_DAMAGE_FROM_JUMP 70.0

#define DAMAGE 30.0
#define DELAY 0.2

new const nazwa[] = "Nozownik |Premium|";
new const opis[] = "Ma 20 nozy do rzucania, jest niewidzialny, po skoczeniu komus na glowe zabija go, nie slychac jego krokow, zostawia slady za soba.";
new const bronie = 1<<CSW_KNIFE;
new const zdrowie = -95;
new const kondycja = 0;
new const inteligencja = 0;
new const wytrzymalosc = 10;

new noze[33], bool: ma_klase[33], skoki[33],  SyncHudObj
new blood
new blood2
new amx_headsplash;
new Float:falling_speed[33];
new Float:damage_after[33][33];

new decals[2] = {107,108}


new bool:g_isDying[33]
new g_decalSwitch[33]


public plugin_init() {
	register_plugin(nazwa, "1.0", "grzesiu131");
	register_cvar("amx_knifedamage_mw2","55")
	register_cvar("amx_knifespeed_mw2","700")
	register_cvar("amx_knifegravity_mw2","0.3")
	RegisterHam(Ham_Spawn, "player", "Spawn", 1)
	register_event("HLTV", "Nowa_Runda", "a", "1=0", "2=0") 
	register_touch("throw_knife", "player", "knife_touch")
	register_touch("throw_knife", "worldspawn",		"touchWorld")
	register_touch("throw_knife", "func_wall",		"touchWorld")
	register_touch("throw_knife", "func_wall_toggle",	"touchWorld")
	amx_headsplash = register_cvar("amx_headsplash", "1"); 
	register_forward(FM_Touch, "forward_touch");
	register_forward(FM_PlayerPreThink, "forward_PlayerPreThink");
	SyncHudObj = CreateHudSyncObj();
	register_forward(FM_PlayerPreThink, "PlayerPreThink");
	register_event("DeathMsg","death_event","a")
	cod_register_class(nazwa, opis, bronie, zdrowie, kondycja, inteligencja, wytrzymalosc);
}
public plugin_precache(){
	precache_model("models/w_throw.mdl");
	blood = precache_model("sprites/blood.spr")
	blood2 = precache_model("sprites/bloodspray.spr")
	precache_sound("player/headshot1.wav")
	precache_sound("player/die1.wav")
}
public cod_class_enabled(id)
{
	if(!(get_user_flags(id) & ADMIN_LEVEL_H))
	{
		client_print(id, print_chat, "[Nozownik] Nie masz uprawnien, aby uzywac tej klasy.")
		return COD_STOP;
	}
	noze[id] = 20;
	ma_klase[id] = true;
	g_isDying[id] = true;
	set_task(0.1, "pokaz_informacje", id+POKAZ_STATUS, _, _, "b");
	set_user_footsteps(id, 1);
	new param[1];
	param[0] = id
	set_task(0.2, "make_footsteps", 4247545+id, param, 1, "b");
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
	
	return COD_CONTINUE;
}
public pokaz_informacje(id)
{
	id -= POKAZ_STATUS
	if(is_user_alive(id))
	{
		set_hudmessage(0, 255, 0, 0.02, 0.5, 0, 0.1, 0.3, 0.0, 0.0);
		ShowSyncHudMsg(id, SyncHudObj, "[Noze : %d / 20]", noze[id])
	}
}
public Spawn(id)
{
	if(ma_klase[id])
	{
		noze[id] = 20
		new param[1]
		param[0] = id
		if(!task_exists(id + POKAZ_STATUS))
			set_task(0.1, "pokaz_informacje", id+POKAZ_STATUS, _, _, "b");
		if(!task_exists(4247545 + id))
			set_task(0.2, "make_footsteps", 4247545+id, param, 1, "b")
		strip_user_weapons(id)
		give_item(id, "weapon_knife");
		g_isDying[id] = true
		set_user_footsteps(id, 1);
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
	}
}
public client_disconnect(id)
	noze[id] = 0
public client_connect(id)
	noze[id] = 0

public cod_class_disabled(id)
{
	g_isDying[id] = false
	noze[id] = 0
	ma_klase[id] = false
	set_user_footsteps(id,0)
	remove_task(id + POKAZ_STATUS)
	remove_task(4247545+id)
	set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255);
}
public Nowa_Runda()
{
	new iEnt = find_ent_by_class(-1, "throw_knife");
	while(iEnt > 0) 
	{
		remove_entity(iEnt);
		iEnt = find_ent_by_class(iEnt, "throw_knife");	
	}
	
}
public cod_class_skill_used(id)
{
	paint_fire(id)
}
public touchWorld(Toucher, Touched){
	remove_entity(Toucher)
	return PLUGIN_HANDLED;
	
}

public knife_touch(Toucher, Touched){
	new kid = entity_get_edict(Toucher, EV_ENT_owner)
	new vic = entity_get_edict(Toucher, EV_ENT_enemy)
	if(is_user_alive(Touched)) 
	{
		new bool:zyje = true;
		if(kid == Touched || vic == Touched)
		{
			return ;
		}
		if(get_cvar_num("mp_friendlyfire") == 0 && get_user_team(Touched) == get_user_team(kid)) 
		{
			return ;
		}
		
		new Float:Random_Float[3]
		for(new i = 0; i < 3; i++) Random_Float[i] = random_float(-50.0, 50.0)
		Punch_View(Touched, Random_Float)
		
		if(get_cvar_num("amx_knifedamage_mw2") >= get_user_health(Touched)){
			zyje = false;
		}
		new origin[3];
		get_user_origin(Touched,origin)
		origin[2] += 25
		if(zyje == true){
			if(get_user_team(Touched) == get_user_team(kid)) 
			{
				new name[33]
				get_user_name(kid,name,32)
				client_print(0,print_chat,"%s attacked a teammate",name)
			}
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(blood2)
			write_short(blood)
			write_byte(229)
			write_byte(25)
			message_end()
			set_user_health(Touched,get_user_health(Touched) - get_cvar_num("amx_knifedamage_mw2"));
			emit_sound(Touched, CHAN_ITEM, "player/headshot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			cod_inflict_damage(Toucher, Touched, 100.0, 1.0, 0, 0)
			//cod_set_user_xp(kid, cod_get_user_xp(kid) + 100)
		}
		
		else
		{
			if(get_user_team(Touched) == get_user_team(kid)) {
				set_user_frags(kid, get_user_frags(kid) - 1)
				client_print(kid,print_center,"You killed a teammate")
			}
			else {
				set_user_frags(kid, get_user_frags(kid) + 1)
				cod_set_user_xp(kid, cod_get_user_xp(kid) + 10)
			}
			
			new gmsgScoreInfo = get_user_msgid("ScoreInfo")
			new gmsgDeathMsg = get_user_msgid("DeathMsg")
			
			
			
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			write_coord(origin[0])
			write_coord(origin[1])
			write_coord(origin[2])
			write_short(blood2)
			write_short(blood)
			write_byte(229)
			write_byte(25)
			message_end()
			
			set_msg_block(gmsgDeathMsg,BLOCK_ONCE)
			set_msg_block(gmsgScoreInfo,BLOCK_ONCE)
			user_kill(Touched,1)
			
			message_begin(MSG_ALL,gmsgScoreInfo)
			write_byte(kid)
			write_short(get_user_frags(kid))
			write_short(get_user_deaths(kid))
			write_short(0)
			write_short(get_user_team(kid))
			message_end()
			
			message_begin(MSG_ALL,gmsgScoreInfo)
			write_byte(Touched)
			write_short(get_user_frags(Touched))
			write_short(get_user_deaths(Touched))
			write_short(0)
			write_short(get_user_team(Touched))
			message_end()
			
			message_begin(MSG_ALL,gmsgDeathMsg,{0,0,0},0)
			write_byte(kid)
			write_byte(Touched)
			write_byte(0)
			write_string("knife")
			message_end()
			emit_sound(Touched, CHAN_ITEM, "player/die1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		//usuwam noz
		remove_entity(Toucher)
	}
}

public paint_fire(id)
{
	new ent = create_entity("info_target")
	if (pev_valid(ent) && is_user_alive(id) && ma_klase[id] && noze[id] > 0)
	{
		
		new Float:vangles[3], Float:nvelocity[3], Float:voriginf[3], vorigin[3];
		
		set_pev(ent, pev_owner, id);
		set_pev(ent, pev_classname, "throw_knife");
		engfunc(EngFunc_SetModel, ent, "models/w_throw.mdl");
		set_pev(ent, pev_gravity, get_cvar_float("amx_knifegravity_mw2"));
		set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 0);
		get_user_origin(id, vorigin, 1);
		
		IVecFVec(vorigin, voriginf);
		set_pev(ent,pev_origin,voriginf)
		
		static Float:player_angles[3]
		pev(id, pev_angles, player_angles)
		player_angles[2] = 0.0
		set_pev(ent, pev_angles, player_angles);
		
		pev(id, pev_v_angle, vangles);
		set_pev(ent, pev_v_angle, vangles);
		pev(id, pev_view_ofs, vangles);
		set_pev(ent, pev_view_ofs, vangles);
		
		new veloc = get_cvar_num("amx_knifespeed_mw2")
		
		set_pev(ent, pev_movetype, MOVETYPE_TOSS);
		set_pev(ent, pev_solid, 2);
		velocity_by_aim(id, veloc, nvelocity);	
		
		set_pev(ent, pev_velocity, nvelocity);
		set_pev(ent, pev_effects, pev(ent, pev_effects) & ~EF_NODRAW);
		set_pev(ent,pev_sequence,0)
		set_pev(ent,pev_framerate,1.0)
		
		entity_set_edict(ent, EV_ENT_owner, id)
		noze[id]-= 1
	}
	return ent;
}

public Punch_View(id, Float:ViewAngle[3])
{
	set_pev(id, pev_punchangle, ViewAngle)
}
public forward_touch(toucher, touched) // This function is called every time a player touches another player.
{
	// NOTE: The toucher is the player standing/falling on top of the other (touched) player's head.
	if(!is_user_alive(toucher) || !is_user_alive(touched)) // The touching players can't be dead.
		return;
	
	if(!get_pcvar_num(amx_headsplash)) // If the plugin is disabled, stop messing with things.
		return;
	if(!ma_klase[toucher])
		return;
	
	if(falling_speed[touched]) // Check if the touched player is falling. If he/she is, don't continue.
		return;
	
	if(get_user_team(toucher) == get_user_team(touched) && !get_cvar_num("mp_friendlyfire")) // If the touchers are in the same team and friendly fire is off, don't continue.
		return;
	
	new touched_origin[3], toucher_origin[3];
	get_user_origin(touched, touched_origin); // Get the origins of the players so it's possible to check if the toucher is standing on the touched's head.
	get_user_origin(toucher, toucher_origin);
	
	new Float:toucher_minsize[3], Float:touched_minsize[3];
	pev(toucher,pev_mins,toucher_minsize);
	pev(touched,pev_mins,touched_minsize); // If touche*_minsize is equal to -18.0, touche* is crouching.
	
	if(touched_minsize[2] != -18.0) // If the touched player IS NOT crouching, check if the toucher is on his/her head.
	{
		if(!(toucher_origin[2] == touched_origin[2]+72 && toucher_minsize[2] != -18.0) && !(toucher_origin[2] == touched_origin[2]+54 && toucher_minsize[2] == -18.0))
		{
			return;
		}
	}
	else // If the touched player is crouching, check if the toucher is on his/her head
	{
		if(!(toucher_origin[2] == touched_origin[2]+68 && toucher_minsize[2] != -18.0) && !(toucher_origin[2] == touched_origin[2]+50 && toucher_minsize[2] == -18.0))
		{
			return;
		}
	}
	
	if(falling_speed[toucher] >= MINIMUM_FALL_SPEED) // If the toucher is falling in the required speed or faster, then landing on top of the touched's head, do some damage to the touched. MUHAHAHAHAHA!!!
	{
		new Float:damage = ((falling_speed[toucher] - MINIMUM_FALL_SPEED + 30) * (falling_speed[toucher] - MINIMUM_FALL_SPEED + 30)) / 1300;
		if(damage > MAXIMUM_DAMAGE_FROM_JUMP) // Make shure that the touched player don't take too much damage.
			damage = MAXIMUM_DAMAGE_FROM_JUMP;
		damage_player(touched, toucher, damage); // Damage or kill the touched player.
		damage_after[toucher][touched] = 0.0; // Reset.
	}
	if(is_user_alive(touched) && damage_after[toucher][touched] <= get_gametime()) // This makes shure that you won't get damaged every frame you have some one on your head. It also makes shure that players won't get damaged faster on fast servers than laggy servers.
	{
		damage_after[toucher][touched] = get_gametime() + DELAY;
		damage_player(touched, toucher, DAMAGE); // Damage or kill the touched player.
	}
}

public forward_PlayerPreThink(id) // This is called every time before a player "thinks". A player thinks many times per second.
{
	//falling_speed[id] = entity_get_float(id, EV_FL_flFallVelocity); // Store the falling speed of the soon to be "thinking" player.
	pev(id, pev_flFallVelocity, falling_speed[id])
}

public damage_player(pwned, pwnzor, Float:damage) // Damages or kills a player. Home made HAX
{
	new health = get_user_health(pwned);
	if(get_user_team(pwned) == get_user_team(pwnzor)) // If both players are in the same team, reduce the damage.
		damage /= 1.4;
	new CsArmorType:armortype;
	cs_get_user_armor(pwned, armortype);
	if(armortype == CS_ARMOR_VESTHELM)
		damage *= 0.7;
	if(health >  damage)
	{
		new pwned_origin[3];
		get_user_origin(pwned, pwned_origin);
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY); // BLOOOOOOOOOOOD!!
		write_byte(TE_BLOODSPRITE);
		write_coord(pwned_origin[0]+8);
		write_coord(pwned_origin[1]);
		write_coord(pwned_origin[2]+26);
		write_short(blood2);
		write_short(blood);
		write_byte(248);
		write_byte(4);
		message_end();
		
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "trigger_hurt"));
		if(!ent)
			return;
		new value[16];
		float_to_str(damage * 2, value, sizeof value - 1);
		set_kvd(0, KV_ClassName, "trigger_hurt");
		set_kvd(0, KV_KeyName, "dmg");
		set_kvd(0, KV_Value, value);
		set_kvd(0, KV_fHandled, 0);
		dllfunc(DLLFunc_KeyValue, ent, 0);
		num_to_str(DMG_GENERIC, value, sizeof value - 1);
		set_kvd(0, KV_ClassName, "trigger_hurt");
		set_kvd(0, KV_KeyName, "damagetype");
		set_kvd(0, KV_Value, value);
		set_kvd(0, KV_fHandled, 0);
		dllfunc(DLLFunc_KeyValue, ent, 0);
		set_kvd(0, KV_ClassName, "trigger_hurt");
		set_kvd(0, KV_KeyName, "origin");
		set_kvd(0, KV_Value, "8192 8192 8192");
		set_kvd(0, KV_fHandled, 0);
		dllfunc(DLLFunc_KeyValue, ent, 0);
		dllfunc(DLLFunc_Spawn, ent);
		set_pev(ent, pev_classname, "head_splash");
		dllfunc(DLLFunc_Touch, ent, pwned);
		engfunc(EngFunc_RemoveEntity, ent);
	}
	else
	{
		new pwned_origin[3];
		get_user_origin(pwned, pwned_origin);
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY); // BLOOOOOOOOOOOD!!
		write_byte(TE_BLOODSPRITE);
		write_coord(pwned_origin[0]+8);
		write_coord(pwned_origin[1]);
		write_coord(pwned_origin[2]+26);
		write_short(blood2);
		write_short(blood);
		write_byte(248);
		write_byte(12);
		message_end();
		
		set_pev(pwned, pev_frags, float(get_user_frags(pwned) + 1));
		user_silentkill(pwned);
		make_deathmsg(pwnzor, pwned, 1, "his/her feet :)");
		if(get_user_team(pwnzor) != get_user_team(pwned)) // If it was a team kill, the pwnzor's money should get reduced instead of increased.
		{
			set_pev(pwnzor, pev_frags, float(get_user_frags(pwnzor) + 1));
			cs_set_user_money(pwnzor, cs_get_user_money(pwnzor) + 300);
			cod_set_user_xp(pwnzor, cod_get_user_xp(pwnzor) + 10)
		}
		else
		{
			set_pev(pwnzor, pev_frags, float(get_user_frags(pwnzor) - 1));
			cs_set_user_money(pwnzor, cs_get_user_money(pwnzor) - 300);
		}
		
		message_begin(MSG_ALL, get_user_msgid("ScoreInfo")); // Fixes the scoreboard.
		write_byte(pwnzor);
		write_short(get_user_frags(pwnzor));
		write_short(cs_get_user_deaths(pwnzor));
		write_short(0);
		write_short(get_user_team(pwnzor));
		message_end();
		
		message_begin(MSG_ALL, get_user_msgid("ScoreInfo"));
		write_byte(pwned);
		write_short(get_user_frags(pwned));
		write_short(cs_get_user_deaths(pwned));
		write_short(0);
		write_short(get_user_team(pwned));
		message_end();
		set_pev(pwned, pev_frags, float(get_user_frags(pwned) - 1));
	}
}
public death_event()
{
	new kid = read_data(1)
	new id = read_data(2)
	if(g_isDying[id])
	{
		g_isDying[id] = false
		remove_task(4247545+id)
	}
	if( kid != id && is_user_alive(kid) && ma_klase[id])
	{
		cod_set_user_xp(kid, cod_get_user_xp(kid) + 30)
	}
}
public make_footsteps(param[])
{
	new id = param[0]
	if(!is_user_alive(id) || get_cvar_num("ftw_active") == 1 || get_speed(id) < 120) return
	new origin[3]
	get_user_origin(id, origin)
	if(entity_get_int(id, EV_INT_bInDuck) == 1)
		origin[2] -= 18
	else
		origin[2] -= 36
	new Float:velocity[3]
	new Float:ent_angles[3]
	new Float:ent_origin[3]
	new ent
	
	entity_get_vector(id, EV_VEC_v_angle, ent_angles)
	entity_get_vector(id, EV_VEC_origin, ent_origin)
	
	ent = create_entity("info_target")
	if(ent > 0)
	{
		ent_angles[0] = 0.0
		if(g_decalSwitch[id] == 0) ent_angles[1] -= 90
		else ent_angles[1] += 90
		entity_set_vector(ent, EV_VEC_origin, ent_origin)
		entity_set_vector(ent, EV_VEC_v_angle, ent_angles)
		VelocityByAim(ent, 12, velocity)
		remove_entity(ent)
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY, origin)
	write_byte(116)
	write_coord(origin[0] + floatround(velocity[0]))
	write_coord(origin[1] + floatround(velocity[1]))
	write_coord(origin[2])
	write_byte(decals[g_decalSwitch[id]])
	message_end()
	g_decalSwitch[id] = 1 - g_decalSwitch[id]
	return
}
public PlayerPreThink(id)
{
        if(!ma_klase[id])
                return PLUGIN_CONTINUE;
        
        new button = pev(id, pev_button);
        new oldbutton = pev(id, pev_oldbuttons);
        new flags = pev(id, pev_flags);
        
        if((button & IN_JUMP) && !(flags & FL_ONGROUND) && !(oldbutton & IN_JUMP) && skoki[id])
        {
                skoki[id]--;
                new Float:velocity[3];
                pev(id, pev_velocity, velocity);
                velocity[2] = random_float(265.0,285.0);
                set_pev(id, pev_velocity, velocity);
        }
        else if(flags & FL_ONGROUND)    
                skoki[id] = 3;
        
        return PLUGIN_CONTINUE;
}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
