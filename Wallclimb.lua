local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = game:GetService("Players").LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")
local Animator = Humanoid:FindFirstChildOfClass("Animator")

local MARGIN_OF_ERROR = 3
local SPEED = 0.05

local WasJustClimbing = false
local IsEnabled = false
local CastParams = RaycastParams.new()
CastParams.FilterType = Enum.RaycastFilterType.Exclude
CastParams.FilterDescendantsInstances = Character:GetDescendants()
local DidInitializeConnection = false
local SizeX = HumanoidRootPart.Size.X / 2 + MARGIN_OF_ERROR
local SizeY = HumanoidRootPart.Size.Y / 2 + MARGIN_OF_ERROR
local WallGrabRange = HumanoidRootPart.Size.Z / 2 + MARGIN_OF_ERROR
local function GetDirectionObject(Sign, Direction)
    return {
        Sign = Sign,
        Direction = Direction,
    }
end
local KeyToDirection = {
    [Enum.KeyCode.W] = GetDirectionObject(1, "UpVector"),
    [Enum.KeyCode.A] = GetDirectionObject(-1, "RightVector"),
    [Enum.KeyCode.S] = GetDirectionObject(-1, "UpVector"),
    [Enum.KeyCode.D] = GetDirectionObject(1, "RightVector"),

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
            print("HOLDING")
            local CombinedInfo = HumanoidRootPart.CFrame[Object.Direction] * Object.Sign
            local HrpPosition = HumanoidRootPart.Position
            Character:PivotTo(Character:GetPivot() * CFrame.new(CombinedInfo * SPEED))
            if CanAdjacentClimb then
                HrpPosition = HumanoidRootPart.Position
                local CastResults = workspace:Raycast(HrpPosition, CombinedInfo * SizeX, CastParams)
                if CastResults and CastResults.Instance then
                    local Part = CastResults.Instance
                    local CastPosition = CastResults.Position
                    local Normal = CastResults.Normal
                    if Part:IsA("Part") then
                        Character:PivotTo(CFrame.lookAt(CastPosition + Normal * WallGrabRange / 2, CastPosition + -Normal))
                        break
                    end
                end
            end
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
        print(3)
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
