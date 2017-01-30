-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
--
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice.
-- And of course you are NOT allow to pretend you have written it.
--
--! @file main_follow.lua
--! @brief component containing a targeted movement generator
--! @copyright Sapier
--! @author Sapier
--! @date 2012-08-09
--
--! @defgroup mgen_follow MGEN: follow movement generator
--! @brief A movement generator creating movement that trys to follow a moving
--! target or reach a given point on map
--! @ingroup framework_int
--! @{
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @class mgen_follow
--! @brief a movement generator trying to follow or reach a target

--!@}

mgen_follow = {}

--! @brief movement generator identifier
--! @memberof mgen_follow
mgen_follow.name = "follow_mov_gen"

-------------------------------------------------------------------------------
-- name: identify_movement_state(ownpos,targetpos)
--
--! @brief check what situation we are
--! @memberof mgen_follow
--! @private
--
--! @param ownpos position of entity
--! @param targetpos position of target
--!
--! @return  "below_los"
--!          "below_no_los"
--!          "same_height_los"
--!          "same_height_no_los"
--!          "above_los"
--!          "above_no_los"
--!          "unknown"
-------------------------------------------------------------------------------
function mgen_follow.identify_movement_state(ownpos,targetpos)
	mobf_assert_backtrace(ownpos ~= nil)
	mobf_assert_backtrace(targetpos ~= nil)

	local same_height_delta = 0.1

	local los = mobf_line_of_sight(ownpos,targetpos)

	if ownpos.y > targetpos.y - same_height_delta and
		ownpos.y < targetpos.y + same_height_delta then

		if los then
			return "same_height_los"
		else
			return "same_height_no_los"
		end
	end

	if ownpos.y < targetpos.y then
		if los then
			return "below_los"
		else
			return "below_no_los"
		end
	end

	if ownpos.y > targetpos.y then
		if los then
			return "above_los"
		else
			return "above_no_los"
		end
	end

	return "unknown"
end

-------------------------------------------------------------------------------
-- name: handleteleport(entity,now)
--
--! @brief handle teleportsupport
--! @memberof mgen_follow
--! @private
--
--! @param entity mob to check for teleport
--! @param now current time
--! @param targetpos position of target
--!
--! @return true/false finish processing
-------------------------------------------------------------------------------
function mgen_follow.handleteleport(entity,now,targetpos)

	if (entity.dynamic_data.movement.last_next_to_target ~= nil ) then
		local time_since_next_to_target =
			now - entity.dynamic_data.movement.last_next_to_target

		dbg_mobf.fmovement_lvl3("MOBF:   time since next to target: " .. time_since_next_to_target ..
									" delay: " .. dump(entity.data.movement.teleportdelay) ..
									" teleportsupport: " .. dump(entity.dynamic_data.movement.teleportsupport))

		if (entity.dynamic_data.movement.teleportsupport) and
			time_since_next_to_target > entity.data.movement.teleportdelay then

			--check targetpos try to playe above if not valid
			local maxoffset = 5
			local current_offset = 0
			while (not environment.possible_pos(entity,{
												x=targetpos.x,
												y=targetpos.y + current_offset,
												z=targetpos.z
												})) and
				current_offset < maxoffset do
				dbg_mobf.fmovement_lvl2(
					"MOBF: teleport target within block trying above: " .. current_offset)
				current_offset = current_offset +1
			end

			targetpos.y = targetpos.y + current_offset

			--adjust to collisionbox of mob
			if entity.collisionbox[2] < -0.5 then
				targetpos.y = targetpos.y - (entity.collisionbox[2] + 0.49)
			end

			mobf_physics.setvelocity(entity, {x=0,y=0,z=0})
			mobf_physics.setacceleration(entity,{x=0,y=0,z=0})
			entity.object:moveto(targetpos)
			entity.dynamic_data.movement.last_next_to_target = now
			
			
			entity.dynamic_data.movement.target = nil
			if type(entity.dynamic_data.movement.reached_callback) == "function" then
				entity.dynamic_data.movement.reached_callback(entity, true)
			end
			
			entity.dynamic_data.movement.reached_callback = nil
			
			return true
		end
	end
	return false
