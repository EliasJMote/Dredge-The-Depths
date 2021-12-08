pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
#include lighting.p8
#include particle_system.p8
#include physics.p8

--[[
0X0    GFX
0X1000 GFX2/MAP2 (SHARED)
0X2000 MAP
0X3000 GFX FLAGS
0X3100 SONG
0X3200 SFX
0X4300 USER DATA
0X5600 CUSTOM FONT (IF ONE IS DEFINED)
0X5E00 PERSISTENT CART DATA (256 BYTES)
0X5F00 DRAW STATE
0X5F40 HARDWARE STATE
0X5F80 GPIO PINS (128 BYTES)
0X6000 SCREEN (8K)
0x8000 USER DATA
]]

function inventory_toggle()
	if(state == "game") then
		state = "inventory"
		menuitem(1, "return to game", inventory)
		sfx(0,-2)
	elseif(state == "inventory") then
		state = "game"
		menuitem(1, "go to inventory", inventory)
		sfx(0)
	end
end

function create_game()
	state = "game"

	menuitem(1, "go to inventory", inventory_toggle)

	current_level = "shallow_waters.p8"

	-- load the graphics, map, flags, music and sfx for shallow waters
	reload(0x0,0x0,0x4300,current_level)

	biome_name = "shallows"

	-- create player
	player = {}
	player.x = 64
	player.y = 60
	player.w = 15
	player.h = 7
	player.dx = 0
	player.dy = 0
	player.init_light_radius = 14
	player.light_radius = player.init_light_radius
	player.light_type = "point"
	player.sonar = nil
	player.dir = "right"
	player.can_mine = false
	player.block_mining = false
	player.mine_block = 0
	player.oxygen = 90

	sea_level = 56
	dark_level = sea_level + 192
	map_tile_offset = (sea_level + 8) / 8

	-- add clouds
	--clouds = {}


	--[[for i=0,24 do
		add(clouds,{x=-4+6*i,y=2,r=4,dx=0.8})
	end
	for i=0,24 do
		add(clouds,{x=0+6*i,y=4,r=4,dx=0.8})
	end]]
	

	--add(clouds,{x=20,y=6,r=6,dx=0.05})
	--add(clouds,{x=26,y=8,r=6,dx=0.05})

	-- add waves
	waves = {}
	for i=0,16 do
		add(waves,i*8)
	end

	far_buoys = {{x=32,y=sea_level-5+8,spr=10,w=8,h=8,dy=1}}
	close_buoys = {{x=104,y=sea_level-12+8,spr=9,w=8,h=16,dy=2}}

	light_sources = {{x=56,y=126,w=3,h=2,col=10},{x=64,y=126,w=3,h=2,col=10}}

	beacons = {}

	-- add beacons
	--for i=0,3 do
	for i=0,4,2 do	
		add(beacons,{x=88+i*8,y=104,spr=33,timer=0,light_radius=4})
	end

	-- add bubble emitters
	emitters = {}
	add(emitters,create_bubble_emitter(16,128+72))
	add(emitters,create_bubble_emitter(24,128+72))
	add(emitters,create_bubble_emitter(32,128+72))

	bubbles = {}
	sparks = {}

	timer = 0

	-- camera position
	cam = {x=0,y=0}

	laser_drill_emitter = nil
	
	-- play ocean sound
	sfx(0)
end

function _init()

	-- version
	version = "0.2.2"

	state = "title"

	timer = 0

	-- play ocean sound
	sfx(0)
end
 
