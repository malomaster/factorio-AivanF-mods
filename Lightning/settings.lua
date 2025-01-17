local shared = require("shared-pre")

data:extend{
    -- Startup
    {
        type = "double-setting",
        name = "af-tsl-rod-catch-radius",
        setting_type = "startup",
        minimum_value = 16,
        default_value = 48,
        maximum_value = 96,
        order = "a-main-1",
    },
    {
        type = "int-setting",
        name = "af-tsl-update-delay",
        setting_type = "startup",
        minimum_value = 15,
        default_value = 30,
        maximum_value = 120,
        order = "a-main-2",
    },
    {
        type = "bool-setting",
        name = "af-tsl-support-surfaces",
        setting_type = "startup",
        default_value = true,
        order = "c-sup-1",
    },
    {
        type = "bool-setting",
        name = "af-tsl-support-recipes",
        setting_type = "startup",
        default_value = true,
        order = "c-sup-2",
    },
    {
        type = "bool-setting",
        name = "af-tsl-early-arty",
        setting_type = "startup",
        default_value = false,
        order = "c-sup-3",
    },

    -- Map/global
    {
        type = "string-setting",
        name = "af-tsl-common-cf---",
        localised_name = "--------- Common:",
        setting_type = "runtime-global",
        default_value = "",
        allowed_values = {""},
        allow_blank = true,
        order = "a-common-0",
    },
    {
        type = "int-setting",
        name = "af-tsl-fire-from-level",
        setting_type = "runtime-global",
        minimum_value = 0,
        default_value = 3,
        maximum_value = 5,
        order = "a-common-1",
    },
    {
        type = "double-setting",
        name = "af-tsl-rate-cf",
        setting_type = "runtime-global",
        minimum_value = 0.01,
        default_value = 1,
        maximum_value = 100,
        order = "a-common-2",
    },
    {
        type = "double-setting",
        name = "af-tsl-energy-cf",
        setting_type = "runtime-global",
        minimum_value = 0.01,
        default_value = 1,
        maximum_value = 100,
        order = "a-common-3",
    },
    {
        type = "int-setting",
        name = "af-tsl-extra-reduct",
        setting_type = "runtime-global",
        minimum_value = -1,
        default_value = 0,
        maximum_value = 2,
        order = "a-common-4",
    },

    {
        type = "string-setting",
        name = "af-tsl-nauvis---",
        localised_name = "--------- Nauvis:",
        setting_type = "runtime-global",
        default_value = "",
        allowed_values = {""},
        allow_blank = true,
        order = "b-home-0",
    },
    {
        type = "int-setting",
        name = "af-tsl-nauvis-base",
        setting_type = "runtime-global",
        minimum_value = 0,
        default_value = 0,
        maximum_value = 3,
        order = "b-home-1",
    },
    {
        type = "double-setting",
        name = "af-tsl-nauvis-scale",
        setting_type = "runtime-global",
        minimum_value = 0,
        default_value = 1,
        maximum_value = 2,
        order = "b-home-2",
    },
    {
        type = "double-setting",
        name = "af-tsl-nauvis-size",
        setting_type = "runtime-global",
        minimum_value = 0.1,
        default_value = 1,
        maximum_value = 50,
        order = "b-home-3",
    },
    {
        type = "double-setting",
        name = "af-tsl-nauvis-zspeed",
        setting_type = "runtime-global",
        minimum_value = 0,
        default_value = 0,
        maximum_value = 10,
        order = "b-home-4",
    },

    {
        type = "string-setting",
        name = "af-tsl-planets---",
        localised_name = "--------- Planets:",
        setting_type = "runtime-global",
        default_value = "",
        allowed_values = {""},
        allow_blank = true,
        order = "zzz-0",
    },
}

local resource, default
for index, info in ipairs(shared.default_presets) do
	resource, default = info[1], info[2]
	if default == nil then default = shared.PRESET_NIL end
	data:extend{{
		type = "string-setting",
        name = shared.preset_setting_name_for_resource(resource),
        localised_name = {"", {"tsl.resource-preset-setting"}, " ", {"item-name."..resource}},
        setting_type = "runtime-global",
        default_value = default,
        allowed_values = shared.allowed_presets,
        order = "zzz-"..string.format("%02d", index),
	}}
end
