local editorOpen = false

RegisterNetEvent('ox_lib:openProByteUIEditor', function(settings)
    if editorOpen then
        SendNUIMessage({ action = 'setProByteUISettings', data = settings })
        return
    end
    editorOpen = true
    SetNuiFocus(true, true)
    SetNuiFocusKeepInput(false)
    SendNUIMessage({
        action = 'openProByteUIEditor',
        data = settings,
    })
end)

RegisterNetEvent('ox_lib:updateProByteUISettings', function(settings)
    SendNUIMessage({
        action = 'setProByteUISettings',
        data = settings,
    })
end)

RegisterNUICallback('getProByteUISettings', function(_, cb)
    cb(lib.callback.await('ox_lib:getProByteUISettings', false))
end)

RegisterNUICallback('saveProByteUISettings', function(data, cb)
    cb(lib.callback.await('ox_lib:saveProByteUISettings', false, data))
end)

RegisterNUICallback('closeProByteUIEditor', function(_, cb)
    editorOpen = false
    cb(1)
    SetNuiFocus(false, false)
    SetNuiFocusKeepInput(false)
end)
