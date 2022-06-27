local PepareLoop = PepareLoop
if not PepareLoop then 
    local try = LoadResourceFile("nb-libs","shared/loop.lua") or LoadResourceFile("nb-loop","nb-loop.lua")
    PepareLoop = PepareLoop or load(try.." return PepareLoop(...)")
end 
if not PepareLoop then
    print("loop lib not found, some functions can not be used")
end 


Scaleform = {}

local scaleform = {}
scaleform.__index = scaleform
scaleform.__tostring = function(self) return self.handle end 
scaleform.__call = function(t,...)
	local tb = {...}
	PushScaleformMovieFunction(t.handle,tb[1])
	for i=2,#tb do
        local v = tb[i]
		if type(v) == "number" then 
			if math.type(v) == "integer" then
				ScaleformMovieMethodAddParamInt(v)
			else
				ScaleformMovieMethodAddParamFloat(v)
			end
		elseif type(v) == "string" then 
            ScaleformMovieMethodAddParamTextureNameString(v) 
		elseif type(v) == "boolean" then ScaleformMovieMethodAddParamBool(v)
        elseif type(v) == "table" then 
            BeginTextCommandScaleformString(v[1])
            for k=2,#v do 
                local c = v[k]
                if string.sub(c, 1, string.len("label:")) == "label:" then 
                    local c = string.sub(c, string.len("label:")+1, string.len(c))
                    AddTextComponentSubstringTextLabel(c)
                elseif string.sub(c, 1, string.len("hashlabel:")) == "hashlabel:" then 
                    local c = string.sub(c, string.len("hashlabel:")+1, string.len(c))
                    AddTextComponentSubstringTextLabelHashKey(tonumber(c))
                else 
                    if type(c) == "number" then 
                        if string.find(GetStreetNameFromHashKey(GetHashKey(v[1])),"~a~") then 
                            AddTextComponentFormattedInteger(c,true)
                        else 
                            AddTextComponentInteger(c)
                        end 
                    else 
                        ScaleformMovieMethodAddParamTextureNameString(c) 
                    end
                end 
            end 
            EndTextCommandScaleformString()
		end
	end 
	PopScaleformMovieFunctionVoid()
end 

Scaleform.Request = function(name)
    local name = name 
    local handle = RequestScaleformMovie(name)
    local timer = GetGameTimer() 
    while not HasScaleformMovieLoaded(handle) and math.abs(GetTimeDifference(GetGameTimer(), timer)) < 5000 do 
        Wait(50)
    end 
    local self;self = {
        name = name,
        handle = handle,
        unvalid = false,
        DrawThisFrame = function() return DrawScaleformMovieFullscreen(handle,255,255,255,255,0) end ,
        Draw2DThisFrame = function(x,y,width,height) return DrawScaleformMovie(handle, x, y, width, height, 255, 255, 255, 255) end ,
        Draw2DPixelThisFrame = function(x,y,width,height) return DrawScaleformMovie(handle, x/1280, y/720, width, height, 255, 255, 255, 255) end ,
        Draw3DThisFrame = function(x, y, z, rx, ry, rz, scalex, scaley, scalez) return DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2) end ,
        Draw3DTransparentThisFrame = function(x, y, z, rx, ry, rz, scalex, scaley, scalez) return DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2) end ,
        loop = nil
    }
    return setmetatable(self,scaleform)
end 
setmetatable(Scaleform,{__call=function(scaleform,name,drawinit,drawend) return scaleform.Request(name,drawinit,drawend) end}) 


function scaleform:Close(cb)
	SetScaleformMovieAsNoLongerNeeded(self.handle)
	self.unvalid = true 
    if self.loop then 
        self.loop:delete() 
        self.loop = nil
    end 
    if cb then cb() end 
end

scaleform.Destory = scaleform.Close 
scaleform.Release = scaleform.Close 
scaleform.Kill = scaleform.Close 

function scaleform:IsAlive()
	return not self.unvalid
end

