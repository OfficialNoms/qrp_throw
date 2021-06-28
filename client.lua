local attachedProp = nil

Citizen.CreateThread(function ()
	local throwables = {}
	for k,v in pairs(Config.Throwables) do 
		local hash = GetHashKey(v)
		table.insert(throwables,hash)
	end 

	print(ESX.DumpTable(throwables))

	exports['bt-target']:AddTargetModel(throwables, {
		options = {
			{
				event = "qrp_throw:pickup",
				icon = "fa-solid fa-traffic-cone",
				label = "Pick up to Throw",
			},
		},
		job = {"all"},
		distance = 3.0
	})
end)

RegisterCommand("throwprop", function(source, args, rawCommand)
	local prop = args[1]
	if attachedProp ~= nil then return end
	TriggerEvent("qrp_throw:createprop",prop)
	ESX.ShowNotification("Prop spawned, press F to throw")
end)

RegisterKeyMapping('throw-attached', "Throw an attached prop", 'keyboard', 'f')

RegisterNetEvent('qrp_throw:pickup')
AddEventHandler('qrp_throw:pickup',function(data)
	local hit, coords, prop = RayCastGamePlayCamera(10.0)
	local playerPed = PlayerPedId()
	if attachedProp ~= nil then return end
	if DoesEntityExist(prop) and attachedProp == nil then
		SetEntityAsMissionEntity(prop)
		AttachEntityToEntity(prop,playerPed, GetPedBoneIndex(playerPed,6286),0,0,0, 0,0,0)
		attachedProp = prop
		RegisterCommand('throw-attached', function()
			if attachedProp ~= nil then 
				ThrowAttachedObject(attachedProp)
			end 
		end)
		ClearPedTasks(playerPed)
		RequestAnimDict('anim@heists@narcotics@trash')
		while not HasAnimDictLoaded('anim@heists@narcotics@trash') do 
			Citizen.Wait(5)
		end 
		TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0 )
	end
end)

RegisterNetEvent('qrp_throw:createprop')
AddEventHandler('qrp_throw:createprop',function(prop)
	local playerPed = PlayerPedId()
	local object = GetHashKey(prop)
	if attachedProp ~= nil then return end
	RequestModel(object)
	while not HasModelLoaded(object) do 
		Citizen.Wait(1)
	end 
	local pos = GetWorldPositionOfEntityBone(playerPed,6286)
	local obj = CreateObject(object, pos.x, pos.y, pos.z, true, true, true)
	Citizen.Wait(50)
	SetEntityAsMissionEntity(obj)
	AttachEntityToEntity(obj,playerPed, GetPedBoneIndex(playerPed,6286),0,0,0, 0,0,0)
	attachedProp = obj
	ESX.ShowNotification("Press F to throw held prop")
	RegisterCommand('throw-attached', function()
		if attachedProp ~= nil then 
			ThrowAttachedObject(attachedProp)
		end 
	end)
	SetModelAsNoLongerNeeded(object)
	ClearPedTasks(playerPed)
	RequestAnimDict('anim@heists@narcotics@trash')
	while not HasAnimDictLoaded('anim@heists@narcotics@trash') do 
		Citizen.Wait(5)
	end 
	TaskPlayAnim(playerPed, 'anim@heists@narcotics@trash', 'walk', 1.0, -1.0,-1,49,0,0, 0,0 )
end)

ThrowAttachedObject = function(object)
	local playerPed = PlayerPedId()
	local animDict = "melee@unarmed@streamed_variations"
	local anim = "plyr_takedown_front_slap"
	ClearPedTasks(playerPed)
	while (not HasAnimDictLoaded(animDict)) do
		RequestAnimDict(animDict)
		Citizen.Wait(5)
	end
	TaskPlayAnim(playerPed, animDict, anim, 8.0, -8.0, -1, 0, 0.0, false, false, false)
	RegisterCommand('throw-attached', function()
		-- do nothing
	end)
	Citizen.Wait(500)
	DetachEntity(object)
	attachedProp = nil
	local forwardVector = GetEntityForwardVector(playerPed)
	local force = randomFloat(Config.MinThrowForce,Config.MaxThrowForce)
	ApplyForceToEntity(object,1,forwardVector.x*force,forwardVector.y*force,forwardVector.z,0,0,0,0,false,true,true,false,true)
	Citizen.Wait(5000)
	object = SetEntityAsNoLongerNeeded()

end

function randomFloat(lower, greater)
    return lower + math.random()  * (greater - lower);
end


function RayCastGamePlayCamera(distance)
	local cameraRotation = GetGameplayCamRot()
	local cameraCoord = GetGameplayCamCoord()
	local direction = RotationToDirection(cameraRotation)
	local destination =
	{
		x = cameraCoord.x + direction.x * distance,
		y = cameraCoord.y + direction.y * distance,
		z = cameraCoord.z + direction.z * distance
	}
	local a, b, c, d, e = GetShapeTestResult(StartShapeTestRay(cameraCoord.x, cameraCoord.y, cameraCoord.z, destination.x, destination.y, destination.z, -1, PlayerPedId(), 0))
	return b, c, e
end

function RotationToDirection(rotation)
	local adjustedRotation =
	{
		x = (math.pi / 180) * rotation.x,
		y = (math.pi / 180) * rotation.y,
		z = (math.pi / 180) * rotation.z
	}
	local direction =
	{
		x = -math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		y = math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)),
		z = math.sin(adjustedRotation.x)
	}
	return direction
end
