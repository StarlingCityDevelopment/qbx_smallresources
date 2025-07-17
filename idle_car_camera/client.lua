local inactive = false               -- Variable to indicate if the player is inactive
local lastInputTime = GetGameTimer() -- Get the current game time in milliseconds

local LocalData = {
    IsInVehicle = false,
    CurrentPlayerCamera = nil,
    CurrentPlayerCamera_CameraTo = nil,
    CurrentPlayerCamera_CameraToPosition = {
        x = 0.0,
        y = 0.0,
        z = 0.0
    }
}

local Config = {
    EnableFade = true,                 -- Enable black fade transition after camera ends
    CameraDuration = 10000,            -- how many seconds the view will be seen after each transition
    EnableMusic = true,                -- Enable Music, put a MusicFile aswell under webfiles/sounds
    RandomizedPositions = true,        -- enable to randomize all cameras
    EnableWarningLights = true,        -- currently no use
    EnableHeadLights = true,           -- currently no use
    EnableHeadLightsOnlyNights = true, -- currently no use
    Cameras = {
        CameraPositions = {
            -- Needs atleast 2 entries to work!

            -- [[!!!]] EXPLANATION [[!!!]]
            -- distance = the camera distance to the vehicle, the player is in
            -- fovFrom = the fov at the start
            -- fovTo = the fov at the end
            -- from = use any of these:

            -- "front-left"             = Front-left corner
            -- "front-middle"           = Directly in front of the car
            -- "front-right"            = Front-right corner

            -- Back positions
            -- "back-left"              = Back-left corner
            -- "back-middle"            = Directly behind the car
            -- "back-right"             = Back-right corner

            -- Side positions
            -- "left"                   = Directly to the left of the car
            -- "right"                  = Directly to the right of the car

            -- Top positions
            -- "top-left"               = Top-left corner
            -- "top-middle"             = Directly above the car
            -- "top-right"              = Top-right corner

            -- Center (top of the vehicle or close to the ground)
            -- "center"                 = Position right above the vehicle (for overview shots)

            -- Intermediate or diagonal positions
            -- "front-left-diagonal"    = Diagonal between front-left and middle
            -- "front-right-diagonal"   = Diagonal between front-right and middle
            -- "back-left-diagonal"     = Diagonal between back-left and middle
            -- "back-right-diagonal"    = Diagonal between back-right and middle

            -- to = see above (from)

            -- Front-to-Left Side
            {
                distance = 4.0,
                fovFrom = 20.0,
                fovTo = 35.0,
                from = "front-middle",
                to = "front-left"
            },
            -- Left-to-Back
            {
                distance = 5.0,
                fovFrom = 30.0,
                fovTo = 40.0,
                from = "front-left",
                to = "left"
            },
            -- Back-to-Right Side
            {
                distance = 6.0,
                fovFrom = 40.0,
                fovTo = 35.0,
                from = "back-middle",
                to = "back-right"
            },
            -- Right Side Sweep
            {
                distance = 5.0,
                fovFrom = 30.0,
                fovTo = 30.0,
                from = "back-right",
                to = "right"
            },
            -- Right-to-Front
            {
                distance = 5.0,
                fovFrom = 35.0,
                fovTo = 40.0,
                from = "right",
                to = "front-right"
            },
            -- Top-down Front
            {
                distance = 8.0,
                fovFrom = 50.0,
                fovTo = 50.0,
                from = "top-middle",
                to = "front-middle"
            },
            -- Left-to-Top
            {
                distance = 7.0,
                fovFrom = 30.0,
                fovTo = 50.0,
                from = "left",
                to = "top-middle"
            },
            -- Back Sweep
            {
                distance = 4.5,
                fovFrom = 40.0,
                fovTo = 35.0,
                from = "back-left",
                to = "back-right"
            },
            -- Low Side Sweep (right)
            {
                distance = 3.5,
                fovFrom = 25.0,
                fovTo = 30.0,
                from = "right",
                to = "back-right"
            },
            -- Back-to-Top Transition
            {
                distance = 6.5,
                fovFrom = 45.0,
                fovTo = 50.0,
                from = "back-middle",
                to = "top-middle"
            }
        }
    },
}

local function GetMouseDelta()
    local mouseX = GetControlNormal(0, 1) -- Mouse X movement (horizontal)
    local mouseY = GetControlNormal(0, 2) -- Mouse Y movement (vertical)
    return mouseX, mouseY
end