end

-------------------------------------------------------------------------------
-- name: check_target(entity, basepos, targetpos, max_distance, now,
-- 						follow_speedup, dstep)
--
--! @brief check if target of non flying mob is reached by now
--! @memberof mgen_follow
--
--! @param entity mob to apply to
--! @param basepos ground position of mob
--! @param targetpos position of target
--! @param max_distance maximum acceptable distance to target
--! @param now current time
--! @param follow speedup speedup to use on following
--! @param dstep time since last call
-------------------------------------------------------------------------------
function mgen_follow.check_target(entity, basepos, targetpos,
									max_distance, now, follow_speedup, dstep)

	local distance = nil
	local height_distance = nil
	
	if entity.data.movement.canfly then

		--real pos is relevant not basepos for flying mobs
		--target for flying mobs is always slightly above it's target
		distance = vector.distance(entity.object:getpos(),
					{x=targetpos.x, y=(targetpos.y+1), z=targetpos.z })
		height_distance = entity.object:getpos().y - (targetpos.y+1)
	
	else
		distance = mobf_calc_distance_2d(basepos,targetpos)
	end
	
	--check if mob needs to move towards target
	dbg_mobf.fmovement_lvl3("MOBF:     mgen_follow.check_target: max distance is set to : "
							.. max_distance .. " dist: " .. distance)
	if distance > max_distance then
	
		if entity.dynamic_data.movement.follow_last_pos ~= nil then
			local distance_last_check = mobf_calc_distance_2d(entity.dynamic_data.movement.follow_last_pos,basepos)
		
			if ( distance_last_check < 0.1) then
				entity.dynamic_data.movement.follow_stuck_counter = 
					(entity.dynamic_data.movement.follow_stuck_counter or 0) + dstep
			else
				entity.dynamic_data.movement.follow_stuck_counter = 0
			end
			
			-- if stuck for 5 seconds give up
			if entity.dynamic_data.movement.follow_stuck_counter > 5 then
				entity.dynamic_data.movement.target = nil
			
				mgen_follow.clear_acceleration(entity, true)
			
				if (type(entity.dynamic_data.movement.reached_callback) == "function") then
					entity.dynamic_data.movement.reached_callback(entity, false)
					entity.dynamic_data.movement.reached_callback = nil
				end
				entity.dynamic_data.movement.follow_stuck_counter = 0
			end
		end
		
		entity.dynamic_data.movement.follow_last_pos = basepos
		
		--set last movement state
		entity.dynamic_data.movement.was_moving_last_step = true

		if mgen_follow.handleteleport(entity,now,targetpos) then
			return
		end

		dbg_mobf.fmovement_lvl3("MOBF:   distance:" .. distance)

		local current_state =
			mgen_follow.identify_movement_state(basepos,targetpos)
			
		local handled = false

		if handled == false and
			(current_state == "same_height_los" or
			current_state == "above_los" or
			current_state == "above_no_los" or
			current_state == "below_los" or
			current_state == "below_no_los" or
			current_state == "same_height_no_los") then
			dbg_mobf.fmovement_lvl3("MOBF: \t Case 1: " .. current_state)
			
			for i = 1 , 5 , 1 do
				local accel_to_set =
					movement_generic.get_accel_to(targetpos,entity,true)
					
				local predicted_pos = movement_generic.predict_next_block(basepos,
					mobf_physics.getvelocity(entity),accel_to_set)
					
				if mobf_calc_distance_2d(predicted_pos,targetpos) < distance then

					handled = mgen_follow.set_acceleration(entity,
														accel_to_set,
														follow_speedup,
														basepos)
				end
			end
		end

		if handled == false then
			dbg_mobf.fmovement_lvl1(
				"MOBF: \t Unexpected or unhandled movement state: "
				 .. current_state)
				 
			mgen_follow.clear_acceleration(entity, true)
				
			-- check for error count to abort following
			mgen_follow.update_and_check_error_count(entity)
		else
			dbg_mobf.fmovement_lvl3(
				"MOBF: \t resetting error counter")
			entity.dynamic_data.movement.follow_error_count = 0
		end
		
		
		--updating animation
		mgen_follow.update_animation(entity, "following")

	--nothing to do
	elseif entity.data.movement.canfly and math.abs(height_distance) > 0.1 then
	
		-- we can fly so just move towards target
		mgen_follow.set_acceleration(entity,
									{ x=0,y=(height_distance*-0.2),z=0},
									follow_speedup,
									basepos)
		mgen_follow.update_animation(entity, "following")
		
	--we're next to target stop movement
	else
		local yaccel = environment.get_default_gravity(basepos,
						entity.environment.media,
						entity.data.movement.canfly)
						
		local current_accel = mobf_physics.getacceleration(entity)
						
		if entity.dynamic_data.movement.was_moving_last_step == true or
			current_accel.Y ~= yaccel then

			dbg_mobf.fmovement_lvl1("MOBF: next to target: " ..
				dump(entity.dynamic_data.movement.target) ..
				" stopping: " .. dump(entity.dynamic_data.movement.stop_at_target))
			
			mgen_follow.clear_acceleration(entity, entity.dynamic_data.movement.stop_at_target)
			
			entity.dynamic_data.movement.last_next_to_target = now
			
			mgen_follow.update_animation(entity, "ntt")
			
			if type(entity.dynamic_data.movement.reached_callback) == "function" then
				entity.dynamic_data.movement.reached_callback(entity, true)
				entity.dynamic_data.movement.reached_callback = nil
			end
		end
	end
	
