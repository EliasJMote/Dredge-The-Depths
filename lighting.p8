pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function sort(a)
    for i=1,#a do
        local j = i
        while j > 1 and a[j-1] > a[j] do
            a[j],a[j-1] = a[j-1],a[j]
            j = j - 1
        end
    end
end

-- distance formula
function distance(x1,y1,x2,y2)
	return sqrt((x1-x2)*(x1-x2) + (y2-y1)*(y2-y1))
end

-- get the address for a point on-screen
function get_pixel_address(x,y)
	return 0x6000 + flr((x + 128 * y) / 2)
end

function horz_line_lighting(x1,x2,y,light_level)

	-- from start to end of address line, read each byte
	--0x6000 is the min, 0x7fff is the max
	-- each byte stores two pixel colors
	-- goes from left to right and up to down on-screen
	local add_start = get_address(x1,y)
	local add_end = get_address(x2,y)

	-- if we roll over to negative addresses, these are bad values
	if(add_start < 0 or add_end < 0) then
		return
	end

	-- from the start of the horizontal line to the end
	for address=add_start,add_end do

		-- if we are at the darkest level, simply change the colors to black
		if(light_level == 0) then
			poke(address, 0)

		-- if we are at the brightest level, do nothing
		else
			return
		end
	end
end

-- cone lighting is an arc of a circle
function cone_lighting(obj,angle_1,angle_2)
	local center = {x=obj.x+obj.w/2,y=obj.y+obj.h/2}

	-- for each scanline
	--for j=0,127 do
	--for j=96,127+cam.y do
	for j=dark_level,127+cam.y do

		-- if we are on a horizontal scanline above or below the object's max light radius, draw the whole
		-- horizontal line black
		if(abs(center.y - j) > obj.light_radius) then
			rectfill(cam.x,j,cam.x+127,j,0)
		else

			-- draw a horizontal line up to the leftmost part of the light circle
			if(center.x - obj.light_radius > 0) then
				rectfill(cam.x,j,center.x - obj.light_radius - 1,j,0)
			end

			-- color black pixels outside the light radius of the player
			for i=center.x - obj.light_radius,center.x + obj.light_radius + 1 do
				if(distance(i,j,center.x,center.y) > obj.light_radius) then
					pset(i,j,0)
				else
					--if(obj.light_type == "point") then
					if(pget(i,j) == 0) then
						pset(i,j,1)
					end
					--end
				end
			end

			-- draw a horizontal line up to the leftmost part of the light circle
			--rectfill(center.x + obj.light_radius + 1,j,128,j,0)
			rectfill(center.x + obj.light_radius + 1,j,128+cam.x,j,0)
		end
	end
end

-- circle lighting is a full 360 degree arc of cone lighting
function circle_lighting(obj)
	cone_lighting(obj,0,360)
end

--[[function multiple_circle_lighting(objs)
	local light_pixels = {}

	for o in all(objs) do
		add(light_pixels,{x=o.x,y=o.y})
	end

	--for j=0,127 do

	-- for each scanline
	--[[for j=96,127 do
		for i=0,127 do
			local dark_pixel = true
			for o in all(objs) do
				if(distance(o.x,o.y,i,j) < o.light_radius) then
					dark_pixel = false
				end
			end
			if(dark_pixel) then
				pset(i,j,0)
			else
				if(pget(i,j) == 0) then
					pset(i,j,12)
				end
			end
		end
	end

	-- check the min_y,max_y range for the light
	if(objs[2] == nil) then
		objs[2] = objs[1]
	end

	local min_y = min(objs[1].y-objs[1].light_radius,objs[2].y-objs[2].light_radius)
	local max_y = max(objs[1].y+objs[1].light_radius,objs[2].y+objs[2].light_radius)

	-- for each scanline
	for j=96,127 do
		
		-- if the scanline is below the min or above the max, draw full black lines
		if(j<min_y or j>max_y) then
			rectfill(0,j,127,j,0)
		else
			-- find all the light pixels on the line
			local light_pixels = {}

			-- for each light
			for o in all(objs) do
				-- check from minimum radius to maximum radius
				--local theta = 0.25 * (j-o.y)/o.light_radius
				--for i=o.x-o.light_radius*cos(theta),o.x+o.light_radius*cos(theta) do
				for i=o.x-o.light_radius,o.x+o.light_radius do

					-- a pixel is a light pixel if the distance is within the light range
					add(light_pixels,i)
				end
			end

			if(#light_pixels > 0) then

				-- we will construct multiple darkness lines based on the light pixels
				-- first, sort them
				sort(light_pixels)



				-- build the first line from 0 to the first pixel - 1
				rectfill(0,j,light_pixels[1]-1,j,0)

				
				for i=light_pixels[1],light_pixels[#light_pixels] do

					-- assume we have a dark pixel
					local dark_pixel = true

					-- check our table of light pixels
					for lp in all(light_pixels) do

						-- if our potential pixel is a light pixel, we don't have a dark pixel
						if(i==lp) then
							dark_pixel = false
						end
					end

					-- if the pixel is dark, darken it
					if(dark_pixel) then
						pset(i,j,0)

					-- otherwise
					else

						-- if its black ocean, light it up
						if(pget(i,j)==0) then
							pset(i,j,12)
						end
					end
				end

				-- build the last line from the last pixel + 1 to 127
				rectfill(light_pixels[#light_pixels]+1,j,127,j,0)
			end
		end
	end
end]]