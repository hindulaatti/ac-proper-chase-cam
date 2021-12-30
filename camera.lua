--------
-- ProperChaseCam by Hindulaatti
-- Some parts of code from "KirbyCam chase cam v1.0b-public 2021.10.20" camera by kirbyguy22
--------
--------------------------------------------------
-- USER VARIABLES: Change these values depending on your preferences
local baseFOV = 45 -- base vertical FOV

-- Changes the focus point of the camera 
-- positive numbers towards the front and negative to the back of the car
local cameraYOffset = 0 
--------------------------------------------------

-- Global stuff for initialization
local wheelCenterOffset = 0
local wheelbase = 0
local cgHeight = 0
local initDone = false
local lastForwardPositionInitDone = false
local lastForwardPosition = vec3()

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

function getCameraDirection(camDir, pitch, cameraAngleModifer)
    local direction = camDir * vec3(-1, -1, -1)
    local camRight = math.cross(camDir, vec3(0,1,0)):normalize()

    -- Apparently these rotate radians around the given vector, pretty useful
    direction:rotate(quat.fromAngleAxis(math.radians(pitch), camRight))
    direction:rotate(quat.fromAngleAxis(cameraAngleModifer, vec3(0,1,0)))

    return direction
end

function getCameraPosition(camDir, carPos, heightCompensation, distance, cameraAngleModifer)
    ac.debug("cameraAngleModifer", cameraAngleModifer)

    -- Rotate camera based on input
    camDir:rotate(quat.fromAngleAxis(cameraAngleModifer, vec3(0,1,0)))
    local cameraPosition = carPos + camDir * distance

    return cameraPosition + heightCompensation
end

function getCameraAngleModifier()
    local joystickLook = ac.getJoystickLook()
    local lookDirection = (ac.looksLeft() and ac.looksRight() or 
    ac.looksBehind()) and -1 or
    ac.looksLeft() and 0.5 or
    ac.looksRight() and -0.5 or
    joystickLook ~= nil and joystickLook.x or 
    0
    return lookDirection * math.pi
end

function update(dt, cameraIndex)
    local cameraParameters = ac.getCameraParameters(cameraIndex)
    local carDir = ac.getCarDirection()
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

    -- To stop this shit initializing to somewhere crap
    if (not lastForwardPositionInitDone) then
        lastForwardPosition = ac.Camera.position
        lastForwardPositionInitDone = true
    end
    
    local cameraDir = (lastForwardPosition - carPos - heightCompensation):normalize()
    local cameraAngleModifier = getCameraAngleModifier()
    
    lastForwardPosition = getCameraPosition(cameraDir, carPos, heightCompensation, distance, 0)
    ac.Camera.direction = getCameraDirection(cameraDir, pitchAngle, cameraAngleModifier)
    ac.Camera.position = getCameraPosition(cameraDir, carPos, heightCompensation, distance, cameraAngleModifier)

    ac.Camera.up = vec3(0, 1, 0)

    ac.Camera.fov = baseFOV
end