end

-------------------------------------------------------------------------------
-- name: env_check(entity)
--
--! @brief check and fix mob environment
--! @memberof mgen_follow
--
--! @param entity mob to generate movement for
-------------------------------------------------------------------------------
function mgen_follow.env_check(entity)


	local basepos  = entity:getbasepos()
	local pos_quality = environment.pos_quality(basepos,entity)

	if environment.evaluate_state(pos_quality, LT_GOOD_POS) or
		(entity.data.movement.canfly and
			environment.evaluate_state(pos_quality,LT_GOOD_FLY_POS)) then
		local toset = {
			x= basepos.x,
			y= basepos.y - 0.5 - entity.collisionbox[2],
			z= basepos.z }
		--save known good position
		entity.dynamic_data.movement.last_pos_in_env = toset
	end

	if pos_quality.media_quality == MQ_IN_AIR or                  -- wrong media
		pos_quality.media_quality == MQ_IN_WATER or               -- wrong media
		pos_quality.geometry_quality == GQ_NONE or                -- no ground contact (TODO this was drop above water before)
		pos_quality.surface_quality_center == SQ_WATER then       -- above water


		if entity.dynamic_data.movement.invalid_env_count == nil then
			entity.dynamic_data.movement.invalid_env_count = 0
		end

		entity.dynamic_data.movement.invalid_env_count =
			entity.dynamic_data.movement.invalid_env_count + 1


		-- don't change at first invalid pos but give some steps to cleanup by
		-- other less invasive mechanisms
		-- if error count tells fatal there's nothing left to be done
		if entity.dynamic_data.movement.invalid_env_count > 10 then
		
			dbg_mobf.fmovement_lvl1("MOBF: followed to wrong place " .. pos_quality.tostring(pos_quality))
			if entity.dynamic_data.movement.last_pos_in_env ~= nil then
				entity.object:moveto(entity.dynamic_data.movement.last_pos_in_env)
				basepos  = entity.getbasepos(entity)
			else
				local newpos = environment.get_suitable_pos_same_level(basepos,1,entity,true)

				if newpos == nil then
					newpos = environment.get_suitable_pos_same_level( {
																		x=basepos.x,
																		y=basepos.y-1,
																		z=basepos.z }
																		,1,entity,true)
				end

				if newpos == nil then
					newpos = environment.get_suitable_pos_same_level( {
																		x=basepos.x,
																		y=basepos.y+1,
																		z=basepos.z }
																		,1,entity,true)
				end

				if newpos == nil then
					dbg_mobf.fmovement_lvl1("MOBF: no way to fix it removing mob")
					spawning.remove(entity,"mgen_follow poscheck")
				else
					newpos.y = newpos.y - (entity.collisionbox[2] + 0.49)
					entity.object:moveto(newpos)
					basepos  = entity.getbasepos(entity)
				end
			end
		end
		
		if not mgen_follow.update_and_check_error_count(entity) then
			return false
		end
	else
		entity.dynamic_data.movement.invalid_env_count = 0
	end

	local current_accel = mobf_physics.getacceleration(entity)

	if pos_quality.level_quality ~= LQ_OK and
		entity.data.movement.canfly then
		

		if pos_quality.level_quality == LQ_ABOVE then
			if current_accel.y >= 0 then
				current_accel.y = - entity.data.movement.max_accel
			end
		end

		if pos_quality.level_quality == LQ_BELOW then
			if current_accel.y <= 0 then
				current_accel.y = entity.data.movement.max_accel
			end
		end

		mobf_physics.setacceleration(entity,current_accel)
		return false
	end

	return true
