simion.workbench_program()
 
--adjustables
adjustable _max_voltage_iterations 	= 1000
adjustable _max_geom_iterations 	= 10000000
adjustable _num_electrons 		= 1000
adjustable _num_voltage_particles 	= 10
adjustable _num_geom_particles 		= 20
adjustable _cem_voltage  		= 200
adjustable _fitness_goal_voltage 	= 1
adjustable _fitness_goal_geom 		= 1

adjustable _w_voltage 	= 0.9
adjustable _ph1_voltage = 0.3
adjustable _ph2_voltage = 0.5

adjustable _w_geom 	 = 0.9
adjustable _ph1_geom = 0.3
adjustable _ph2_geom = 0.5

adjustable _min_strip1_width = 25
adjustable _min_strip2_width = 50
adjustable _min_strip3_width = 100
  
--local variables
local particle_counter_voltage = 1
local iteration_counter_voltage = 0

local particle_counter_geom = 1
local iteration_counter_geom = 0

local last_change_voltage = 0 
     
--local "constants"
local iob_width = 256
local iob_height = 92
local iob_length = 200 

--channeltron radius and position. (is used to calculate ion splat inside or outside channeltron)
local Rc = 30
local Xc = 215
local Yc = 46
local Zc = 100 
         
-- used to find out how many electrons actually made it into the box
local start_of_box = 120
            
-- local Tables
local particle_swarm_voltage = {}
local global_best_conf_voltage = {}

local particle_swarm_geom = {}
local global_best_conf_geom = {}                  

local splats = {}
           
     
-- init voltage particles 
local function initVoltageParticles()

	--init particles for voltage PSO
	global_best_conf_voltage.fitness = 0
	global_best_conf_voltage.s1 = 0 
	global_best_conf_voltage.s2 = 0 
	global_best_conf_voltage.s3 = 0 

	for i=1, _num_voltage_particles do
		particle_swarm_voltage[i] = {}

		particle_swarm_voltage[i].current_conf = {}
		particle_swarm_voltage[i].current_conf.s1 = math.random(0,_cem_voltage)
		particle_swarm_voltage[i].current_conf.s2 = math.random(0,_cem_voltage)
		particle_swarm_voltage[i].current_conf.s3 = math.random(0,_cem_voltage)
		particle_swarm_voltage[i].current_conf.Vs1 = math.random(-_cem_voltage,_cem_voltage)
		particle_swarm_voltage[i].current_conf.Vs2 = math.random(-_cem_voltage,_cem_voltage)
		particle_swarm_voltage[i].current_conf.Vs3 = math.random(-_cem_voltage,_cem_voltage)

		particle_swarm_voltage[i].best_conf = {}
		particle_swarm_voltage[i].best_conf.s1 = particle_swarm_voltage[i].current_conf.s1
		particle_swarm_voltage[i].best_conf.s2 = particle_swarm_voltage[i].current_conf.s2
		particle_swarm_voltage[i].best_conf.s3 = particle_swarm_voltage[i].current_conf.s3
		particle_swarm_voltage[i].best_conf.Vs1 = particle_swarm_voltage[i].current_conf.Vs1
		particle_swarm_voltage[i].best_conf.Vs2 = particle_swarm_voltage[i].current_conf.Vs2
		particle_swarm_voltage[i].best_conf.Vs3 = particle_swarm_voltage[i].current_conf.Vs3

		particle_swarm_voltage[i].best_fitness = 0
		particle_swarm_voltage[i].current_fitness = 0
	end
	
end
 
local function initGeomParticles()
	--init particles for geom PSO
	global_best_conf_geom.fitness = 0
	global_best_conf_geom.s1 = 0 
	global_best_conf_geom.s2 = 0 
	global_best_conf_geom.s3 = 0 

	for i=1, _num_geom_particles do
		particle_swarm_geom[i] = {}
		
		p = particle_swarm_geom[i]

		p.current_conf = {}
		p.current_conf.s3 = math.random(_min_strip3_width, iob_length-10)
		p.current_conf.s2 = math.random(_min_strip2_width, p.current_conf.s3)
		p.current_conf.s1 = math.random(_min_strip1_width, p.current_conf.s2)
		p.current_conf.Vs1 = math.random( -(iob_length - _min_strip1_width),(iob_length - _min_strip1_width) )
		p.current_conf.Vs2 = math.random( -(iob_length - _min_strip2_width),(iob_length - _min_strip2_width) )
		p.current_conf.Vs3 = math.random( -(iob_length - _min_strip3_width),(iob_length - _min_strip3_width) )

		p.best_conf = {}
		p.best_conf.s1 = p.current_conf.s1
		p.best_conf.s2 = p.current_conf.s2
		p.best_conf.s3 = p.current_conf.s3
		p.best_conf.Vs1 = p.current_conf.Vs1
		p.best_conf.Vs2 = p.current_conf.Vs2
		p.best_conf.Vs3 = p.current_conf.Vs3

		p.best_fitness = 0
		p.current_fitness = 0
	end
	
