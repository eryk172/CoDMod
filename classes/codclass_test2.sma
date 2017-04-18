#include <amxmodx>
#include <cod>

new class, classPromotion;

new const nazwa[] = "Test2";
new const opis[] = "Natychmiastowe zabicie z noza(PPM)";
new const frakcja[] = "Testy2";
new const bronie = 1<<CSW_DEAGLE;
new const zdrowie = 40;
new const inteligencja = 0;
new const sila = 10;
new const kondycja = 50;
new const wytrzymalosc = 0;

public plugin_init() 
{
	register_plugin(nazwa, "1.0", "O'Zone");
	
	cod_register_class(nazwa, opis, frakcja, bronie, zdrowie, inteligencja, sila, wytrzymalosc, kondycja);
}

public cod_class_enabled(id, promotion)
{
	set_bit(id, class);

	classPromotion = promotion;

	if(classPromotion == PROMOTION_THIRD) cod_set_user_multijumps(id, 2);
}
	
public cod_class_disabled(id, promotion)
	rem_bit(id, class);

public cod_class_spawned(id)
	if(classPromotion == PROMOTION_THIRD) cod_set_user_multijumps(id, 2);

public cod_item_damage_attacker(attacker, victim, Float:damage, damageBits)
	if(get_user_weapon(attacker) == CSW_KNIFE && damageBits & DMG_BULLET && damage > 20 && get_bit(attacker, class))
		cod_kill_player(attacker, victim, damageBits);
