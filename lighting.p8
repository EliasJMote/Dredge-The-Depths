pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
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
	for j=96,127 do

		-- if we are on a horizontal scanline above or below the object's max light radius, draw the whole
		-- horizontal line black
		if(abs(center.y - j) > obj.light_radius) then
			rectfill(0,j,127,j,0)
		else

			-- draw a horizontal line up to the leftmost part of the light circle
			if(center.x - obj.light_radius > 0) then
				rectfill(0,j,center.x - obj.light_radius - 1,j,0)
			end

			-- color black pixels outside the light radius of the player
			for i=center.x - obj.light_radius,center.x + obj.light_radius do
				if(distance(i,j,center.x,center.y) > obj.light_radius) then
					pset(i,j,0)
				end
			end

			-- draw a horizontal line up to the leftmost part of the light circle
			rectfill(center.x + obj.light_radius + 1,j,127,j,0)
		end
	end
end

-- circle lighting is a full 360 degree arc of cone lighting
function circle_lighting(obj)
	cone_lighting(obj,0,360)
end

function multiple_circle_lighting(objs)
	local light_pixels = {}

	for o in all(objs) do
		add(light_pixels,{x=o.x,y=o.y})
	end

	--for j=0,127 do
	for j=96,127 do
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
end