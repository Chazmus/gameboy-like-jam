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
	player = Player:new{
		x = starting_position.x,
		y = starting_position.y,
		dx = 0,
		dy = 0
	}
	add(game_objects, player)
	return player
end

player = spawn_player{x=0, y=0}

function player:update()
	if input_utils[up] then
		self.position.y -= 1
	end
	if input_utils[down] then
		self.position.y += 1
	end
	if input_utils[right] then
		self.position.x += 1
	end
	if input_utils[left] then
		self.position.x -= 1
	end
end

function player:draw()
	spr(1, player.position.x, player.position.y)
end


-->8
-- section 2
-->8
-- section 3

-- for any given point on the
-- map, true if there is wall
-- there.

function solid(x, y)
	-- grab the cel value
	val=mget(x, y)
	
	-- check if flag 1 is set (the
	-- orange toggle button in the 
	-- sprite editor)
	return fget(val, 1)
	
end

-- solid_area
-- check if a rectangle overlaps
-- with any walls

--(this version only works for
--actors less than one tile big)

function solid_area(x,y,w,h)
	return 
		solid(x-w,y-h) or
		solid(x+w,y-h) or
		solid(x-w,y+h) or
		solid(x+w,y+h)
end

-- true if [a] will hit another
-- actor after moving dx,dy

-- also handle bounce response
-- (cheat version: both actors
-- end up with the velocity of
-- the fastest moving actor)

function solid_actor(a, dx, dy)
	for a2 in all(actor) do
		if a2 != a then
		
			local x=(a.x+dx) - a2.x
			local y=(a.y+dy) - a2.y
			
			if ((abs(x) < (a.w+a2.w)) and
					 (abs(y) < (a.h+a2.h)))
			then
				
				-- moving together?
				-- this allows actors to
				-- overlap initially 
				-- without sticking together    
				
				-- process each axis separately
				
				-- along x
				
				if (dx != 0 and abs(x) <
				    abs(a.x-a2.x))
				then
					
					v=abs(a.dx)>abs(a2.dx) and 
					  a.dx or a2.dx
					a.dx,a2.dx = v,v
					
					local ca=
					 collide_event(a,a2) or
					 collide_event(a2,a)
					return not ca
				end
				
				-- along y
				
				if (dy != 0 and abs(y) <
					   abs(a.y-a2.y)) then
					v=abs(a.dy)>abs(a2.dy) and 
					  a.dy or a2.dy
					a.dy,a2.dy = v,v
					
					local ca=
					 collide_event(a,a2) or
					 collide_event(a2,a)
					return not ca
				end
				
			end
		end
	end
	
	return false
end


-- checks both walls and actors
function solid_a(a, dx, dy)
	if solid_area(a.x+dx,a.y+dy,
				a.w,a.h) then
				return true end
	return solid_actor(a, dx, dy) 
end

-- return true when something
-- was collected / destroyed,
-- indicating that the two
-- actors shouldn't bounce off
-- each other

function collide_event(a1,a2)
	
	-- player collects treasure
	if (a1==player and a2.k==35) then
		del(actor,a2)
		sfx(3)
		return true
	end
	
	sfx(2) -- generic bump sound
	
	return false
end

function move_actor(a)

	-- only move actor along x
	-- if the resulting position
	-- will not overlap with a wall

	if not solid_a(a, a.dx, 0) then
		a.x += a.dx
	else
		a.dx *= -a.bounce
	end

	-- ditto for y

	if not solid_a(a, 0, a.dy) then
		a.y += a.dy
	else
		a.dy *= -a.bounce
	end
	
	-- apply friction
	-- (comment for no inertia)
	
	a.dx *= (1-a.friction)
	a.dy *= (1-a.friction)
	
	-- advance one frame every
	-- time actor moves 1/4 of
	-- a tile
	
	a.frame += abs(a.dx) * 4
	a.frame += abs(a.dy) * 4
	a.frame %= a.frames

	a.t += 1
	
end


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
