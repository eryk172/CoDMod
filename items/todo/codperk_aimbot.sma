/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <codmod>
#include <fakemeta>
#include <engine>

#define IsPlayer(%1) 	(1 <= %1 <= get_maxplayers() && is_user_alive(%1))
#define DiffTeam(%1 %2) (get_user_team(%1) != get_user_team(%2))
#define moreRecoil(%1) 	(get_user_weapon(%1) == CSW_AK47 || get_user_weapon(%1) == CSW_AUG || get_user_weapon(%1) == CSW_GALIL || get_user_weapon(id) == CSW_DEAGLE)
new cvar_tracking, cvar_norecoil, cvar_range;

const Float:HeadOriginWithRecoil 	= 14.0;
const Float:HeadOriginWithoutRecoil 	= 8.5;

new const perk_name[] = "Aimbot";
new const perk_desc[] = "W czasie gry przytrzymujemy [C], najbli�sza g�owa przeciwnika zostanie namierzona.";

new bool:ma_perk[33];
public plugin_init() 
{
	register_plugin(perk_name, "1.0", "Kaleka");
	
	cod_register_perk(perk_name, perk_desc);
	
	register_forward(FM_CmdStart, "fwCmdStart");
	register_forward(FM_TraceLine, "fwTraceLine", 1);
	register_forward(FM_StartFrame, "fwServerFrame");

	cvar_tracking 	= register_cvar("aimbot_tracking", "1");
	cvar_norecoil 	= register_cvar("aimbot_norecoil", "0");
	cvar_range 	= register_cvar("aimbot_range", "1000");
	
}
public cod_perk_enabled(id)
{
	ma_perk[id] = true;
}
public cod_perk_disabled(id)
{
	ma_perk[id] = false;
}

public cod_perk_used(id){
	if(!get_pcvar_num(cvar_tracking)) return 1;
	
	if(IsPlayer(id)){		
		if(ma_perk[id]){
			new NeariestPlayer = Neariest(id);
			
			if(IsPlayer(NeariestPlayer)){
				set_hudmessage(0, 255, 0, 0.42, 0.55, 1, 0.1, 0.1, 0.1, 0.1)
				show_hudmessage(id, "Znaleziono przeciwnika..");
				
				new Float:fHeadOrigin[3], Float:fHeadAngles[3];
				engfunc(EngFunc_GetBonePosition, NeariestPlayer, 8, fHeadOrigin, fHeadAngles);	
				
				if(moreRecoil(id))
					DecreaseHead(fHeadOrigin, HeadOriginWithRecoil);
				
				else	
					DecreaseHead(fHeadOrigin, HeadOriginWithoutRecoil);
				
				entity_set_aim(id, fHeadOrigin);
			}
			else{
				set_hudmessage(255, 0, 0, 0.39, 0.55, 1, 0.1, 0.1, 0.1, 0.1)
				show_hudmessage(id, "Przeciwnicy sa zbyt daleko...");
			}
				
		}
	}
	return 0;
}
public fwServerFrame(){
	if(!get_pcvar_num(cvar_norecoil)) return 1;
	new ent = -1;
	while ((ent = find_ent_by_class(ent, "player"))){
		if(IsPlayer(ent)){
			new buttons = pev(ent, pev_button);
			if(buttons & IN_ATTACK){
				set_pev(ent, pev_punchangle, Float:{0.0, 0.0, 0.0 });
			}
		}
	}
	return 0;
}

public fwTraceLine(Float:fVec1[3], Float:fVec2[3], NoMonsters, id){
	if(!get_pcvar_num(cvar_norecoil) && ma_perk[id]) return FMRES_IGNORED;
	
	new vHit[3], Float:fHit[3];
	get_user_origin(id, vHit, 4);
	IVecFVec(vHit, fHit);
	
	set_tr(TR_vecEndPos, fHit);
	
	return FMRES_IGNORED;
}

stock DecreaseHead(Float:fOrigin[3], Float:ammount) fOrigin[2] -= ammount;

stock entity_set_aim(ent, const Float:origin2[3], bone=0){
	if(!pev_valid(ent))
		return 0;
		

	static Float:origin[3];
	origin[0] = origin2[0];
	origin[1] = origin2[1];
	origin[2] = origin2[2];
	
	static Float:ent_origin[3], Float:angles[3];
	
	if(bone)
		engfunc(EngFunc_GetBonePosition,ent,bone,ent_origin,angles);
	else
		pev(ent,pev_origin,ent_origin);
	
	origin[0] -= ent_origin[0]
	origin[1] -= ent_origin[1]
	origin[2] -= ent_origin[2]
	
	static Float:v_length;
	v_length = vector_length(origin);
	
	static Float:aim_vector[3];
	aim_vector[0] = origin[0] / v_length;
	aim_vector[1] = origin[1] / v_length;
	aim_vector[2] = origin[2] / v_length;
	
	static Float:new_angles[3];
	vector_to_angle(aim_vector,new_angles);
	
	new_angles[0] *= -1;
	
	if(new_angles[1]>180.0) new_angles[1] -= 360;
	if(new_angles[1]<-180.0) new_angles[1] += 360;
	if(new_angles[1]==180.0 || new_angles[1]==-180.0) new_angles[1]=-179.999999;
	
	set_pev(ent,pev_angles,new_angles);
	set_pev(ent,pev_fixangle,1);
	
	return 1;
}	

stock Neariest(iEntity){
	new iPlayers[32], iNum;
	
	get_players(iPlayers, iNum, "ache", get_user_team(iEntity) == 2 ? "TERRORIST" : "CT");
	
	new iClosestPlayer = 0, Float:flClosestDist = float(get_pcvar_num(cvar_range));
	new iPlayer, Float:flDist;
	
	for( new i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		flDist = entity_range( iPlayer, iEntity );
		
		if(flDist < flClosestDist)
		{
			iClosestPlayer = iPlayer;
			flClosestDist = flDist;
		}
	}
	return iClosestPlayer;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1045\\ f0\\ fs16 \n\\ par }
*/
