--[[
 tune.lua - lens tuning example.
 
 This focuses on ion #6.

 The electrode tuning resembles a binary search.  It searches for an
 electrode voltage that causes ions to hit within a certain radius.
 The search terminates when the goal is reached or the maximum permitted
 number of tries is exceeded.
 
 See also tune_binaryoptlib.lua for a more convenient to use version of
 this.

 (c) 2006-2011 Scientific Instrument Services, Inc. (Licensed SIMION 8.0/8.1)
--]]

simion.workbench_program()

--===== variables

adjustable max_voltage = 1000        -- tuning voltage upper bound
adjustable min_voltage = 0           -- tuning voltage lower bound
adjustable _abs_goal_for_y = 0.001   -- goal for abs(y) bounds
adjustable max_tries = 20            -- rerun limit
 
adjustable test_voltage = 900        -- electrode voltage (current run)
adjustable upper_volts = 0           -- last upper bound voltage
adjustable lower_volts = 0           -- last lower bound voltage
adjustable upper_y = 0               -- last upper y hit
adjustable lower_y = 0               -- last lower y hit

local ysave                          -- y splat recorded in last run


-- called on Fly'm and expected to initiate runs by calling `run()`.
function segment.flym()
  sim_trajectory_image_control = 1 -- don't preserve trajectories

  -- Perform runs.
  upper_volts = min_voltage
  lower_volts = max_voltage
  local is_goal_reached
  for i=1, max_tries do
    ysave = nil -- reset for next run

    -- Perform run.
    if i == 1 then  -- First run.
      test_voltage = upper_volts
      run()
      upper_y = ysave  -- save results
    elseif i == 2 then  -- Second run.
      test_voltage = lower_volts
      run()
      lower_y = ysave  -- save results
      -- swap
      if upper_y <= lower_y then
        upper_volts, lower_volts = lower_volts, upper_volts
      end
    else -- Subsequent runs (at mid-point voltage)
      test_voltage = (lower_volts + upper_volts) / 2
      run()
      if ysave < 0 then   -- reverse tuning
        lower_volts = test_voltage
      else                -- direct tuning
        upper_volts = test_voltage
      end
    end

    -- Display results.
    print("n = "..i..", y = "..ysave..", volts = "..test_voltage) 

    -- Is goal reached?
    if abs(ysave) <= _abs_goal_for_y then
      print("Attained Tuning Goal of ", _abs_goal_for_y)
      print("Final Rerun to Save Trajectories")
      is_goal_reached = true
      break
    end
  end
  if not is_goal_reached then
    print("Aborted: Hit Loop Limit")
    error("Aborted: Hit Loop Limit")
  end
  
  -- Do one last run, keeping trajectories.
  sim_trajectory_image_control = 0  -- keep trajectories
  run()
  
  sim_retain_changed_potentials = 1 -- keep last (tuned) voltages.
end


-- called exactly once on start of each run.
local first
function segment.initialize_run()
  first = true
end


-- called multiple times per time-step to adjust voltages.
function segment.fast_adjust()
  adj_elect02 = test_voltage
end


-- called on every time-step for each particle in PA instance.
function segment.other_actions()
  -- Update the PE surface display on first time-step of run.
  if first then first = false; sim_update_pe_surface = 1 end
end
 

-- called on each particle termination inside a PA instance.
function segment.terminate()
  if ion_number ==6 then  -- tune only on ion 6
    ysave = ion_py_mm    
  end
end


-- called exactly once on end of each run termination.
function segment.terminate_run()
end


--[[
 Footnotes:
 [1] The flym/initialize_run/terminate_run segments are new in SIMION 8.1.0.40.
     See "Workbench Program Extensions in SIMION 8.1" in the supplemental
     documentation (Help menu).
--]]
