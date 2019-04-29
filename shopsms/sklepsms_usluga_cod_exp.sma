#include <amxmodx>
#include <sklep_sms>
#include <cod>

#define PLUGIN "Sklep-SMS: Usluga CoD Exp"
#define AUTHOR "O'Zone"
#define VERSION "3.3.7"

new const serviceID[MAX_ID] = "cod_exp";

public plugin_init()
	register_plugin(PLUGIN, VERSION, AUTHOR);

public plugin_natives()
	set_native_filter("native_filter");

public plugin_cfg()
	ss_register_service(serviceID);

public ss_service_chosen(id) 
{
	if (!cod_get_user_class(id)) {
		client_print_color(id, id, "^x03[SKLEPSMS]^x01 Musisz^x04 wybrac klase^x01, aby moc zakupic^x04 EXP^x01.");

		return SS_STOP;
	}
	
	return SS_OK;
}

public ss_service_bought(id, amount) 
	cod_set_user_exp(id, amount);
