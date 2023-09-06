require("script/common")
local math2d = require("math2d")
local Lib = require("script/event_lib")
local lib = Lib.new()

local gui_update_rate = 9
local order_ttl = 60 * 5
local visual_ttl = 2

local max_oris = { -- titan cannon max orientation shift
  0.15, 0.15,
  0.4, 0.4,
  0.2, 0.2,
}

local titan_explo_bolt = shared.mod_prefix.."bolt-plasma-3"



----- Weapons -----

local function init_gun(name)
  local weapon_type = shared.weapons[name]
  return  {
    name = name,
    cd = 0,
    oris = 0, -- orientation shift of the cannon
    target = nil, -- LuaEntity or position
    ordered = 0, -- task creation tick for expiration
    gun_cd = 0,
    attack_number = 0, -- from weapon_type.attack_size
    ammo_count = weapon_type.inventory,
    ai = false,
  }
end


local function calc_max_dst(titan_type, k, weapon_type)
  return weapon_type.max_dst * (1 + 0.01*titan_type.class)
end


local function bolt_attacker(entity, titan_type, cannon, weapon_type, source, target)
  if weapon_type.bolt_type == nil then
    error("Weapon "..weapon_type.name.." has no bolt type!")
  end
  local speed = weapon_type.speed or 10
  local barrel = weapon_type.barrel or 12
  if weapon_type.category == shared.wc_flamer then
    source = math2d.position.add(source, {math.random(-1, 1), math.random(-1, 1)})
  end
  if barrel > 0 then
    source = math2d.position.add(source, point_orientation_shift(entity.orientation, cannon.oris, barrel))
  end
  entity.surface.create_entity{
    name=weapon_type.bolt_type, force=entity.force,
    position=source, source=source, target=target, speed=speed,
  }
end


local function gun_do_attack(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, attacker)
  -- TODO: add some time before attack
  -- TODO: calculate gun muzzle position
  if (cannon.attack_number or 0) >= 1 then
    cannon.attack_number = cannon.attack_number - 1
  elseif weapon_type.attack_size > 1 then
    cannon.attack_number = (weapon_type.attack_size-1) or 0
  end
  cannon.ammo_count = math.max(0, cannon.ammo_count - weapon_type.per_shot)
  local target = cannon.target
  if (weapon_type.scatter or 0) > 0 then
    target = math2d.position.add(target, {
      math.random(-weapon_type.scatter, weapon_type.scatter),
      math.random(-weapon_type.scatter, weapon_type.scatter)})
  end
  attacker(entity, titan_type, cannon, weapon_type, gunpos, target)
  cannon.gun_cd = tick + weapon_type.cd * 60
  -- log("gun_do_attack name: "..cannon.name..", attack_number: "..cannon.attack_number)

  if (cannon.attack_number or 0) <= 0 then
    cannon.target = nil
    cannon.attack_number = 0
    cannon.when_can_rotate = tick + 90*weapon_type.grade
  else
    cannon.ordered = tick
  end
end


local function control_simple_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, attacker)
  if cannon.target ~= nil and tick < cannon.ordered + order_ttl then
    local dst = math2d.position.distance(gunpos, cannon.target)
    if cannon.gun_cd < tick and dst > 4 and dst < calc_max_dst(titan_type, k, weapon_type) then
      gun_do_attack(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, attacker)
    end

  else
    cannon.target = nil
  end
end


local function control_rotate_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, attacker)
  if cannon.target ~= nil and tick < cannon.ordered + order_ttl then
    -- TODO: check if target is a LuaEntity
    local tori = points_to_orientation(gunpos, cannon.target)
    local orid = orientation_diff(ori+cannon.oris, tori)
    cannon.oris = cannon.oris + (0.04-0.005*weapon_type.grade)*orid
    cannon.oris = math.clamp(cannon.oris, -max_oris[k], max_oris[k])
    local dst = math2d.position.distance(gunpos, cannon.target)

    if true
      and math.abs(orid) < 0.015
      and cannon.gun_cd < tick
      and dst > 4 and dst < calc_max_dst(titan_type, k, weapon_type)
    then
      gun_do_attack(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, attacker)
    end

  else
    cannon.target = nil
    if (cannon.when_can_rotate or 0) < tick then
      -- Smoothly remove oris
      if math.abs(cannon.oris) > 0.005 then
        cannon.oris = cannon.oris * 0.95
      else
        cannon.oris = 0
      end
    end
  end
