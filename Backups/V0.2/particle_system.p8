pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function create_bubble_emitter(x,y)
	local e = {
		x=x,
		y=y,
		t=flr(rnd(60)),
		name="bubble"
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
		col=6
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
	if(b.t >= 150) then
		del(bs,b)
	end
	b.t += 1
	return b,bs
end

function create_spark_emitter(x,y)
	local e = {
		x=x,
		y=y,
		t=0,
		name="spark"
	}
	return e
end

function emit_spark(x,y)
	local s = {
		x=x,
		y=y,
		dx=rnd(4)-2,
		dy=rnd(4)-2,
		t=5,
		col=3
	}
	return s
end

function update_spark_emitter(e,ss)
	if(e.t >= 2) then
		add(ss,emit_spark(e.x,e.y))
		e.t = 0
	end
	e.t +=1
	return e,ss
end

function update_spark(s,ss)
	s.x += s.dx
	s.y += s.dy
	
	if(s.t <= 0) then
		del(ss,s)
	end
	s.t -= 1
	return s,ss
end