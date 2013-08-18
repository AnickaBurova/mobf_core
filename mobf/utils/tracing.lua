-------------------------------------------------------------------------------
-- Mob Framework Mod by Sapier
-- 
-- You may copy, use, modify or do nearly anything except removing this
-- copyright notice. 
-- And of course you are NOT allow to pretend you have written it.
--
--! @file tracing.lua
--! @brief generic functions used in many different places
--! @copyright Sapier
--! @author Sapier
--! @date 2013-02-04
--!
-- Contact sapier a t gmx net
-------------------------------------------------------------------------------

--! @defgroup gen_func Generic functions
--! @brief functions for various tasks
--! @ingroup framework_int
--! @{

callback_statistics = {}

statistics = {}
statistics.total = 0
statistics.abms = 0
statistics.onstep = 0
statistics.mapgen = 0
statistics.lastcalc = 0
statistics.activate = 0
statistics.punch = 0
statistics.spawn_onstep = 0
statistics.data = {}
statistics.data.total        = { current=0,maxabs=0,max=0 }
statistics.data.abm          = { current=0,maxabs=0,max=0 }
statistics.data.onstep       = { current=0,maxabs=0,max=0 }
statistics.data.mapgen       = { current=0,maxabs=0,max=0 }
statistics.data.activate     = { current=0,maxabs=0,max=0 }
statistics.data.punch        = { current=0,maxabs=0,max=0 }
statistics.data.mobs         = { current=0,maxabs=" ",max=0 }
statistics.data.spawn_onstep = { current=0,maxabs=0,max=0 }

-------------------------------------------------------------------------------
-- name: mobf_statistic_calc()
--
--! @brief periodic update statistics
--
-------------------------------------------------------------------------------
function mobf_statistic_calc(dtime)
	local now = mobf_get_time_ms()
	if statistics.lastcalc == nil or now > statistics.lastcalc + 30000 then
		local delta = now - statistics.lastcalc
		local current_total  = (statistics.total/delta)*100
		local current_abm    = (statistics.abms/delta)*100
		local current_onstep = (statistics.onstep/delta)*100
		local current_mapgen = (statistics.mapgen/delta)*100
		local current_activate = (statistics.activate/delta)*100
		local current_punch  = (statistics.punch/delta)*100
		local current_spawn_onstep  = (statistics.spawn_onstep/delta)*100
		
		local active_mobs = 1
		for index,value in pairs(minetest.luaentities) do 
			if value.data ~= nil and value.data.name ~= nil then
				active_mobs = active_mobs +1
			end
		end
		
		statistics.total = 0
		statistics.abms = 0
		statistics.onstep = 0
		statistics.mapgen = 0
		statistics.activate = 0
		statistics.punch = 0
		statistics.spawn_onstep = 0
	
		statistics.data.total.current = current_total
		statistics.data.total.maxabs = MAX(statistics.data.total.maxabs, math.floor(current_total*300))
		statistics.data.total.max = MAX(statistics.data.total.max,current_total)
		
		statistics.data.abm.current = current_abm
		statistics.data.abm.maxabs = MAX(statistics.data.abm.maxabs, math.floor(current_abm*300))
		statistics.data.abm.max = MAX(statistics.data.abm.max,current_abm)
		
		statistics.data.onstep.current = current_onstep
		statistics.data.onstep.maxabs = MAX(statistics.data.onstep.maxabs, math.floor(current_onstep*300))
		statistics.data.onstep.max = MAX(statistics.data.onstep.max,current_onstep)
		
		statistics.data.mapgen.current = current_mapgen
		statistics.data.mapgen.maxabs = MAX(statistics.data.mapgen.maxabs, math.floor(current_mapgen*300))
		statistics.data.mapgen.max = MAX(statistics.data.mapgen.max,current_mapgen)
		
		statistics.data.activate.current = current_activate
		statistics.data.activate.maxabs = MAX(statistics.data.activate.maxabs, math.floor(current_activate*300))
		statistics.data.activate.max = MAX(statistics.data.activate.max,current_activate)
		
		statistics.data.punch.current = current_punch
		statistics.data.punch.maxabs = MAX(statistics.data.punch.maxabs, math.floor(current_punch*300))
		statistics.data.punch.max = MAX(statistics.data.punch.max,current_punch)
		
		statistics.data.spawn_onstep.current = current_spawn_onstep
		statistics.data.spawn_onstep.maxabs = MAX(statistics.data.spawn_onstep.maxabs, math.floor(current_spawn_onstep*300))
		statistics.data.spawn_onstep.max = MAX(statistics.data.spawn_onstep.max,current_spawn_onstep)
		
		statistics.data.mobs.current = active_mobs
		statistics.data.mobs.max = MAX(statistics.data.mobs.max,active_mobs)
		
		statistics.lastcalc = now
	end
end

-------------------------------------------------------------------------------
-- name: mobf_warn_long_fct(starttime,fctname,facility)
--
--! @brief alias to get current time
--
--! @param starttime time fct started
--! @param fctname name of function
--! @param facility name of facility to add time to
--
--! @return current time in seconds
-------------------------------------------------------------------------------
function mobf_warn_long_fct(starttime,fctname,facility)
	local currenttime = mobf_get_time_ms()
	local delta = currenttime - starttime
	
	if delta > 0 and minetest.world_setting_get("mobf_enable_statistics") then
		if facility == "abm" then
			statistics.abms = statistics.abms + delta
			statistics.total = statistics.total + delta
		end
		
		if facility == "on_step_total" then
			statistics.onstep = statistics.onstep + delta
			statistics.total = statistics.total + delta
		end
		
		if facility == "mapgen" then
			statistics.mapgen = statistics.mapgen + delta
			statistics.total = statistics.total + delta
		end
		
		if facility == "spawn_onstep" then
			statistics.spawn_onstep = statistics.spawn_onstep + delta
			statistics.total = statistics.total + delta
		end
		
		if facility == "onpunch_total" then
			statistics.punch = statistics.punch + delta
			statistics.total = statistics.total + delta
		end
		
		if facility == "onactivate_total" then
			statistics.activate = statistics.activate + delta
			statistics.total = statistics.total + delta
		end
	end
	
	if minetest.world_setting_get("mobf_enable_callback_statistics") then
		if facility == nil then
			facility = "generic"
		end
		
		if callback_statistics[facility] == nil then
			callback_statistics[facility] = {
				upto_005ms = 0,
				upto_010ms = 0,
				upto_020ms = 0,
				upto_050ms = 0,
				upto_100ms = 0,
				upto_200ms = 0,
				more       = 0,
				valcount   = 0,
				sum        = 0,
				last_time  = 0,
			}
		end
		
		callback_statistics[facility].valcount = callback_statistics[facility].valcount +1
		callback_statistics[facility].sum = callback_statistics[facility].sum + delta
		
		if callback_statistics[facility].valcount == 1000 then
			callback_statistics[facility].valcount = 0
			local deltatime = currenttime - callback_statistics[facility].last_time
			callback_statistics[facility].last_time = currenttime
			
			minetest.log(LOGLEVEL_ERROR,"Statistics for: " .. facility .. ": " .. 
										callback_statistics[facility].upto_005ms .. "," ..
										callback_statistics[facility].upto_010ms .. "," ..
										callback_statistics[facility].upto_020ms .. "," ..
										callback_statistics[facility].upto_050ms .. "," ..
										callback_statistics[facility].upto_100ms .. "," ..
										callback_statistics[facility].upto_200ms .. "," ..
										callback_statistics[facility].more .. 
										" (".. callback_statistics[facility].sum .. " / " .. deltatime .. ") " ..
										tostring(math.floor((callback_statistics[facility].sum/deltatime) * 100)) .. "%")
										
			callback_statistics[facility].sum = 0
		end
		
		if delta < 5 then
			callback_statistics[facility].upto_005ms = callback_statistics[facility].upto_005ms +1
			return
		end
		if delta < 10 then
			callback_statistics[facility].upto_010ms = callback_statistics[facility].upto_010ms +1
			return
		end
		if delta < 20 then
			callback_statistics[facility].upto_020ms = callback_statistics[facility].upto_020ms +1
			return
		end
		if delta < 50 then
			callback_statistics[facility].upto_050ms = callback_statistics[facility].upto_050ms +1
			return
		end
		if delta < 100 then
			callback_statistics[facility].upto_100ms = callback_statistics[facility].upto_100ms +1
			return
		end
		
		if delta < 200 then
			callback_statistics[facility].upto_200ms = callback_statistics[facility].upto_200ms +1
			return
		end
		
		callback_statistics[facility].more = callback_statistics[facility].more +1
	end
	
	if delta >200 then
		minetest.log(LOGLEVEL_ERROR,"MOBF: function " .. fctname .. " took too long: " .. delta .. " ms")
	end
end

-------------------------------------------------------------------------------
-- name: mobf_bug_warning()
--
--! @brief make bug warnings configurable
--
--! @param level bug severity level to use for minetest.log
--! @param text data to print to log
-------------------------------------------------------------------------------
function mobf_bug_warning(level,text)
	if minetest.world_setting_get("mobf_log_bug_warnings") then
		minetest.log(level,text)
	end
end

--initialize statistics
if minetest.world_setting_get("mobf_enable_statistics") then
	minetest.register_globalstep(mobf_statistic_calc)
end

--!@}