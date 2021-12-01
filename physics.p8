pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- check if a map cell is solid
--[[function solid(x,y)
	local obj = blocks[cur_room][flr(x/8)+16*flr(y/8)+1]
	if(obj ~= nil) then

		-- flag 0 is a solid block
		if(fget(obj,0)) then
			return true
		end
	end
	return false
end

-- check if the area is solid
function solid_area(x,y,w,h)
	return solid(x+w,y) or solid(x+w,y+h) or solid(x,y) or solid(x,y+h)
end

-- check if something has collided with the player
function char_collision(e)
	if(p1.x<e.x+e.w and p1.x+p1.w>e.x and p1.y<e.y+e.h and p1.y+p1.h>e.y) then
		return true
	end
	return false
end

-- player keyboard commands
function player_controls()
	local spd = 1

	-- move around
	if(not is_reading) then
		-- horizontal movement
		if(btn(0)) then
			p1.dx = -spd
			p1.dir = "left"
		end
		if(btn(1)) then
			p1.dx = spd 
			p1.dir = "right"
		end
		if not btn(0) and not btn(1) then
			p1.dx = 0
		end
		
		-- vertical movement
		if(btn(2)) then
			p1.dy = -spd
			p1.ydir = "up"
		end
		if(btn(3)) then
			p1.dy = spd
			p1.ydir = "down"
		end
		if not btn(2) and not btn(3) then
			p1.dy = 0
		end
	end
end

-- move the player, an npc or an enemy
function move_actor(act, is_solid)
	
	if(is_solid) then
		if not solid_area(act.x+act.dx,act.y,act.w,act.h) then
			act.x += act.dx
		else
			act.dx = 0
		end

		if not solid_area(act.x,act.y+act.dy,act.w,act.h) then
			act.y += act.dy
		else
			act.dy = 0
		end
	else
		act.x += act.dx
		act.y += act.dy
	end
end]]