pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- check if a map cell is solid
function solid(x,y)
	
	-- subtract 8 to account for the map being low on the shallow level
	if(fget(mget(flr(x/8),flr(y/8)-map_tile_offset),0)) then
		return true
	end
	return false
end

-- check if the area is solid
function solid_area(x,y,w,h)
	return solid(x+w,y) or solid(x+w,y+h) or solid(x,y) or solid(x,y+h)
end

-- player keyboard commands
function player_controls()
	local spd = 1

	-- player horizontal movement
	if(btn(0) and player.x > 0) then
		player.dx = -spd
		player.dir = "left"
	elseif(btn(1)) then
		player.dx = spd
		player.dir = "right"
	else
		player.dx = 0
	end

	-- player vertical movement
	if(btn(2) and player.y > sea_level-4+8) then
		player.dy = -spd
	elseif(btn(3)) then
		player.dy = spd
	else
		player.dy = 0
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
end