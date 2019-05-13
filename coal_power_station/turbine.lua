--[[

	TechAge
	=======

	Copyright (C) 2019 Joachim Stolberg

	LGPLv2.1+
	See LICENSE.txt for more information
	
	TA3 Power Station Turbine

]]--

-- for lazy programmers
local S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local P = minetest.string_to_pos
local M = minetest.get_meta

-- Load support for intllib.
local MP = minetest.get_modpath("techage")
local I,_ = dofile(MP.."/intllib.lua")

local POWER_CONSUMPTION = 15

local Power = techage.SteamPipe
local consumer = techage.consumer

local function swap_node(pos, name)
	local node = minetest.get_node(pos)
	if node.name == name then
		return
	end
	node.name = name
	minetest.swap_node(pos, node)
end

-- called from pipe network
local function valid_power_dir(pos, power_dir, in_dir)
	return power_dir == in_dir or in_dir == 5
end

local function play_sound(pos)
	local mem = tubelib2.get_mem(pos)
	if mem.running then
		mem.handle = minetest.sound_play("techage_turbine", {
			pos = pos, 
			gain = 1,
			max_hear_distance = 15})
		minetest.after(2, play_sound, pos)
	end
end

local function stop_sound(pos)
	local mem = tubelib2.get_mem(pos)
	if mem.running and mem.handle then
		minetest.sound_stop(mem.handle)
		mem.handle = nil
	end
end

-- called from pipe network
local function turn_on(pos, dir, sum)
	local mem = tubelib2.get_mem(pos)
	local res = techage.power.start_dedicated_node(pos, 6, "techage:cooler", sum)
	if sum > 0 and res then
		swap_node(pos, "techage:turbine_on")
		mem.running = true
		play_sound(pos)
	else
		swap_node(pos, "techage:turbine")
		mem.running = false
		stop_sound(pos)
	end
end	


minetest.register_node("techage:turbine", {
	description = I("TA3 Turbine"),
	tiles = {
		-- up, down, right, left, back, front
		"techage_filling_ta3.png^techage_frame_ta3.png^techage_steam_hole.png",
		"techage_filling_ta3.png^techage_frame_ta3.png",
		"techage_filling_ta3.png^techage_appl_open.png^techage_frame_ta3.png",
		"techage_filling_ta3.png^techage_frame_ta3.png^techage_steam_hole.png",
		"techage_filling_ta3.png^techage_appl_turbine.png^techage_frame_ta3.png",
		"techage_filling_ta3.png^techage_appl_turbine.png^techage_frame_ta3.png",
	},
	techage = {
		turn_on = turn_on,
		read_power_consumption = consumer.read_power_consumption,
		power_network = Power,
		power_side = "L",
		valid_power_dir = valid_power_dir,
	},
	
	after_place_node = function(pos, placer)
		local mem = consumer.after_place_node(pos, placer)
		mem.power_consumption = POWER_CONSUMPTION
		mem.running = false
	end,
	
	after_tube_update = consumer.after_tube_update,
	after_dig_node = consumer.after_dig_node,

	paramtype2 = "facedir",
	groups = {cracky=2, crumbly=2, choppy=2},
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_node("techage:turbine_on", {
	tiles = {
		-- up, down, right, left, back, front
		"techage_filling_ta3.png^techage_frame_ta3.png^techage_steam_hole.png",
		"techage_filling_ta3.png^techage_frame_ta3.png",
		"techage_filling_ta3.png^techage_appl_open.png^techage_frame_ta3.png",
		"techage_filling_ta3.png^techage_frame_ta3.png^techage_steam_hole.png",
		{
			image = "techage_filling4_ta3.png^techage_appl_turbine4.png^techage_frame4_ta3.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.4,
			},
		},
		{
			image = "techage_filling4_ta3.png^techage_appl_turbine4.png^techage_frame4_ta3.png",
			backface_culling = false,
			animation = {
				type = "vertical_frames",
				aspect_w = 32,
				aspect_h = 32,
				length = 0.4,
			},
		},
	},
	techage = {
		turn_on = turn_on,
		read_power_consumption = consumer.read_power_consumption,
		power_network = Power,
		power_side = "L",
		valid_power_dir = valid_power_dir,
	},
	
	after_tube_update = consumer.after_tube_update,
	after_dig_node = consumer.after_dig_node,

	paramtype2 = "facedir",
	groups = {not_in_creative_inventory=1},
	diggable = false,
	on_rotate = screwdriver.disallow,
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
})

minetest.register_craft({
	output = "techage:turbine",
	recipe = {
		{"basic_materials:steel_bar", "techage:iron_ingot", "default:wood"},
		{"techage:steam_pipeS", "basic_materials:gear_steel", ""},
		{"default:wood", "techage:iron_ingot", "basic_materials:steel_bar"},
	},
})

techage.register_help_page(I("TA3 Turbine"), 
I([[Part of the Coal Power Station.
Has to be placed side by side
with the TA3 Generator.
(see TA3 Coal Power Station)]]), "techage:turbine")

Power:add_secondary_node_names({"techage:turbine", "techage:turbine_on"})

minetest.register_lbm({
	label = "[techage] Turbine sound",
	name = "techage:power_station",
	nodenames = {"techage:turbine_on"},
	run_at_every_load = true,
	action = function(pos, node)
		play_sound(pos)
	end
})