end

-------------------------------------------------------------------------------
-- name: get_target_pos(entity)
--
--! @brief get position of target
--! @memberof mgen_follow
--
--! @param entity mob to generate movement for
-------------------------------------------------------------------------------
function mgen_follow.get_target_pos(entity)
	local basepos  = entity:getbasepos()
	local targetpos = nil

	if entity.dynamic_data.movement.target ~= nil then
		dbg_mobf.fmovement_lvl3("MOBF:     mgen_follow.get_target_pos: have moving target")

		if not mobf_is_pos(entity.dynamic_data.movement.target) then
			targetpos = entity.dynamic_data.movement.target:getpos()
		else
			targetpos = entity.dynamic_data.movement.target
		end
	end

	if targetpos == nil and
		entity.dynamic_data.movement.guardspawnpoint == true then
		dbg_mobf.fmovement_lvl3("MOBF:     mgen_follow.get_target_pos: non target selected")
		targetpos = entity.dynamic_data.spawning.spawnpoint
	end

	if targetpos == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF: " .. entity.data.name
		.. " don't have targetpos "
		.. "SP: " .. dump(entity.dynamic_data.spawning.spawnpoint)
		.. " TGT: " .. dump(entity.dynamic_data.movement.target))
		return
	end
	
	if mobf_line_of_sight({x=basepos.x,y=basepos.y+1,z=basepos.z},
					 {x=targetpos.x,y=targetpos.y+1,z=targetpos.z})  == false then
		dbg_mobf.fmovement_lvl3("MOBF:     mgen_follow.get_target_pos: no line of sight (Ignored by now)")
		--TODO teleport support?
		--TODO other ways to handle this?
		--return
	end

	return targetpos
end

