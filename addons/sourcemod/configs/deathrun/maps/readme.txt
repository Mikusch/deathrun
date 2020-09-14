When the plugin loads, this folder is automatically scanned for map configuration files. Item definition indexes specified in such a file will always override matching ones in the global configuration.

The map configuration file should be named <map name>.items.cfg, omitting any workshop prefix and suffix.

Examples:

	dr_horrors -> dr_horrors.items.cfg
	dr_paradoxal_v4 -> dr_paradoxal_v4.items.cfg
	workshop/dr_scprun_v2.ugc2183648308 -> dr_scprun_v2.items.cfg

The KV structure is identical to the global configuration. See items.cfg for more details.
