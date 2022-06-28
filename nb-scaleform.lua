local PepareLoop = PepareLoop
if not PepareLoop then 
    local try = LoadResourceFile("nb-libs","shared/loop.lua") or LoadResourceFile("nb-loop","nb-loop.lua")
    PepareLoop = PepareLoop or load(try.." return PepareLoop(...)")
end 
if not PepareLoop then
    print("loop lib not found, some functions can not be used")
end 


Scaleform = {}

Scaleform.Request = function(name)
    local ishud = type(name) == "number"
    local name = name 
    local handle = ishud and RequestScaleformScriptHudMovie(name) or RequestScaleformMovie(name)
    local timer = GetGameTimer() 
    repeat 
        local check = (ishud and HasScaleformScriptHudMovieLoaded(name) or HasScaleformMovieLoaded(handle))
        Wait(50)
    until check or math.abs(GetTimeDifference(GetGameTimer(), timer)) > 5000
    local unvalid = false 
    local drawinit = nil
    local drawend = nil
    local loop = nil 
    local self;self = {
        handle = handle,
        ishud = ishud,
        DrawThisFrame = function() return DrawScaleformMovieFullscreen(handle,255,255,255,255,0) end ,
        Draw2DThisFrame = function(x,y,width,height) return DrawScaleformMovie(handle, x, y, width, height, 255, 255, 255, 255) end ,
        Draw2DPixelThisFrame = function(x,y,width,height) return DrawScaleformMovie(handle, x/1280, y/720, width, height, 255, 255, 255, 255) end ,
        Draw3DThisFrame = function(x, y, z, rx, ry, rz, scalex, scaley, scalez) return DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2) end ,
        Draw3DTransparentThisFrame = function(x, y, z, rx, ry, rz, scalex, scaley, scalez) return DrawScaleformMovie_3dNonAdditive(handle, x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2) end ,
        
    }
    function self:Release(duration,cb)
        if PepareLoop then 
            local cb = type(duration) ~= "number" and duration or cb 
            local duration = type(duration) == "number" and duration or nil
            if not duration then 
                if ishud then 
                    RemoveScaleformScriptHudMovie(name)
                else 
                    SetScaleformMovieAsNoLongerNeeded(handle)
                end 
                unvalid = true 
                if loop then 
                    loop:delete() 
                    loop = nil
                end 
                if cb then cb() end 
            elseif loop then  
                local cb_local = function()
                    if ishud then 
                    RemoveScaleformScriptHudMovie(name)
                    else 
                        SetScaleformMovieAsNoLongerNeeded(handle)
                    end 
                    unvalid = true
                    if cb then cb() end 
                    loop = nil
                end 
                loop:delete(duration,cb_local) 
            end 
        else 
            if ishud then 
                RemoveScaleformScriptHudMovie(name)
            else 
                SetScaleformMovieAsNoLongerNeeded(handle)
            end 
            unvalid = true 
            if loop then 
                loop:delete() 
                loop = nil
            end 
            if cb then cb() end 
        end 
    end
    self.Destory = self.Release 
    self.Close = self.Release 
    self.Kill = self.Release 
    function self:IsAlive()
        return not unvalid
    end
    if PepareLoop then 
        local DrawScaleformMovieFullscreen = DrawScaleformMovieFullscreen
        local DrawScaleformMovie = DrawScaleformMovie
        local DrawScaleformMovie_3dNonAdditive = DrawScaleformMovie_3dNonAdditive
        local DrawScaleformMovie_3d = DrawScaleformMovie_3d
        local DrawMain = function(drawer,params)
            if not loop then 
                loop = PepareLoop(0)
                local unpack = table.unpack
                local drawer = drawer 
                if not drawinit then 
                    loop(function(duration)
                        if not loop then return duration("kill") end 
                        params(function(...)
                            drawer(handle,...)
                        end)
                    end,function()
                        self:Close()
                    end)
                else 
                    loop(function(duration)
                        if not loop then return duration("kill") end 
                        if drawinit() then 
                            params(function(...)
                                drawer(handle,...)
                            end)
                        end 
                        drawend()
                    end,function()
                        self:Close()
                    end)
                end 
            end 
        end 
        
        function self:PepareDrawInit(_drawinit,_drawend)
           drawinit = _drawinit
           drawend = _drawend or ResetScriptGfxAlign
        end 
        function self:Draw()
            return DrawMain(DrawScaleformMovieFullscreen,function(params)
                params(255,255,255,255,0)
            end)
        end 

        function self:Draw2D(x,y,width,height)
            return DrawMain(DrawScaleformMovie,function(params)
                params(x, y, width, height, 255, 255, 255, 255)
            end)
        end 

        function self:Draw2DPixel(x,y,width,height)
            return self:Draw2D(x/1280,y/720,width,height)
        end 

        function self:Draw3D(x, y, z, rx, ry, rz, scalex, scaley, scalez)
            return DrawMain(DrawScaleformMovie_3dNonAdditive,function(params)
                params(x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
            end)
        end

        function self:Draw3DTransparent(x, y, z, rx, ry, rz, scalex, scaley, scalez)
            return DrawMain(DrawScaleformMovie_3d,function(params)
                params(x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
            end)
        end
        function self:__tostring() return handle end 
        function self:__call(...)
            local tb = {...}
            if ishud then 
                BeginScaleformScriptHudMovieMethod(name,tb[1])
            else 
                BeginScaleformMovieMethod(handle,tb[1])
            end 
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
            EndScaleformMovieMethod()
        end 
    end 
    return setmetatable(self,self)
end 
setmetatable(Scaleform,{__call=function(x,name,drawinit,drawend) return x.Request(name,drawinit,drawend) end}) 






