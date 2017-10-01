#include <amxmodx>
#include <cstrike>
#include <hamsandwich>
#include <cod>

#define PLUGIN "CoD Class Pulkownik"
#define VERSION "1.0"
#define AUTHOR "O'Zone"

#define NAME         "Pulkownik"
#define DESCRIPTION  "Zadaje coraz wieksze obrazenia wraz ze spadkiem ilosci amunicji w magazynku M249. Mniejsza widocznosc z nozem."
#define FRACTION     "Podstawowe"
#define WEAPONS      (1<<CSW_M249)|(1<<CSW_GLOCK18)
#define HEALTH       20
#define INTELLIGENCE 0
#define STRENGTH     0
#define STAMINA      5
#define CONDITION    5

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	cod_register_class(NAME, DESCRIPTION, FRACTION, WEAPONS, HEALTH, INTELLIGENCE, STRENGTH, STAMINA, CONDITION);
}

public cod_class_enabled(id, promotion)
	cod_set_user_render(id, 60, CLASS, RENDER_ALWAYS, CSW_KNIFE);

public cod_class_damage_attacker(attacker, victim, weapon, &Float:damage, damageBits, hitPlace)
	if(weapon == CSW_M249 && damageBits & DMG_BULLET) cod_inflict_damage(attacker, victim, (100 - cs_get_weapon_ammo(get_pdata_cbase(attacker, 373))) * 0.2, 0.0, damageBits);
