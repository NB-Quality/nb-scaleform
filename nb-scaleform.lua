local _M_ = {}
do 

    local totalThread = 0
    local debugMode = false
    local e = {} setmetatable(e,{__call = function(t,...) end})
    local newLoopThread = function(t,k)  
        CreateThread(function()
            totalThread = totalThread + 1
            local o = t[k]
            repeat 
                local tasks = (o or e)
                local n = #tasks
                if n==0 then 
                    goto end_loop 
                end 
                for i=1,n do 
                    (tasks[i] or e)()
                end 
            until n == 0 or Wait(k) 
            ::end_loop::
            totalThread = totalThread - 1
            t[k] = nil

            return 
        end)
    end   

    local Loops = setmetatable({[e]=e}, {__newindex = function(t, k, v)
        rawset(t, k, v)
        newLoopThread(t, k)
    end})

    local newLoopObject = function(t,selff,f)
        local fns = t.fns
        local fnsbreak = t.fnsbreak
        local f = f 
        local selff = selff
        local ref = function(act,val)
            if act == "break" or act == "kill" then 
                local n = fns and #fns or 0
                if n > 0 then 
                    for i=1,n do 
                        if fns[i] == f then 
                            table.remove(fns,i)
                            if fnsbreak and fnsbreak[i] then fnsbreak[i]() end
                            table.remove(fnsbreak,i)
                            if #fns == 0 then 
                                table.remove(Loops[t.duration],i)
                            end
                            break
                        end
                    end
                else 
                    return t:delete(fbreak)
                end
            elseif act == "set" or act == "transfer" then 
                return t:transfer(val) 
            elseif act == "get" then 
                return t.duration
            end 
        end
        local aliveDelay = nil 
        return function(action,...)
            if not action then
                if aliveDelay and GetGameTimer() < aliveDelay then 
                    return e()
                else 
                    aliveDelay = nil 
                    return selff(ref)
                end
            elseif action == "setalivedelay" then 
                local delay = ...
                aliveDelay = GetGameTimer() + delay
            else 
                ref(action,...)
            end
        end 
    end 

    local PepareLoop = function(duration,init)
        if not Loops[duration] then Loops[duration] = {} end 
        local self = {}
        self.duration = duration
        self.fns = {}
        self.fnsbreak = {}
        local selff
        if init then 
            selff = function(ref)
                local fns = self.fns
                local n = #fns
                if init() then 
                    for i=1,n do 
                        fns[i](ref)
                    end 
                end 
            end 
        else 
            selff = function(ref)
                local fns = self.fns
                local n = #fns
                for i=1,n do 
                    fns[i](ref)
                end 
            end 
        end 
        setmetatable(self, {__index = Loops[duration],__call = function(t,f,...)
            if type(f) ~= "string" then 
                local fbreak = ...
                table.insert(t.fns, f)
                if fbreak then table.insert(self.fnsbreak, fbreak) end
                local obj = newLoopObject(self,selff,f)
                table.insert(Loops[duration], obj)
                self.obj = obj
                return self
            elseif self.obj then  
                return self.obj(f,...)
            end 
        end,__tostring = function(t)
            return "Loop("..t.duration.."), Total Thread: "..totalThread
        end})
        self.found = function(self,f)
            for i,v in ipairs(Loops[self.duration]) do
                if v == self.obj then
                    return i
                end 
            end 
            return false
        end
        self.delay = nil 
        self.delete = function(s,delay,cb)
            local delay = delay
            local cb = cb 
            if type(delay) ~= "number" then 
                cb = delay
                delay = nil 
            end 
            local del = function(instant)
                if self.delay == delay or instant == "negbook" then 
                    if Loops[duration] then 
                        local i = s.found(s)
                        if i then
                            local fns = self.fns
                            local fnsbreak = self.fnsbreak
                            local n = fns and #fns or 0
                            if n > 0 then 
                                table.remove(fns,n)
                                if fnsbreak and fnsbreak[n] then fnsbreak[n]() end
                                table.remove(fnsbreak,n)
                                if #fns == 0 then 
                                    table.remove(Loops[duration],i)
                                end
                                if cb then cb() end
                            elseif debugMode then  
                                error("It should be deleted")
                            end 
                            
                        elseif debugMode then  
                            error('Task deleteing not found',2)
                        end
                    elseif debugMode then  
                        error('Task deleteing not found',2)
                    end 
                end 
            end 
            if delay and delay>0 then 
                SetTimeout(delay,del)
                self.delay = delay 
            else
                self.delay = nil 
                del("negbook")
            end 
        end
        self.transfer = function(s,newduration)
            if s.duration == newduration then return end
            local i = s.found(s) 
            if i then
                table.remove(Loops[s.duration],i)
                s.obj("setalivedelay",newduration)
                if not Loops[newduration] then Loops[newduration] = {} end 
                table.insert(Loops[newduration],s.obj)
                s.duration = newduration
            end
        end
        self.set = self.transfer 
        return self
    end 
    _M_.PepareLoop = PepareLoop
end 



local PepareLoop = PepareLoop
if not PepareLoop then 
    local try = LoadResourceFile("nb-libs","shared/loop.lua") or LoadResourceFile("nb-loop","nb-loop.lua")
    PepareLoop = PepareLoop or (try and load(try.." return PepareLoop(...)")) or _M_.PepareLoop
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
        local SetCurrentDrawer = function(_drawer)
            local drawer = function(...) _drawer(handle,...) end  
            return function(cb)
                if not loop then 
                    loop = PepareLoop(0)
                    local unpack = table.unpack
                    if not drawinit then 
                        loop(function(duration)
                            if not loop then return duration("kill") end 
                            cb(drawer)
                        end,function()
                            self:Close()
                        end)
                    else 
                        loop(function(duration)
                            if not loop then return duration("kill") end 
                            if drawinit() then 
                                cb(drawer)
                            end 
                            drawend()
                        end,function()
                            self:Close()
                        end)
                    end 
                end 
            end 
        end 
        
        function self:PepareDrawInit(_drawinit,_drawend)
           drawinit = _drawinit
           drawend = _drawend or ResetScriptGfxAlign
        end 
        
        local Drawer = SetCurrentDrawer(DrawScaleformMovieFullscreen)
        function self:Draw()
            return Drawer(function(_)
                _(255, 255, 255, 255,0)
            end)
        end 

        local Drawer = SetCurrentDrawer(DrawScaleformMovie)
        function self:Draw2D(x,y,width,height)
            return Drawer(function(_)
                _(x, y, width, height, 255, 255, 255, 255)
            end)
        end 

        function self:Draw2DPixel(x,y,width,height)
            return self:Draw2D(x/1280,y/720,width,height)
        end 

        local Drawer = SetCurrentDrawer(DrawScaleformMovie_3dNonAdditive)
        function self:Draw3D(x, y, z, rx, ry, rz, scalex, scaley, scalez)
            return Drawer(function(_)
                _(x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
            end)
        end

        local Drawer = SetCurrentDrawer(DrawScaleformMovie_3d)
        function self:Draw3DTransparent(x, y, z, rx, ry, rz, scalex, scaley, scalez)
            return Drawer(function(_)
                _(x, y, z, rx, ry, rz, 2.0, 2.0, 1.0, scalex, scaley, scalez, 2)
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