-------------------------------------------------------------------------------
-- name: callback(entity,now)
--
--! @brief main callback to make a mob follow its target
--! @memberof mgen_follow
--
--! @param entity mob to generate movement for
--! @param now current time
-------------------------------------------------------------------------------
function mgen_follow.callback(entity,now, dstep)

	dbg_mobf.fmovement_lvl3("MOBF: Follow mgen callback called")

	if entity == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: called movement gen without entity!")
		return
	end

	if entity.dynamic_data == nil or
		entity.dynamic_data.movement == nil then
		mobf_bug_warning(LOGLEVEL_ERROR,"MOBF BUG!!!: >" ..entity.data.name .. "< removed=" .. dump(entity.removed) .. " entity=" .. tostring(entity) .. " probab movement callback")
		return
	end


	local follow_speedup =  {x=10,y=2,z=10 }

	if entity.data.movement.follow_speedup ~= nil then
		if type(entity.data.movement.follow_speedup) == "table" then
			follow_speedup = entity.data.movement.follow_speedup
		else
			follow_speedup.x= entity.data.movement.follow_speedup
			follow_speedup.z= entity.data.movement.follow_speedup
		end
	end
	
	--if speedup is disabled reset
	if not entity.dynamic_data.movement.follow_speedup then
		follow_speedup = { x=1, y=1, z=1}
	end

	-- check max speed limit
	mgen_follow.checkspeed(entity)

	-- check environment
	if not mgen_follow.env_check(entity) then
		dbg_mobf.fmovement_lvl2("MOBF:   env_check tells we're done")
	end

	--fixup height fixup
	if entity.data.movement.canfly then
		if current_accel.y ~= 0 then
			current_accel.y = 0
			mobf_physics.setacceleration(entity,current_accel)
		end
	end

	-- check if there's a target
	if entity.dynamic_data.movement.target ~= nil or
		entity.dynamic_data.movement.guardspawnpoint then
		
		dbg_mobf.fmovement_lvl3("MOBF:   Target available")
		
		--calculate distance to target
		local targetpos = mgen_follow.get_target_pos(entity)
		local basepos  = entity:getbasepos()

		mgen_follow.check_target(entity, basepos, targetpos,
			entity.dynamic_data.movement.max_distance or 1.5, now, follow_speedup, dstep)

	else
		dbg_mobf.fmovement_lvl2("MOBF:   mgen_follow no target set?!")
		--TODO evaluate if this is an error case
	end
end

-------------------------------------------------------------------------------
-- name: update_animation()
--
--! @brief update animation according to the follow movegen substate
--! @memberof mgen_follow
--! @public
-------------------------------------------------------------------------------
function mgen_follow.update_animation(entity, anim_state)

	-- no need to change
	if anim_state == entity.dynamic_data.movement.anim_selected then
		return
	end

	-- check if there's a animation specified for stand in this state
	local statename, state = entity:get_state()
	
	if anim_state == "following" then
		entity.dynamic_data.movement.anim_selected = "following"
		
		if state.animation_walk ~= nil  then
			graphics.set_animation(entity, state.animation_walk)
		elseif state.animation ~= nil then
			graphics.set_animation(entity, state.animation)
		end
	elseif anim_state == "ntt" then
		entity.dynamic_data.movement.anim_selected = "ntt"
		
		if state.animation_next_to_target ~= nil then
			graphics.set_animation(entity, state.animation_next_to_target)
		end
	end
end

-------------------------------------------------------------------------------
-- name: next_block_ok()
--
--! @brief check quality of next block
--! @memberof mgen_follow
--! @public
-------------------------------------------------------------------------------
function mgen_follow.next_block_ok(entity,pos,acceleration,velocity)
	local current_velocity = velocity

	if current_velocity == nil then
		current_velocity = mobf_physics.getvelocity(entity)
	end

	local predicted_pos = movement_generic.predict_next_block(pos,current_velocity,acceleration)

	local quality = environment.pos_quality(predicted_pos,entity)
	
	local entity_properties = entity.object:get_properties()
	
	local quality_above = environment.pos_quality( 
							{x=predicted_pos.x, y=predicted_pos.y + entity_properties.stepheight, z=predicted_pos.z },
							entity)

	return (
			(quality.media_quality == MQ_IN_MEDIA) and
			(quality.level_quality == LQ_OK) and
			(
				(quality.surface_quality_min == Q_UNKNOWN) or
				(quality.surface_quality_min >= SQ_WRONG)
			)
		) or
		(
			(quality_above.media_quality == MQ_IN_MEDIA) and
			(quality_above.level_quality == LQ_OK) and
			(
				(quality_above.surface_quality_min == Q_UNKNOWN) or
				(quality_above.surface_quality_min >= SQ_WRONG)
			)
		)
