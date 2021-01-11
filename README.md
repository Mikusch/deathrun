# Deathrun Neu
Inspired by the plugins I played many years back that were never made accessible to the public, Deathrun Neu aims to keep weapon restrictions as little as possible while not ruining the core gameplay.

## Features
* Activator queue system (`!drnext`)
* Ability to hide teammates in crowded areas (`!drhide`)
* Built-in third-person mode (`!drthirdperson`)
* Dynamic Activator health for fair combat minigames
* Highly customizable item configuration
* Configurable round timer (using the `tf_arena_round_time` ConVar)

## Dependencies
* SourceMod 1.10
* [DHooks with Detour Support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
* [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)
* [More Colors](https://forums.alliedmods.net/showthread.php?t=185016) (compile only)

## Configuration
The global item configuration found in `configs/deathrun/items.cfg` allows you to configure and restrict each player's items as you please.
Map-specific configuration files are read from the `configs/deathrun/maps` directory.

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
Using entity properties:
```
"307"	// Ullapool Caber
{
	"entprops"
	{
		"1"	// Makes the weapon start already detonated
		{
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
Some older maps have issues with players being able to activate buttons or kill other players through walls with explosive or throwable weapons. Instead of having to block these weapons in the global item configuration you have the option of creating a configuration file for each map.

To do that, put a file called `<map name>.items.cfg` in the `configs/deathrun/maps` directory. Workshop prefixes and suffixes should be omitted.

Any item definition indexes specified in a map-specific item configuration will override the global configuration.

## ConVars
- `dr_version` - Plugin version, don't touch.
- `dr_queue_points ( def. "15" )` - Amount of queue points awarded to runners at the end of each round.
- `dr_allow_thirdperson ( def. "1" )` - If enabled, players may toggle thirdperson. Set to 0 if you use other thirdperson plugins that may conflict.
- `dr_chattips_interval ( def. "240" )` - Interval between helpful tips printed to chat, in seconds. Set to 0 to disable chat tips.
- `dr_runner_glow ( def. "0" )` - If enabled, runners will have a glowing outline.
- `dr_num_activators ( def. "1" )` - Amount of activators chosen at the start of a round.
- `dr_scout_speed_penalty ( def. "80.0" )` - Max speed penalty for Scouts, in HU/s.