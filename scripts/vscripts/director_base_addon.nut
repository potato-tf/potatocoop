//custom coop mode vscript
//by Braindawg

//stole from give_tf_weapon library but it fails to include here?
IncludeScript("netpropperf.nut")


const CRAWL_SPEED = 20;
// const CRICKET_INDEX = 748;
// const RIOT_INDEX = 740;
// const CRICKET_WORLDINDEX = 658;

local mapname = Director.GetMapName();
local lockedclosets = false;
local firsthint = false;
local hasriotshield = false;
local closetradius = 256;
local maplist = ["c1m1_hotel", "c2m1_highway", "c3m1_plankcountry", "c4m1_milltown_a", "c5m1_waterfront", "c6m1_riverbank", "c7m1_docks", "c8m1_apartment", "c9m1_alleys", "c10m1_caves", "c11m1_greenhouse", "c12m1_hilltop", "c13m1_alpinecreek", "c14m1_junkyard"]
local weaponsToConvert;
local saferoomdoor;
local originalname;

//director tweaks
DirectorOptions <- 
{
	SpecialRespawnInterval = 12
    MaxSpecials = 6
    BaseSpecialLimit = 2
    SpecialSlotCountdownTime = 1
    SpecialInitialSpawnDelayMin = 0
    SpecialInitialSpawnDelayMin = 15
    ZombieTankHealth = 6000

    CommonLimit = 65
	HunterLimit = 4
	BoomerLimit = 2
	ChargerLimit = 2
	JockeyLimit = 1
	SmokerLimit = 1
	SpitterLimit = 1

	function ConvertWeaponSpawn(classname)
	{
        printl("name" + classname)
		if ( classname in weaponsToConvert )
		{
			printl(classname + "converted")
            return weaponsToConvert[classname];
		}
		return 0;
	}
}

printl("******************");
printl("******************");
printl("******************");
printl("Potato coop loaded");
printl("******************");
printl("******************");
printl("******************");

if (!IsModelPrecached("models/infected/boomette.mdl"))
    PrecacheModel("models/infected/boomette.mdl");

if (!IsModelPrecached("models/infected/limbs/exploded_boomette.mdl"))
    PrecacheModel("models/infected/limbs/exploded_boomette.mdl");

if (!IsModelPrecached("models/infected/boomette.mdl"))
    PrecacheModel("models/infected/boomette.mdl");
    
if (!IsModelPrecached("models/infected/boomer.mdl"))
    PrecacheModel("models/infected/boomer.mdl");

if (!IsModelPrecached("models/infected/boomer_l4d1.mdl"))
    PrecacheModel("models/infected/boomer_l4d1.mdl");

if (!IsModelPrecached("models/weapons/melee/w_riotshield.mdl"))
    PrecacheModel("models/weapons/melee/w_riotshield.mdl");

if (!IsModelPrecached("models/weapons/melee/v_riotshield.mdl"))
    PrecacheModel("models/weapons/melee/v_riotshield.mdl");

if (!IsModelPrecached("models/survivors/survivor_mechanic.mdl"))
    PrecacheModel("models/survivors/survivor_mechanic.mdl")
    
if (!IsModelPrecached("models/survivors/survivor_gambler.mdl"))
    PrecacheModel("models/survivors/survivor_gambler")

if (!IsModelPrecached("models/survivors/survivor_coach.mdl"))
    PrecacheModel("models/survivors/survivor_coach.mdl")

if (!IsModelPrecached("models/survivors/survivor_producer.mdl"))
    PrecacheModel("models/survivors/survivor_producer.mdl")

if (!IsModelPrecached("models/survivors/survivor_teenangst.mdl"))
    PrecacheModel("models/survivors/survivor_teenangst.mdl")

if (!IsModelPrecached("models/survivors/survivor_biker.mdl"))
    PrecacheModel("models/survivors/survivor_biker.mdl")

if (!IsModelPrecached("models/survivors/survivor_manager.mdl"))
    PrecacheModel("models/survivors/survivor_manager.mdl")

