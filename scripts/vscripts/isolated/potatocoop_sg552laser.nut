Msg("Running potatocoop's SG552's ON-SCOPE LASERS script\n")
IncludeScript("netpropperf");

// =========================
//  ON-SCOPE LASERS - START
// =========================

const TEAM_SPECTATE = 1;
const TEAM_SURVIVOR = 2;
const TEAM_INFECTED = 3;
const MAX_WEAPONS = 6;

enum UPGRADEBIT
{
	INCENDIARY_AMMO = 1, // (1 << 0)
	EXPLOSIVE_AMMO  = 2, // (1 << 1)
	LASER_SIGHT     = 4  // (1 << 2)
};

/*****************************************************
	SG552's ON-SCOPE LASERS
	
	Objective:
	  Gives SG552 laser sights on scope only, but scoped shots
	  consume 2 ammo per shot.
	  
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

	  2) Remember the player getting the laser upgrade
	  on the "player_use" event. This is so we don't
	  remove their laser upgrade when they zoom in.
	    Script will add the var "scope["HasRealLaser"]" into
	  their script scope.
	  
	  3) Remove the scope laser from survivors on "map_transition"
	  event to prevent the laser carrying to the next level.
	  
	  4) On "player_transitioned" event, check if any weapons
	  has a laser sight active.
	    If true, script will set "scope["HasRealLaser"]" to true.
		
	  5) While zoomed in, make the weapon use up 2 ammo per shot
	  on the "weapon_fire" event, which can be accomplised by
	  doing "SetClip1(weapon.Clip1() - 1)".
	    For the workshop, this should be made customisable.
	
	Bugs:
	  1) Event "player_use" doesn't fire while the player is
	  still reloading, so that alone cannot be used to apply
	  "scope["HasRealLaser"]" on the weapon.
	  
	  Approach: On the "receive_upgrade" event, check if the
	  weapon's "m_bInReload" is true. If that is the case, apply
	  "scope["HasRealLaser"]" to the weapon.
	  
	  Orin: DONE ✅
	  
	  2) Shadowysn:
	  Various actions exit the scoped state by making the SG552
	  an inactive weapon, however they do not fire the event
	  "weapon_zoom", giving the player permanent laser sights:
	    - Switching weapons  
	    - Picking up a different primary
	    - Getting incapped (even though getting hurt unzooms with an event)
	    - Running out of ammo 
	
	  APPROACH: Catch these illegal lasers by adding a think
	  function when the player zooms in, which we can detect
	  by checking if the weapon's owner exists and if the owner
	  is zoomed in. Once either the illegal laser is removed
	  or the player zooms out, the think will be removed.
	   The think function will be named "ScopeClearThink".
	  
	  Orin: DONE ✅
	  
	Testing prodecure:
	> Preparation:
	  1) In console, "script Convars.SetValue("developer", 1)".
	  2) Give yourself a SG552 with "give rifle_sg552".
	  3) Perform the procedures "ILLEGAL SCOPE LASERS" and "TRANSITIONS".
	  4) In console, do "ent_create upgrade_laser_sight", then get the
	  laser upgrade from the spawned entity while reloading. Repeat
	  step 3.
	
	> > ILLEGAL SCOPE LASERS:
	  1) Validate the standard zoom logic is working by doing
	  each of the following while zoomed in:
	    - Zooming out after
		- Jumping
		- Falling off high ground
		
		The laser should not appear while unscoped unless the
		weapon has laser upgrades.

	  2) Validate the think function is working by doing each
	  of the following while zoomed in:
	    - Switching to another item then back  
	    - Picking up a different primary
	    - Getting incapped ("hurtme 100" in console)
	    - Running out of ammo ("ammo_assaultrifle_max 1;give pumpshotgun;give rifle_sg552;ent_create weapon_ammo_spawn;ammo_assaultrifle_max 360")
		
		The laser should not appear while unscoped unless the
		weapon has laser upgrades.
	  
	> > TRANSITIONS:
	  1) Use "warp_all_survivors_to_checkpoint" in console.
	  2) While zoomed in, close the door.
	  3) Zoom in then out after map transition and see if the laser persists.
	  
	> Helpers:
	  My alias for tutorial_standards:
	  - "alias slaysurvivors "script RurinSlaySurvivors()""
	  - "alias resetscript "unpause;host_timescale 6;slaysurvivors;wait 400;ent_fire relay_intro_finished trigger;wait 100;host_timescale 1;give rifle_sg552;setang 30 176 0;ent_create upgrade_laser_sight""
	
*****************************************************/