end
             
-- clear the splats.    
local function clearSplats()
	for i=1, _num_electrons do
		splats[i].x = 0;
    	splats[i].y = 0;
		splats[i].z = 0;
	end
end 

--do pso algorithm for the voltage part.
local function psoVoltageUpdate(logger, logger_debug)
   	--evaluate the fitness value for the different particles
	--and update the local and global best values.
	for i=1, _num_voltage_particles do
		local p = particle_swarm_voltage[i]
		
		if  p.current_fitness > p.best_fitness then
			p.best_fitness = p.current_fitness
			p.best_conf.s1 = p.current_conf.s1
			p.best_conf.s2 = p.current_conf.s2
			p.best_conf.s3 = p.current_conf.s3
		end
		
		if p.current_fitness > global_best_conf_voltage.fitness then
			global_best_conf_voltage.fitness = p.best_fitness
			global_best_conf_voltage.s1 = p.best_conf.s1
			global_best_conf_voltage.s2 = p.best_conf.s2
			global_best_conf_voltage.s3 = p.best_conf.s3
			last_change_voltage = iteration_counter_voltage
		end
	end	
	
	--print the fitness values for all the particles
	for i=1, _num_voltage_particles do
		logger_debug:add_line(	i .. "\t" ..
					particle_swarm_voltage[i].current_fitness .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.s1 .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.s2 .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.s3 .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.Vs1 .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.Vs2 .. "\t" ..
			  		particle_swarm_voltage[i].current_conf.Vs3)
	end
		
	--print the global best 
	print("best_conf_fitness=" .. global_best_conf_voltage.fitness ..
		  " ,e1=" .. global_best_conf_voltage.s1 ..
		  " ,e2=" .. global_best_conf_voltage.s2 ..
		  " ,e3=" .. global_best_conf_voltage.s3)			
		   
	--log the global best to file.
	logger:add_line("iterationVoltage no=" .. iteration_counter_voltage ..
					", best_conf_fitness=" .. global_best_conf_voltage.fitness ..
		  			" ,e1=" .. global_best_conf_voltage.s1 ..
		  			" ,e2=" .. global_best_conf_voltage.s2 ..
		  			" ,e3=" .. global_best_conf_voltage.s3)

	--update the particles for new values using a PSO algorithm                
	for i=1, _num_voltage_particles do
		local p = particle_swarm_voltage[i]
		local rp = math.random()
		local rg = math.random()
		
		p.current_conf.Vs1 = _w_voltage*p.current_conf.Vs1 + _ph1_voltage*rp*(p.best_conf.s1-p.current_conf.s1) + _ph2_voltage*rg*(global_best_conf_voltage.s1-p.current_conf.s1)  
        p.current_conf.Vs2 = _w_voltage*p.current_conf.Vs2 + _ph1_voltage*rp*(p.best_conf.s2-p.current_conf.s2) + _ph2_voltage*rg*(global_best_conf_voltage.s2-p.current_conf.s2)
		p.current_conf.Vs3 = _w_voltage*p.current_conf.Vs3 + _ph1_voltage*rp*(p.best_conf.s3-p.current_conf.s3) + _ph2_voltage*rg*(global_best_conf_voltage.s3-p.current_conf.s3)
		
		p.current_conf.s1 = p.current_conf.s1 + p.current_conf.Vs1
		p.current_conf.s2 = p.current_conf.s2 + p.current_conf.Vs2
		p.current_conf.s3 = p.current_conf.s3 + p.current_conf.Vs3
		  
		--check so voltages are not aout of bounds
		if p.current_conf.s1 > _cem_voltage then
			 p.current_conf.s1 = _cem_voltage
		elseif p.current_conf.s1 < 0 then
			p.current_conf.s1 = 0
		end
		
		if p.current_conf.s2 > _cem_voltage then
			 p.current_conf.s2 = _cem_voltage
		elseif p.current_conf.s2 < 0 then
			p.current_conf.s2 = 0
		end
		
		if p.current_conf.s3 > _cem_voltage then
			 p.current_conf.s3 = _cem_voltage
		elseif p.current_conf.s3 < 0 then
			p.current_conf.s3 = 0
		end
		
	end
 
