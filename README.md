# nb-scaleform
Lua extended Scaleform Wrapper

## with wrapper
```
local sf = Scaleform("mp_big_message_freemode")
sf("SHOW_SHARD_WASTED_MP_MESSAGE", "SOME TEXT", "SOME MORE TEXT", 5)
sf:Draw()
```

## without Wrapper:
```
Citizen.CreateThread(function()
    local scaleform = RequestScaleformMovie("mp_big_message_freemode")
    while not HasScaleformMovieLoaded(scaleform) do
        Citizen.Wait(0)
    end
    
    BeginScaleformMovieMethod(scaleform, "SHOW_SHARD_WASTED_MP_MESSAGE")
    PushScaleformMovieMethodParameterString("SOME TEXT")
    PushScaleformMovieMethodParameterString("SOME MORE TEXT")
    PushScaleformMovieMethodParameterInt(5)
    EndScaleformMovieMethod()

    while true do
        Citizen.Wait(0)
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
    end
end)
```

## more functions 
```
handle:PepareDrawInit(initfn,endfn) -- you can put SetScriptGfxDrawOrder or something like that and endfn with ResetScriptGfxAlign
handle:Draw()
handle:DrawDuration(duration,releasecb)
handle:Draw2D(x,y,width,height)
handle:Draw2DDuration(duration,x,y,width,height,releasecb)
handle:Draw2DPixel(x,y,width,height) 
handle:Draw3D(x, y, z, rx, ry, rz, scalex, scaley, scalez)
handle:Draw3DDuration(duration,x, y, z, rx, ry, rz, scalex, scaley, scalez, releasecb)
handle:Draw3DTransparent(x, y, z, rx, ry, rz, scalex, scaley, scalez)
handle:Draw3DTransparentDuration(duration, x, y, z, rx, ry, rz, scalex, scaley, scalez, releasecb)
handle:Draw3DPed(ped,offsetx,offsety,offsetz) -- draw a scaleform by the ped, you could make floating hud something easily...
handle:Draw3DPedTransparent(ped,offsetx,offsety,offsetz) -- draw a scaleform by the ped, you could make floating hud something easily...
handle:Draw3DPedDuration(duration,ped,offsetx,offsety,offsetz) -- draw a scaleform by the ped, you could make floating hud something easily...
handle:Draw3DPedTransparentDuration(duration,ped,offsetx,offsety,offsetz) -- draw a scaleform by the ped, you could make floating hud something easily...
```
