Msg("Running potatocoop's director_base_addon.nut script\n")

//custom coop mode vscript
//by Braindawg

//stole from give_tf_weapon library but it fails to include here?
IncludeScript("netpropperf.nut")

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

if (!IsModelPrecached("models/props_doors/door_urban_rooftop_damaged_break.mdl"))
    PrecacheModel("models/props_doors/door_urban_rooftop_damaged_break.mdl")

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


const CRAWL_SPEED = 35;
const M60_CLIP_MAX = 450;
// const CRICKET_INDEX = 748;
// const RIOT_INDEX = 740;
// const CRICKET_WORLDINDEX = 658;

local mapname = Director.GetMapName();
local lockedclosets = false;
local firsthint = false;
local hasriotshield = false;
local closetradius = 256;
local maplist = ["c1m1_hotel", "c2m1_highway", "c3m1_plankcountry", "c4m1_milltown_a", "c5m1_waterfront", "c6m1_riverbank", "c7m1_docks", "c8m1_apartment", "c9m1_alleys", "c10m1_caves", "c11m1_greenhouse", "c12m1_hilltop", "c13m1_alpinecreek", "c14m1_junkyard"]
local survmodellist = ["models/survivors/survivor_gambler.mdl", "models/survivors/survivor_producer.mdl", "models/survivors/survivor_coach.mdl", "models/survivors/survivor_mechanic.mdl", "models/survivors/survivor_namvet.mdl", "models/survivors/survivor_teenangst.mdl", "models/survivors/survivor_biker.mdl", "models/survivors/survivor_manager.mdl"]
local weaponsToConvert;
local originalname;
local infodirector;

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
    cm_InfiniteFuel = 1
    AllowWitchesInCheckpoints = 1
    cm_ProhibitBosses = false
    TankHitDamageModifierCoop = 0.4
    cm_AggressiveSpecials = false

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

//cvars
::SetCVars <- function()
{
    //survivors
    SetValue("survivor_allow_crawling", 1);
    SetValue("survivor_crawl_speed", CRAWL_SPEED);
    SetValue("ammo_shotgun_max", 90);
    SetValue("survivor_burn_factor_expert", 0.35);
    SendToServerConsole("sm_cvar survivor_friendly_fire_factor_expert 0");

    //infected
    SetValue("boomer_leaker_chance", 15);
    SetValue("smoker_tongue_delay", 0.5);
    SetValue("z_health", 10);
    SetValue("z_jockey_health", 250);
    SetValue("z_difficulty", "impossible");

    //100 tick related
    SetValue("sv_maxupdaterate", 100); 
    SetValue("sv_maxcmdrate", 100); 
    SetValue("sv_mincmdrate", 100); 
    SetValue("net_splitpacket_maxrate", 100000); 
    SetValue("rate", 100000)
    SetValue("fps_max", 1000); 
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
    SendToServerConsole("sm_cvar l4d_static_minimum_survivor 4");
    SendToServerConsole("sm_cvar l4d_autojoin 2");
}

//speedrun timer, doesn't work on dedicated :/