end

-- do pso algorithm for geom particles 
local function psoGeomUpdate(logger, logger_debug)
   	
	-- check for a new global best.
	for i=1, _num_geom_particles do
		p = particle_swarm_geom[i]
		
		if p.best_fitness > global_best_conf_geom.fitness then
			global_best_conf_geom.fitness = p.best_fitness
			global_best_conf_geom.s1 = p.best_conf.s1   
	        	global_best_conf_geom.s2 = p.best_conf.s2
			global_best_conf_geom.s3 = p.best_conf.s3
		end
	end
	
	--print the fitness values for all the particles
	for i=1, _num_geom_particles do
		p = particle_swarm_geom[i]
		logger_debug:add_line(	i .. "\t" ..
					p.current_fitness .. "\t" ..
			  		p.current_conf.s1 .. "\t" ..
			  		p.current_conf.s2 .. "\t" ..
			  		p.current_conf.s3 .. "\t" ..
			  		p.current_conf.Vs1 .. "\t" ..
			  		p.current_conf.Vs2 .. "\t" ..
			  		p.current_conf.Vs3)
	end
		
	--print the global best 
	print("best_conf_fitness_geom=" .. global_best_conf_geom.fitness ..
		  " ,e1=" .. global_best_conf_geom.s1 ..
		  " ,e2=" .. global_best_conf_geom.s2 ..
		  " ,e3=" .. global_best_conf_geom.s3)			
		   
	--log the global best to file.
	logger:add_line("iterationGeom no=" .. iteration_counter_geom ..
					", best_conf_fitness=" .. global_best_conf_geom.fitness ..
		  			" ,e1=" .. global_best_conf_geom.s1 ..
		  			" ,e2=" .. global_best_conf_geom.s2 ..
		  			" ,e3=" .. global_best_conf_geom.s3)

	--update the particles for new values using a PSO algorithm                
	for i=1, _num_geom_particles do
		local p = particle_swarm_geom[i]
		local rp = math.random()
		local rg = math.random()
		
		p.current_conf.Vs1 = _w_geom*p.current_conf.Vs1 + _ph1_geom*rp*(p.best_conf.s1-p.current_conf.s1) + _ph2_geom*rg*(global_best_conf_geom.s1-p.current_conf.s1)  
        p.current_conf.Vs2 = _w_geom*p.current_conf.Vs2 + _ph1_geom*rp*(p.best_conf.s2-p.current_conf.s2) + _ph2_geom*rg*(global_best_conf_geom.s2-p.current_conf.s2)
		p.current_conf.Vs3 = _w_geom*p.current_conf.Vs3 + _ph1_geom*rp*(p.best_conf.s3-p.current_conf.s3) + _ph2_geom*rg*(global_best_conf_geom.s3-p.current_conf.s3)
		
		p.current_conf.s1 = p.current_conf.s1 + p.current_conf.Vs1
		p.current_conf.s2 = p.current_conf.s2 + p.current_conf.Vs2
		p.current_conf.s3 = p.current_conf.s3 + p.current_conf.Vs3
		  
		--check so widths are not out of bounds
		if p.current_conf.s3 > iob_length-10 then
			 p.current_conf.s3 = iob_length-10
		elseif p.current_conf.s3 < _min_strip3_width then
			p.current_conf.s3 = _min_strip3_width
		end
		 
		if p.current_conf.s2 > iob_length - _min_strip3_width then
			 p.current_conf.s2 =  iob_length - _min_strip3_width
		elseif p.current_conf.s2 < _min_strip2_width then
			p.current_conf.s2 = _min_strip2_width
		end
		
		
		if p.current_conf.s1 > iob_length - _min_strip2_width then
			 p.current_conf.s1 = iob_length - _min_strip2_width
		elseif p.current_conf.s1 < _min_strip1_width then
			p.current_conf.s1 = _min_strip1_width
		end
				
	end
 
end
                                      
-- update a geom particle for an iteration
local function geomUpdateGemFile()
   	
    -- prepare for the next particle (i.e. change the gem and build and refine it)
	
	p = particle_swarm_geom[particle_counter_geom]   
	-- convert GEM file to PA# file.
	_G.s1 = p.current_conf.s1
	_G.s2 = p.current_conf.s2
	_G.s3 = p.current_conf.s3  
	
	--simion.experimental.gemrefine('tubeandbox.gem', 'tubeandbox.pa#', 0.1)
  
	local pa = simion.open_gem('tubeandbox.gem'):to_pa()
	      -- TODO: this function not yet documented
	pa:save('tubeandbox.pa#')
	pa:close()

	--simion.command("refine --convergence=0.5 tubeandbox.pa#")

	-- reload in workbench
	simion.wb.instances[1].pa:load('tubeandbox.pa#')

    	-- refine PA# file.
	simion.wb.instances[1].pa:refine({convergence = 0.5})
		
