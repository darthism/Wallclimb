local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:FindFirstChildOfClass("Animator")

local MARGIN_OF_ERROR = 1
local SPEED = 0.2

local WasJustClimbing = false
local IsEnabled = false
local CastParams = RaycastParams.new()
CastParams.FilterType = Enum.RaycastFilterType.Exclude
CastParams.FilterDescendantsInstances = Character:GetDescendants()
local DidInitializeConnection = false
local SizeX = HumanoidRootPart.Size.X / 2 + MARGIN_OF_ERROR
local SizeY = HumanoidRootPart.Size.Y / 2 + MARGIN_OF_ERROR
local WallGrabRange = HumanoidRootPart.Size.Z / 2 + MARGIN_OF_ERROR
local KeyToDirection = {
	[Enum.KeyCode.W] = Vector3.yAxis,
	[Enum.KeyCode.A] = -Vector3.xAxis,
	[Enum.KeyCode.S] = -Vector3.yAxis,
	[Enum.KeyCode.D] = Vector3.xAxis,

}
local function StopAllAnimations()
    for _, Animation in ipairs(Animator:GetPlayingAnimationTracks()) do
        Animation:Stop()
    end
end
local NegativeSurfaceNormal = nil
local function OnMovementInput(Input, GPE)
    if GPE then return end
    if not WasJustClimbing then return end
    local KeyCode = Input.KeyCode
    local Object = KeyToDirection[KeyCode]
    local CanAdjacentClimb = KeyCode == Enum.KeyCode.A or KeyCode == Enum.KeyCode.D
    if Object then
        while UserInputService:IsKeyDown(KeyCode) do
            if not WasJustClimbing then break end
			Character:PivotTo(Character:GetPivot() * CFrame.new(Object * SPEED))
            task.wait()
        end  
    end
end
local function OnExit(Input, GPE)
    if GPE then return end
    if Input.KeyCode == Enum.KeyCode.Space then
        WasJustClimbing = false
        HumanoidRootPart.Anchored = false
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end
RunService.Heartbeat:Connect(function()
    local Pos = HumanoidRootPart.Position
    local CastResults = workspace:Raycast(Pos, HumanoidRootPart.CFrame.LookVector * WallGrabRange, CastParams)
    if CastResults then
        NegativeSurfaceNormal = -CastResults.Normal
        if not WasJustClimbing then
            WasJustClimbing = true
            StopAllAnimations()
            HumanoidRootPart.Anchored = true
            Character:PivotTo(CFrame.lookAt(HumanoidRootPart.Position, HumanoidRootPart.Position + NegativeSurfaceNormal))
        end
        if not DidInitializeConnection then
            DidInitializeConnection = true
            UserInputService.InputBegan:Connect(OnMovementInput)
            UserInputService.InputBegan:Connect(OnExit)
        end
    else
        WasJustClimbing = false
    end
end)
local WallJump = {}
function WallJump.SetSpeed(Speed)
    SPEED = Speed
end
function WallJump.GetSpeed()
    return SPEED
end
function WallJump.DisableWallClimb()
    IsEnabled = false
end
function WallJump.EnableWallClimb()
    IsEnabled = true
end
return WallJump
