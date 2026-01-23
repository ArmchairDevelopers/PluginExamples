require("common/sdk")

-- The time in seconds that it will take for the spawn animation to occur.
local interpolationTimeSeconds <const> = 1.0

-- Helper functions for interpolation easing.
-- See https://easings.net for more information.
local function easeInOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        return 1 - (-2 * t + 2)^3 / 2
    end
end

local function easeInOutQuadratic(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return 1 - (-2 * t + 2)^2 / 2
    end
end

-- Interpolates between two game positions using cubic easing for translation and quadratic easing for rotation.
-- This is the same method that the Battlefield games use to interpolate camera movement. They also delay camera
-- rotation by a small amount, which we do here as well.
local function interpolateTransform(startTransform, endTransform, t, rotationDelay)
    local result = LinearTransform()

    -- Calculate the adjusted time for rotation interpolation based on the delay.
    local adjustedT = math.max(0, (t - rotationDelay) / (1 - rotationDelay))
    local easeRot = easeInOutQuadratic(math.min(1, adjustedT))

    -- Interpolate rotation (right, up, and forward matrices) using quadratic easing
    result.right   = startTransform.right * (1 - easeRot) + endTransform.right * easeRot
    result.up      = startTransform.up * (1 - easeRot) + endTransform.up * easeRot
    result.forward = startTransform.forward * (1 - easeRot) + endTransform.forward * easeRot

    -- Interpolate translation using cubic easing
    local easeTrans = easeInOutCubic(t)
    result.trans = startTransform.trans * (1 - easeTrans) + endTransform.trans * easeTrans

    return result
end

SpawnCameraAnimator = {
    scene = nil,
    startTransform = nil,
    cameraEntity = nil,
    interpolatorEntity = nil,
    timer = 0,

    cameraPushed = function(self, data, camera, scene)
        if data.typeInfo.name ~= "SoldierFirstPersonCameraData" then
            return
        end

        self.scene = scene

        -- Obtain the position of the current camera. This is not the position
        -- of the newly pushed camera, but the position of the camera that was
        -- active when the new camera was pushed. This is the position that we want
        -- to interpolate *from*.
        self.startTransform = LinearTransform()
        Utils.GetActiveCameraTransform(self.startTransform)

        -- Create a CameraEntity with a high priority. This will override the player's camera.
        -- We set the new camera's transform to the player's camera transform, store the current
        -- camera position, the new camera entity, and the real player camera, and then interpolate
        -- the new camera towards the real camera every game tick.
        local data = CameraEntityData()
        data.nameId = "SkyCamera"
        data.priority = 2600000
        data.enabled = true
        data.focalLength = 50.0
        data.focusDistance = 1000.0
        data.aperture = 8.0
        data.shutterSpeed = 50.0
        data.iso = 100.0
        data.spotMeterScale = 1.0
        data.transform = self.startTransform

        local entity = EntityManager.Create(data)
        if entity == nil then
            print("Failed to create camera entity! Aborting camera animation.")
            self.scene = nil
            self.startTransform = nil
            return
        end

        -- Entities are essentially like a nodes in an Unreal Engine style blueprint.
        -- The camera entity has a "TakeControl" input event which we can use to signal
        -- the game engine to switch to this camera.
        entity:Event(EntityEvent("TakeControl"))
        self.cameraEntity = entity
        self.timer = 0
    end,

    onTick = function(self, deltaTime)
        if self.cameraEntity == nil then
            return
        end

        self.timer = self.timer + deltaTime
        local t = self.timer / interpolationTimeSeconds

        local playerCameraTransform = self.scene.activeCamera.transform
        self.cameraEntity.data.transform = interpolateTransform(self.startTransform, playerCameraTransform, t, 0.15)

        -- If the animation is over, release our camera and reset everything.
        if t >= 1 then
            self.cameraEntity:Event(EntityEvent("ReleaseControl"))
            self.cameraEntity = nil
            self.timer = 0
            self.scene = nil
        end
    end
}

-- Listen for the camera push event to start the animation.
EventManager.Listen('ClientCameraManager:Push', SpawnCameraAnimator.cameraPushed, SpawnCameraAnimator)

-- Listen for the game tick to update the camera position.
EventManager.Listen('Client:UpdatePre', SpawnCameraAnimator.onTick, SpawnCameraAnimator)