end


local function control_beam_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick)
  control_rotate_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, bolt_attacker)
end

local function control_bolt_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick)
  control_rotate_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, bolt_attacker)
end

local function control_rocket_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick)
  control_simple_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, bolt_attacker)
end

local function control_melta_gun(cannon, weapon_type, entity, ori, tick)
  control_rotate_gun(entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick, bolt_attacker)
end

local wc_control = {}
wc_control[shared.wc_rocket] = control_rocket_gun
wc_control[shared.wc_bolter] = control_bolt_gun
wc_control[shared.wc_quake]  = control_bolt_gun
wc_control[shared.wc_flamer] = control_bolt_gun
wc_control[shared.wc_plasma] = control_bolt_gun
wc_control[shared.wc_melta]  = control_melta_gun
wc_control[shared.wc_laser]  = control_beam_gun
wc_control[shared.wc_hell]   = control_beam_gun

local color_default_dst = {1,1,1}
local color_gold    = {255, 220,  50}
local color_orange  = {255, 160,  50}
local color_red     = {200,  20,  20}
local color_blue    = { 70, 120, 230}
local color_purple  = {200,  20, 200}
local color_green   = {20,  120,  20}
local color_cyan    = {20,  200, 200}
local color_ltgrey  = {160, 160, 160}
local color_dkgrey  = { 60,  60,  60}

local wc_color = {}
wc_color[shared.wc_rocket] = color_ltgrey
wc_color[shared.wc_bolter] = color_dkgrey
wc_color[shared.wc_quake]  = color_dkgrey
wc_color[shared.wc_flamer] = color_orange
wc_color[shared.wc_plasma] = color_blue
wc_color[shared.wc_melta]  = color_cyan
wc_color[shared.wc_laser]  = color_gold
wc_color[shared.wc_hell]   = color_red
-- wc_color[shared.wc_gravy]  = color_purple
-- wc_color[shared.wc_warpm]  = color_green



----- Visual Interface -----
-- https://lua-api.factorio.com/latest/classes/LuaGuiElement.html

local main_frame_name = "wh40k_titans_main_frame"
local action_toggle_ammo_count = "titan_toggle_ammo_count"
local action_toggle_gun_mod = "titan_toggle_gun_mod"
local action_zoom_out = "titan_zoom_out"

local function remove_titan_gui_by_player(player)
  if ctrl_data.titan_gui[player.index] then
    ctrl_data.titan_gui[player.index].main_frame.destroy()
    ctrl_data.titan_gui[player.index] = nil
  end
end

function remove_titan_gui_by_titan(titan_info)
  for _, obj in pairs(ctrl_data.titan_gui) do
    if obj.titan_info == titan_info then
      remove_titan_gui_by_player(obj.player)
    end
  end
end