end

-------------------------------------------------------------------------------
-- name: initialize()
--
--! @brief initialize movement generator
--! @memberof mgen_follow
--! @public
-------------------------------------------------------------------------------
function mgen_follow.initialize(entity,now)
	--intentionally empty
end

-------------------------------------------------------------------------------
-- name: init_dynamic_data(entity,now)
--
--! @brief initialize dynamic data required by movement generator
--! @memberof mgen_follow
--! @public
--
--! @param entity mob to initialize dynamic data
--! @param now current time
-------------------------------------------------------------------------------
function mgen_follow.init_dynamic_data(entity,now)

	local pos = entity.object:getpos()

	local data = {
			target = nil,
			guardspawnpoint = false,
			max_distance = entity.data.movement.max_distance,
			invalid_env_count = 0,
			follow_speedup = true,
			}

	if entity.data.movement.guardspawnpoint ~= nil and
		entity.data.movement.guardspawnpoint then
			dbg_mobf.fmovement_lvl3("MOBF: setting guard point to: " .. printpos(entity.dynamic_data.spawning.spawnpoint))
			data.guardspawnpoint = true
		end

		if entity.data.movement.teleportdelay~= nil then
			data.last_next_to_target = now
			data.teleportsupport = true
		end

	entity.dynamic_data.movement = data
end

-------------------------------------------------------------------------------
-- name: checkspeed(entity)
--
--! @brief check if mobs speed is within it's limits and correct if necessary
--! @memberof mgen_follow
--! @private
--
--! @param entity mob to initialize dynamic data
-------------------------------------------------------------------------------
function mgen_follow.checkspeed(entity)

	local current_velocity = mobf_physics.getvelocity(entity)

	local xzspeed =
		mobf_calc_scalar_speed(current_velocity.x,current_velocity.z)
		
	
	local max_speed = entity.data.movement.max_speed
	
	if mobf_physics.is_floating(entity) then
		max_speed = max_speed * 1.5
	end

	if (xzspeed > entity.data.movement.max_speed) then

		local direction = mobf_calc_yaw(current_velocity.x,
										current_velocity.z)

		--reduce speed to 90% of current speed
		local new_speed = mobf_calc_vector_components(direction,xzspeed*0.9)

		local current_accel = mobf_physics.getacceleration(entity)

		new_speed.y = current_velocity.y
		mobf_physics.setvelocity(entity,new_speed)
		mobf_physics.setacceleration(entity,{x=0,y=current_accel.y,z=0})

		return true
	end

	return false
end

-------------------------------------------------------------------------------
-- name: set_acceleration(entity,accel,speedup)
--
--! @brief apply acceleration to entity
--! @memberof mgen_follow
--! @private
--
--! @param entity mob to apply to
--! @param accel acceleration to set
--! @param speedup speedup factor
--! @param pos current position
-------------------------------------------------------------------------------
function mgen_follow.set_acceleration(entity,accel,speedup,pos)

	accel.x = accel.x*speedup.x
	accel.z = accel.z*speedup.z

	if entity.data.movement.canfly then
		accel.y = accel.y*speedup.y
	end

	-- check if accel to set would result in walking to invalid block
	if mgen_follow.next_block_ok(entity,pos,accel) then
		dbg_mobf.fmovement_lvl3("MOBF:   setting acceleration to: " .. printpos(accel));
		mobf_physics.setacceleration(entity,accel)
		return true
	-- check if not considering y accel would work
	elseif mgen_follow.next_block_ok(entity,pos,{x=accel.x,y=0,z=accel.z}) then
		dbg_mobf.fmovement_lvl3("MOBF:   setting acceleration to: " .. printpos(accel));
		mobf_physics.setacceleration(entity,accel)
		return true
	--check if not applying any acceleration and ignoring y velocity would work
	else
		dbg_mobf.fmovement_lvl1(
			"MOBF: \t acceleration " .. printpos(accel) ..
			" is invalid try stopping mob")
		
		local current_velocity = mobf_physics.getvelocity(entity)
		current_velocity.y = 0

		if mgen_follow.next_block_ok(entity,pos,{x=0,y=accel.y,z=0},current_velocity) then
			accel = {x=0,y=accel.y,z=0}
			mobf_physics.setvelocity(entity,current_velocity)
			mobf_physics.setacceleration(entity,accel)
			return false
		end
	end

	dbg_mobf.fmovement_lvl1(
		"MOBF: \t acceleration " .. printpos(accel) ..
		" is bad didn't find a way from getting to some invaid state!")

	return false