local function StartCameraTransition(pos1, rot1, pos2, rot2, transitionTime, fov1, fov2, vehicle)
    -- Destroy any existing cameras
    if LocalData.CurrentPlayerCamera then
        DestroyCam(LocalData.CurrentPlayerCamera)
    end
    if LocalData.CurrentPlayerCamera_CameraTo then
        DestroyCam(LocalData.CurrentPlayerCamera_CameraTo)
    end
    -- Create the two cameras for the transition
    LocalData.CurrentPlayerCamera = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos1.x, pos1.y, pos1.z, rot1.x, rot1
        .y, rot1.z, fov1, true, 2)
    LocalData.CurrentPlayerCamera_CameraTo = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", pos2.x, pos2.y, pos2.z,
        rot2.x, rot2.y, rot2.z, fov2, true, 2)

    -- Make both cameras point at the vehicle
    PointCamAtEntity(LocalData.CurrentPlayerCamera, vehicle, 0.0, 0.0, 0.0)
    PointCamAtEntity(LocalData.CurrentPlayerCamera_CameraTo, vehicle, 0.0, 0.0, 0.0)

    -- Activate the first camera and start the transition to the second camera
    SetCamActive(LocalData.CurrentPlayerCamera, true)
    RenderScriptCams(true, false, 0, true, true)

    SetCamActiveWithInterp(LocalData.CurrentPlayerCamera_CameraTo, LocalData.CurrentPlayerCamera, transitionTime, 100, 50)

    -- Wait for the transition to complete before moving on
end

local function GetRelativePosition(vehicle, positionName, distance)
    local coords = GetEntityCoords(vehicle)         -- Get the vehicle's current position
    local forward = GetEntityForwardVector(vehicle) -- Forward direction of the vehicle
    local up = vector3(0.0, 0.0, 1.0)               -- Up direction (Z axis)

    -- Calculate the right vector by rotating the forward vector 90 degrees around the Z axis
    local right = vector3(-forward.y, forward.x, 0.0)

    -- Get vehicle dimensions to avoid clipping
    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
    local vehicleHeight = (maxDim.z - minDim.z) * 2 -- Verdopple die Höhe
    local vehicleWidth = (maxDim.x - minDim.x) * 2  -- Verdopple die Breite
    local vehicleLength = (maxDim.y - minDim.y)     -- Verdopple die Länge

    -- Define the offsets for each position relative to the vehicle
    local offsets = {
        -- Front positions, adjusted by vehicle width/length
        ["front-left"] = forward * distance - right * (vehicleWidth * 0.5 + distance * 0.5),  -- Front-left corner
        ["front-middle"] = forward * distance,                                                -- Directly in front of the car
        ["front-right"] = forward * distance + right * (vehicleWidth * 0.5 + distance * 0.5), -- Front-right corner

        -- Back positions, adjusted by vehicle width/length
        ["back-left"] = -forward * distance - right * (vehicleWidth * 0.5 + distance * 0.5),  -- Back-left corner
        ["back-middle"] = -forward * distance,                                                -- Directly behind the car
        ["back-right"] = -forward * distance + right * (vehicleWidth * 0.5 + distance * 0.5), -- Back-right corner

        -- Side positions, adjusted by vehicle width
        ["left"] = -right * (distance + vehicleWidth * 0.5), -- Directly to the left of the car
        ["right"] = right * (distance + vehicleWidth * 0.5), -- Directly to the right of the car

        -- Top positions, considering the height of the vehicle
        ["top-left"] = forward * distance - right * (vehicleWidth * 0.5 + distance * 0.5) +
            up * (vehicleHeight + distance),              -- Top-left corner
        ["top-middle"] = up * (vehicleHeight + distance), -- Directly above the car
        ["top-right"] = forward * distance + right * (vehicleWidth * 0.5 + distance * 0.5) +
            up * (vehicleHeight + distance),              -- Top-right corner

        -- Center (top of the vehicle or close to the ground)
        ["center"] = vector3(0.0, 0.0, vehicleHeight), -- Position right above the vehicle (for overview shots)

        -- Intermediate or diagonal positions
        ["front-left-diagonal"] = forward * distance * 0.7 - right * (vehicleWidth * 0.5 + distance * 0.7),  -- Diagonal between front-left and middle
        ["front-right-diagonal"] = forward * distance * 0.7 + right * (vehicleWidth * 0.5 + distance * 0.7), -- Diagonal between front-right and middle
        ["back-left-diagonal"] = -forward * distance * 0.7 - right * (vehicleWidth * 0.5 + distance * 0.7),  -- Diagonal between back-left and middle
        ["back-right-diagonal"] = -forward * distance * 0.7 +
            right *
            (vehicleWidth * 0.5 + distance * 0.7) -- Diagonal between back-right and middle
    }

    -- Return the calculated position based on the requested positionName
    return coords + offsets[positionName]