local function create_titan_gui(player, titan_info)
  if ctrl_data.titan_gui[player.index] then
    if ctrl_data.titan_gui[player.index].titan_info == titan_info then
      -- The required GUI already exists
      return
    else
      -- Some wrong GUI exists
      remove_titan_gui_by_player(player)
    end
  end

  ctrl_data.by_player[player.index] = ctrl_data.by_player[player.index] or {}
  local player_settings = ctrl_data.by_player[player.index]
  player_settings.guns = player_settings.guns or {}

  local guiobj = {
    player = player,
    titan_info = titan_info,
    guns = {},
  }
  ctrl_data.titan_gui[player.index] = guiobj
  if player.gui.screen[main_frame_name] then
    player.gui.screen[main_frame_name].destroy()
  end
  guiobj.main_frame = player.gui.screen.add{
    type="frame", name=main_frame_name, caption={shared.mod_name..".titan-dashboard"},
    direction="horizontal",
  }
  guiobj.main_frame.style.size = {340, 180}
  -- guiobj.main_frame.auto_center = true
  player.opened = main_frame

  guiobj.weapon_table = guiobj.main_frame.add{type="table", name="weapon_table", column_count=#titan_info.guns, style="filter_slot_table"}
  -- guiobj.weapon_table.clear()
  for k, cannon in pairs(titan_info.guns) do
    if not player_settings.guns[k] then
      player_settings.guns[k] = {mode = math.ceil(k/2)}
    end
    guiobj.guns[k] = {}
    guiobj.guns[k].img = guiobj.weapon_table.add{
      type="sprite-button", sprite=("recipe/"..shared.mod_prefix..cannon.name),
      tooltip={"item-name."..shared.mod_prefix..cannon.name},
      show_percent_for_small_numbers=true,
    }
  end
  for k, cannon in pairs(titan_info.guns) do
    guiobj.guns[k].ammo = guiobj.weapon_table.add{
      type="sprite-button", sprite=("item/"..shared.weapons[cannon.name].ammo),
      -- show_percent_for_small_numbers=true,
      tags={action=action_toggle_ammo_count},
    }
  end
  for k, cannon in pairs(titan_info.guns) do
    guiobj.guns[k].mode = guiobj.weapon_table.add{
      type="sprite-button", tags={action=action_toggle_gun_mod, index=k},
    }
  end

  guiobj.titan_info_table = guiobj.main_frame.add{type="table", name="titan_info_table", column_count=1, style="filter_slot_table"}
  guiobj.titan_info_table.add{
    type="sprite-button", sprite="item/radar",
    tooltip={"controls."..shared.mod_prefix.."zoom-out"},
    tags={action=action_zoom_out},
  }
  guiobj.void_shield = guiobj.titan_info_table.add{
    type="sprite-button", sprite="item/"..shared.void_shield,
    tooltip={"controls.wh40k-titans-vs-value"},
  }
end

lib:on_event(defines.events.on_player_driving_changed_state, function(event)
  local player = game.players[event.player_index]
  if not player.character then return end
  if player.character.vehicle then
    local titan_info = ctrl_data.titans[player.character.vehicle.unit_number]
    if not titan_info then return end

    create_titan_gui(player, titan_info)
  else
    remove_titan_gui_by_player(player)
  end
end)

local function update_gui()
  local tick = game.tick
  for _, guiobj in pairs(ctrl_data.titan_gui) do
    if not guiobj.player.valid or not guiobj.titan_info.entity.valid then
      remove_titan_gui_by_player(guiobj.player)
    else
      local player_settings = ctrl_data.by_player[guiobj.player.index] or {}
      if guiobj.void_shield then
        guiobj.void_shield.number = math.floor(100 * guiobj.titan_info.shield / shared.titan_types[guiobj.titan_info.class].max_shield)
      end
      local still_cd
      for k, cannon in pairs(guiobj.titan_info.guns) do
        still_cd = cannon.gun_cd > tick
        if still_cd then
          guiobj.guns[k].img.number = 1- (cannon.gun_cd-tick) /shared.weapons[cannon.name].cd /60
        else
          guiobj.guns[k].img.number = nil
        end
        if guiobj.guns[k].img.toggled ~= nil then
          guiobj.guns[k].img.toggled = still_cd or (cannon.target ~= nil) and (tick < cannon.ordered + order_ttl)
        end
        if player_settings.percent_ammo then
          guiobj.guns[k].ammo.number = math.floor(100 *(cannon.ammo_count or 0) /shared.weapons[cannon.name].inventory)
        else
          guiobj.guns[k].ammo.number = cannon.ammo_count or 0
        end
        if guiobj.titan_info.guns[k].ai then
          -- guiobj.guns[k].mode.text = "AI"
          guiobj.guns[k].mode.sprite = "virtual-signal/signal-info"
        elseif player_settings.guns[k].mode == 1 then
          guiobj.guns[k].mode.sprite = "virtual-signal/signal-1"
        elseif player_settings.guns[k].mode == 2 then
          guiobj.guns[k].mode.sprite = "virtual-signal/signal-2"
        elseif player_settings.guns[k].mode == 3 then
          guiobj.guns[k].mode.sprite = "virtual-signal/signal-3"
        else
          guiobj.guns[k].mode.sprite = "virtual-signal/signal-red"
        end
      end
    end
  end
end

lib:on_nth_tick(gui_update_rate, update_gui)

script.on_event(defines.events.on_gui_click, function(event)
  local player = game.get_player(event.player_index)
  local player_settings = ctrl_data.by_player[event.player_index]
  local titan_info = nil
  if player.character and player.character.vehicle then
    titan_info = ctrl_data.titans[player.character.vehicle.unit_number]
  end

  if event.element.tags.action == action_toggle_ammo_count then
    player_settings.percent_ammo = not player_settings.percent_ammo

  elseif event.element.tags.action == action_toggle_gun_mod then
    local k = event.element.tags.index
    if not titan_info then return end
    if titan_info.guns[k].ai then
      titan_info.guns[k].ai = false
    else
      player_settings.guns[k].mode = math.fmod((player_settings.guns[k].mode or 0) + 1, 4)
      if player_settings.guns[k].mode == 0 then
        titan_info.guns[k].ai = true
      end
    end

  elseif event.element.tags.action == action_zoom_out then
    if not titan_info then return end
    player.zoom = 1 / (3 + titan_info.class/10)
  end
end)



----- Intro -----

function lib.register_titan(entity)
  if ctrl_data.titans[entity.unit_number] then return end
  local titan_type = shared.titan_types[entity.name]
  if not titan_type then
    game.print("Got bad titan "..entity.name)
    return
  end
  local titan_info = {
    entity = entity,
    class = titan_type.class,
    shield = titan_type.max_shield /2, -- void shield health amount
    voice_cd = 0, -- phrases muted till
    body_cd = 0, -- step and rotation sounds muted till
    track_cd = 0, -- footstep track drawing cooldown till
    foot_cd = 0,
    track_rot = false, -- R or L
    foot_rot = false, -- R or L
    foots = {}, -- 2 foot entities
    guns = {}, -- should be added by bunker script
  }

  if titan_type.class == shared.class_warhound then
    titan_info.guns = {
      init_gun(shared.weapon_inferno),
      -- init_gun(shared.weapon_inferno),
      init_gun(shared.weapon_plasma_blastgun),
      -- init_gun(shared.weapon_turbolaser),
      -- init_gun(shared.weapon_lascannon),
    }
  elseif titan_type.class <= shared.class_reaver then
    titan_info.guns = {
      init_gun(shared.weapon_plasma_blastgun),
      init_gun(shared.weapon_plasma_blastgun),
      init_gun(shared.weapon_turbolaser),
    }
  elseif titan_type.class >= shared.class_warmaster then
    titan_info.guns = {
      init_gun(shared.weapon_plasma_blastgun),
      init_gun(shared.weapon_plasma_blastgun),
      init_gun(shared.weapon_turbolaser),
    }
  else
    titan_info.guns = {
      init_gun(shared.weapon_plasma_destructor),
      -- init_gun(shared.weapon_plasma_annihilator),
      init_gun(shared.weapon_turbolaser),
      -- init_gun(shared.weapon_lascannon),
      init_gun(shared.weapon_apocalypse_missiles),
      init_gun(shared.weapon_missiles),
    }
  end

  titan_info.guns = table.slice(titan_info.guns, 1, #titan_type.guns)

  ctrl_data.titans[entity.unit_number] = titan_info
  entity.surface.play_sound{
    path="wh40k-titans-phrase-init",
    position=entity.position, volume_modifier=1
  }
end



----- OUTRO -----

function lib.titan_death(titan_info)

  -- TODO: create corpse

  local source = titan_info.entity.position
  local target
  local scatter = titan_info.class / 5
  for i = 0, titan_info.class/10 do
    target = math2d.position.add(
      titan_info.entity.position,
      {math.random(-scatter, scatter), math.random(-scatter, scatter)}
    )
    titan_info.entity.surface.create_entity{
      name=titan_explo_bolt,
      position=source, source=source, target=target, speed=10,
    }
  end
end



----- MAIN -----

local function process_single_titan(titan_info)
  local tick = game.tick
  local titan_type = shared.titan_types[titan_info.class]
  local class = titan_info.class
  local name = titan_type.name
  local entity = titan_info.entity
  local surface = entity.surface
  local spd = math.abs(entity.speed)
  if entity.speed < 0 then
    entity.speed = entity.speed * 0.99
  end
  local ori = entity.orientation
  local oris = math.sin(tick/120 *2*math.pi) * 0.02 * spd/0.3
  -- titan_info.oris = oris
  local shadow_shift = {2 * (1+0.1*class), 1}

  ----- Body

  rendering.draw_animation{
    animation=name.."-shadow",
    x_scale=1, y_scale=1, render_layer=shared.rl_shadow,
    time_to_live=visual_ttl,
    surface=surface, target=entity, target_offset=shadow_shift,
    orientation=ori+oris,
  }
  rendering.draw_animation{
    animation=name,
    x_scale=1, y_scale=1, render_layer=shared.rl_body,
    time_to_live=visual_ttl,
    surface=surface, target=entity, target_offset={0, 0},
    orientation=ori+oris,
  }
  rendering.draw_light{
    sprite=shared.mod_prefix.."light", scale=7+0.3*class,
    intensity=1+0.05*class, minimum_darkness=0, color=tint,
    time_to_live=visual_ttl,
    surface=surface, target=math2d.position.add(entity.position, point_orientation_shift(ori, 0, 6)),
  }


  ----- Void Shield
  -- TODO: consider energy spent on guns?
  -- 3 minutes for the full recharge
  titan_info.shield = math.min((titan_info.shield or 0) + titan_type.max_shield /60 /180, titan_type.max_shield)
  local sc = 0.75 + 0.025*class

  -- Main visual
  if titan_info.shield > 100 then
    rendering.draw_sprite{
      sprite=shared.mod_prefix.."shield",
      x_scale=sc, y_scale=sc, render_layer=shared.rl_shield,
      time_to_live=visual_ttl,
      surface=surface, target=math2d.position.add(entity.position, point_orientation_shift(ori, 0, 2)),
    }
  end

  -- Ratio bar
  local shield_cf = titan_info.shield/titan_type.max_shield
    if shield_cf < 0.99 then
    local w2 = 1 + class/10
    local yy = 4 + class/10
    local hh = 0.5
    rendering.draw_rectangle{
      color={0,0,0,1}, filled=true,
      left_top=entity, left_top_offset={-w2-0.1,yy-0.1},
      right_bottom=entity, right_bottom_offset={w2+0.1,yy+hh+0.1},
      surface=surface, time_to_live=visual_ttl,
      forces={entity.force}, only_in_alt_mode=true
    }
    rendering.draw_rectangle{
      color={1,1,1,1}, filled=true,
      left_top=entity, left_top_offset={-w2,yy},
      right_bottom=entity, right_bottom_offset={-w2+2*w2*shield_cf,yy+hh},
      surface=surface, time_to_live=visual_ttl,
      forces={entity.force}, only_in_alt_mode=true
    }
  end


  ----- The Guns
  local weapon_type, gunpos, cannon
  local for_whom = list_players({entity.get_driver(), entity.get_passenger()})
  for k, _ in ipairs(titan_type.guns) do
    cannon = titan_info.guns[k]
    weapon_type = shared.weapons[cannon.name]
    gunpos = math2d.position.add(entity.position, point_orientation_shift(ori, titan_type.guns[k].oris, titan_type.guns[k].shift))
    wc_control[weapon_type.category](entity, titan_type, k, cannon, gunpos, weapon_type, ori, tick)

    rendering.draw_animation{
      animation=weapon_type.animation,
      x_scale=1, y_scale=1, render_layer=titan_type.guns[k].layer,
      time_to_live=visual_ttl,
      surface=surface,
      target=gunpos,
      orientation=ori-oris/2 + cannon.oris,
    }
    if #for_whom > 0 then
      rendering.draw_circle{
        color=wc_color[weapon_type.category] or color_default_dst,
        radius=calc_max_dst(titan_type, k, weapon_type) *0.95,
        filled=false, width=10+0.5*class, time_to_live=visual_ttl,
        surface=surface, target=gunpos, players=for_whom, --forces={entity.force},
        draw_on_ground=true, only_in_alt_mode=true,
      }
    end
    -- TODO: add weapons shadow
  end

  -- TODO: remove foots if too far

  local img, sc, foot
  if spd > 0.03 then


    ----- Foots

    if titan_info.foot_cd < tick then
      titan_info.foot_cd = tick + 15 + 1.5*class
      titan_info.foot_rot = not titan_info.foot_rot

      foot = titan_info.foots[titan_info.foot_rot and 1 or 2]
      if foot and foot.valid then foot.destroy() end

      local foot_oris, foot_shift
      if entity.speed < 0 then
        foot_oris = 0.4 * (titan_info.foot_rot and -1 or 1)
        foot_shift = 6 + class/10
      else
        foot_oris = 0.1 * (titan_info.foot_rot and -1 or 1)
        foot_shift = 8 + class/10
      end
      if class < 20 then
        img = shared.mod_prefix.."foot-small"
        sc = 1
      else
        img = shared.mod_prefix.."foot-big"
        sc = (class+5) /20
      end
      foot = surface.create_entity{
        name=titan_type.foot, force="neutral",
        position=math2d.position.add(entity.position, point_orientation_shift(ori, foot_oris, foot_shift)),
      }
      ctrl_data.foots[#ctrl_data.foots+1] = {  -- TODO: is this buggy?!?
        owner = entity, entity=foot,
        animation=img, ori=ori, sc=sc,
      }
      surface.create_entity{
        name=titan_type.foot.."-damage", force="neutral", speed=1,
        position=foot.position, target=foot.position, source=math2d.position.add(foot.position, {x=0, y=-1})
      }
      titan_info.foots[titan_info.foot_rot and 1 or 2] = foot
      -- if titan_info.foots[titan_info.leg and 2 or 1] then
      --   game.print("Placed foot: "..serpent.line(foot.valid).." / "..serpent.line(titan_info.foots[titan_info.leg and 2 or 1].valid))
      -- end

      -- TODO: if not over_water, apply landfill/shallow-water if small (deep)water found
    end


    ----- Tracks

    if titan_info.track_cd < tick then
      titan_info.track_cd = tick + 45 + 1.5*class
      titan_info.track_rot = not titan_info.track_rot

      if class < 20 then
        img = shared.mod_prefix.."step-small"
        sc = 1
      else
        img = shared.mod_prefix.."step-big"
        sc = class / 20
      end

      rendering.draw_animation{
        animation=img, x_scale=sc, y_scale=sc,
        render_layer=shared.rl_track, time_to_live=60*5,
        surface=surface,
        target=math2d.position.add(entity.position, point_orientation_shift(ori, 0.25 * (titan_info.track_rot and 1 or -1), 4+0.1*titan_info.class)),
        target_offset={3, 0}, orientation=ori-oris/2,
      }
    end


    ----- Movement sounds

    local volume = math.min(1, spd/0.2) -- TODO: add class coef?
    if titan_info.body_cd < tick then
      surface.play_sound{
        path="wh40k-titans-walk-step",
        position=entity.position, volume_modifier=volume*0.8
      }
      titan_info.body_cd = tick + 30 + 1.5*class
    end
    if titan_info.voice_cd < tick then
      if math.random(100) < 30 then
        surface.play_sound{
          path="wh40k-titans-phrase-walk",
          position=entity.position, volume_modifier=1
        }
      end
      titan_info.voice_cd = tick + 450 + 15*class
    end
  end -- if spd

  -- Prevent slowing down
  if entity.stickers then
    for _, st in pairs(entity.stickers) do
      if st.valid then st.destroy() end
    end
  end
end


local function process_titans()
  for unit_number, titan_info in pairs(ctrl_data.titans) do
    if titan_info.entity.valid then
      process_single_titan(titan_info)
    else
      ctrl_data.titans[unit_number] = nil
    end
  end
  for index, info in pairs(ctrl_data.foots) do
    if info.entity.valid then
      rendering.draw_animation{
        animation=info.animation,
        x_scale=info.sc or 1, y_scale=info.sc or 1, render_layer=shared.rl_foot,
        time_to_live=visual_ttl,
        surface=info.entity.surface,
        target=info.entity,
        orientation=info.ori,
      }
    else
      ctrl_data.foots[index] = nil
    end
  end
end


lib:on_event(defines.events.on_tick, process_titans)



----- Attack Order -----

local function handle_attack_order(event, kind)
  -- https://lua-api.factorio.com/latest/events.html#CustomInputEvent
  local player = game.players[event.player_index]
  if not (player.character and player.character.vehicle) then return end
  local entity = player.character.vehicle
  local titan_info = ctrl_data.titans[entity.unit_number]
  if not titan_info then return end
  local titan_type = shared.titan_types[titan_info.class]

  local tick = game.tick
  local target = event.cursor_position
  local todo
  local done = false
  local weapon_type, dst

  local player_settings = ctrl_data.by_player[event.player_index] or {}
  player_settings.guns = player_settings.guns or {}

  for k, cannon in pairs(table.shallow_copy(titan_info.guns)) do
    if (player_settings.guns[k] or {}).mode == kind and not titan_info.guns[k].ai then
      weapon_type = shared.weapons[titan_info.guns[k].name]
      todo = true
      todo = todo and cannon.gun_cd < tick
      todo = todo and (cannon.target == nil or cannon.ordered+order_ttl < tick)
      todo = todo and cannon.ammo_count >= weapon_type.per_shot*weapon_type.attack_size

      if todo then
        dst = math2d.position.distance(entity.position, target)
        todo = dst > weapon_type.min_dst and dst < calc_max_dst(titan_type, k, weapon_type)
      end

      -- TODO: make priority choice: if there is gun_cd, save for secondary task order, trying to find a free cannon
      if todo then
        cannon.target = event.cursor_position
        cannon.ordered = tick
        -- cannon.attack_number = 0
        done = true
        break
      end
    end
  end

  if done then
    if titan_info.voice_cd < tick then
      if math.random(100) < 80 then
        entity.surface.play_sound{
          path="wh40k-titans-phrase-attack",
          position=entity.position, volume_modifier=1
        }
      end
      titan_info.voice_cd = tick + 450 + 15*titan_info.class
    end
  else
    -- game.print("No ready titan cannon")
  end
end

lib:on_event(shared.mod_prefix.."attack-1", function(event) handle_attack_order(event, 1) end)
lib:on_event(shared.mod_prefix.."attack-2", function(event) handle_attack_order(event, 2) end)
lib:on_event(shared.mod_prefix.."attack-3", function(event) handle_attack_order(event, 3) end)



----- Void Shields absorbing

lib:on_event(defines.events.on_entity_damaged, function(event)
  local entity = event.entity
  local unit_number = entity.valid and entity.unit_number
  if unit_number == nil then return end
  if ctrl_data.titans[unit_number] then
    local tctrl = ctrl_data.titans[unit_number]
    entity.health = event.final_health + event.final_damage_amount
    local damage = event.final_damage_amount
    local shielded = math.min(damage, tctrl.shield)
    tctrl.shield = tctrl.shield - shielded
    damage = damage - shielded
    entity.health = entity.health - damage
    -- game.print("damage: "..damage..", shielded: "..shielded)
  end
end)


return lib