function _update()

	if(state == "title") then
		if(btnp(4)) then
			state = "instructions"
		end

	elseif(state == "instructions") then
		if(btnp(4)) then
			create_game()
		end

	elseif(state == "game") then

		-- shoot sonar
		--if(btnp(4)) then
			--player.sonar = {x=player.x+player.w-6,y=player.y+player.h/2-7}
		--end
		if(btn(4) and laser_drill_emitter == nil) then
			if(player.dir == "left") then
				laser_drill_emitter = create_spark_emitter(player.x+3,player.y+7)
			else
				laser_drill_emitter = create_spark_emitter(player.x+15,player.y+7)
			end
		elseif(btn(4) == false and laser_drill_emitter ~= nil) then
			laser_drill_emitter = nil
		end

		player_controls()

		-- blocks that are one block wide can be moved through in the middle of the body
		-- when going up or down but not left or right
		-- this is a bug (seems to be caused by the player being double normal width)
		move_actor(player, true)

		-- block finder (for mining)
		player.can_mine = false
		player.mine_block = 0
		if(player.dir == "left") then
			player.mine_block = mget(flr(player.x/8-1),flr(player.y/8-1)-map_tile_offset+1)
			
		-- block finding on the right goes one block too far when player is as horizontally close to a block as
		-- possible (bug)
		else
			player.mine_block = mget(flr(player.x/8+3),flr(player.y/8-1)-map_tile_offset+1)
		end

		if(fget(player.mine_block,0)) then
			player.can_mine = true
		end

		-- mine blocks if able
		if(player.can_mine and btn(4)) then
			player.block_mining = true
		else
			player.block_mining = false
		end

		-- losing oxygen
		if(player.oxygen > 0) then
			if(player.y > sea_level+6) then
				player.oxygen -= 1/30
			else
				player.oxygen = 90
			end
		else
			player.oxygen = 0
		end

		-- if the player reaches the exit of the level
		--if(player.y > 40 * 8) then

		if(current_level == "shallow_waters.p8") then
			if(player.x > 128*8) then
				current_level = "coral_reef.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.x = 16
				player.oxygen = 90
			end
		elseif(current_level == "coral_reef.p8") then
			if(player.y > 40*8) then
				current_level = "deep_ocean.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				waves = {}
				reload(0x0,0x0,0x4300,current_level)
				player.y = 16
				player.oxygen = 90
			end
		elseif(current_level == "deep_ocean.p8") then
			if(player.y > 40*8) then
				current_level = "mountains.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.y = 16
				player.oxygen = 90
			end
		elseif(current_level == "mountains.p8") then
			if(player.x > 128*8) then
				current_level = "crystal_caves.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.x = 16
				player.y = 16
				player.oxygen = 90
			end
		elseif(current_level == "crystal_caves.p8") then
			if(player.y > 40*8) then
				current_level = "ruins.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.y = 16
				player.oxygen = 90
			end
		elseif(current_level == "ruins.p8") then
			if(player.y > 40*8) then
				current_level = "trench.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.y = 16
				player.oxygen = 90
			end
		elseif(current_level == "trench.p8") then
			if(player.y > 40*8) then
				current_level = "core.p8"
				close_buoys = {}
				far_buoys = {}
				bubbles = {}
				emitters = {}
				reload(0x0,0x0,0x4300,current_level)
				player.y = 16
				player.oxygen = 90
			end
		end

		-- move waves
		for i=1,#waves do
			waves[i] += 0.25
			if(waves[i] >= 128) then
				waves[i] = 0 - 8
			end
		end

		-- update emitters
		for e in all(emitters) do
			--if(e.name == "bubble") then
				e,bubbles = update_bubble_emitter(e,bubbles)
			--else
				--e,sparks = update_spark_emitter(e,sparks)
			--end
		end

		-- update laser drill emitter
		if(laser_drill_emitter ~= nil) then
			
			if(laser_drill_emitter ~= nil) then
				if(player.dir == "left") then
					laser_drill_emitter.x = player.x + 1
				else
					laser_drill_emitter.x = player.x + 15
				end
			end

			laser_drill_emitter.y = player.y+7
			laser_drill_emitter,sparks = update_spark_emitter(laser_drill_emitter,sparks)
		end

		-- update bubbles
		for b in all(bubbles) do
			b,bubbles = update_bubble(b,bubbles)
		end

		-- update sparks
		for s in all(sparks) do
			s,sparks = update_spark(s,sparks)
		end

		-- update sonar
		if(player.sonar ~= nil) then
			player.sonar.x += 6
		end

		-- initialize the camera
		cam = {x=player.x-64,y=player.y-64}

		-- update the camera based on player position
		if(player.x < 64) then
			cam.x = 0
		elseif(player.x >= 128*8-64) then
			cam.x = 128*8-128
		end

		if(player.y < 64) then
			cam.y = 0
		elseif(player.y >= 32*10-64) then
			cam.y = 32*10-128
		end

		-- the player's light should grow and shrink periodically
		player.light_radius = player.init_light_radius + sin(timer/45)
	end

	-- update timer
	timer += 1
end

