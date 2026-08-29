-- Discord: iso9660, 641535958449127444 Roblox: the_usertheruserthe, 1457851253 
local sizeX = 128
local sizeY = 128


local sizeVector = Vector2.new(sizeX,sizeY)

local EI = game:GetService("AssetService"):CreateEditableImage({Size=sizeVector})
script.Parent.ImageContent = Content.fromObject(EI)

local screenbuffer = buffer.create(sizeX*sizeY*4)

local lerp = math.lerp
local floor = math.floor
function cLerp(c1,c2,t) 
	return 
		floor(lerp(c1.r,c2.r,t)*255),
		floor(lerp(c1.g,c2.g,t)*255),
		floor(lerp(c1.b,c2.b,t)*255)
end

function plot(x,y,r,g,b)
	buffer.writeu32(screenbuffer, x*4 + y*sizeX*4, bit32.bor(   
		255 * (2^24) ,
		b * (2^16) ,
		g * (2^8) ,
		r))

end

-- covers slopes between 0 and -1 
function bresenhamLow(x0, y0, x1, y1, c1, c2)

	local dx = x1 - x0
	local dy = y1 - y0
	local yi = 1
	if dy < 0 then
		yi = -1
		dy = -dy
	end
	local D = (2 * dy) - dx
	local y = y0

	for x = x0, x1 do
		local t = (x - x0) / (x1-x0) -- baked remap formula x0-x1 -> 0-1
		local r,g,b = cLerp(c1,c2,t)
		plot(x, y, r, g, b)
		if D > 0 then
			y = y + yi
			D = D + (2 * (dy - dx))
		else
			D = D + 2*dy
		end 
	end
end

-- covers positive or negative steep slopes
function bresenhamHigh(x0, y0, x1, y1, c1, c2)
	local dx = x1 - x0
	local dy = y1 - y0
	local xi = 1
	if dx < 0 then
		xi = -1
		dx = -dx
	end 
	local D = (2 * dx) - dy
	local x = x0

	for y = y0, y1 do
		local t = (y - y0) / (y1-y0) -- baked remap formula y0-y1 -> 0-1
		local r,g,b = cLerp(c1,c2,t)
		plot(x, y, r, g, b)
		if D > 0 then
			x = x + xi
			D = D + (2 * (dx - dy))
		else
			D = D + 2*dx
		end 
	end
end

local abs = math.abs
function bresenham(x0, y0, x1, y1,c1,c2)
	if abs(y1 - y0) < abs(x1 - x0) then
		if x0 > x1 then
			bresenhamLow(x1, y1, x0, y0,c2,c1)
		else
			bresenhamLow(x0, y0, x1, y1,c1,c2)
		end

	else
		if y0 > y1 then
			bresenhamHigh(x1, y1, x0, y0,c2,c1)
		else
			bresenhamHigh(x0, y0, x1, y1,c1,c2)
		end 
	end

end


-- struct vec3 {float x; float y; float z;}

-- vertices array: vec3[8]
local info = {
	{-0.5,-0.5,-0.5},

	{-0.5,0.5,-0.5},

	{0.5,-0.5,-0.5},

	{0.5,0.5,-0.5},

	{-0.5,-0.5,0.5},

	{-0.5,0.5,0.5},

	{0.5,-0.5,0.5},

	{0.5,0.5,0.5}

}

	
-- call it a gimbal mutex the way they be losing degrees of rotation

--2--------4
--| 6----8 |
--| |    | |
--| 5----7 |     
--1--------3

-- struct edge {unsigned int from; unsigned int to};

-- edges array: edge[12], uses vertex ids
local edges = {
	{1,5},
	{2,6},
	{3,7},
	{4,8},

	{1,2},
	{1,3},
	{3,4},
	{2,4},

	{5,6},
	{5,7},
	{7,8},
	{6,8},
};

local vertexColors = {
	Color3.new(0,0,0),
	Color3.new(1,0,0),
	Color3.new(0,1,0),
	Color3.new(1,1,0),
	
	Color3.new(0,0,1),
	Color3.new(1,0,1),
	Color3.new(0,1,1),
	Color3.new(1,1,1),
}

-- struct vec2 {float x; float y};
local rotated = {
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0},
	{0.0,0.0,0.0}	
} -- vec3[8]