end
                                  
local function geomUpdateValues()

-- check to see that this is not the first particle
  		--update the current particle.
   	p = particle_swarm_geom[particle_counter_geom]

	p.current_fitness = global_best_conf_voltage.fitness

	if p.current_fitness > p.best_fitness then
		p.best_conf.s1 = p.current_conf.s1
		p.best_conf.s2 = p.current_conf.s2
		p.best_conf.s3 = p.current_conf.s3
		p.best_fitness = p.current_fitness
	end            
	
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
	-- init random
	math.randomseed(os.time()) 
       
	-- init splats
	for i=1, _num_electrons do
		splats[i] = {};
		splats[i].x = 0;
		splats[i].y = 0;
		splats[i].z = 0;
	end
	
	initVoltageParticles()
	initGeomParticles()
end 
                     
--run the init.
init()

function segment.flym()
	
	--open the logfile.
	logger_debug_voltage = logfile(("log_debug-voltage%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	logger_debug_geom = logfile(("log_debug-geom%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	logger = logfile(("log-%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	
	logger_debug_voltage:add_line("n\t fitness\t s1\t s2\t s3\t Vs1\t Vs2\t Vs3")
	logger_debug_geom:add_line("n\t fitness\t s1\t s2\t s3\t Vs1\t Vs2\t Vs3") 
          
	for k=1,_max_geom_iterations do
		
		iteration_counter_geom = k

		for l=1, _num_geom_particles do
			
			--update the particle counter
			particle_counter_geom = l
			             
			-- uppdate the gem.
			geomUpdateGemFile()
			
			--reset the voltages
			initVoltageParticles()
		
			--loop the voltages PSO to completion.
			for m=1,_max_voltage_iterations do
		
				iteration_counter_voltage = m     
		
				--for each iteration, loop through the particles.
				for i=1,_num_voltage_particles do
					particle_counter_voltage = i 	
					run()
					clearSplats()
				end
		
				--update voltages with pso.
				psoVoltageUpdate(logger, logger_debug_voltage)
		
				--check if we should stop
			    	if global_best_conf_voltage.fitness > _fitness_goal_voltage then
					break
				end
				if iteration_counter_voltage - last_change_voltage > 5 then
					break
				end
		
				--continue looping.
			end 
			
			--update the geom particle with new best voltage run.
			geomUpdateValues()
			
		end
		
		-- do the Geom PSO algorithm
		psoGeomUpdate(logger, logger_debug_geom)
		
		-- check if we should quit.
		if  global_best_conf_geom.fitness > _fitness_goal_geom then
			break
		end 
		
		
	end
	
	logger:close()
	logger_debug_geom:close()
	logger_debug_voltage:close()
	
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
		Rmax = Rc-splats[i].x + Xc
		Rs = math.sqrt((splats[i].y-Yc)^2 + (splats[i].z-Zc)^2)
		
		if splats[i].x > start_of_box then
			num_electrons_inside_box = num_electrons_inside_box + 1
			
			if Rs < Rmax then
				num_electrons_inside_cem = num_electrons_inside_cem + 1
			end
		end
		
		
	 --   print("n=" .. i ..
	  --  	  " ,x=" .. splats[i].x ..
	 --      " ,y=" .. splats[i].y ..
	 --      " ,z=" .. splats[i].z)
	 --   print("Rs=" .. Rs .. 
	 --   	  ", Rmax=" .. Rmax)
	 end
	
	 particle_swarm_voltage[particle_counter_voltage].current_fitness = num_electrons_inside_cem/num_electrons_inside_box
	 -- Print out the statistics.
	 print("fitness=" .. num_electrons_inside_cem/num_electrons_inside_box)
	
end

-- SIMION initialize segment.  Called on particle creation.
-- Not used at the moment
function segment.initialize()

					
end  
                         
-- SIMION fast_adjust segment. Called multiple times per time-step
-- to adjust voltages.
-- Does not do anything at the moment.
function segment.fast_adjust()
     --change the elctrode values to the current particles optimization values.	
	adj_elect02 = particle_swarm_voltage[particle_counter_voltage].current_conf.s1
	adj_elect03 = particle_swarm_voltage[particle_counter_voltage].current_conf.s2
	adj_elect04 = particle_swarm_voltage[particle_counter_voltage].current_conf.s3
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