end

-------------------------------------------------------------------------------
-- name: set_target(entity, target, follow_speedup, max_distance)
--
--! @brief set target for movgen
--! @memberof mgen_follow
--
--! @param entity mob to apply to
--! @param target to set
--! @param follow_speedup --unused here
--! @param max_distance maximum distance to target to be tried to reach
--! @param reached_callback function to call if target is reached, or some permanent failure happened
-------------------------------------------------------------------------------
function mgen_follow.set_target(entity, target, follow_speedup, max_distance, reached_callback, stop)

	entity.dynamic_data.movement.target = target
	entity.dynamic_data.movement.follow_error_count = 0

	if type(follow_speedup) == "table" then
		local details = follow_speedup
		
		if details.stop ~= nil then
			entity.dynamic_data.movement.stop_at_target = details.stop
		end
		
		if target ~= nil and details.reached_callback ~= nil then
			entity.dynamic_data.movement.reached_callback = details.reached_callback
		else
			entity.dynamic_data.movement.reached_callback = nil
		end
		
		entity.dynamic_data.movement.max_distance = details.max_target_distance
	
-- legacy mode to be removed!
	else
		entity.dynamic_data.movement.max_distance = max_distance
		
		if stop ~= false then
			entity.dynamic_data.movement.stop_at_target = true
		end
		if target ~= nil then
			entity.dynamic_data.movement.reached_callback = reached_callback
		end
		
	end
	
	return true
end

-------------------------------------------------------------------------------
-- name: update_and_check_error_count(entity)
--
--! @brief increase error count and do apropriate actions in case of problems
--! @memberof mgen_follow
--
--! @param entity mob to check
--! @return true = no problem false = problem
-------------------------------------------------------------------------------
function mgen_follow.update_and_check_error_count(entity)

	entity.dynamic_data.movement.follow_error_count = 
		(entity.dynamic_data.movement.follow_error_count or 0) + 1
		
	if entity.dynamic_data.movement.follow_error_count and
			entity.dynamic_data.movement.follow_error_count > 25 then
		
		if type(entity.dynamic_data.movement.reached_callback) == "function" then
			entity.dynamic_data.movement.target = nil
			
			mgen_follow.clear_acceleration(entity, true)
			
			entity.dynamic_data.movement.reached_callback(entity, false)
			
			entity.dynamic_data.movement.reached_callback = nil
		end
		
		return false
	end
	
	return true
end

-------------------------------------------------------------------------------
-- name: clear_acceleration(entity, velocity_too)
--
--! @brief don't do any check just stop acceleratin/moving the mob
--! @memberof mgen_follow
--
--! @param entity mob to reset
--! @param velocity_too reset velocity too?
-------------------------------------------------------------------------------
function mgen_follow.clear_acceleration(entity, velocity_too)

	local yaccel = environment.get_default_gravity(entity:getbasepos(),
			entity.environment.media,
			entity.data.movement.canfly)
	

	entity.object:setacceleration({ x=0, y=yaccel, z=0})
	
	if velocity_too == true then
		mobf_physics.setvelocity(entity, {x=0, y=0, z=0})
	end
end

--register this movement generator
registerMovementGen(mgen_follow.name,mgen_follow)