local projected = {
	{0.0,0.0},	
	{0.0,0.0},
	{0.0,0.0},
	{0.0,0.0},
	{0.0,0.0},
	{0.0,0.0},
	{0.0,0.0},
	{0.0,0.0}
} -- vec2[8]
local angle = 0.0 -- float;

local angleX, angleY, angleZ -- float;
angleX = 0.0
angleY = 0.0
angleZ = 0.0

-- all sines are 0 and cosines are 1 for all angles are inited as 0
local xSin,ySin,zSin, xCos,yCos,zCos -- float;
xSin=0.0
ySin=0.0
zSin=0.0

xCos=1.0
yCos=1.0
zCos=1.0

-- protection against vert.z approaching 0
local distanceFromCamera = 2.0; -- float; 

local cos = math.cos -- float (*)(float)
local sin = math.sin -- float (*)(float)

game:GetService("RunService").RenderStepped:Connect(function(deltaTime: number) 


	-- clear, transparent background fill
	buffer.fill(screenbuffer,0,0,sizeX*sizeY*4) 
	
	local vert1Id, vert2Id, vert1, vert2 

	xSin = sin(angleX);
	xCos = cos(angleX);
	ySin = sin(angleY);
	yCos = cos(angleY);
	zSin = sin(angleZ);
	zCos = cos(angleZ);

	-- premultipled rotation matrix, XYZ intristic order 
	for i = 1, 8, 1 do
		rotated[i] = {
			-- .x=
			(info[i][1] * ( zCos * yCos )) + (info[i][2] * ( zCos * ySin * xSin - zSin * xCos )) + (info[i][3] * ( zCos * ySin * xCos + zSin * xSin )), 
			-- .y=
			(info[i][1] * ( zSin * yCos )) + (info[i][2] * ( zSin * ySin * xSin + zCos * xCos)) + (info[i][3] * (zSin * ySin * xCos - zCos * xSin )), 
			-- .z=
			(info[i][1] * ( -ySin)) + (info[i][2] * ( yCos * xSin)) + (info[i][3] * (yCos * xCos ))  
		} 
	end

	-- simple perspective projection
	for i = 1, 8, 1 do
		projected[i] = {
			rotated[i][1]/(rotated[i][3]+distanceFromCamera), -- vert.x  / ( vert.z + distanceFromCamera)
			rotated[i][2]/(rotated[i][3]+distanceFromCamera)  -- vert.y  / ( vert.z + distanceFromCamera)
		} 
	end

	-- drawing the edges
	for edgeID = 1, 12, 1 do
		
		vert1Id = edges[edgeID][1] -- (vec2*)(edges[edgeID].from) (or (vec2*)(&projected + edges[edgeID].from))
		vert2Id = edges[edgeID][2] -- (vec2*)(edges[edgeID].to)

		vert1 = (Vector2.new(projected[vert1Id][1],projected[vert1Id][2])+Vector2.one)/2*sizeVector -- (vec2){.x=(*vert1Id.x+1)/2,.y=(*vert1Id.y+1)/2}
		vert2 = (Vector2.new(projected[vert2Id][1],projected[vert2Id][2])+Vector2.one)/2*sizeVector -- (vec2){.x=(*vert2Id.x+1)/2,.y=(*vert2Id.y+1)/2}
		
		bresenham(
			floor(vert1.X),
			floor(vert1.Y),
			floor(vert2.X),
			floor(vert2.Y),
			
			vertexColors[vert1Id],
			vertexColors[vert2Id])
		
	end

	angleX+=deltaTime*0.4
	angleY+=deltaTime*0.8
	angleZ+=deltaTime*1.2
	
	EI:WritePixelsBuffer(Vector2.zero,sizeVector,screenbuffer)
end)
--shoutout to:
--Arthur Cayley - for helping to establish modern matrix algebra
--Leonhard Euler - for developing a way to describe 3d rotations using angles and coordinate transformations
--Jack Bresenham - for inventing the Bresenham line algorithm, allowing to actually plot the lines on a pixel grid
--David Evans and Ivan Sutherland - for pioneering the first CG research groups and helping to develop early techniques
--James D. Foley, Andries van Dam, Steven Feiner, and John Hughes - for writing "Fundamentals of Interactive Computer Graphics" in 1982
