CreateThread(function()
    local sf = Scaleform("mp_big_message_freemode")
    sf("SHOW_SHARD_WASTED_MP_MESSAGE", "SOME TEXT AND LABEL:", {"ESDOLLA",123456}, 5)
    sf:Draw()
   
    sf:Close(4000,function()
        print('closed')
    end)
end)
CreateThread(function()
    local sfhud = Scaleform(21)
    sfhud("SET_PLAYER_CHIPS",0)
    sfhud:Draw()
    local sfhud2 = Scaleform(22)
    sfhud2("SET_PLAYER_CHIP_CHANGE",123,true)
    sfhud2:Draw()
 
    sfhud:Close(4000,function()
        print('closed2')
    end)
    sfhud2:Close(4000,function()
        print('closed3')
    end)
end)
