--[[--------------------------------------------------
	Helium UI by qfx (qfluxstudios@gmail.com)
	Copyright (c) 2019 Elmārs Āboliņš
	gitlab.com/project link here
----------------------------------------------------]]
local path     = ...
local helium   = require(path..".dummy")
helium.conf    = require(path..".conf")
helium.utils   = require(path..".utils")
helium.element = require(path..".core.element")
helium.input   = require(path..".core.input")
helium.loader  = require(path..".loader")
helium.stack   = require(path..".core.stack")
helium.atlas   = require(path..".core.atlas")
helium.elementBuffer = {}
helium.elementInsertionQueue = {}
helium.__index = helium

setmetatable(helium, {__call = function(s, chunk)
	return setmetatable({
		draw = function (param, inputs, x, y, w, h)
			return helium.element.immediate(param, inputs, chunk, x, y, w, h)
		end
	}, 
	{__call = function(s, param, w, h)
		return helium.element(chunk, param, w, h)
	end,})
end})

local first = true
local skip = true

function helium.load()
	helium.atlas.load()
end

function helium.unload()
	helium.atlas.unassignAll()
	helium.elementBuffer = {}
end


function helium.draw()
	if first and not skip then
		--love.graphics.setScissor(500, 500, 1, 1)

		local startTime = love.timer.getTime()
		
		for i = 1, 20 do
			love.graphics.print(i,-100,-100)
		end

		helium.element.setBench((love.timer.getTime()-startTime)/5)
		helium.atlas.setBench((love.timer.getTime()-startTime)/5)

		first = false
		--love.graphics.setScissor()
	elseif first then
		skip = false
	end

	--We don't want any side effects affecting internal rendering
	love.graphics.reset()
	for i, e in ipairs(helium.elementBuffer) do
		e:externalRender()
	end

	for i, e in ipairs(helium.elementInsertionQueue) do
		table.insert(helium.elementBuffer, e)
	end
	helium.elementInsertionQueue = {}
end

function helium.update(dt)

	for i = 1, #helium.elementBuffer do
		if helium.elementBuffer[i]:externalUpdate(i) then
			table.remove(helium.elementBuffer,i)
		end
	end
end

--[[
	A user doesn't have to use this particular love.run

	helium.render()
	helium.update(dt)

	Need to be called either through love.update and love.draw respectively
	or put in to your custom love.run

	And for inputs to work the love.event part needs to look something like this:

	for name, a,b,c,d,e,f in love.event.poll() do
		if name == "quit" then
			if not love.quit or not love.quit() then
				return a
			end
		end

		if not(helium.eventHandlers[name]) or not(helium.eventHandlers[name](a, b, c, d, e, f)) then
			love.handlers[name](a, b, c, d, e, f)
		end
	end
]]
if helium.conf.AUTO_RUN then
	function love.run()
		if love.load then love.load() end--love.arg.parseGameArguments(arg), arg) end

		-- We don't want the first frame's dt to include time taken by love.load.
		if love.timer then love.timer.step() end

		local dt = 0

		-- Main loop time.
		return function()
			-- Process events.
			helium.stack.newFrame()
			if love.event then
				love.event.pump()
				for name, a,b,c,d,e,f in love.event.poll() do
					if name == "quit" then
						if not love.quit or not love.quit() then
							return a or 0
						end
					end

					if not(helium.input.eventHandlers[name]) or not(helium.input.eventHandlers[name](a, b, c, d, e, f)) then
						love.handlers[name](a, b, c, d, e, f)
					end
				end
			end


			-- Update dt, as we'll be passing it to update
			if love.timer then dt = love.timer.step() end

			-- Call update and draw
			if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
			local st = love.timer.getTime()
			helium.update(dt)
			heliumTime = love.timer.getTime()-st

			if love.graphics and love.graphics.isActive() then
				love.graphics.origin()
				love.graphics.clear(love.graphics.getBackgroundColor())
				
				st = love.timer.getTime()
				helium.draw()
				heliumTime=heliumTime+love.timer.getTime()-st

				if love.draw then love.draw() end


				love.graphics.present()
			end
			
			if love.timer then love.timer.sleep(0.001) end
		end
	end
end

--Typescript
helium.helium = helium
return helium