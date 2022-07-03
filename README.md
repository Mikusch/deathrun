# Deathrun Neu

Deathrun Neu is inspired by the plugins I played many years ago that were never made accessible to the public.
It aims to keep weapon restrictions as little as possible while not ruining the core gameplay.

## Features

* Activator queue system (`!drqueue`)
* Ability to hide other players in crowded areas (`!drhide`)
* Dynamic Activator health for fair combat minigames
* Configurable round timer (using the `tf_arena_round_time` ConVar)
* Highly customizable item and plugin configuration

## Dependencies

* SourceMod 1.11
* [DHooks with Detour Support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
* [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)
* [More Colors](https://forums.alliedmods.net/showthread.php?t=185016) (compile only)

## Configuration

The global item configuration found in `configs/deathrun/items.cfg` allows you to configure and restrict each player's
items as you please. Map-specific configuration files are read from the `configs/deathrun/maps` directory.

For example, there are two different ways to disable the jumping capabilities of the Ullapool Caber.

Using attributes:

```
"307"	// Ullapool Caber
{
	"attributes"
	{
		"1"	// Zeroes out the self damage push force
		{
			"name"	"self dmg push force decreased"
			"value"	"0.0"
			"mode"	"set"
		}
	}
}
```

Using entity properties (advanced):

```
"307"	// Ullapool Caber
{
	"entprops"
	{
		"1"	// Makes the weapon start already detonated
		{
			"target"	"weapon"
			"name"		"m_iDetonated"
			"type"		"send"
			"field_type"	"int"
			"value"		"1"
		}
	}
}
```

These two methods may also be combined. For example, to give Medics a one-time use ÜberCharge that can not be rebuilt:

```
"29"	// Medi Gun
{
	"attributes"
	{
		"1"
		{
			"name"	"heal rate penalty"	// No healing
			"value"	"0.0"
		}
		"2"
		{
			"name"	"ubercharge rate penalty"	// No ÜberCharge gain
			"value"	"0.0"
		}
	}
	"entprops"
	{
		"1"	// Sets the ÜberCharge level to 100%
		{
			"target"	"weapon"
			"name"		"m_flChargeLevel"
			"type"		"send"
			"field_type"	"float"
			"value"		"1.0"
		}
	}
}
```

See [items.cfg](/addons/sourcemod/configs/deathrun/items.cfg) for more details and the default configuration.

### Map Configuration

Some older maps have issues with players being able to activate buttons or kill other players through walls with
explosive or throwable weapons. Instead of having to block these weapons in the global item configuration you have the
option of creating a configuration file for each map.

To do that, put a file called `<map name>.items.cfg` in the `configs/deathrun/maps` directory. Workshop prefixes and
suffixes should be omitted.

Any item definition indexes specified in a map-specific item configuration will override the global configuration.

## ConVars

- `dr_version` - Plugin version, don't touch.
- `dr_queue_points ( def. "15" )` - Amount of queue points awarded to runners at the end of each round.
- `dr_chattips_interval ( def. "240" )` - Interval between helpful tips printed to chat, in seconds. Set to 0 to disable
  chat tips.
- `dr_runner_glow ( def. "0" )` - If enabled, runners will have a glowing outline.
- `dr_activator_count ( def. "1" )` - Amount of activators chosen at the start of a round.
- `dr_activator_health_modifier ( def. "1.0" )` - Modifier of the health the activator receives from runners.
- `dr_activator_healthbar ( def. "1" )` - If enabled, the activator health will be displayed on screen.
- `dr_backstab_damage ( def. "750.0" )` - Damage dealt to the activator by backstabs. Set to 0 to let the game determine the damage.
- `dr_speed_modifier ( def. "0.0" )` - Maximum speed modifier for all classes, in HU/s.
    - `dr_speed_modifier_scout ( def. "0.0" )` - Maximum speed modifier for Scout, in HU/s.
    - `dr_speed_modifier_sniper ( def. "0.0" )` - Maximum speed modifier for Sniper, in HU/s.
    - `dr_speed_modifier_soldier ( def. "0.0" )` - Maximum speed modifier for Soldier, in HU/s.
    - `dr_speed_modifier_demoman ( def. "0.0" )` - Maximum speed modifier for Demoman, in HU/s.
    - `dr_speed_modifier_medic ( def. "0.0" )` - Maximum speed modifier for Medic, in HU/s.
    - `dr_speed_modifier_heavy ( def. "0.0" )` - Maximum speed modifier for Heavy, in HU/s.
    - `dr_speed_modifier_pyro ( def. "0.0" )` - Maximum speed modifier for Pyro, in HU/s.
    - `dr_speed_modifier_spy ( def. "0.0" )` - Maximum speed modifier for Spy, in HU/s.
    - `dr_speed_modifier_engineer ( def. "0.0" )` - Maximum speed modifier for Engineer, in HU/s.
