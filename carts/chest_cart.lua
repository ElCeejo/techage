--[[

	TechAge
	=======

	Copyright (C) 2019-2020 Joachim Stolberg

	AGPL v3
	See LICENSE.txt for more information

	TA3 Chest Cart
	
]]--

-- for lazy programmers
local M = minetest.get_meta
local S = techage.S
local P2S = function(pos) if pos then return minetest.pos_to_string(pos) end end
local S2P = minetest.string_to_pos
local MP = minetest.get_modpath("minecart")
local cart = dofile(MP.."/cart_lib1.lua")

cart:init(true)

local function formspec()
	return "size[8,6]"..
	default.gui_bg..
	default.gui_bg_img..
	default.gui_slots..
	"list[context;main;3,0;2,2;]"..
	"list[current_player;main;0,2.3;8,4;]"..
	"listring[context;main]"..
	"listring[current_player;main]"
end

local function can_dig(pos, player)
	local owner = M(pos):get_string("owner")
	if owner ~= "" and (owner ~= player:get_player_name() or
			not minetest.check_player_privs(player:get_player_name(), "minecart")) then
		return false
	end
	local inv = minetest.get_meta(pos):get_inventory()
	return inv:is_empty("main")
end

local function allow_metadata_inventory_put(pos, listname, index, stack, player)
	local owner = M(pos):get_string("owner")
	if owner ~= "" and owner ~= player:get_player_name() then
		return 0
	end
	return stack:get_count()
end

local function allow_metadata_inventory_take(pos, listname, index, stack, player)
	local owner = M(pos):get_string("owner")
	if owner ~= "" and owner ~= player:get_player_name() then
		return 0
	end
	return stack:get_count()
end

minetest.register_node("techage:chest_cart", {
	description = S("TA Chest Cart"),
	tiles = {
		-- up, down, right, left, back, front		
			"techage_chest_cart_top.png",
			"techage_chest_cart_bottom.png",
			"techage_chest_cart_side.png",
			"techage_chest_cart_side.png",
			"techage_chest_cart_front.png",
			"techage_chest_cart_front.png",
		},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-7/16,  3/16, -7/16, 7/16, 8/16, 7/16},
			{-8/16, -8/16, -8/16, 8/16, 3/16, 8/16},
		},
	},
	paramtype2 = "facedir",
	paramtype = "light",
	sunlight_propagates = true,
	is_ground_content = false,
	groups = {cracky = 2, crumbly = 2, choppy = 2},
	node_placement_prediction = "",
	
	can_dig = can_dig,
	allow_metadata_inventory_put = allow_metadata_inventory_put,
	allow_metadata_inventory_take = allow_metadata_inventory_take,
	
	after_place_node = function(pos)
		local inv = M(pos):get_inventory()
		inv:set_size('main', 4)
		M(pos):set_string("formspec", formspec())
	end,
	
	on_place = function(itemstack, placer, pointed_thing)
		return cart.add_cart(itemstack, placer, pointed_thing, "techage:chest_cart")
	end,
	
	on_punch = function(pos, node, puncher, pointed_thing)
		cart.node_on_punch(pos, node, puncher, pointed_thing, "techage:chest_cart_entity")
	end,
	
	set_cargo = function(pos, data)
		--print("set_cargo", P2S(pos), #data)
		local inv = M(pos):get_inventory()
		for idx, stack in ipairs(data) do
			inv:set_stack("main", idx, stack)
		end
	end,
	
	get_cargo = function(pos)
		local inv = M(pos):get_inventory()
		local data = {}
		for idx = 1, 4 do
			local stack = inv:get_stack("main", idx)
			data[idx] = {name = stack:get_name(), count = stack:get_count()}
		end
		--print("get_cargo", P2S(pos), #data)
		return data
	end,

	after_dig_node = function(pos, oldnode, oldmetadata, digger)
		local name = oldmetadata.fields.removed_rail or "carts:rail"
		minetest.add_node(pos, {name = name})
	end,
})

minecart.register_cart_entity("techage:chest_cart_entity", "techage:chest_cart", {
	initial_properties = {
		physical = false,
		collisionbox = {-0.5, -0.5, -0.5, 0.5, 0.5, 0.5},
		visual = "wielditem",
		textures = {"techage:chest_cart"},
		visual_size = {x=0.66, y=0.66, z=0.66},
		static_save = false,
	},
	on_activate = cart.on_activate,
	on_punch = cart.on_punch,
	on_step = cart.on_step,
})

techage.register_node({"techage:chest_cart"}, {
	on_pull_item = function(pos, in_dir, num, item_name)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return techage.get_items(pos, inv, "main", num)
	end,
	on_push_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return techage.put_items(inv, "main", stack)
	end,
	on_unpull_item = function(pos, in_dir, stack)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		return techage.put_items(inv, "main", stack)
	end,
	on_recv_message = function(pos, src, topic, payload)
		if topic == "state" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			return techage.get_inv_state(inv, "main")
		else
			return "unsupported"
		end
	end,
})	

minetest.register_craft({
	output = "techage:chest_cart",
	recipe = {
			{"default:junglewood", "default:chest_locked", "default:junglewood"},
			{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		},
})
