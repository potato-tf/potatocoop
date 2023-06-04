Msg("Running potatocoop_sg552laser script\n")
IncludeScript("netpropperf")

// ===========================
//   DAWGMOD's SG552 - START
// ===========================

const TEAM_SPECTATE = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
const MAX_WEAPONS = 6;

/*****************************************************
	DAWGMOD's SG552
	
	Objective:
	  Identical stats to vanilla MP5, but spawns with
	  a permanent laser sight. Scoped shots deal 50
	  damage on headshot at any range and are 100%
	  accurate, but consume 2 ammo per shot.
	  
	  EDIT:
	  Ditch the 2 ammo per shot penalty, and have laser sight
	  while scoped instead.
	  
	  EDIT2:
	  The 2 ammo per shot penalty is back.
	  
	Technical limitations:
	  Using "net_fakelag 120", we can see the following occurs
	  on high ping:
	  - Laser sights will have a delayed appearance, sometimes
	    not even playing its sound.
	  - While zoomed in, ammo will decrease by only 1 per shot.
	    After a short delay, the numbers will quickly descend
		to the right number. Combining "net_fakeloss 20" will
		occasionally have the number rapidly descend instead.
	  
	Do these:
	  1) Toggle laser sights with the "weapon_zoom" event.
	  Script will check if "m_hZoomOwner" netprop == null.

	  2) Track if the primary weapon already had a laser
	  sight on the "player_use" event so we don't remove
	  their "real laser".
	  Script will add a var into their script scope.
	  
	  3) Remove the SG552's scoped laser when all survivors
	  reach and close a checkpoint saferoom, so it won't
	  carry to the next level.
	  
	  4) On new round start, check if SG552 has a real laser.
	  If true, script will set "scope["HasRealLaser"]" to true.
	  
	  2A) For some rational reason, "player_use" doesn't fire
	  when the player is reloading, so that screws over my
	  function that applies "HasRealLaser".
	  With that said, script will set "scope["HasRealLaser"]"
	  to true if both the weapon's "m_bInReload" is true and
	  the player does receive lasers in the "receive_upgrade" event.
	  
	  Orin: DONE.
	  
	  1A) Have the SG552's use up 2 ammo per shot when firing while
	  zoomed in. Do this only if we have the fake laser.
	  Script will do "SetClip1(weapon.Clip1() - 1);" on the game
	  event "weapon_fire".
	  
	  Orin: DONE.
	  
	Testing prodecure:
	  1) In console, "script Convars.SetValue("developer", 1)".
	  2) Give yourself a SG552 with "give rifle_sg552".
	  3) Validate "HasRealLaser" by zooming in and out and zooming
	  in then both jumping and falling off.
	  4) In console, "ent_create upgrade_laser_sight" then get the
	  laser upgrade from it while reloading, and then repeat Step 3.
	  5) Use "warp_all_survivors_to_checkpoint" in console, then while zoomed in close the door. Zoom in then out after map transition
	  and see if the laser persists.
	  6) Repeat Step 5 but with a new fresh SG552.
	  
	  My alias for tutorial_standards:
	  - "alias resetscript "unpause;host_timescale 6;sm_slay @s;wait 350;host_timescale 1;give rifle_sg552;setang 10 176 0;ent_create upgrade_laser_sight"
	
*****************************************************/

// Regexp to turn "function func_a(params)" into "func_a <- function(params)":
// - FIND: (function )([_a-zA-Z]*)(\()
// - REPLACE: ::DawgSG552.(\2) <- function(\3)
::DawgSG552 <- {}

// -----------------
// ++ Game Events ++
// -----------------

// Purpose: Toggles the SG552's scope laser when zoomed in
// when the player hasn't picked up laser sights yet.
//
// Note: The event fires multiple times when a player either falls
// off, jumps or reloads while zoomed in, or spams +attack3 while zooming // in and out.
//
// net_showevents 2:
////
/* Server event "weapon_zoom", Tick 6835:
- "userid" = "22"
*/
////
::DawgSG552.OnGameEvent_weapon_zoom <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    local activeWeapon = NetProps.GetPropEntity(player, "m_hActiveWeapon");

    if ( activeWeapon.GetClassname() != "weapon_rifle_sg552" )
		return;
	
	// (scope && true) returns null.. so (scope != null && true) is needed.
	local scope = activeWeapon.GetScriptScope();
	local hasRealLaser = (scope != null && ("HasRealLaser" in scope));
	
	if( developer() )
		printl( "SG552 has real laser: " + hasRealLaser );
  
	if( !hasRealLaser )
	{
		local zoomOwner = NetProps.GetPropEntity(player, "m_hZoomOwner");
		if ( zoomOwner != null )
		{
			player.GiveUpgrade(UPGRADE_LASER_SIGHT);
		}
		else
		{
			player.RemoveUpgrade(UPGRADE_LASER_SIGHT);
		}
	}
}.bindenv(this)

