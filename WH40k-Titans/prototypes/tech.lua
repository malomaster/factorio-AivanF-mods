local shared = require("shared")

local function get_weapon_effects(grade)
  local result = {}
  local already = {}
  for _, info in pairs(shared.weapons) do
    if grade == info.grade and not already[info.name] then
      result[#result+1] = { type = "unlock-recipe", recipe = info.entity }
      already[info.name] = true
    end
  end
  return result
end

local function get_titan_effects(class)
  local result = {}
  for _, info in pairs(shared.titan_type_list) do
    if class == math.floor(info.class/10) then
      result[#result+1] = { type = "unlock-recipe", recipe = info.entity }
    end
  end
  return result
end

local tech_researches = {
  {
    name = shared.mod_prefix.."base",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/datacard-titan.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = {
      { type = "unlock-recipe", recipe = shared.excavator },
      { type = "unlock-recipe", recipe = "af-reverse-lab-2" },
      { type = "unlock-recipe", recipe = shared.sp },
      { type = "unlock-recipe", recipe = shared.lab },
    },
    prerequisites = {
      "military-science-pack",
      "chemical-science-pack",
    },
    unit = {
      count = 500,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
        {"military-science-pack", 1},
        {"chemical-science-pack", 1},
        -- {"utility-science-pack", 1},
        -- {"production-science-pack", 1},
        -- {"space-science-pack", 1},
      },
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."assembly",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-assembly.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = {
      { type = "unlock-recipe", recipe = shared.bunker_minable },
    },
    prerequisites = {shared.mod_prefix.."base"},
    unit = {
      count = 10,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."production",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-production.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = {
      -- Body parts
      { type = "unlock-recipe", recipe = shared.servitor },
      { type = "unlock-recipe", recipe = shared.brain },
      { type = "unlock-recipe", recipe = shared.energy_core },
      { type = "unlock-recipe", recipe = shared.void_shield },
      { type = "unlock-recipe", recipe = shared.motor },
      { type = "unlock-recipe", recipe = shared.frame_part },
      -- Common details
      { type = "unlock-recipe", recipe = shared.antigraveng },
      { type = "unlock-recipe", recipe = shared.realityctrl },
      -- { type = "unlock-recipe", recipe = shared.emfc },
      -- Weapon parts
      { type = "unlock-recipe", recipe = shared.barrel },
      { type = "unlock-recipe", recipe = shared.proj_engine },
      { type = "unlock-recipe", recipe = shared.melta_pump },
      -- { type = "unlock-recipe", recipe = shared.he_emitter },
      -- { type = "unlock-recipe", recipe = shared.ehe_emitter },
    },
    prerequisites = afci_bridge.clean_prerequisites{
      shared.mod_prefix.."base",
      afci_bridge.get.emfc().prerequisite,
      afci_bridge.get.he_emitter().prerequisite,
      afci_bridge.get.ehe_emitter().prerequisite,
      afci_bridge.get.st_operator().prerequisite,
    },
    unit = {
      count = 500,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },


  ------- Titan classes
  {
    name = shared.mod_prefix.."1-class",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-1.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    -- effects = {
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_warhound].entity },
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_direwolf].entity },
    -- },
    effects = get_titan_effects(1),
    prerequisites = {shared.mod_prefix.."assembly"},
    unit = {
      count = 50,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."2-class",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-2.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    -- effects = {
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_reaver].entity },
    -- },
    effects = get_titan_effects(2),
    prerequisites = {shared.mod_prefix.."1-class"},
    unit = {
      count = 100,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."3-class",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-3.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    -- effects = {
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_warlord].entity },
    -- },
    effects = get_titan_effects(3),
    prerequisites = {shared.mod_prefix.."2-class"},
    unit = {
      count = 250,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."4-class",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-4.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    -- effects = {
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_warmaster].entity },
    -- },
    effects = get_titan_effects(4),
    prerequisites = {shared.mod_prefix.."3-class"},
    unit = {
      count = 400,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."5-class",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/titan-5.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    -- effects = {
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.titan_imperator].entity },
    --   { type = "unlock-recipe", recipe = shared.titan_types[shared.class_warmonger].entity },
    -- },
    effects = get_titan_effects(5),
    prerequisites = {shared.mod_prefix.."4-class"},
    unit = {
      count = 600,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },



  ------- Weapon grades
  {
    name = shared.mod_prefix.."1-grade",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/grade-1.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = get_weapon_effects(shared.gun_grade_small),
    prerequisites = {
      -- shared.mod_prefix.."production",
      shared.mod_prefix.."1-class",
    },
    unit = {
      count = 50,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."2-grade",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/grade-2.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = get_weapon_effects(shared.gun_grade_medium),
    prerequisites = {shared.mod_prefix.."1-grade", shared.mod_prefix.."3-class"},
    unit = {
      count = 200,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
  {
    name = shared.mod_prefix.."3-grade",
    type = "technology",
    icons = {
      {
      icon = shared.media_prefix.."graphics/tech/grade-3.png",
      icon_size = 256,
      icon_mipmaps = 1,
      }
    },
    effects = get_weapon_effects(shared.gun_grade_big),
    prerequisites = {shared.mod_prefix.."2-grade", shared.mod_prefix.."5-class"},
    unit = {
      count = 400,
      ingredients = {{shared.sp, 1}},
      time = 30
    },
    order = name
  },
}

data:extend(tech_researches)

se_prodecural_tech_exclusions = se_prodecural_tech_exclusions or {}
for _, info in pairs(tech_researches) do
  table.insert(se_prodecural_tech_exclusions, info.name)
end
