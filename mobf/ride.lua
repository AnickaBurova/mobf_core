-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file ride.lua
--! @brief class containing mobf functions for riding
--! @copyright Sapier
--! @author Sapier
--! @date 2013-01-06
--
--
--! @defgroup mobf_ride functions required for riding mobs
--! @brief a component containing all functions required to ride a mob
--! @ingroup framework_int
--! @{ 
--
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

mobf_ride = {}

------------------------------------------------------------------------------
-- name: attache_player(entity,player)
--
--! @brief make a player ride this mob
--! @ingroup mobf
--
--! @param entity entity to be ridden
--! @param player player riding
-------------------------------------------------------------------------------
function mobf_ride.attache_player(entity,player)

	entity.dynamic_data.ride.is_attached = true
	entity.dynamic_data.ride.player = player
	entity.object:setacceleration({x=0,y=-9.81,z=0})
	entity.object:setvelocity({x=0,y=-9.81,z=0})
	
	local attacheoffset = {x=0,y=0.5,z=0}
	
	if entity.data.ride ~= nil and
		entity.data.ride.attacheoffset ~= nil then
		attacheoffset = entity.data.ride.attacheoffset
	end
		
	player:set_attach(entity.object,"",attacheoffset, {x=0,y=0,z=0})
end

------------------------------------------------------------------------------
-- name: dettache_player(entity,player)
--
--! @brief make a player ride this mob
--! @ingroup mobf
--
--! @param entity entity to be ridden
--! @param player player riding
-------------------------------------------------------------------------------
function mobf_ride.dettache_player(entity)

	entity.dynamic_data.ride.is_attached = false
	entity.dynamic_data.ride.player:set_detach()
	entity.dynamic_data.ride.player = nil
	
end


------------------------------------------------------------------------------
-- name: on_step_callback(entity)
--
--! @brief make a player ride this mob
--! @ingroup mobf
--
--! @param entity entity to be ridden
-------------------------------------------------------------------------------
function mobf_ride.on_step_callback(entity)

	if entity.dynamic_data.ride.is_attached then
		dbg_mobf.ride_lvl3("MOBF: have attached player")
		local walkspeed  = 3
		local sneakspeed = 0.5
		local jumpspeed  = 30
		
		if entity.data.ride ~= nil then
			if entity.data.ride.walkspeed ~= nil then
				walkspeed = entity.data.ride.walkspeed
			end
			
			if entity.data.ride.runspeed ~= nil then
				runspeed = entity.data.ride.runspeed
			end
			
			if entity.data.ride.sneakspeed ~= nil then
				sneakspeed = entity.data.ride.sneakspeed
			end
			
			if entity.data.ride.jumpspeed ~= nil then
				jumpspeed = entity.data.ride.jumpspeed
			end
		end
			
		local dir = entity.dynamic_data.ride.player:get_look_yaw()
		local current_speed = entity.object:getacceleration()
		
		local speed_to_set = {x=0,y=current_speed.y,z=0}
		if dir ~= nil then
			local playerctrl = entity.dynamic_data.ride.player:get_player_control()
			
			if playerctrl ~= nil then
			
				local setspeed = false
				
				if playerctrl.jump and
					entity.is_on_ground(entity) then
					speed_to_set.y = jumpspeed
					setspeed = true
				end
				
				--just set speed to playerview direction
				if playerctrl.up then
					setspeed = true
				end
				
				--invert playerview direction
				if playerctrl.down then
					dir = dir + math.pi
					setspeed = true
				end
				
				if playerctrl.left then
					if playerctrl.up then
						dir = dir + math.pi/4
					elseif playerctrl.down then
						dir = dir - math.pi/4
					else
						dir = dir + math.pi/2
					end
					setspeed = true
				end
				
				if playerctrl.right then
					if playerctrl.up then
						dir = dir - math.pi/4
					elseif playerctrl.down then
						dir = dir + math.pi/4
					else
						dir = dir - math.pi/2
					end
					setspeed = true
				end
				
				local selected_speed = walkspeed
				
				if playerctrl.sneak then
					selected_speed = sneakspeed
				end
			
				

				if setspeed then
					speed_to_set_xz = mobf_calc_speed_components(dir,selected_speed)
				
					speed_to_set.x = speed_to_set_xz.x
					speed_to_set.z = speed_to_set_xz.z
				end
				
				entity.object:setvelocity(speed_to_set)
				
				--fix switched model orientation
				entity.object:setyaw(dir)
			end
			
		
		end
		
		return true
	else
		return false
	end
end

------------------------------------------------------------------------------
-- name: attache_player(entity,player)
--
--! @brief make a player ride this mob
--! @ingroup mobf
--
--! @param entity entity to be ridden
--! @param player player riding
-------------------------------------------------------------------------------
function mobf_ride.init(entity)
	local data = {
		is_attached = false,
		player = nil,
		}
		
	entity.dynamic_data.ride = data
end