function _draw()
	cls()	

	if(state == "title") then

		for i=0,4 do
			for j=0,4 do
				spr(1,(i*32+8*sin(timer/180))%160-32,(j*32+timer/8)%160-32,4,4)
			end
		end

		rectfill(29,6,99,14,0)
		print("dredge the depths",31,8,7)

		rectfill(25,94,103,102,0)
		print("press z/\142 to start",27,96,7)

		rectfill(102,119,128,127,0)
		print("v" .. version,104,121,7)

	elseif(state == "instructions") then
		print("instructions",42,8,7)
		print("press z/\142 to start",27,96,7)

	elseif(state == "game") then

		camera(cam.x,cam.y)

		
		if(current_level == "shallow_waters.p8" or current_level == "coral_reef.p8") then

			-- sky background
			rectfill(cam.x,8,cam.x+127,sea_level-1+8,5)


			-- draw moons
			spr(13,cam.x+88,cam.y/8+30)
			spr(14,cam.x+16,cam.y/4+44,2,2)

			-- ocean background
			rectfill(cam.x,sea_level+8,cam.x+127,sea_level+64-1+8,12)
			rectfill(cam.x,sea_level+64+8,cam.x+127,dark_level-1,1)

			-- light to dark ocean gradient
			rectfill(0,sea_level+64-6,cam.x+127,sea_level+64-6,1)
			rectfill(0,sea_level+64,cam.x+127,sea_level+64,1)
			rectfill(0,sea_level+64+4,cam.x+127,sea_level+64+4,1)
			rectfill(0,sea_level+64+6,cam.x+127,sea_level+64+6,1)

			--skyline
			rectfill(0,8,cam.x+127,10,6)
			rectfill(0,12,cam.x+127,12,6)
			rectfill(0,14,cam.x+127,14,6)
			rectfill(0,18,cam.x+127,18,6)
			rectfill(0,24,cam.x+127,24,6)
		else
			rectfill(cam.x,8,cam.x+127,dark_level-1,1)
		end

		-- dark to black ocean gradient
		rectfill(0,dark_level-2,cam.x+127,dark_level-2,0)
		rectfill(0,dark_level-4,cam.x+127,dark_level-4,0)
		rectfill(0,dark_level-8,cam.x+127,dark_level-8,0)
		rectfill(0,dark_level-14,cam.x+127,dark_level-14,0)

		-- draw far buoys
		for b in all(far_buoys) do
			spr(b.spr,b.x+cam.x*7/8,b.y+b.dy*sin((timer+30)/90),b.w/8,b.h/8)
		end

		-- draw bubble particles
		for b in all(bubbles) do
			circ(b.x,b.y,b.r,b.col)
		end

		-- draw waves
		for w in all(waves) do
			rectfill(cam.x+w,sea_level+8,cam.x+w+4,sea_level+8,7)
		end

		-- draw the dolphin
		spr(6,96,sea_level+32+3*sin(timer/90)+16,2,1,true)

		-- draw close buoys
		for b in all(close_buoys) do
			spr(b.spr,b.x,b.y+b.dy*sin((timer+30)/90),b.w/8,b.h/8)
		end

		-- draw the normal map
		map(0,0,0,sea_level+8,128,64)

		-- add circular lighting for the player
		circle_lighting(player)

		-- draw the light layer (flag 1)
		map(0,0,0,sea_level+8,128,64,0x2)

		-- draw the player
		if(player.dir == "right") then
			spr(2+(flr(timer/6)%2)*2,player.x,player.y,2,1)
		else
			spr(2+(flr(timer/6)%2)*2,player.x,player.y,2,1,true)
		end

		-- draw the laser cutter on the player
		if(laser_drill_emitter) then
			if(player.dir == "left") then
				rectfill(player.x+1,player.y+7-flr(timer/6)%2,player.x+1+1,player.y+7-flr(timer/6)%2,7+timer%3)
			else
				rectfill(player.x+13,player.y+7-flr(timer/6)%2,player.x+13+1,player.y+7-flr(timer/6)%2,7+timer%3)
			end
			
		end

		-- draw the sparks
		for s in all(sparks) do
			line(s.x,s.y,s.x,s.y,7+timer%3)
		end

		-- draw sonar
		if(player.sonar ~= nil) then
			spr(8,player.sonar.x,player.sonar.y,1,2)
		end

		-- draw fog
		--[[for j=0,3,2 do
			for i=0,128,2 do
				rectfill(i,j,i,j,5)
			end
		end
		for j=4,15,2 do
			for i=0,128,2 do
				rectfill(i,j,i,j,6)
			end
		end]]

		--[[print("fps = " .. stat(7),0,0,8)
		print("cpu = " .. stat(1))
		]]

		----------------------------------------------------------------
		-------------------- draw the status screen --------------------
		----------------------------------------------------------------


		-- draw the black bar for the status screen
		rectfill(cam.x,cam.y,cam.x+127,cam.y+7,0)

		--
		--print("\151",cam.x+24,cam.y)

		-- draw the 'o' item
		rect(cam.x,cam.y,cam.x+7,cam.y+7,8)
		print("\142",cam.x+11,cam.y+3,7)
		spr(64,cam.x,cam.y)

		-- draw the 'x' item
		rect(cam.x+24,cam.y,cam.x+24+7,cam.y+7,8)
		print("\151",cam.x+11+24,cam.y+3,7)
		spr(65,cam.x+24,cam.y)

		-- draw the depth
		spr(127,cam.x+48,cam.y)
		print(flr((player.y + player.h)/8 - 8) .. "\'",cam.x+76-16,cam.y+3,7)

		-- draw biome
		--rect(cam.x+96,cam.y,cam.x+96+8-1,cam.y+8-1,8)
		spr(126,cam.x+120,cam.y)
		--print(player.mine_block,cam.x,cam.y,7)
		--[[if(player.mine_block == 56 and player.block_mining) then
			print("currently mining quartz",cam.x,cam.y,7)
		else
			print("not currently mining",cam.x,cam.y,7)
		end]]

		-- draw oxygen
		spr(125,cam.x+80,cam.y)
		if(player.oxygen > 60) then
			print("X".. ceil(player.oxygen),cam.x+90,cam.y+3,7)
		elseif(player.oxygen > 30) then
			print("X".. ceil(player.oxygen),cam.x+90,cam.y+3,10)
		elseif(player.oxygen > 0) then
			print("X".. ceil(player.oxygen),cam.x+90,cam.y+3,8)
		else
			print("X".. ceil(player.oxygen),cam.x+90,cam.y+3,5)
		end

		-- draw health
		rect(cam.x+109,cam.y,cam.x+117-1,cam.y+8-1,8)

		--print(mget(flr(player.x/8),flr(player.y/8)),cam.x,cam.y,7)
		--print("(" .. player.x .. "," .. player.y .. ")",cam.x,cam.y,7)
		--print("(" .. player.x .. "," .. player.y .. ")",cam.x,cam.y+8,8)
		--print(mget(flr(player.x/8),flr(player.y/8)-3),cam.x,cam.y+8,8)
		--rectfill(player.x,player.y,player.x,player.y,0)
		--print("(" .. player.x .. "," .. player.y .. ")",cam.x,cam.y,7)

		-- block finder (for mining)
		if(player.dir == "left") then
			if(player.can_mine) then
				local c = 11
				if(fget(player.mine_block,2) and player.block_mining) then c = 7+timer%3 end
				rect(player.x-8-player.x%8,player.y-player.y%8,player.x-player.x%8-1,player.y+7-player.y%8,c)
			end

		-- block finding on the right goes one block too far when player is as horizontally close to a block as
		-- possible (bug)
		else
			
			if(player.can_mine) then
				local c = 11
				if(fget(player.mine_block,2) and player.block_mining) then c = 7+timer%3 end
				rect(player.x+player.w-player.x%8+8+1,player.y-player.y%8,player.x+player.w+8+8-player.x%8,player.y+7-player.y%8,c)
			end
		end

	elseif(state == "inventory") then
		spr(64,64,64)
	end
