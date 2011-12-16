simion.workbench_program()
    

--adjustables
adjustable _max_iterations = 10000
adjustable _num_electrons = 500
adjustable _num_particles = 50
adjustable _cem_voltage  = 300
adjustable _fitness_goal = 0.99

adjustable _w = 0.9
adjustable _ph1 = 0.3
adjustable _ph2 = 0.5
  
--local variables
local particle_counter = 1 
     
--local "constants"
local iob_width = 256
local iob_height = 92
local iob_length = 200 

local Rc = 30
local Xc = 215
local Yc = 46
local Zc = 100 

local start_of_box = 120
            
-- local Tables
local particle_swarm = {}
local global_best_conf = {}                  

local splats = {}
               
-- init stuff
math.randomseed(os.time())

for i=1, _num_electrons do
	splats[i] = {};
	splats[i].x = 0;
    splats[i].y = 0;
	splats[i].z = 0;
end 

global_best_conf.fitness = 0
global_best_conf.s1 = 0 
global_best_conf.s2 = 0 
global_best_conf.s3 = 0 

for i=1, _num_particles do
	particle_swarm[i] = {}

	particle_swarm[i].current_conf = {}
	particle_swarm[i].current_conf.s1 = math.random(0,_cem_voltage)
	particle_swarm[i].current_conf.s2 = math.random(0,_cem_voltage)
	particle_swarm[i].current_conf.s3 = math.random(0,_cem_voltage)
	particle_swarm[i].current_conf.Vs1 = math.random(-_cem_voltage,_cem_voltage)
	particle_swarm[i].current_conf.Vs2 = math.random(-_cem_voltage,_cem_voltage)
	particle_swarm[i].current_conf.Vs3 = math.random(-_cem_voltage,_cem_voltage)

	particle_swarm[i].best_conf = {}
	particle_swarm[i].best_conf.s1 = particle_swarm[i].current_conf.s1
	particle_swarm[i].best_conf.s2 = particle_swarm[i].current_conf.s2
	particle_swarm[i].best_conf.s3 = particle_swarm[i].current_conf.s3
	particle_swarm[i].best_conf.Vs1 = particle_swarm[i].current_conf.Vs1
	particle_swarm[i].best_conf.Vs2 = particle_swarm[i].current_conf.Vs2
	particle_swarm[i].best_conf.Vs3 = particle_swarm[i].current_conf.Vs3

	particle_swarm[i].best_fitness = 0
	particle_swarm[i].current_fitness = 0
end
    
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

function segment.flym()
	
	--open the logfile.
	logger_debug = logfile(("log_debug-%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	logger = logfile(("log-%s.txt"):format(os.date("%m-%d-%Y-%H-%M")))
	
	logger_debug:add_line("n\t fitness\t s1\t s2\t s3\t Vs1\t Vs2\t Vs3")

	--loop number of iterations
	for k=1,_max_iterations do
		    
		--for each iteration, loop through the particles.
		for i=1,_num_particles do
			particle_counter = i 	
			run()
		end
		
		--evaluate the fitness value for the different particles
		--and update the local and global best values.
		for i=1, _num_particles do
			local p = particle_swarm[i]
			
			if  p.current_fitness > p.best_fitness then
				p.best_fitness = p.current_fitness
				p.best_conf.s1 = p.current_conf.s1
				p.best_conf.s2 = p.current_conf.s2
				p.best_conf.s3 = p.current_conf.s3
			end
			
			if p.current_fitness > global_best_conf.fitness then
				global_best_conf.fitness = p.best_fitness
				global_best_conf.s1 = p.best_conf.s1
				global_best_conf.s2 = p.best_conf.s2
				global_best_conf.s3 = p.best_conf.s3
			end
		end	
		
		--print the fitness values for all the particles
		for i=1, _num_particles do
			logger_debug:add_line(	i .. "\t" ..
						particle_swarm[i].current_fitness .. "\t" ..
				  		particle_swarm[i].current_conf.s1 .. "\t" ..
				  		particle_swarm[i].current_conf.s2 .. "\t" ..
				  		particle_swarm[i].current_conf.s3 .. "\t" ..
				  		particle_swarm[i].current_conf.Vs1 .. "\t" ..
				  		particle_swarm[i].current_conf.Vs2 .. "\t" ..
				  		particle_swarm[i].current_conf.Vs3)
		end
			
		--print the global best 
		print("best_conf_fitness=" .. global_best_conf.fitness ..
			  " ,e1=" .. global_best_conf.s1 ..
			  " ,e2=" .. global_best_conf.s2 ..
			  " ,e3=" .. global_best_conf.s3)			
			   
		--log the global best to file.
		logger:add_line("iteration no=" .. k ..
						", best_conf_fitness=" .. global_best_conf.fitness ..
			  			" ,e1=" .. global_best_conf.s1 ..
			  			" ,e2=" .. global_best_conf.s2 ..
			  			" ,e3=" .. global_best_conf.s3)

		
		--check if we should stop
        	if global_best_conf.fitness > _fitness_goal then
			break
		end
			
        	--update the particles for new values using a PSO algorithm                
		for i=1, _num_particles do
			local p = particle_swarm[i]
			local rp = math.random()
			local rg = math.random()
			
			p.current_conf.Vs1 = _w*p.current_conf.Vs1 + _ph1*rp*(p.best_conf.s1-p.current_conf.s1) + _ph2*rg*(global_best_conf.s1-p.current_conf.s1)  
	        	p.current_conf.Vs2 = _w*p.current_conf.Vs2 + _ph1*rp*(p.best_conf.s2-p.current_conf.s2) + _ph2*rg*(global_best_conf.s2-p.current_conf.s2)
			p.current_conf.Vs3 = _w*p.current_conf.Vs3 + _ph1*rp*(p.best_conf.s3-p.current_conf.s3) + _ph2*rg*(global_best_conf.s3-p.current_conf.s3)
			
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
		
		--continue looping.
	end
	
	logger:close()
	logger_debug:close()
	
end

--runs at start of each run. zeros splats.
function segment.initialize_run()
    for i=1, _num_electrons do
		splats[i].x = 0;
	    splats[i].y = 0;
		splats[i].z = 0;
	end
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
	
	 particle_swarm[particle_counter].current_fitness = num_electrons_inside_cem/num_electrons_inside_box
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
	adj_elect02 = particle_swarm[particle_counter].current_conf.s1
	adj_elect03 = particle_swarm[particle_counter].current_conf.s2
	adj_elect04 = particle_swarm[particle_counter].current_conf.s3
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
