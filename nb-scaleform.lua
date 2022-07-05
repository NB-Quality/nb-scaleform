
local _M_ = {}
do 
local Tasksync = _M_
local Loops = {}
local e = {}
local totalthreads = 0
setmetatable(Loops,{__newindex=function(t,k,v) rawset(t,tostring(k),v) end,__index=function(t,k) return rawget(t,tostring(k)) end})
setmetatable(e,{__call=function()end})

local GetDurationAndIndex = function(obj,cb) for duration,names in pairs(Loops) do for i=1,#names do local v = names[i] if v == obj then local duration_tonumber = tonumber(duration) if cb then cb(duration_tonumber,i) end return duration_tonumber,i end end end end
local remove_manual = function(duration,index) local indexs = Loops[duration] table.remove(indexs,index) if #indexs == 0 then Loops[duration] = nil end end 
local remove = function(obj,cb) GetDurationAndIndex(obj,function(duration,index) remove_manual(duration,index) if cb then cb() end end) end 
local init = function(duration,obj,cb) if Loops[duration] == nil then Loops[duration] = {}; if cb then cb() end end table.insert(Loops[duration],obj) end 
local newloopobject = function(duration,onaction,ondelete)
    local onaction = onaction 
    local ondelete = ondelete 
    local duration = duration 
    local releaseobject = nil 
    local ref = nil 
    if onaction and ondelete then 
        return function (action,value)
            if not action or action == "onaction" then 
                return onaction(ref)
            elseif action == "ondelete" then 
                return ondelete()
            elseif action == "setduration" then 
                duration = value 
            elseif action == "getduration" then 
                return duration 
            elseif action == "getfn" then 
                return onaction 
            elseif action == "setref" then 
                ref = value
            elseif action == "setreleasetimerobject" then 
                releaseobject = value 
            elseif action == "getreleasetimerobject" then 
                return releaseobject
            elseif action == "set" then 
                duration = value 
            elseif action == "get" then 
                return duration 
            end 
        end 
    elseif onaction and not ondelete then 
        return function (action,value)
            if not action or action == "onaction" then 
                return onaction(ref)
            elseif action == "setduration" then 
                duration = value 
            elseif action == "getduration" then 
                return duration 
            elseif action == "getfn" then 
                return onaction 
            elseif action == "setref" then 
                ref = value
            elseif action == "setreleasetimerobject" then 
                releaseobject = value 
            elseif action == "getreleasetimerobject" then 
                return releaseobject
            elseif action == "set" then 
                duration = value 
            elseif action == "get" then 
                return duration 
            end 
        end 
    end 
end 


local updateloop = function(obj,new_duration,cb)
    remove(obj,function()
        init(new_duration,obj,function()
            Tasksync.__createNewThreadForNewDurationLoopFunctionsGroup(new_duration,cb)
        end)
    end)
end 

local ref = function (default,obj)
    return function(action,v) 
        if action == 'get' then 
            return obj("getduration") 
        elseif action == 'set' then 
            return Tasksync.transferobject(obj,v)  
        elseif action == 'kill' or action == 'break' then 
            Tasksync.deleteloop(obj)
        end 
    end 
end 

Tasksync.__createNewThreadForNewDurationLoopFunctionsGroup = function(duration,init)
    local init = init   
    CreateThread(function()
        totalthreads = totalthreads + 1
        local loop = Loops[duration]
        
        if init then init() init = nil end
        repeat 
            local Objects = (loop or e)
            local n = #Objects
            for i=1,n do 
                (Objects[i] or e)()
            end 
            Wait(duration)
            
        until n == 0 
        --print("Deleted thread",duration)
        totalthreads = totalthreads - 1
        return 
    end)
end     

Tasksync.__createNewThreadForNewDurationLoopFunctionsGroupDebug = function(duration,init)
    local init = init   
    CreateThread(function()
        local loop = Loops[duration]
        if init then init() init = nil end
        repeat 
            local Objects = (loop or e)
            local n = #Objects
            for i=1,n do 
                (Objects[i] or e)()
            end 
        until n == 0 
        --print("Deleted thread",duration)
        return 
    end)