if PepareLoop then 

    function scaleform:PepareDrawInit(drawinit,drawend)
       self.drawinit = drawinit
       self.drawend = drawend or ResetScriptGfxAlign
    end 

    local DrawMain = function(self,drawer,...)
        if not self.loop then 
            self.loop = PepareLoop(0)
            local handle = self.handle
            local drawinit = self.drawinit
            local drawend = self.drawend
            local opts = {...}
            local unpack = table.unpack
            if not drawinit then 
                self.loop(function()
                    local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                    drawer(handle,unpack(opts))
                end,function()
                    self:Close()
                end)
            else 
                self.loop(function()
                    local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                    if drawinit() then 
                        drawer(handle,unpack(opts))
                    end 
                    drawend()
                end,function()
                    self:Close()
                end)
            end 
        end 
    end 

    local DrawMainDuration = function(self,drawer,duration,releasecb,...)
        if not self.loop then 
            self.loop = PepareLoop(0)
            
            local handle = self.handle
            local drawinit = self.drawinit
            local drawend = self.drawend
            local opts = {...}
            local unpack = table.unpack
            if not drawinit then 
                self.loop(function()
                    local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                    drawer(handle,unpack(opts))
                end,function()
                    self:Close()
                end)
            else 
                self.loop(function()
                    local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                    if drawinit() then 
                        drawer(handle,unpack(opts))
                    end 
                    drawend()
                end,function()
                    self:Close()
                    if releasecb then releasecb() end
                end)
            end 
            self.loop:release(duration)
        else 
            self.loop:release(duration)
        end 
    end 

    function scaleform:Draw()
        return DrawMain(self,DrawScaleformMovieFullscreen,255,255,255,255,0)
    end 

    function scaleform:DrawDuration(duration,releasecb)
        return DrawMainDuration(self,DrawScaleformMovieFullscreen,duration,releasecb,255,255,255,255,0)
    end 

    function scaleform:Draw2D(x,y,width,height)
        return DrawMain(self,DrawScaleformMovie,x, y, width, height, 255, 255, 255, 255)
    end 

    function scaleform:Draw2DDuration(duration,x,y,width,height,releasecb)
        return DrawMainDuration(self,DrawScaleformMovie,duration,releasecb,x, y, width, height, 255, 255, 255, 255)
    end 

    function scaleform:Draw2DPixel(x,y,width,height)
        return scaleform:Draw2D(self,x/1280,y/720,width,height)
    end 

    function scaleform:Draw3D(x, y, z, rx, ry, rz, scalex, scaley, scalez)
        return DrawMain(self,DrawScaleformMovie_3dNonAdditive, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end

    function scaleform:Draw3DDuration(duration,x, y, z, rx, ry, rz, scalex, scaley, scalez, releasecb)
        return DrawMainDuration(self,DrawScaleformMovie_3dNonAdditive, duration, releasecb, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end

    function scaleform:Draw3DTransparent(x, y, z, rx, ry, rz, scalex, scaley, scalez)
        return DrawMain(self,DrawScaleformMovie_3d, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end

    function scaleform:Draw3DTransparentDuration(duration, x, y, z, rx, ry, rz, scalex, scaley, scalez, releasecb)
        return DrawMainDuration(self,DrawScaleformMovie_3d, duration, releasecb, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
    end

    local function GetPlayerPedOrVehicle(player)
        local ped = (player == nil or player== -1) and PlayerPedId() or GetPlayerPed(player)
        local veh = GetVehiclePedIsIn(ped)
        return veh~=0 and veh or ped
    end

    function scaleform:Draw3DPed(ped,offsetx,offsety,offsetz)
        if not self.loop then 
            self.loop = PepareLoop(0)
            
            local handle = self.handle
            local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
            
            self.loop(function()
                local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                local entity = ped
                local model = GetEntityModel(entity)
                local s1,s2 = GetModelDimensions(model)
                local sizeVector = s2-s1
                local inveh = IsPedInAnyVehicle(entity) 
                local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
                local x,y,z = table.unpack(coords)
                local rot = GetEntityRotation(entity,2)
                local rx,ry,rz = table.unpack(rot)
                local scale = vector3(1.0,1.0,1.0)
                local scalex, scaley, scalez = table.unpack(scale)
                SetGameplayCamRelativePitch(0, 0.1);
                SetGameplayCamRelativeHeading(0);
                DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, inveh and -ry or ry, inveh and rz or -rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)

            end ,function()
                self:Close()
               
            end)
            
        end 
    end
    function scaleform:Draw3DPedDuration(duration,ped,offsetx,offsety,offsetz)
        if not self.loop then 
            self.loop = PepareLoop(0)
            
            local handle = self.handle
            local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
            
            self.loop(function()
                local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                local entity = ped
                local model = GetEntityModel(entity)
                local s1,s2 = GetModelDimensions(model)
                local sizeVector = s2-s1
                local inveh = IsPedInAnyVehicle(entity) 
                local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
                local x,y,z = table.unpack(coords)
                local rot = GetEntityRotation(entity,2)
                local rx,ry,rz = table.unpack(rot)
                local scale = vector3(1.0,1.0,1.0)
                local scalex, scaley, scalez = table.unpack(scale)
                SetGameplayCamRelativePitch(0, 0.1);
                SetGameplayCamRelativeHeading(0);
                DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, inveh and -ry or ry, inveh and rz or -rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
                if releasecb then releasecb() end
            end ,function()
                self:Close()
            end)
            self.loop:release(duration)
        else 
            self.loop:release(duration)
        end 
    end
    function scaleform:Draw3DPedTransparent(ped,offsetx,offsety,offsetz)
        if not self.loop then 
            self.loop = PepareLoop(0)
            
            local handle = self.handle
            local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
            self.loop(function()
                local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                local entity = ped
                local model = GetEntityModel(entity)
                local s1,s2 = GetModelDimensions(model)
                local sizeVector = s2-s1
                local inveh = IsPedInAnyVehicle(entity) 
                local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
                local x,y,z = table.unpack(coords)
                local rot = GetEntityRotation(entity,2)
                local rx,ry,rz = table.unpack(rot)
                local scale = vector3(1.0,1.0,1.0)
                local scalex, scaley, scalez = table.unpack(scale)
                SetGameplayCamRelativePitch(0, 0.1);
                SetGameplayCamRelativeHeading(0);
                DrawScaleformMovie_3d(handle, x, y, z, rx, inveh and -ry or ry, rz, 2.0, 2.0, 1.0, scalex, -scaley, scalez, 2)
            end ,function()
                self:Close()
            end)
        end 
    end
    function scaleform:Draw3DPedTransparentDuration(duration,ped,offsetx,offsety,offsetz)
        if not self.loop then 
            self.loop = PepareLoop(0)
            
            local handle = self.handle
            local offset = offsety == nil and (offsetx or vector3(0.0,0.0,0.0)) or vector3(offsetx,offsety,offsetz)
            self.loop(function()
                local temploop = self.loop
                    if not temploop then return temploop:delete() end 
                local entity = ped
                local model = GetEntityModel(entity)
                local s1,s2 = GetModelDimensions(model)
                local sizeVector = s2-s1
                local inveh = IsPedInAnyVehicle(entity) 
                local coords = inveh and GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.z/2) or GetOffsetFromEntityInWorldCoords(entity,offset.x,offset.y,offset.z+sizeVector.y/2)
                local x,y,z = table.unpack(coords)
                local rot = GetEntityRotation(entity,2)
                local rx,ry,rz = table.unpack(rot)
                local scale = vector3(1.0,1.0,1.0)
                local scalex, scaley, scalez = table.unpack(scale)
                SetGameplayCamRelativePitch(0, 0.1);
                SetGameplayCamRelativeHeading(0);
                DrawScaleformMovie_3d(handle, x, y, z, rx, inveh and -ry or ry, rz, 2.0, 2.0, 1.0, scalex, -scaley, scalez, 2)
            end ,function()
                self:Close()
            end)
            self.loop:release(duration)
        else 
            self.loop:release(duration)
        end 
    end

end 