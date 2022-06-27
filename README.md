# nb-scaleform
Lua extended Scaleform Wrapper

## with wrapper
```
CreateThread(function()
    local sf = Scaleform("mp_big_message_freemode")
    sf("SHOW_SHARD_WASTED_MP_MESSAGE", "SOME TEXT AND LABEL:", {"ESDOLLA",123456}, 5)
    sf:Draw()
end)
```
```
CreateThread(function()
    local sfhud = Scaleform(21)
    sfhud("SET_PLAYER_CHIPS",0)
    sfhud:Draw()
    local sfhud2 = Scaleform(22)
    sfhud2("SET_PLAYER_CHIP_CHANGE",123,true)
    sfhud2:Draw()
    Wait(4000)
    sfhud:Close()
    sfhud2:Close()
end)
```

## without Wrapper:
```
CreateThread(function()
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
```
CreateThread(function()
    local scale = RequestScaleformScriptHudMovie(21)
    while not HasScaleformScriptHudMovieLoaded(21) do
        print('wait for scaleform')
        Citizen.Wait(0)
    end
    BeginScaleformScriptHudMovieMethod(21, "SET_PLAYER_CHIPS")
    ScaleformMovieMethodAddParamInt(123)
    EndScaleformMovieMethod()
    local scale = RequestScaleformScriptHudMovie(22)
    while not HasScaleformScriptHudMovieLoaded(22) do
        print('wait for scaleform')
        Citizen.Wait(0)
    end
    BeginScaleformScriptHudMovieMethod(22, "SET_PLAYER_CHIP_CHANGE")
    ScaleformMovieMethodAddParamInt(123)
    ScaleformMovieMethodAddParamBool(true)
    EndScaleformMovieMethod()
    Wait(4000)
    RemoveScaleformScriptHudMovie(21)
    RemoveScaleformScriptHudMovie(22)
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
handle:DrawThisFrame()
handle:Draw2DThisFrame(x,y,width,height)
handle:Draw2DPixelThisFrame(x,y,width,height)
handle:Draw3DThisFrame(x, y, z, rx, ry, rz, scalex, scaley, scalez)
handle:Draw3DTransparentThisFrame(x, y, z, rx, ry, rz, scalex, scaley, scalez)

```
