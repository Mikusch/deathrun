# Retro Deathrun
I was fed up with the lack of good public Deathrun plugins out there, so I went ahead and made my own.

Inspired by the plugins I played many years back that were never made accessible to the public, this plugin aims to keep player restrictions as little as possible while not ruining the gameplay.

## Features
* Activator queue system
* Built-in third-person mode (can be disabled by server operators using ``dr_allow_thirdperson``)
* Little to no restrictions on equipped weapons
* Buffed activator health for combat minigames
* Configurable round timer

## Dependencies
* SourceMod 1.10
* [DHooks with Detour Support](https://forums.alliedmods.net/showpost.php?p=2588686&postcount=589)
* [TF2Attributes](https://forums.alliedmods.net/showthread.php?t=210221)

## Configuration
The weapon configuration found in ``configs/deathrun/weapons.cfg`` allows you to configure weapons as you please. 
For example, there are multiple ways to disable the jumping capabilities of the Ullapool Caber:

```
"307"	// Ullapool Caber
{
	"entprops"
	{
		"entprop"
		{
			// Sets the m_iDetonated entity prop to 1
			"name"		"m_iDetonated"
			"type"		"send"
			"field_type"	"int"
			"value"		"1"
		}
	}
}
```
```
"307"	// Ullapool Caber
{
	"attributes"
	{
		"attribute"
		{
			// Zeroes out the self damage push force
			"name"	"self dmg push force decreased"
			"value"	"0.0"
			"mode"	"set"
		}
	}
}
```
This repository already contains a configuration file that should suffice for most use cases.