end     

Tasksync.addloop = function(duration,fn,fnondelete,isreplace)
    local obj = newloopobject(duration,fn,fnondelete)
    obj("setref",ref(duration,obj))
    local indexs = Loops[duration]
    if isreplace and Loops[duration] then 
        for i=1,#indexs do 
            if indexs[i]("getfn") == fn then 
                remove(indexs[i])
            end 
        end 
    end 
    init(duration,obj,function()
        if duration < 0 then Tasksync.__createNewThreadForNewDurationLoopFunctionsGroupDebug(duration) else 
            Tasksync.__createNewThreadForNewDurationLoopFunctionsGroup(duration)
        end 
    end)
    return obj
end 
Tasksync.insertloop = Tasksync.addloop

Tasksync.deleteloop = function(obj,cb)
    remove(obj,function()
        obj("ondelete")
        if cb then cb() end 
    end)
end 
Tasksync.removeloop = Tasksync.deleteloop

Tasksync.transferobject = function(obj,duration)
    local old_duration = obj("getduration")
    if duration ~= old_duration then 
        updateloop(obj,duration,function()
            obj("setduration",duration)
            Wait(old_duration)
        end)
    end 
end 
 
local newreleasetimer = function(obj,timer,cb)
    local releasetimer = timer   + GetGameTimer()
    local obj = obj 
    local tempcheck = Tasksync.PepareLoop(250)  
    tempcheck(function(duration)
        if GetGameTimer() > releasetimer then 
            tempcheck:delete()
            Tasksync.deleteloop(obj,cb)
        end 
    end)
    return function(action,value)
        if action == "get" then 
            return releasetimer
        elseif action == "set" then 
            releasetimer = timer + GetGameTimer()
        end 
    end 
end  


Tasksync.setreleasetimer = function(obj,releasetimer,cb)
    if not obj("getreleasetimerobject") then 
        obj("setreleasetimerobject",newreleasetimer(obj,releasetimer,function()
            obj("setreleasetimerobject",nil)
            if cb then cb() end 
        end))
    else 
        obj("getreleasetimerobject")("set",releasetimer)
    end 

end 

Tasksync.PepareLoop = function(duration,releasecb)
    local self = {}
    local obj = nil 
    self.add = function(self,_fn,_fnondelete)
        local ontaskdelete = nil
        if not _fnondelete then 
            if releasecb then 
                ontaskdelete = function()
                    releasecb(obj)
                end 
            end
        else 
            if releasecb then 
                ontaskdelete = function()
                    releasecb(obj)
                    _fnondelete(obj)
                end 
            else 
                ontaskdelete = function()
                    _fnondelete(obj)
                end 
            end
        end
        obj = Tasksync.addloop(duration,_fn,ontaskdelete)
        return obj
    end
    self.delete = function(self,duration,cb)
        local cb = type(duration) ~= "number" and duration or cb 
        local duration = type(duration) == "number" and duration or nil
    
        if obj then 
            if duration then 
                Tasksync.setreleasetimer(obj,duration,cb) 
            else 
                Tasksync.deleteloop(obj,cb) 
            end 
        end
    end
    self.release = self.delete
    self.remove = self.delete
    self.kill = self.delete
    self.set = function(self,newduration)
        if obj then Tasksync.transferobject(obj,newduration) end 
    end
    self.get = function(self)
        if obj then return obj("getduration") end 
    end

    return setmetatable(self,{__call = function(self,...)
        return self:add(...)
    end,__tostring = function()
        return "This duration:"..self.get().."Total loop threads:"..totalthreads
    end})
end
end 


local PepareLoop = PepareLoop
if not PepareLoop then 
    local try = LoadResourceFile("nb-libs","shared/loop.lua") or LoadResourceFile("nb-loop","nb-loop.lua")
    PepareLoop = PepareLoop or load(try.." return PepareLoop(...)") or _M_.PepareLoop
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