end
__gfx__
00000000611111111666111111111611111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000611111166666611111116111111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666616611111661111116111111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111666111111161111166611111116610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111116111111166666666666666666110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111116111111166111166111111161110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111116111111161111116611111166110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111116111111161111111161111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111166111111161111111161111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111661111111161111111161111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000116611111111666661111161111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000116666666116611116661166111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000116611116666111111166116666666110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000116111111161111111116616666116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000166111111161111111111666111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000161111111161111111111161111116110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000161111111161111111111161111111610000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000661111111161111111111161111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000661111111161111111111161111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000161111116666111111111161111116660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000166111166116611111111166111666110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000116666661111161111166666666661110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111611111116666661111111661110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111661111111161111111111161110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111161111111161111111111161110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111161111111116111111111661110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111161111111116111111116661110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111661111111116111111666666110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666666611111111116666666661116660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000611111611111166666111116111111660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111661111661111111166111111660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000111111166666611111111161111111160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
003000200465005650076500b6500f65013650126500f6500a6500565003650086500b650096500665005650076500b6500c6500e6500f6500d6500a6500765007650096500b6500d6500d6500c6500865005650
00180020056000760008600096000b6000d6000f6001160012600136001460014600126000f6000c600076000460002600026000460006600096000a6000a6000a6000a6000a6000a6000a6000a6000860005600