if (!IsModelPrecached("models/survivors/survivor_namvet.mdl"))
    PrecacheModel("models/survivors/survivor_namvet.mdl")

//cvars
::SetCVars <- function()
{
    SetValue("survivor_allow_crawling", 1);
    SetValue("survivor_crawl_speed", CRAWL_SPEED);
    SetValue("boomer_leaker_chance", 20);
    SetValue("smoker_tongue_delay", 0.5);
    SetValue("z_health", 10);
    SetValue("z_jockey_health", 250);
    SetValue("z_difficulty", "impossible");
    SetValue("mp_friendlyfire", 0);
    SetValue("survivor_burn_factor_expert ", 0.2);

    SendToServerConsole("sm_cvar survivor_friendly_fire_factor_normal 0");
    SendToServerConsole("sm_cvar survivor_friendly_fire_factor_hard 0");
    SendToServerConsole("sm_cvar survivor_friendly_fire_factor_expert 0");

    //100 tick related
    SetValue("sv_maxupdaterate", 100); 
    SetValue("sv_maxcmdrate", 100); 
    SetValue("net_splitpacket_maxrate", 100000); 
    SetValue("fps_max", 150); 
    SetValue("nb_update_frequency", 0.03); 
    SendToServerConsole("nb_update_frequency 0.03");

    //bots 
    // SetValue("allow_all_bot_survivor_team", 1);
    // SetValue("sb_all_bot_game", 1);
    // SetValue("z_special_spawn_interval", 12);

    //maxplayers override, requires plugins
    SetValue("sv_maxplayers", 8);
    SetValue("sv_visiblemaxplayers", 8);
    SendToServerConsole("sm_cvar l4d_survivor_limit 8");
    SendToServerConsole("sm_cvar l4d_static_minimum_survivor 8");
    SendToServerConsole("sm_cvar l4d_autojoin 2");

    //8 slots 
    // while (GetFloat("l4d_multislots_max_survivors") != 8)
    // {   
    //     SetValue("l4d_multislots_max_survivors", 8);
    //     SetValue("l4d_multislots_spawn_survivors_roundstart", 1);
    //     SetValue("l4d_multislots_respawnhp", 100);
    //     SetValue("l4d_multislots_respawnbuffhp", 0);
    //     SetValue("l4d_multislots_firstweapon", 0);
    //     SetValue("l4d_multislots_secondweapon", 0);
    //     SetValue("l4d_multislots_thirdweapon", 0);
    //     SetValue("l4d_multislots_forthweapon", 0);
    //     SetValue("l4d_multislots_thirdweapon", 0);

    //     //just in case
    //     SendToServerConsole("l4d_multislots_max_survivors 8");
    //     SendToServerConsole("l4d_multislots_spawn_survivors_roundstart 1");
    //     SendToServerConsole("l4d_multislots_respawnhp 100");
    //     SendToServerConsole("l4d_multislots_respawnbuffhp 0");
    //     SendToServerConsole("l4d_multislots_firstweapon 0");
    //     SendToServerConsole("l4d_multislots_secondweapon 0");
    //     SendToServerConsole("l4d_multislots_thirdweapon 0");
    //     SendToServerConsole("l4d_multislots_forthweapon 0");
    //     SendToServerConsole("l4d_multislots_fifthweapon 0");
    // }
}

//speedrun timer, doesn't work on dedicated :/

//replace all map spawned scouts
//does this even work?
if ( (mapname.slice(2, 5) == "m1_") || (mapname.slice(3, 6) == "m1_") )
{
    weaponsToConvert =
    {
        weapon_sniper_scout = "weapon_hunting_rifle_spawn"
    }

} else {

    weaponsToConvert =
    {
        weapon_sniper_scout = "weapon_hunting_rifle_spawn"
        weapon_first_aid_kit = "weapon_ammo_pack_spawn" //doesn't work
    }
}

