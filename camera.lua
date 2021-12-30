--------
-- ProperChaseCam by Hindulaatti
-- Some parts of code from "KirbyCam chase cam v1.0b-public 2021.10.20" camera by kirbyguy22
--------
--------------------------------------------------
-- USER VARIABLES: Change these values depending on your preferences
local baseFOV = 65 -- base vertical FOV

-- Changes the focus point of the camera 
-- positive numbers towards the front and negative to the back of the car
local cameraYOffset = 0 
--------------------------------------------------

-- Global stuff for initialization
local wheelCenterOffset = 0
local wheelbase = 0
local cgHeight = 0
local initDone = false

function getWheelbase()
    local tyreFLPos = carPos - ac.getTyrePosition(1)
    local tyreRLPos = carPos - ac.getTyrePosition(3)
    return (tyreFLPos - tyreRLPos):length() / 2
end

function getWheelCenter(carPos)
    for i = 1, 4 do
        wheelCenter = wheelCenter + ac.getTyrePosition(i)
    end
    local wheelCenter = wheelCenter / 4
    return carPos - wheelCenter
end

function getWheelCenterOffset(wheelCenterFlat)
    local centerDir = ac.getCarDirection():dot(wheelCenter:normalize())
    return wheelCenterFlat:length() * math.sign(-centerDir) + cameraYOffset
end

function getCameraDirection(camDir, pitch)
    local direction = camDir * vec3(-1,-1,-1)
    local pitchCorrection = vec3(0, pitch/50, 0)

    return direction + pitchCorrection
end

function getCameraPosition(camDir, carPos, heightCompensation, distance)
    local cameraPosition = carPos + camDir * distance

    return cameraPosition + heightCompensation
end

function update(dt, cameraIndex)
    local cameraParameters = ac.getCameraParameters(cameraIndex)
    local carUp = ac.getCarUp()
    local acCarPos = ac.getCarPosition()
    
    local height = cameraParameters.height
    local pitchAngle = -cameraParameters.pitch

    if (not initDone) then
        local wheelCenter = getWheelCenter(acCarPos)
        local wheelCenterFlat = vec3(wheelCenter.x, 0, wheelCenter.z)
        wheelCenterOffset = getWheelCenterOffset(wheelCenterFlat)
        wheelbase = getWheelbase()
        cgHeight = ac.getCGHeight()
        initDone = true
    end

    local carDir = vec3()
    carDir:set(ac.getCarDirection())

    -- Set the center of the car? ac.getCarPosition() is some corner?
    local carPos = acCarPos - cgHeight * carUp + wheelCenterOffset * carDir

    local distance = cameraParameters.distance + (wheelbase) -- scale distance by wheelbase to compensate for different cars

    local heightCompensation = vec3(0, height, 0)
    local cameraDir = (ac.Camera.position - carPos - heightCompensation):normalize()

    --cameraDir = math.cross(cameraDir, vec3())
    ac.Camera.direction = getCameraDirection(cameraDir, pitchAngle)
    ac.Camera.position = getCameraPosition(cameraDir, carPos, heightCompensation, distance)

    ac.Camera.up = vec3(0, 1, 0)

    ac.Camera.fov = baseFOV
end
