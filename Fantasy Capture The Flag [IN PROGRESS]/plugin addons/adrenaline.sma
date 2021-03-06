/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <amxmisc>
#include < hamsandwich >
#include < cstrike >
#include < fakemeta >
#include <fun>

#define PLUGIN "New Plug-In"
#define VERSION "1.0"
#define AUTHOR "author"

#define MAX_PLAYERS		32 + 1
#define FFADE_IN 		0x0000


#define TASK_ADRENALINE		978968
#define ADRENALINE_DURATION	8

#define IS_PLAYER(%1)		(1 <= %1 <= gMaxPlayers)

new bool:bAdrenaline[ MAX_PLAYERS ] = false;	

new gHudSync;
new gMessageScreenFade;
new gMaxPlayers;

const m_iXtraOff = 4;
const m_iXtraOffPlayer = 5;
const m_pPlayer	= 41;
const m_iClip = 51;
const m_pActiveItem = 373;
const m_flNextPrimaryAttack = 46;

const  NOSHOT_BITSUM = ( 1<<CSW_KNIFE ) | ( 1<<CSW_HEGRENADE ) | (1<<CSW_FLASHBANG) | ( 1<<CSW_SMOKEGRENADE );

new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

stock const gMaxClip[ CSW_P90 + 1 ] =
{
	-1,  13, -1, 10,  1,  7,    1, 30, 30,  1,  30, 
	20, 25, 30, 35, 25, 12, 20, 10, 30, 100, 
	8 , 30, 30, 20,  2, 7, 30, 30, -1,  50
};

new const gAdrenalineSound[ ] = "fvox/adrenaline_shot.wav";
	
public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	new szWeaponName[ 32 ];
	
	for( new iId = CSW_P228; iId <= CSW_P90; iId++ ) 
	{ 
		if( ~NOSHOT_BITSUM & 1<<iId && get_weaponname( iId, szWeaponName, charsmax( szWeaponName ) ) )
		{ 
			RegisterHam( Ham_Weapon_PrimaryAttack, szWeaponName, "bacon_PrimaryAttack", true );
		}
	}
	
	RegisterHam( Ham_Player_ResetMaxSpeed, "player", "bacon_ResetMaxSpeed", 1 );

	register_clcmd( "adre", "CommandAdrenaline" );
	
	register_event( "DeathMsg", "Hook_Death", "a" );
	register_event("CurWeapon" , "Event_CurWeapon" , "be" , "1=1" );
	
	gHudSync = CreateHudSyncObj( );
	gMaxPlayers = get_maxplayers( );
	gMessageScreenFade = get_user_msgid( "ScreenFade" );
}

public plugin_precache( )
{
	precache_sound( gAdrenalineSound );
}

public client_connect( id )
{
	bAdrenaline[ id ] = false;
}

public CommandAdrenaline( id )
{
	if( !is_user_alive( id ) )
	{
		return PLUGIN_HANDLED;
	}
	
	if( bAdrenaline[ id ] == true )
	{
		set_hudmessage( 210, 210, 210, -1.0, 0.81, 2, 6.0, 4.0 );
		ShowSyncHudMsg( id, gHudSync, "You are already using Adrenaline!" );
	
		return PLUGIN_HANDLED;
	}
	
	bAdrenaline[ id ] = true;
	
	UTIL_Fade( id, 210, 210, 210, 200 );
	set_hudmessage( 210, 210, 210, -1.0, 0.81, 2, 6.0, 4.0 );
	ShowSyncHudMsg( id, gHudSync, "You have injected Adrenaline!" );
	
	set_user_rendering( id, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 15 );
	set_task( float( ADRENALINE_DURATION ), "RemoveAdrenaline", id + TASK_ADRENALINE );
	emit_sound( id, CHAN_VOICE, gAdrenalineSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM );
	
	return PLUGIN_HANDLED;
}

public RemoveAdrenaline( iTaskid )
{
	new id = iTaskid - TASK_ADRENALINE;
	
	if( IS_PLAYER( id ) )
	{
		if( is_user_alive( id ) )
		{
			ExecuteHamB( Ham_Player_ResetMaxSpeed, id );
			remove_task( id + TASK_ADRENALINE );
			set_user_rendering( id );
			
			bAdrenaline[ id ] = false;
			
			set_hudmessage( 210, 210, 210, -1.0, 0.81, 2, 6.0, 4.0 );
			ShowSyncHudMsg( id, gHudSync, "Adrenaline effects are gone!" );
		}
	}
}

public Hook_Death( )
{
	new iVictim = read_data( 2 );

	if( IS_PLAYER( iVictim ) )
	{
		remove_task( iVictim + TASK_ADRENALINE );
		set_user_rendering( iVictim );
		ExecuteHamB( Ham_Player_ResetMaxSpeed, iVictim );
			
		bAdrenaline[ iVictim ] = false;
	}
}

public Event_CurWeapon( id )
{
	new iWeapon = read_data( 2 );

	if( bAdrenaline[ id ] == true )
	{
		new Float:flMaxSpeed = 450.0;
	
		engfunc( EngFunc_SetClientMaxspeed, id, flMaxSpeed );
		set_pev( id, pev_maxspeed, flMaxSpeed );

    		if( !( NOSHOT_BITSUM & ( 1<<iWeapon ) ) )
    		{
			new iEntWeap = get_pdata_cbase( id, m_pActiveItem, m_iXtraOffPlayer );
			new iClip = get_pdata_int( iEntWeap, m_iClip, m_iXtraOff );
			
			if( iClip <= 0 )
			{
				set_pdata_int( iEntWeap, m_iClip, gMaxClip[ iWeapon ], m_iXtraOff );
			}
    		}
	}
}


public bacon_ResetMaxSpeed( id )
{
	if( is_user_alive( id ) )
	{
		if( bAdrenaline[ id ] == true )
		{
			new Float:flMaxSpeed = 450.0;
	
			engfunc( EngFunc_SetClientMaxspeed, id, flMaxSpeed );
			set_pev( id, pev_maxspeed, flMaxSpeed );
		}
	}
}

public bacon_PrimaryAttack( iWeapon )
{
	new id = get_pdata_cbase( iWeapon, m_pPlayer, m_iXtraOff );
	
	if( bAdrenaline[ id ] == true )
	{
		set_pdata_float( iWeapon, m_flNextPrimaryAttack, get_pdata_float( iWeapon, m_flNextPrimaryAttack, m_iXtraOff ) * 0.5, m_iXtraOff );
	}
}

stock UTIL_Fade( id, r, g, b, a )
{
	message_begin( MSG_ONE_UNRELIABLE, gMessageScreenFade , _, id );
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( FFADE_IN );
	write_byte( r );
	write_byte( g );
	write_byte( b ); 
	write_byte( a );
	message_end( );
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0\\ deflang2057{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