// Purpose: Have the SG552 use 2 ammo per shot when firing
// while zoomed in, but only if we have the fake laser.
//
// net_showevents 2:
////
/* Server event "weapon_fire", Tick 16970:
- "userid" = "2"
- "weapon" = "rifle_sg552"
- "weaponid" = "34"
- "count" = "1"
*/
////
::DawgSG552.OnGameEvent_weapon_fire <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local wep = params.weapon;
	local weapon = GetPropEntity(player, "m_hActiveWeapon");

	if (GetPropEntity(player, "m_hZoomOwner") != null && wep == "rifle_sg552")
	{
		local scope = weapon.GetScriptScope();
		local hasRealLaser = (scope != null && ("HasRealLaser" in scope));
		if( !hasRealLaser )
			weapon.SetClip1(weapon.Clip1() - 1);
	}
}.bindenv(this)

// Purpose: Track if players have interacted with
// the "upgrade_laser_sight" entity by adding a var
// into their script scope.
//
// net_showevents 2:
////
/* Server event "player_use", Tick 7660:
- "userid" = "22"
- "targetid" = "191"
*/
////
::DawgSG552.OnGameEvent_player_use <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local targetEnt = EntIndexToHScript(params.targetid);
	
	if( targetEnt.GetClassname() == "upgrade_laser_sight" )
	{
		// Doesn't matter to check for lasers here.
		local sg552 = FindInPlayerInv("weapon_rifle_sg552", player);
		if( sg552 != null )
			SetHasRealLaser(sg552, true);
	}
}.bindenv(this)

// Purpose: Track if players have interacted with
// the "upgrade_laser_sight" entity by adding a var
// into their script scope, but while the SG552
// is reloading.
//
// net_showevents 2:
////
/* Server event "receive_upgrade", Tick 4273:
- "userid" = "93"
- "upgrade" = "LASER_SIGHT"
*/
////
::DawgSG552.OnGameEvent_receive_upgrade <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local upgrade = params.upgrade;
	
	if( upgrade == "LASER_SIGHT" )
	{
		local sg552 = FindInPlayerInv("weapon_rifle_sg552", player);
		if( sg552 != null )
		{
			if( NetProps.GetPropInt(sg552, "m_bInReload") == 1 )
				SetHasRealLaser(sg552, true);
		}
	}
}.bindenv(this)

// Purpose: Remove the SG552's laser during map
// transitions if it's not the real laser.
// 
// net_showevents 2:
////
/* Server event "map_transition", Tick 1239:
*/
////
::DawgSG552.OnGameEvent_map_transition <- function( params )
{
	for( local player; player = Entities.FindByClassname(player, "player"); )
	{
		local activeWeapon = NetProps.GetPropEntity(player, "m_hActiveWeapon");
		if( activeWeapon.GetClassname() == "weapon_rifle_sg552" )
		{
			local scope = activeWeapon.GetScriptScope();
			local hasRealLaser = (scope != null && ("HasRealLaser" in scope));
			
			// Zoomed in or not, doesn't matter.
			if( !hasRealLaser )
			{
				player.RemoveUpgrade(UPGRADE_LASER_SIGHT);
			}
		}
	}
}.bindenv(this)

// Purpose: Set SG552's "scope["HasRealLaser"]" to true 
// if it has a laser at post-transitions.
//
/* Server event "player_transitioned", Tick 121:
- "userid" = "40"
*/
////

::DawgSG552.OnGameEvent_player_transitioned <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local sg552 = FindInPlayerInv("weapon_rifle_sg552", player);
	
	if( sg552 != null )
	{
		// UPGRADE_INCENDIARY_AMMO = 1 (1 << 0)
		// UPGRADE_EXPLOSIVE_AMMO  = 2 (1 << 1)
		// UPGRADE_LASER_SIGHT     = 4 (1 << 2)
		local upgradeBitVec = NetProps.GetPropInt( sg552, "m_upgradeBitVec" );
		if( (upgradeBitVec & 4) != 0 )
		{
			SetHasRealLaser(sg552, true);
		}
	}
}.bindenv(this)

// -------------
// ++ Helpers ++
// -------------
// These functions do not validate arguments before using them.
// Weak refs are so they point to same space in memory.

::DawgSG552.SetHasRealLaser <- function(weapon, val)
{
	weapon.ValidateScriptScope();
	local scope = weapon.GetScriptScope();
	scope["HasRealLaser"] <- val;
	
	if( developer() )
		printl( "SetHasRealLaser: " + weapon.GetClassname() + " to " + val );
}
::SetHasRealLaser <- ::DawgSG552.SetHasRealLaser.weakref().ref()

::DawgSG552.FindInPlayerInv <- function(weapon_name, player)
{
	for( local i = 0; i < MAX_WEAPONS; i++ )
	{
		local weapon = NetProps.GetPropEntityArray(player, "m_hMyWeapons", i);
		if( weapon != null && weapon.GetClassname() == weapon_name )
		{
			return weapon;
		}
	}
}
::FindInPlayerInv <- ::DawgSG552.FindInPlayerInv.weakref().ref()

__CollectGameEventCallbacks(::DawgSG552)

// =========================
//   DAWGMOD's SG552 - END
// =========================