end

local function StopCamera()
    if LocalData.CurrentPlayerCamera ~= nil then
        DestroyCam(LocalData.CurrentPlayerCamera, false)
    end

    if LocalData.CurrentPlayerCamera_CameraTo ~= nil then
        DestroyCam(LocalData.CurrentPlayerCamera_CameraTo, false)
    end

    LocalData.CurrentPlayerCamera_CameraTo = nil
    LocalData.CurrentPlayerCamera = nil

    SetVehicleIndicatorLights(cache.vehicle, 0, false)
    SetVehicleIndicatorLights(cache.vehicle, 1, false)
    DoScreenFadeIn(1000)
    RenderScriptCams(false, true, 1500, true, true)

    TriggerEvent('ts_hud:client:showHud')
end

local function StartIdleCam(vehicle)
    if #Config.Cameras.CameraPositions < 2 then
        print("No valid camera positions found in config. Please add at least 2 positions.")
        return
    end

    TriggerEvent('ts_hud:client:hideHUD')
    DoScreenFadeOut(1000)
    Wait(1000)

    CreateThread(function()
        local cameraIndex = 1

        if Config.RandomizedPositions == true then
            cameraIndex = math.random(1, #Config.Cameras.CameraPositions)
        end

        while inactive do
            if inactive == false then
                StopCamera()
                return
            end
            -- Get the current camera config
            local cameraConfig = Config.Cameras.CameraPositions[cameraIndex]

            -- Calculate the "from" and "to" positions based on the vehicle's current position
            local fromPos = GetRelativePosition(vehicle, cameraConfig.from, cameraConfig.distance)
            local toPos = GetRelativePosition(vehicle, cameraConfig.to, cameraConfig.distance)

            -- Get the current rotation of the vehicle to set the camera direction
            local rot = GetEntityRotation(vehicle, 2)
            DoScreenFadeIn(1000)
            -- Start the camera transition, passing the vehicle to ensure the camera looks at it
            StartCameraTransition(fromPos, rot, toPos, rot, Config.CameraDuration, cameraConfig.fovFrom,
                cameraConfig.fovTo, vehicle)
            SendNUIMessage({
                type = "EnableCamera",
                payload = { true }
            })
            -- Wait for the transition duration
            Wait(Config.CameraDuration - 3000)
            DoScreenFadeOut(3000)
            if LocalData.CurrentPlayerCamera == nil then
                StopCamera()
                return
            end
            Wait(3000)
            if LocalData.CurrentPlayerCamera == nil then
                StopCamera()
                return
            end
            -- Move to the next camera index, loop back if at the end of the list
            cameraIndex = cameraIndex + 1
            if Config.RandomizedPositions == true then
                cameraIndex = math.random(1, #Config.Cameras.CameraPositions)
            end
            if cameraIndex > #Config.Cameras.CameraPositions then
                cameraIndex = 1
            end
        end
    end)
end

lib.onCache("vehicle", function(vehicle)
    if not vehicle and LocalData.CurrentPlayerCamera ~= nil then
        StopCamera()
        return
    end

    SetTimeout(1000, function()
        lastInputTime = GetGameTimer()
        while cache.vehicle do
            Wait(1000)
            local speed = GetEntitySpeed(vehicle)
            local isInputActive = IsControlPressed(0, 32) or -- W key (move forward)
                IsControlPressed(0, 33) or                   -- S key (move back)
                IsControlPressed(0, 34) or                   -- A key (move left)
                IsControlPressed(0, 35) or                   -- D key (move right)
                IsControlPressed(0, 44) or                   -- Space key (jump)
                IsControlPressed(0, 20) or                   -- Shift key (sprint)
                IsControlPressed(0, 29)                      -- Tab key (cover)

            local mouseX, mouseY = GetMouseDelta()
            local isMouseMoving = (mouseX ~= 0 or mouseY ~= 0)

            if isInputActive or isMouseMoving or speed ~= 0 then
                lastInputTime = GetGameTimer()
                if inactive and LocalData.CurrentPlayerCamera ~= nil then
                    inactive = false
                    StopCamera()
                end
            else
                if (GetGameTimer() - lastInputTime) >= (60000) * 2.5 then
                    if not inactive and LocalData.CurrentPlayerCamera == nil then
                        inactive = true
                        StartIdleCam(cache.vehicle)
                        SetVehicleIndicatorLights(cache.vehicle, 0, true)
                        SetVehicleIndicatorLights(cache.vehicle, 1, true)
                        Wait(2000)
                    end
                end
            end
        end
    end)
end)