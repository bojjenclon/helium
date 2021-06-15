local path  = string.sub(..., 1, string.len(...) - string.len(".core.scene"))

local atlas  = require(path..'.core.atlas')
local helium = require(path..'.dummy')
local input  = require(path..'.core.input')

---@class scene
local scene = {
	activeScene = nil
}
scene.__index = scene

---comment
---@param cached boolean @whether to enable caching on this scene
---@return scene
function scene.new(cached)
	---@type scene
	local self = {
		atlas = cached and atlas.create() or nil,
		cached = cached or false,
		subscriptions = {},
		buffer = {}
	}
	return setmetatable(self, scene)
end

local skipframes = 10
function scene.bench()
	if skipframes == 0 then
		local startTime = love.timer.getTime()
		
		for i = 1, 20 do
			love.graphics.print(i,-100,-100)
		end
		
		helium.setBench((love.timer.getTime()-startTime)/5)
	elseif skipframes>0 then
		skipframes = skipframes - 1
	end
end

---Activates this scene
function scene:activate()
	scene.activeScene = self
end

---Keeps the scene in memory with potentially the atlas
function scene:deactivate()
	scene.activeScene = nil
end

---Recreates this scene 
function scene:reload()
	self.atlas = self.cached and atlas.create() or nil
	self.ioSubscriptions = {}
	self.buffer = {}
end

---Nukes the scene and it's elements and atlases and subscriptions from memory
---To achieve same state as after creation, use reload
function scene:unload()
	self.atlas = nil
	self.buffer = nil
	self.ioSubscriptions = nil
end

---Draws this scene and it's elements
function scene:draw()
	helium.stack.newFrame()
	if not helium.benchNum then
		scene.bench()
	end
	
	love.graphics.push("all")
	love.graphics.setColor(1,1,1,1)
	for i, e in ipairs(self.buffer) do
		e:externalRender()
	end
	love.graphics.pop()

end

---Updates this scene and it's elements
---@param dt number
function scene:update(dt)
	for i = 1, #self.buffer do
		if self.buffer[i]:externalUpdate(i) then
			table.remove(self.buffer, i)
		end
	end
end

return scene