pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function create_bubble_emitter(x,y)
	local e = {
		x=x,
		y=y,
		t=flr(rnd(60)),
	}
	return e
end

function emit_bubble(x,y)
	local b = {
		x=x,
		x_init=x,
		y=y,
		r=4,
		t=flr(rnd(30)),
		col=3
	}
	return b
end

function update_bubble_emitter(e,bs)
	if(e.t >= 60) then
		add(bs,emit_bubble(e.x,e.y))
		e.t = 0
	end
	e.t +=1
	return e,bs
end

function update_bubble(b,bs)
	b.x = b.x_init + 4*sin(b.t / 45)
	b.y -= 0.5
	if(b.t % 30 == 0) then
		b.r -= 1
	end
	if(b.t >= 120) then
		del(bs,b)
	end
	b.t += 1
	return b,bs
end