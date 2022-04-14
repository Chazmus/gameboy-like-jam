pico-8 cartridge // http://www.pico-8.com
version 34
__lua__
-- Framework

game_objects = {}
actions = {}

function _init()
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


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000