::DeadCenterOverride <- function()
{
    //gun store closet door is far away from the rescue spot
    if (mapname == "c1m2_streets")
    {
        closetradius = 300;
        //force cola panic event (for some reason panic events break after doing our own panic events for the rescue closets)
        DoEntFire("store_alarm_relay", "AddOutput", "OnTrigger info_director:ForcePanicEvent::0:-1", 0.0, null, null);
    }

    //force lower path
    //1/10 chance for upper path
    if (mapname == "c1m3_mall")
    {
        local random = RandomInt(1, 10)
        
        if (random != 10)
        {
            DoEntFire("compare_minifinale", "Kill", "", 0.0, null, null);
            DoEntFire("relay_stairwell_close", "Kill", "", 0.0, null, null);
            DoEntFire("relay_hallway_close", "Trigger", "", 5.0, null, null);
        }
    }
    printl("||||Dead Center Override Loaded||||")
}
::DarkCarnivalOverride <- function()
{
    //closet here is too close to another door
    if (mapname == "c2m3_coaster")
    {
        closetradius = 64;
    }
    printl("||||Dark Carnival Override Loaded||||")
}

::ColdStreamOverride <- function()
{
    //kill this shit
    if (mapname == "c13m2_southpinestream")
    {

        //wanted to make a new one but this doesn't work
        local nonflashbang = SpawnEntityFromTable("env_lightglow", {
            targetname = "newlightglow",
            origin = Vector(8086.89, 5446.05, 572), 
            angles = Vector(0, 90, 0),
            rendercolor = "255 193 159",
            spawnflags = 1,
            MaxDist = 3000,
            MinDist = 2000,
            GlowProxySize = 2.0,
            HorizontalGlowSize = 200,
            VerticalGlowSize = 50
        })
        // nonflashbang.__KeyValueFromString("rendercolor", "255 193 159");
        
        for ( local flashbang; flashbang = FindByClassname(flashbang, "env_lightglow"); )
        {
            printl(flashbang)
            if (flashbang.GetName() != "newlightglow")
            {   
                DoEntFire("!activator", "AddOutput", "targetname flashbang", 0.0, flashbang, flashbang)
                DoEntFire("flashbang", "Color", "0 0 0", 1.0, null, null);
            }
        }
    }
    printl("||||Cold Stream Override Loaded||||")
}

//vanilla map overrides
//WARNING: autism, but I want to contain everything to one script file

::MapOverrides <- function()
{
    local mapprefixes = []
    local mapprefixtruncated = array(14);
    
    foreach (maps in maplist)
    {
        local prefixes = split(maps, "_")

        foreach(prefix in prefixes)
        {
            if (prefix.len() > 2) mapprefixes.push(prefix);    
        }
    }

    for (local i = 0; i < mapprefixes.len(); i++)
    {
        //even elements of the array contain the prefix
        if (i % 2 == 0) mapprefixtruncated.insert(i, mapprefixes[i].slice(0, mapprefixes[i].len() - 1));
    }
        
    for (local i = 0; i < mapprefixtruncated.len(); i++) 
    {
        //even elements of the array contain the prefix
        if (i % 2 == 0)
        {
            // printl(i + " " + mapprefixtruncated[i])    

            if ( mapname.slice(0, mapprefixtruncated[i].len()) == mapprefixtruncated[i])
            {
                printl(mapname.slice(0, mapprefixtruncated[i].len()))
                local mapindex = (ceil((i.tofloat() + 1.0) / 2.0))

                MapCase(mapindex)
            }
        }
    }    
}

::MapCase <- function(currentmap)
{
    switch(currentmap)
    {
    case 1:
        DeadCenterOverride(); break;
    case 2:
        DarkCarnivalOverride(); break;
    // case 3:
    //     SwampFeverOverride(); break;
    // case 4:
    //     HardRainOverride(); break;
    // case 5:
    //     ParishOverride(); break;
    // case 6:
    //     PassingOverride(); break;
    // case 7:
    //     SacrificeOverride(); break;
    // case 8:
    //     NoMercyOverride(); break;
    // case 9:
    //     CrashCourseOverride(); break;
    // case 10:
    //     DeathTollOverride(); break;
    // case 11:
    //     DeadAirOverride(); break;
    // case 12:
    //     BloodHarvestOverride(); break;
    case 13:
        ColdStreamOverride(); break;
    // case 14:
    //     LastStandOverride(); break;

    }
}