//replace all map spawned scouts
//does this even work?
if ( (mapname.slice(2, 5) == "m1_") || (mapname.slice(3, 6) == "m1_") )
{
    weaponsToConvert =
    {
        weapon_sniper_scout_spawn = "weapon_hunting_rifle_spawn"
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
        //update: this was caused by fucking with the info_director targetname
        // DoEntFire("store_alarm_relay", "AddOutput", "OnTrigger info_director:ForcePanicEvent::0:-1", 0.0, null, null);
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

::NoMercyOverride <- function()
{
    //block the street like zonemod
    if (mapname == "c8m1_apartment")
    {
        SpawnEntityFromTable("prop_dynamic", {
            origin = Vector(2418, 3799, 4)
            angles = Vector(-1.5, 270, 0)
            model = "models/props_vehicles/semi_trailer_wrecked.mdl"
            solid = 6
            disableshadows = 1
        })
        SpawnEntityFromTable("prop_dynamic", {
            origin = Vector(2115, 3892, 16)
            angles = Vector(0, 90, 0)
            model = "models/props_street/police_barricade2.mdl"
            solid = 6
            disableshadows = 1
        })
        SpawnEntityFromTable("prop_dynamic", {
            origin = Vector(2726, 3772, 16)
            angles = Vector(0, 90, 0)
            model = "models/props_street/police_barricade.mdl"
            solid = 6
            disableshadows = 1
        })
        SpawnEntityFromTable("prop_dynamic", {
            origin = Vector(2786, 3772, 16)
            angles = Vector(0, 90, 0)
            model = "models/props_street/police_barricade.mdl"
            solid = 6
            disableshadows = 1
        })
        SpawnEntityFromTable("env_physics_blocker", {
            origin = Vector(2109, 3892, 2248)
            mins = "-77 -1 -2232"
            maxs = "77 1 2232"
            initialstate = 1
            BlockType = 1
        })
        SpawnEntityFromTable("env_physics_blocker", {
            origin = Vector(2419, 3776, 2312)
            mins = "-267 -59 -2168"
            maxs = "267 59 2168"
            initialstate = 1
            BlockType = 1
        })
        SpawnEntityFromTable("env_physics_blocker", {
            origin = Vector(2753, 3772, 2248)
            mins = "-68 -1 -2232"
            maxs = "68 1 2232"
            initialstate = 1
            BlockType = 1
        })
    }
    //block storage room path
    if (mapname == "c8m3_sewers")
    {
        printl(mapname)

        SpawnEntityFromTable("prop_dynamic_override", {
            origin = Vector(11268.054688, 4664, 15.803272)
            angles = Vector(0, 90, 0)
            model = "models/props_doors/door_urban_rooftop_damaged_break.mdl"
            solid = 6
            disableshadows = 1
            
        })
    }
    printl("||||No Mercy Override Loaded||||")
}

::ColdStreamOverride <- function()
{
    if (mapname == "c13m2_southpinestream")
    {
        //kill this shit
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
        //delay the tunnel event
        RemoveOutput(director, "OnDamaged", "event_alarme", "BeginScript", "")
        // AddOutput(director, "OnDamaged", "event_alarme", "BeginScript", "", 8, 1)

        //use DoEntFire to add a delay just to be safe
        DoEntFire("info_director", "AddOutput", "OnDamaged event_alarme:BeginScript::8:1", 5, null, null)
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
    case 8:
        NoMercyOverride(); break;
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
        SendToServerConsole("sm_cvar l4d_static_minimum_survivor 4");
        SendToServerConsole("sm_cvar l4d_autojoin 2");
    }
    //superversus hasn't been updated since the zoey crash fix, cba to recompile the plugin
    //wanted to use this to force l4d2 chars on l4d1 maps but doesn't work
    for (local i = 1; i < GetFloat("l4d_survivor_limit"); i++)
    {
        local player = PlayerInstanceFromIndex(i);
        for (local i  = 0; i < survmodellist.len(); i++)
        {
            // printl(GetPropInt(player, "m_survivorCharacter"))
            if (player != null && player.GetModelName() == survmodellist[i] && GetPropInt(player, "m_survivorCharacter") != i )
            {
                SetPropInt(player, "m_survivorCharacter", i);
                printl("set " + player + " with model " + player.GetModelName() + " to survivor index " + i)
            }
        }
        
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
    SpeedrunHUD <- { Fields = { timer = { slot = HUD_MID_TOP, special = HUD_SPECIAL_ROUNDTIME, flags = HUD_FLAG_NOBG | HUD_FLAG_AS_TIME, name = "timer" } }, }
    HUDSetLayout(SpeedrunHUD);

    local worldspawn = Entities.FindByClassname(null, "worldspawn")
        worldspawn.ValidateScriptScope();
        worldspawn.GetScriptScope().MainThink <- MainThink;
        AddThinkToEnt(worldspawn, "MainThink");

    //get info_director name since we change it to something else for rescue closets
    //not setting this back to the original name will break many events (c10m3_ranchhouse, c2m1_streets cola event, etc)
    for (infodirector; infodirector = FindByClassname(infodirector, "info_director"); )
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
    MapOverrides();
}

//leaker model stuff
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

//    replace cricket bat with riot shield
    if (weapon == "melee")
    {
        printl(wepent);
        printl(vmindex);
        printl(GetPropInt(wepent, "m_nModelIndex"));
        if (vmindex == CRICKET_INDEX)
        {
            SetPropInt(viewmodel, "m_nModelIndex", RIOT_INDEX);
            SetPropString(viewmodel, "m_ModelName", "models/weapons/melee/v_riotshield.mdl");
            viewmodel.SetModel("models/weapons/melee/v_riotshield.mdl");

            SetPropInt(wepent, "m_nModelIndex", RIOT_INDEX);
            SetPropString(wepent, "m_ModelName", "models/weapons/melee/w_riotshield.mdl");
            wepent.SetModel("models/weapons/melee/w_riotshield.mdl");
            hasriotshield = true;
        }
    }

    if (weapon == "rifle_m60")
        wepent.SetClip1(M60_CLIP_MAX)
    
}

// function OnGameEvent_weapon_drop(params)
// {
//     if (params.item != "melee") return;

//     printl("PropID: " + params.propid + " Item: " + params.item)
// }

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
        if (activeWeapon == null) return;
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

//tank rage, faster move speed and attack speed
function OnGameEvent_zombie_ignited(params)
{
    local tank = params.victimname;
    if (tank != "Tank" ) return;

    SetValue("z_tank_speed", 240);
}
function OnGameEvent_tank_killed(params)
{
    SetValue("z_tank_speed", 210);
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