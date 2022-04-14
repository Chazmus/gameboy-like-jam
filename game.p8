pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- Framework

game_objects = {}
actions = {}
function _init()
	player = make_actor(9, 1, 1, 2, 2, 2)
	foreach(game_objects, 
	function(go) 
		if go.init != nil then
			go:init()
		end
	end)
end

function _update()
	control_player(player)
	foreach(game_objects, move_actor)
	-- Input utils update MUST be done last
	input_utils:update()
end

function _draw()
    cls()
	map(0)
	foreach(game_objects, draw_actor)
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

function control_player(pl)
	accel = 0.05
	if (btn(0)) pl.dx -= accel 
	if (btn(1)) pl.dx += accel 
	if (btn(2)) pl.dy -= accel 
	if (btn(3)) pl.dy += accel 
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
	for a2 in all(game_objects) do
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
		del(game_objects,a2)
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
	
	a.frame += (abs(a.dx) * 4)
	a.frame += (abs(a.dy) * 4)
	a.frame %= a.frames
	a.t += 1
end

-- make an actor
-- and add to global collection
-- k is the sprite number
-- x,y means center of the actor
-- in map tiles
function make_actor(k, x, y, frames, width, height)
	a={
		k = k,
		x = x,
		y = y,
		dx = 0,
		dy = 0,		
		frame = 0,
		t = 0,
		friction = 0.15,
		bounce  = 0.3,
		frames = frames,
		
		-- half-width and half-height
		-- slightly less than 0.5 so
		-- that will fit through 1-wide
		-- holes.
		w = width * 0.4,
		h = height * 0.4,
		width = width,
		height = height
	}
	
	add(game_objects, a)
	return a
end

function draw_actor(a)
	printh(a.width)
	local sx = (a.x * 8 * a.width) - (4 * a.width)
	local sy = (a.y * 8 * a.height) - (4 * a.height)
	spr(a.k + a.frame, sx, sy, a.width, a.height)
end

-- converts anything to string, even nested tables
function tostring(any)
    if type(any)=="function" then 
        return "function" 
    end
    if any==nil then 
        return "nil" 
    end
    if type(any)=="string" then
        return any
    end
    if type(any)=="boolean" then
        if any then return "true" end
        return "false"
    end
    if type(any)=="table" then
        local str = "{ "
        for k,v in pairs(any) do
            str=str..tostring(k).."->"..tostring(v).." "
        end
        return str.."}"
    end
    if type(any)=="number" then
        return ""..any
    end
    return "unkown" -- should never show
end

-->8
--section 4
-->8
-- section 5
__gfx__
000000000044444000000004440000003333333333333334cccccccccccccccc4ccccccc00000004440000000000000000000000000000000000000000000000
000000000444044400000044444000003333433333333344cc33cccccccccccc4ccccccc00000044444000000000000444000000000000000000000000000000
00700700444009490000009999900000343393333333344cc3333ccccc3ccccc4ccccccc00000099999000000000004444400000000000000000000000000000
0007700044000c9c0000049c9c94000039433343333344ccc3333ccccc3ccc3c4ccccccc0000049c9c9400000000009999900000000000000000000000000000
00077000440009c900000099999000003393339333344cccc3333ccccc3c3c3c4ccccccc00000099999000000000049c9c940000000000000000000000000000
0070070044000c9c0000004444400000333343333344cccccc33cccccccc3c3c4ccccccc00000044444000000000009999900000000000000000000000000000
00000000444009c900000c44944c000033339333344ccccccccccccccccc3ccc4ccccccc00000c44944c000000000c44444c0000000000000000000000000000
00000000044000900000ccc444ccc0003333333344cccccccccccccccccccccc4ccccccc0000ccc444ccc0000000cc44944cc000000000000000000000000000
0093900004000040000c9ccc3ccc9c004444444433333333cccccccc99999999ccccccc4000c9ccc3ccc9c00000c9cc444cccc00000000000000000000000000
0009000004999940000990cc3cc099004444444433333333cccccccc99999999ccccccc4000990cc3cc0990000099ccc3ccc9c00000000000000000000000000
09040900004994000009004c4c4009004444444433333333cccccccc99999999ccccccc40009004c4c400900000900cc3cc00900000000000000000000000000
049494000444444000000044444000004444444433333333cccccccc99999999ccccccc400000044444000000000004c4c400000000000000000000000000000
004440004444444400000044444000004444444433333333cccccccc99999999ccccccc400000044444000000000004444400000000000000000000000000000
093439004444444400000044044000004444444433333333cccccccc99999999ccccccc400000044044000000000004444400000000000000000000000000000
009490004444444400000099099000004444444433333333cccccccc99999999ccccccc400000099099000000000004404400000000000000000000000000000
000900000444444000000999099900004444444433333333cccccccc99999999ccccccc400000999099900000000099909990000000000000000000000000000
000000000000000000000444444000004444444444cccccccccccccccccccc444333333300000000000000000000000000000000000000000000000000000000
00400400000044400000400440040000cccccccc344cccccccccccccccccc4434433333300000000000000000000000000000000000000000000000000000000
00440440000ccc440004000440004000cccccccc3344cccccccccccccccc4433c443333300000000000000000000000000000000000000000000000000000000
0044444000090cc40040009449000400cccccccc33344cccccccccccccc44333cc44333300000000000000000000000000000000000000000000000000000000
009c9440000000c40040009999000400cccccccc333344cccccccccccc443333ccc4433300000000000000000000000000000000000000000000000000000000
9cc44444400000c40040009999000400cccccccc3333344cccccccccc4433333cccc443300000000000000000000000000000000000000000000000000000000
cc4444444444cc440040cc9999cc0400cccccccc33333344cccccccc44333333ccccc44300000000000000000000000000000000000000000000000000000000
40044444444cccc0044cccccccccc440cccccccc333333344444444443333333cccccc4400000000000000000000000000000000000000000000000000000000
0000cc444cccc4440094cccccccc4900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ccccccc44440099444444449900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000ccc00cc44440049944444499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000c0c000cc4400044999999994400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000c0c0000c0400094499999944900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000c0c0000c0c00099444444449900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000c0c0000c0c00049944444499400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000044999999994400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333000000000000000033333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000020202020000000000000000000000000002000200000000000000000000000202020202000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1504151515041515151515151504151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515151515151515041500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1515151515151515150415151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1415151515150524242815151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414041515150806071815151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414140415042526262704151515150400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141415151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141415151515151504151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141414151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1414141515151504151515151515041500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1514151515151515151515151515151500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