//general think function
::MainThink <- function()
{

    //idk why just putting this cvar in server.cfg or SetCVars doesn't work
    if (GetFloat("l4d_survivor_limit") != 8)
    {
        SendToServerConsole("sm_cvar l4d_survivor_limit 8");
        SendToServerConsole("sm_cvar l4d_static_minimum_survivor 8");
        SendToServerConsole("sm_cvar l4d_autojoin 2");
    }

    //superversus hasn't been updated since the zoey crash fix, cba to recompile the plugin
    for (local i = 1; i < GetFloat("l4d_survivor_limit"); i++)
    {
        local player = PlayerInstanceFromIndex(i);
        if (player != null && player.GetModelName() == "models/survivors/survivor_teenangst.mdl" && GetPropInt(player, "m_survivorCharacter") !=5 )
            SetPropInt(player, "m_survivorCharacter", 5);
        
    }

    //replace cricket bat with riot shield
    for (local shield; shield = FindByClassname(shield, "weapon_melee"); )
    {
        local owner = GetPropEntity(shield, "m_hOwner");
        local viewmodel = GetPropEntity(owner, "m_hViewModel");
        
        if (owner == null) return;
        
        // printl("weapon: " + shield + " owner: " + owner + " viewmodel: " + viewmodel + " model name: " + activegun.GetModelName());
        
        if (viewmodel.GetModelName() ==  "models/weapons/melee/v_cricket_bat.mdl")
            viewmodel.SetModel("models/weapons/melee/v_riotshield.mdl");
    }

    //replace cricket bat world model 
    //does not work lol
    for (local cricketbat; cricketbat = Entities.FindByModel(cricketbat, "models/weapons/melee/w_cricket_bat.mdl"); )
    {
        printl(cricketbat);
        cricketbat.SetModel("models/weapons/melee/w_riotshield.mdl");
    }
}

//all event functions below

