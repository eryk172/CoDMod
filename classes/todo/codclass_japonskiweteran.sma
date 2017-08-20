/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <fakemeta>
#include <codmod>
#include <engine>

new const nazwa[] = "Japonski Weteran";
new const opis[] = "Moze wspinac sie po scianie";
new const bronie = 1<<CSW_M3;
new const zdrowie = 15;
new const kondycja = 20;
new const inteligencja = 10;
new const wytrzymalosc = 5;

new Float:g_wallorigin[32][3];
new bool:ma_klase[33];

public plugin_init() {
	register_plugin(nazwa, "1.0", "Crew");
	
	cod_register_class(nazwa, opis, bronie, zdrowie, kondycja, inteligencja, wytrzymalosc);
	register_forward(FM_Touch, "fwd_touch");
}
public fwd_touch(id, world)
{
    if(!is_user_alive(id) && ma_klase[id])
        return FMRES_IGNORED;
    
    new classname[32];
    entity_get_string(world, EV_SZ_classname, classname, 31);
    
    if(equal(classname, "worldspawn") || equal(classname, "func_wall") || equal(classname, "func_breakable"))
        entity_get_vector(id, EV_VEC_origin, g_wallorigin[id]);
    return FMRES_IGNORED;
}
public client_PreThink(id)
{
    new button = get_user_button(id);
    if(button & IN_USE && ma_klase[id])
    {
        static Float:origin[3];
        entity_get_vector(id, EV_VEC_origin, origin);
        
        if(get_distance_f(origin, g_wallorigin[id]) > 25.0)    
            return FMRES_IGNORED;
    
        if(get_entity_flags(id) & FL_ONGROUND) 
            return FMRES_IGNORED;

        if(button & IN_FORWARD)
        {
            static Float:velocity[3];
            velocity_by_aim(id, 240, velocity);
            entity_set_vector(id, EV_VEC_velocity, velocity);
        }
        else if(button & IN_BACK)
        {
            static Float:velocity[3];
            velocity_by_aim(id, -240, velocity);
            entity_set_vector(id, EV_VEC_velocity, velocity);
        }
    }    
    return FMRES_IGNORED;
}

public cod_class_enabled(id){       
	ma_klase[id] = true;
}

public cod_class_disabled(id){
	ma_klase[id] = false;
}
