pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- Framework

game_objects = {}
actions = {}

function _init()
	foreach(game_objects, 
	function(go) 
		if go.init != nil then
			go:init()
		end
	end)
end

function _update()
	foreach(game_objects, 
	function(go) 
		if go.update != nil then
			go:update()
		end
	end)

	foreach(actions, 
	function(c)
		if costatus(c) then
		  coresume(c)
		else
		  del(actions,c)
		end
	end)

	-- Input utils update MUST be done last
	input_utils:update()
end

function _draw()
    cls()
	foreach(game_objects, 
	function(go) 
		if go.draw != nil then
			go:draw()
		end
	end)
end


-- Input utils
left,right,up,down,fire1,fire2=0,1,2,3,4,5
black,dark_blue,dark_purple,dark_green,brown,dark_gray,light_gray,white,red,orange,yellow,green,blue,indigo,pink,peach=0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15

input_utils = {
	left = false,
	right = false,
	up = false,
	down = false,
	fire1 = false,
	fire2 = false
}

add(game_objects, input_utils)

function input_utils:update()
	printh("processing input")
	self[left] = btn(left)
	self[right] = btn(right)
	self[up] = btn(up)
	self[down] = btn(down)
	self[fire1] = btn(fire1)
	self[fire2] = btn(fire2)
end

function input_utils:get_button_down(button)
	-- Returns true only in the frame that the button was pushed down
	return self[button] == false and btn(button)
end

function input_utils:get_button_up(button)
	-- Returns true only in the frame that the button was released
	return self[button] == true and not btn(button)
end

function input_utils:handle_hold_button(button, hold_time, success_function, update_function)
	-- Return true if the given button has been held down for the given amount of time
	local c = cocreate(
		function()
			start_time = time()
			while btn(button) and time() < (start_time + hold_time) do
				if update_function != nil then
					update_function()
				end
				yield()
			end
			if not btn(button) then
				return
			end
			success_function()
		end
	)
	add(actions, c)
end


-->8
-- section 1
Player = {}
function Player:new (o)
  o = o or {}   -- create object if user does not provide one
  setmetatable(o, self)
  self.__index = self
  return o
end

function spawn_player(starting_position)
	local starting_target = {x=starting_position.x, y=starting_position.y}
	local player = Player:new{
		position = starting_position,
	}
	add(game_objects, player)
	return player
end

player = spawn_player{64, 64}

function player:update()
	printh(input_utils.up)
	if input_utils.up then
		self.position.y -= 1
	end
	if input_utils.down then
		self.position.y += 1
	end
	if input_utils.right then
		self.position.x += 1
	end
	if input_utils.left then
		self.position.x -= 1
	end
end

function player:draw()
	spr(1, player.x, player.y)
end


-->8
-- section 2
-->8
-- section 3
-->8
--section 4
-->8
-- section 5
__gfx__
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c9999c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700c90aa09c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000c9abba9c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000c9abba9c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700c90aa09c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c9999c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000cccc000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