// Regexp to turn "function func_a(params)" into "func_a <- function(params)":
// - FIND: (function )([_a-zA-Z]*)(\()
// - REPLACE: ::OnScopeLasers.(\2) <- function(\3)
::OnScopeLasers <- {}

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
::OnScopeLasers.OnGameEvent_weapon_zoom <- function(params)
{
    local player = GetPlayerFromUserID(params.userid);
    local activeWeapon = ::GetPropEntity(player, "m_hActiveWeapon");

    if ( activeWeapon.GetClassname() != "weapon_rifle_sg552" )
		return;
	
	// Null means the scope might be non-existant.
	// Add the think function when we validate the scope.
	local scope = activeWeapon.GetScriptScope();
	if( scope == null )
	{
		// Validate it, then get it again.
		activeWeapon.ValidateScriptScope();
		scope = activeWeapon.GetScriptScope();
		
		if ( !("ScopeClearThink" in scope) )
		{
			scope["ScopeClearThink"] <- ::OnScopeLasers.ScopeClearThink;
		}
	}

	local hasRealLaser = ("HasRealLaser" in scope);
	if( developer() )
		printl( "SG552 has real laser: " + hasRealLaser );
  
	if( !hasRealLaser )
	{
		local zoomOwner = ::GetPropEntity(player, "m_hZoomOwner");
		if ( zoomOwner != null )
		{
			AddThinkToEnt(activeWeapon, "ScopeClearThink");
			player.GiveUpgrade(UPGRADE_LASER_SIGHT);
		}
		else
		{
			AddThinkToEnt(activeWeapon, null);
			player.RemoveUpgrade(UPGRADE_LASER_SIGHT);
		}
	}
}.bindenv(this)

// Purpose: Clear the laser sight when the weapon exits the scoped
// state by being inactive, not firing the "weapon_zoom" event.
//
// Notes: Can't remove the think function with "AddThinkToEnt(self,null)"
// if done inside the think function itself.
// Shouldn't bindenv this!
//
::OnScopeLasers.ScopeClearThink <- function()
{	
	local owner = ::GetPropEntity(self, "m_hOwnerEntity");
	if( owner == null || ::GetPropEntity(owner, "m_hZoomOwner") == null )
	{
		local upgradeBitVec = ::GetPropInt(self, "m_upgradeBitVec");
		if( (upgradeBitVec & UPGRADEBIT.LASER_SIGHT) )
		{
			::SetPropInt(self, "m_upgradeBitVec", upgradeBitVec & ~4);
			
			if( developer() )
				printl("Removed illegal laser.")
			
			EntFire("!activator", "RunScriptCode", "AddThinkToEnt(self, null)", 0.1, self);
			return RAND_MAX;
		}
	}
	
	// 3 times per second
	return (1.0 / 3);
}

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
::OnScopeLasers.OnGameEvent_weapon_fire <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local wep = params.weapon;
	local weapon = ::GetPropEntity(player, "m_hActiveWeapon");

	if ( ::GetPropEntity(player, "m_hZoomOwner") != null && wep == "rifle_sg552")
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
::OnScopeLasers.OnGameEvent_player_use <- function( params )
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
::OnScopeLasers.OnGameEvent_receive_upgrade <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local upgrade = params.upgrade;
	
	if( upgrade == "LASER_SIGHT" )
	{
		local sg552 = FindInPlayerInv("weapon_rifle_sg552", player);
		if( sg552 != null )
		{
			if( ::GetPropInt(sg552, "m_bInReload") == 1 )
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
::OnScopeLasers.OnGameEvent_map_transition <- function( params )
{
	for( local player; player = ::FindByClassname(player, "player"); )
	{
		local activeWeapon = ::GetPropEntity(player, "m_hActiveWeapon");
		if( activeWeapon != null && activeWeapon.GetClassname() == "weapon_rifle_sg552" )
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

::OnScopeLasers.OnGameEvent_player_transitioned <- function( params )
{
	local player = GetPlayerFromUserID(params.userid);
	local sg552 = FindInPlayerInv("weapon_rifle_sg552", player);
	
	if( sg552 != null )
	{
		local upgradeBitVec = ::GetPropInt( sg552, "m_upgradeBitVec" );
		if( (upgradeBitVec & UPGRADEBIT.LASER_SIGHT) != 0 )
		{
			SetHasRealLaser(sg552, true);
		}
	}
}.bindenv(this)

// -------------
// ++ Helpers ++
// -------------
// These functions do not validate arguments before using them.

::OnScopeLasers.SetHasRealLaser <- function(weapon, val)
{
	weapon.ValidateScriptScope();
	local scope = weapon.GetScriptScope();
	scope["HasRealLaser"] <- val;
	
	if( developer() )
		printl( "SetHasRealLaser: " + weapon.GetClassname() + " to " + val );
}
::SetHasRealLaser <- ::OnScopeLasers.SetHasRealLaser;

::OnScopeLasers.FindInPlayerInv <- function(weapon_name, player)
{
	for( local i = 0; i < MAX_WEAPONS; i++ )
	{
		local weapon = ::GetPropEntityArray(player, "m_hMyWeapons", i);
		if( weapon != null && weapon.GetClassname() == weapon_name )
		{
			return weapon;
		}
	}
}
::FindInPlayerInv <- ::OnScopeLasers.FindInPlayerInv;

__CollectGameEventCallbacks(::OnScopeLasers)

// =======================
//  ON-SCOPE LASERS - END
// =======================