// ClearGameEventCallbacks() // not necessary in l4d2
function OnGameEvent_round_start_post_nav(params)
{
    SetCVars();
    MapOverrides();
    // SetValue("l4d_multislots_max_survivors", 8);
    // SetValue("l4d_multislots_spawn_survivors_roundstart", 1);    
    // SendToServerConsole("l4d_multislots_spawn_survivors_roundstart 1");
    // SendToServerConsole("l4d_multislots_max_survivors 8");
    SpeedrunHUD <- { Fields = { timer = { slot = HUD_MID_TOP, special = HUD_SPECIAL_ROUNDTIME, flags = HUD_FLAG_NOBG | HUD_FLAG_AS_TIME, name = "timer" } }, }
    HUDSetLayout(SpeedrunHUD);

    //apply think function to an ent that exists in every map
    for (saferoomdoor; saferoomdoor = FindByClassname(saferoomdoor, "prop_door_rotating_checkpoint"); )
    {
        saferoomdoor.ValidateScriptScope();
        saferoomdoor.GetScriptScope().MainThink <- MainThink;
        AddThinkToEnt(saferoomdoor, "MainThink");
    }

    //get info_director name since we change it to something else for rescue closets
    //not setting this back to the original name will break many events (c10m3_ranchhouse, c2m1_streets cola event, etc)
    for (local infodirector; infodirector = FindByClassname(infodirector, "info_director"); )
        originalname = infodirector.GetName()
    

    //replace cricket bat with riot shield
    
    for (local cricket; cricket = FindByClassname(cricket, "weapon_melee_spawn"); )
    {
        if ((cricket.GetModelName() == "models/weapons/melee/w_cricket_bat.mdl"))
        {
            // SetPropInt(cricket, "m_nModelIndex", RIOT_INDEX);
            SetPropString(cricket, "m_ModelName", "models/weapons/melee/w_riotshield.mdl");
            cricket.SetModel("models/weapons/melee/w_riotshield.mdl");
            cricket.SetAngles(cricket.GetAngles() - QAngle(0 90 0));
        }
        
    }

    // 1 in 5 chance to spawn a scout instead of a chrome
    for (local chrome; chrome = FindByClassname(chrome, "weapon_shotgun_chrome_spawn"); )
    {
        local rand = RandomInt(1, 5);

        if (rand == 5)
        {
            SpawnEntityFromTable("weapon_sniper_scout_spawn", {
                origin = chrome.GetLocalOrigin(),
                angles = chrome.GetLocalAngles().ToKVString(),
                count = GetPropInt(chrome, "m_itemCount")
            })
            printl("replaced " + chrome + " at " + chrome.GetLocalOrigin())
            chrome.Kill()
        } else {

            printl("Scout roll: " + rand + ".  Need 5");
        }
    }

    //generic weapon_spawn too
    for (local chrome2; chrome2 = FindByClassname(chrome2, "weapon_spawn"); )
    {
    //    printl(chrome2 + " ID:" + GetPropInt(chrome2, "m_weaponID") + " Location:" + chrome2.GetLocalOrigin());
        if (GetPropInt(chrome2, "m_weaponID") != 8) return;

        local rand = RandomInt(1, 5);

        if (rand == 5)
        {
            SpawnEntityFromTable("weapon_sniper_scout_spawn", {
                origin = chrome2.GetLocalOrigin(),
                angles = chrome2.GetLocalAngles().ToKVString(),
                count = GetPropInt(chrome2, "m_itemCount")
            })
            printl("replaced " + chrome2 + " at " + chrome2.GetLocalOrigin())
            chrome2.Kill()
        } else {
            
            printl("Scout roll: " + rand + ".  Need 5");
        }
    }
}

//leaker model stuff
//this also forces real zoey with the 8 player stuff
function OnGameEvent_player_spawn(params)
{
    local player = GetPlayerFromUserID(params.userid)

    // printl(player + "Zombie Type: " + player.GetZombieType() + " Variant: " + GetPropInt(player, "m_nVariantType") )

    if (player.GetZombieType() != 2) return;

    if (GetPropInt(player, "m_nVariantType") == 1 )
    {
        player.SetModel("models/infected/boomette.mdl");
        return;
    } 
    //this might be redundant, I don't remember if boomettes ever spawn in l4d1 campaigns 
    if (Director.IsL4D1Campaign()) 
    {
        player.SetModel("models/infected/boomer_l4d1.mdl");
        return;

    } else {
        player.SetModel("models/infected/boomer.mdl");
    }
}

//remove charger resistance
function OnGameEvent_charger_charge_start(params)
{
    local charger = GetPlayerFromUserID(params.userid);
    if ( (IsPlayerABot(charger)) && (charger.GetHealth() > 0) )
        charger.SetHealth(charger.GetHealth() / 3);
}

function OnGameEvent_charger_charge_end(params)
{
    local charger = GetPlayerFromUserID(params.userid);
    if ( (IsPlayerABot(charger)) && (charger.GetHealth() > 0) )
        charger.SetHealth(charger.GetHealth() * 3);
}

//allow hunter skeeting
//there's no events that reliably fire after the hunter lands (pounce_end and other similar events are useless)
function OnGameEvent_ability_use(params)
{
    local hunter = GetPlayerFromUserID(params.userid);

    if (hunter.GetZombieType() != 3) return;

    if ( (IsPlayerABot(hunter)) && (hunter.GetHealth() > 150) )
        hunter.SetHealth(150);

    // printl(hunter.GetHealth());
}

