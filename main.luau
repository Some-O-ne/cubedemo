-- Discord: iso9660, 641535958449127444 Roblox: the_usertheruserthe, 1457851253 
local sizeX = 128
local sizeY = 128

local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local screenbuffer = buffer.create(sizeX*sizeY*4)

local lerp = math.lerp
local floor = math.floor
local abs = math.abs

local parent = script.Parent

local sizeVector = Vector2.new(sizeX,sizeY)

local EI = AssetService:CreateEditableImage({Size=sizeVector})


parent.ImageContent = Content.fromObject(EI)


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

-- covers cases where the line slope is low (dy < dx)
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

-- covers cases where the line slope is high (dy > dx)
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

-- determines which out of the 2 implementations to use, also reverses argument order in cases where the end is before the start. 
-- when arguments are reversed, color order is reversed as well
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


local vertexData = {
	{x=-0.5,y=-0.5,z=-0.5},

	{x=-0.5,y=0.5,z=-0.5},

	{x=0.5,y=-0.5,z=-0.5},

	{x=0.5,y=0.5,z=-0.5},

	{x=-0.5,y=-0.5,z=0.5},

	{x=-0.5,y=0.5,z=0.5},

	{x=0.5,y=-0.5,z=0.5},

	{x=0.5,y=0.5,z=0.5}

}


-- call it a gimbal mutex the way they be losing degrees of rotation

--2--------4
--| 6----8 |
--| |    | |
--| 5----7 |     
--1--------3

-- struct edge {unsigned int from; unsigned int to};

-- edges array: edge[16], uses vertex ids
local edges = {
	{startVertex=1,endVertex=5},
	{startVertex=2,endVertex=6},
	{startVertex=3,endVertex=7},
	{startVertex=4,endVertex=8},

	{startVertex=1,endVertex=2},
	{startVertex=1,endVertex=3},
	{startVertex=3,endVertex=4},
	{startVertex=2,endVertex=4},

	{startVertex=5,endVertex=6},
	{startVertex=5,endVertex=7},
	{startVertex=7,endVertex=8},
	{startVertex=6,endVertex=8},
	
	{startVertex=1,endVertex=4},	
	{startVertex=1,endVertex=6},
	{startVertex=5,endVertex=8},
	{startVertex=7,endVertex=4},
	{startVertex=2,endVertex=8},
	{startVertex=1,endVertex=7},


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
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0},
	{x=0.0,y=0.0,z=0.0}	
} -- vec3[8]


local projected = {
	{x=0.0,y=0.0},	
	{x=0.0,y=0.0},
	{x=0.0,y=0.0},
	{x=0.0,y=0.0},
	{x=0.0,y=0.0},
	{x=0.0,y=0.0},
	{x=0.0,y=0.0},
	{x=0.0,y=0.0}
} -- vec2[8]

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

function getEdgeDepth(edge)
	return (rotated[edge.startVertex].z + rotated[edge.endVertex].z)/2
end

-- protection against vert.z approaching 0
local distanceFromCamera = 2.0; -- float; 

local cos = math.cos
local sin = math.sin 

RunService.RenderStepped:Connect(function(deltaTime: number) 
	-- clear, transparent background fill
	buffer.fill(screenbuffer,0,0,sizeX*sizeY*4) 
 
	xSin = sin(angleX);
	xCos = cos(angleX);
	ySin = sin(angleY);
	yCos = cos(angleY);
	zSin = sin(angleZ);
	zCos = cos(angleZ);
	
	-- rotating the vertices using a
	-- premultipled rotation matrix, XYZ order 
	for i = 1, #vertexData do
		rotated[i] = {
			x=
				vertexData[i].x * ( zCos * yCos ) +
				vertexData[i].y * ( zCos * ySin * xSin - zSin * xCos ) + 
				vertexData[i].z * ( zCos * ySin * xCos + zSin * xSin ),
			
			y=
				vertexData[i].x * ( zSin * yCos ) + 
				vertexData[i].y * ( zSin * ySin * xSin + zCos * xCos ) + 
				vertexData[i].z * ( zSin * ySin * xCos - zCos * xSin ),
			
			z=
				vertexData[i].x * ( -ySin ) + 
				vertexData[i].y * ( yCos * xSin ) + 
				vertexData[i].z * ( yCos * xCos )  
		} 
	end

	-- simple perspective projection
	for i = 1, #rotated do
		projected[i] = {
			x=rotated[i].x/(rotated[i].z+distanceFromCamera),
			y=rotated[i].y/(rotated[i].z+distanceFromCamera)  
		} 
	end
	
	-- simple implementation of the painter's algorithm, works tho, no weird overlaps
	-- '>' because the camera is looking toward +Z
	table.sort(edges,
		function(a0, a1)
			return getEdgeDepth(a0) > getEdgeDepth(a1) 
	end)
	
	local startVertexId, endVertexId, startVertex, endVertex
	
	-- drawing the edges
	for edgeID = 1, #edges do

		startVertexId = edges[edgeID].startVertex
		endVertexId = edges[edgeID].endVertex 

		startVertex = sizeVector/2 * Vector2.new(
			projected[startVertexId].x+1,
			projected[startVertexId].y+1)
		
		endVertex =  sizeVector/2 * Vector2.new(
			projected[endVertexId].x+1,
			projected[endVertexId].y+1) 

		bresenham(
			floor(startVertex.X),
			floor(startVertex.Y),
			floor(endVertex.X),
			floor(endVertex.Y),

			vertexColors[startVertexId],
			vertexColors[endVertexId])

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
