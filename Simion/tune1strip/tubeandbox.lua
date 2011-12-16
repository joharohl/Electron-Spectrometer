simion.workbench_program()
 
--adjustables
adjustable _cem_voltage      	= 200
adjustable _strip1_width_min 	= 30
adjustable _strip1_width_max 	= 90
adjustable _step_width       	= 4
adjustable _strip1_voltage_min  = 0
adjustable _strip1_voltage_max  = 20
adjustable _ke_min 		= 0
adjustable _ke_max		= 50
adjustable _ke_step		= 0.5
adjustable _step_voltage	= 1
adjustable _num_electrons 	= 1000
  
--local "constants"
local strip1_set_voltage = 0
local ke_set = 0
local last_fitness = 0

local iob_width = 360
local iob_height = 92
local iob_length = 200 

--channeltron radius and position. (is used to calculate ion splat inside or outside channeltron)
local Rc = 30
local Xc = 355
local Yc = 46
local Zc = 100 
         
-- used to find out how many electrons actually made it into the box
local start_of_box = 151
            
local splats = {}
           
-- clear the splats.    
local function clearSplats()
	for i=1, _num_electrons do
		splats[i].x = 0;
    	splats[i].y = 0;
		splats[i].z = 0;
	end
end 
                                      
-- update a geom particle for an iteration
local function UpdateGemFile()
   		pa = simion.open_gem('tubeandbox.gem'):to_pa()
		-- TODO: this function not yet documented
	
	    pa:save('tubeandbox.pa#')
	    pa:close()
      
		-- reload in workbench
		simion.wb.instances[1].pa:load('tubeandbox.pa#')

	    -- refine PA# file.
		simion.wb.instances[1].pa:refine()  
		
end

-- create a logger class
local logfile = function(filename)   
  local fh = assert(io.open(filename, "a"))
  fh:write(('Start of new run - %s\n'):format(os.date()))

  local self = {}
  
  function self:add_line(text)
    fh:write(('%s\n'):format(text))
    self:flush()
  end
  function self:close()
    fh:write('end of Run\n')
	fh:write('-----------------------------------\n')
    fh:close()
  end
  function self:flush()
	fh:flush()
  end
  return self
end

-- init everything.
local function init()
          
	-- init splats
	for i=1, _num_electrons do
		splats[i] = {};
		splats[i].x = 0;
		splats[i].y = 0;
		splats[i].z = 0;
	end
 
end 
    


function segment.flym()
	init()
	local logger = logfile(("log-%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	logger:add_line("width, voltage, fitness")
	      
   	for i=1, (_strip1_width_max-_strip1_width_min)/_step_width do
		_G.s1 = _strip1_width_min +_step_width*(i-1)
		UpdateGemFile()

		for j=1, (_strip1_voltage_max - _strip1_voltage_min)/_step_voltage do
			strip1_set_voltage = _strip1_voltage_min+(j-1)*_step_voltage

			for k=1, (_ke_max - _ke_min)/_ke_step do
				ke_set = _ke_min + (k-1)*_ke_step

				run()
				logger:add_line(_G.s1 .. ", " .. strip1_set_voltage .. ", " .. ke_set .. ", " .. last_fitness)
			
				clearSplats()
			end
		end
	end 	
end

--runs at start of each run. zeros splats.
function segment.initialize_run()
    
end 

--runs at end of each run. Update the particle-values.
function segment.terminate_run()
	local Rs                 
	local Rmax
	
	local num_electrons_inside_cem = 0
	local num_electrons_inside_box = 0
	
	for i=1, _num_electrons do
		Rmax = Xc -splats[i].x
		Rs = math.sqrt((splats[i].y-Yc)^2 + (splats[i].z-Zc)^2)
		
		if splats[i].x > start_of_box then
			num_electrons_inside_box = num_electrons_inside_box + 1
			
			if Rs < Rmax and Rmax < Rc then
				num_electrons_inside_cem = num_electrons_inside_cem + 1
			end
		end
		
		
	    --print("n=" .. i ..
	    --	  " ,x=" .. splats[i].x ..
	    --   " ,y=" .. splats[i].y ..
	    --   " ,z=" .. splats[i].z)
	    --print("Rs=" .. Rs .. 
	    --	  ", Rmax=" .. Rmax)
	 end
	
	print(num_electrons_inside_cem .. " " .. num_electrons_inside_box)


	 -- Print out the statistics.
	 last_fitness = num_electrons_inside_cem/num_electrons_inside_box
	
end

-- SIMION initialize segment.  Called on particle creation.
-- Not used at the moment
function segment.initialize()
	
	-- Convert ion velocity to 3-D polar coordinates.
    	local speed, az_angle, el_angle = rect3d_to_polar3d(ion_vx_mm, ion_vy_mm, ion_vz_mm)	
	--update speed.
	speed = ke_to_speed(ke_set, ion_mass)
	-- get the new xyz components.
	ion_vx_mm, ion_vy_mm, ion_vz_mm = polar3d_to_rect3d(speed, az_angle, el_angle)
							
end  
                         
-- SIMION fast_adjust segment. Called multiple times per time-step
-- to adjust voltages.
-- Does not do anything at the moment.
function segment.fast_adjust()
   	  --change the elctrode values to the current particles optimization values.	
	adj_elect02 = strip1_set_voltage
	--adj_elect03 = particle_swarm_voltage[particle_counter_voltage].current_conf.s2
	--adj_elect04 = particle_swarm_voltage[particle_counter_voltage].current_conf.s3
	adj_elect06 = _cem_voltage
end
 
--runs at start of each run. update voltages.
function init_p_values()

end
    
-- runs when all ions have splatted but once for every ion. save the data to the arrays.
function segment.terminate()                  
	splats[ion_number].x = ion_px_gu
	splats[ion_number].y = ion_py_gu
	splats[ion_number].z = ion_pz_gu
end

-- runs at every timestep. Just checks for out of bounds splats.
function segment.other_actions()
	--just a sanity check. if the particle is very close to get out of the pa. splat it.
	if ion_px_gu < 0.1 or ion_px_gu > iob_width-0.1 then
		ion_splat = -1
	end
	
	if ion_py_gu < 0.1 or ion_py_gu > iob_height-0.1 then
		ion_splat = -1
	end
	   
	if ion_pz_gu < 0.1 or ion_pz_gu > iob_length-0.1 then
		ion_splat = -1
	end                                         
end 