//lock all rescue closet doors, trigger a panic event, then unlock and open doors after 15s
function OnGameEvent_survivor_call_for_help(params)
{
    local player = EntIndexToHScript(params.subject);
    
    if (lockedclosets) return;

    SpawnEntityFromTable("env_hudhint", {
        targetname = "rescuehint",
        origin = player.GetOrigin(),
        message = "Rescue door unlocking shortly...",
    })

    DoEntFire("info_director", "AddOutput", "targetname panic", 0.0, null, null);
    // printl("Flow: " + GetAverageSurvivorFlowDistance())

    //find all doors within radius of the rescue zone
    //the large radius by default is to take care of cases like c2m2 bathrooms where there are a bunch of rescue closets behind separate doors
    //this will certainly cause issues elsewhere (like c1m2_streets gun store closet and c2m3_coaster maintenance room closet)
    //map-specific overrides take care of this
    for (local doors; doors = FindByClassnameWithin(doors, "*_door*", player.GetOrigin(), closetradius); )
    {
        DoEntFire("!activator", "Close", "", 0.0, doors, doors);
        DoEntFire("!activator", "Lock", "", 0.1, doors, doors);
        DoEntFire("!activator", "AddOutput", "targetname rescuedoor", 0.0, doors, doors);
        // DoEntFire("rescuedoor", "AddOutput", "OnLockedUse !self:CallScriptFunction:ShowRescueHint:0.01:-1", 0.02, doors, doors);
        DoEntFire("rescuedoor", "AddOutput", "OnLockedUse panic:ForcePanicEvent::0.01:-1", 0.01, doors, doors);
        DoEntFire("rescuedoor", "AddOutput", "OnLockedUse panic:AddOutput:targetname "+ originalname +":0.02:-1", 0.02, doors, doors);
        DoEntFire("rescuedoor", "AddOutput", "OnLockedUse rescuedoor:Unlock::15:-1", 0.02, doors, doors);
        DoEntFire("rescuedoor", "AddOutput", "OnLockedUse rescuedoor:Open::16:-1", 0.02, doors, doors);
        DoEntFire("rescuedoor", "AddOutput", "OnLockedUse rescuehint:ShowHudHint::0:-1", 0.02, doors, doors);
    }
    lockedclosets = true;

    if (firsthint) return;

    ShowRescueHint();
    firsthint = true;
}

::ShowRescueHint <- function()
{
    ClientPrint(null, 3, "Rescue closets will unlock 15 seconds after use, be prepared for a fight...")
    ClientPrint(null, 4, "Rescue closets will unlock 15 seconds after use, be prepared for a fight...")
}

function OnGameEvent_survivor_rescued(params) { lockedclosets = false; }

//weapon rebalances
function OnGameEvent_item_pickup(params)
{
    local player = GetPlayerFromUserID(params.userid)
    local weapon = params.item;
    local viewmodel = GetPropEntity(player, "m_hViewModel");
    local vmindex = GetPropInt(viewmodel, "m_nModelIndex");
    local wepent = GetPropEntity(player, "m_hActiveWeapon");
    // printl(weapon);

    //replace cricket bat with riot shield
    // if (weapon == "melee")
    // {
    //     printl(wepent);
    //     printl(vmindex);
    //     printl(GetPropInt(wepent, "m_nModelIndex"));
    //     if (vmindex == CRICKET_INDEX)
    //     {
    //         SetPropInt(viewmodel, "m_nModelIndex", RIOT_INDEX);
    //         SetPropString(viewmodel, "m_ModelName", "models/weapons/melee/v_riotshield.mdl");
    //         viewmodel.SetModel("models/weapons/melee/v_riotshield.mdl");

    //         SetPropInt(wepent, "m_nModelIndex", RIOT_INDEX);
    //         SetPropString(wepent, "m_ModelName", "models/weapons/melee/w_riotshield.mdl");
    //         wepent.SetModel("models/weapons/melee/w_riotshield.mdl");
    //         hasriotshield = true;
    //     }
    // }
}

// function OnGameEvent_weapon_drop(params)
// {
//     if (params.item != "melee") return;

//     printl("PropID: " + params.propid + " Item: " + params.item)
// }

