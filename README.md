# Deathrun Neu

A Deathrun plugin for Team Fortress 2 with minimal weapon and class restrictions.

## Features

* Activator queue system (`!queue`)
* Ability to toggle visility of teammates in crowded areas (`!hide`)
* Dynamic activator health for combat minigames
* Anti-exploit measures
* Highly customizable item and plugin configuration

## Dependencies

* SourceMod 1.12+
* [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)
* [TF2Items](https://forums.alliedmods.net/showthread.php?t=115100)
* [TF2 Utils](https://forums.alliedmods.net/showthread.php?t=338773)
* [TF2 Econ Data](https://forums.alliedmods.net/showthread.php?t=315011)
* [Plugin State Manager](https://github.com/Mikusch/PluginStateManager) (compile only)
* [More Colors](https://forums.alliedmods.net/showthread.php?t=185016) (compile only)

## Configuration

The global item configuration found in `configs/deathrun/items.cfg` allows you to configure and restrict each player's
items as you please.

For example, there are two different ways to disable the jumping capabilities of the Ullapool Caber.

Using attributes:

```
"307"	// Ullapool Caber
{
	"attributes"
	{
		"self dmg push force decreased"	"0"
	}
}
```

Using netprops:

```
"307"	// Ullapool Caber
{
	"netprops"
	{
		"m_iDetonated"	// Makes the weapon start already detonated
		{
			"target"		"item"
			"type"			"send"
			"field_type"	"int"
			"value"			"1"
		}
	}
}
```

These two methods may also be combined. For example, you can give Medics a one-time use ÜberCharge with this
configuration:

```
"29"	// Medi Gun
{
	"attributes"
	{
		"heal rate penalty"			"0" // No healing
		"ubercharge rate penalty"	"0" // No ÜberCharge gain
	}
	"netprops"
	{
		"m_flChargeLevel"	// Sets the ÜberCharge level to 100%
		{
			"target"		"weapon"
			"type"			"send"
			"field_type"	"float"
			"value"			"1"
		}
	}
}
```

If you don't want to copy-paste the same configuration onto similar weapons, you may use the prefabs system. After an
item has been defined, you can copy its properties over to another weaopon:

```
"211"	// Medi Gun (Renamed/Strange)
{
	"prefab"	"29"
}
"35"	// Kritzkrieg
{
	"prefab"	"29"
}
```

See [items.cfg](/addons/sourcemod/configs/deathrun/items.cfg) for more details and the default configuration.