//give sg552 a laser sight while scoped
function OnGameEvent_weapon_fire(params)
{
    local player = GetPlayerFromUserID(params.userid);
    local wep = params.weapon;
    local weapon = GetPropEntity(player, "m_hActiveWeapon");

    // printl(weapon)

    if (GetPropEntity(player, "m_hZoomOwner") != null && wep == "rifle_sg552")
    {
        weapon.SetClip1(weapon.Clip1() - 1);
        player.GiveUpgrade(UPGRADE_LASER_SIGHT);
        return;
    }
    player.RemoveUpgrade(UPGRADE_LASER_SIGHT);
}

// function OnGameEvent_weapon_zoom(params)
// {
//     local player = GetPlayerFromUserID(params.userid)
//     local weapon = GetPropEntity(player, "m_hActiveWeapon")

//     if (weapon.GetClassname() != "weapon_rifle_sg552") return;
// }

//tank rage, faster move speed and attack speed
function OnGameEvent_zombie_ignited(params)
{
    local tank = params.victimname;
    if (tank != "Tank" ) return;

    SetValue("z_tank_speed", 230);
    SetValue("z_tank_attack_interval", 1);
}
function OnGameEvent_tank_killed(params)
{
    SetValue("z_tank_speed", 210);
    SetValue("z_tank_attack_interval", 1.5);
}

//bile rounds for explosive ammo on grenade launcher
function OnGameEvent_receive_upgrade(params)
{
    local player = GetPlayerFromUserID(params.userid)
    local upgrade = params.upgrade

    if ((GetPropEntity(player, "m_hActiveWeapon") == "weapon_grenade_launcher") && (upgrade == EXPLOSIVE_AMMO))
        printl("TODO: Add bile rounds here")
}

//make FF only hurt the attacker
//actually just disable FF entirely
//actually this is dumb just force the cvars with sm_cvar
// function OnGameEvent_player_hurt_concise(params)
// {
//     local player = GetPlayerFromUserID(params.userid)
//     local attacker = EntIndexToHScript(params.attackerentid)
//     local damage = params.dmg_health
    
//     if ( attacker == null || player == null ) return; 
//     if ( attacker.GetClassname() != "player" || player.GetClassname() != "player" || !player.IsSurvivor() || !attacker.IsSurvivor() ) return;

//     //this should still allow for 1hp incaps
//     if (player.GetHealth() > 1)
//     {
//         player.SetHealth(player.GetHealth() + damage);
//         return;
//     }

//     if (player.GetHealthBuffer() > 1)
//     {
//         player.SetHealthBuffer(player.GetHealthBuffer() + damage)
//     }

//     // printl("added " + damage + " health back to " + player)

//     // if ( attacker.GetHealth() < 5 || attacker.GetHealthBuffer() < 5 ) return;

//     // attacker.SetHealth(attacker.GetHealth() - (damage / 2) )
//     // printl("removed " + damage + " health from " + attacker)
// }

//dunno if any maps only fire one or the other event for finales so just gonna do both
// function OnGameEvent_finale_win(params)
// {
//     ClientPrint(null, 3, "Map Won! Changing to random map in 15 seconds...")
//     DoEntFire("prop_door_rotating_checkpoint", "CallScriptFunction", "ChangeMap", 15.0, null, null)
// }

function OnGameEvent_finale_vehicle_leaving(params)
{
    ClientPrint(null, 3, "Map Won! Changing to random map in 15 seconds...")
    DoEntFire("prop_door_rotating_checkpoint", "CallScriptFunction", "ChangeMap", 15.0, null, null)
}

::ChangeMapTest <- function()
{

    ClientPrint(null, 3, "Map Won! Changing to random map in 10 seconds...");
    DoEntFire("prop_door_rotating_checkpoint", "CallScriptFunction", "ChangeMap", 10.0, null, null);
}

::ChangeMap <- function()
{
    SendToServerConsole("changelevel " + maplist[RandomInt(0, 13)]);
}
__CollectGameEventCallbacks( this );