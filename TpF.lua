local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")

local SavedCFrame = nil
local IsOpen = true

-- تحديث الشخصية عند إعادة الإحياء
Player.CharacterAdded:Connect(function(Char)
	Character = Char
	HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
end)

-- إنشاء ScreenGui الأساسية
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AdvancedTeleportGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = Player:WaitForChild("PlayerGui")

-- [1] الإطار الرئيسي (Main Frame)
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 180)
Frame.Position = UDim2.new(0.5, -140, 0.5, -90)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true -- لضمان عدم خروج خلفية الرموز
Frame.Parent = ScreenGui

local FrameCorner = Instance.new("UICorner")
FrameCorner.CornerRadius = UDim.new(0, 16)
FrameCorner.Parent = Frame

local FrameStroke = Instance.new("UIStroke")
FrameStroke.Color = Color3.fromRGB(0, 170, 255)
FrameStroke.Thickness = 1.8
FrameStroke.Parent = Frame

-- [2] خلفية تساقط الرموز (Falling Symbols Effect)
local MatrixContainer = Instance.new("Frame")
MatrixContainer.Size = UDim2.new(1, 0, 1, 0)
MatrixContainer.BackgroundTransparency = 1
MatrixContainer.ZIndex = 1
MatrixContainer.Parent = Frame

local Symbols = {"0", "1", "✦", "⚡", "★", "♦", "✖", "∞"}

local function CreateSymbol()
	if not Frame.Parent or not IsOpen then return end
	
	local Symbol = Instance.new("TextLabel")
	Symbol.Text = Symbols[math.random(1, #Symbols)]
	Symbol.Font = Enum.Font.Code
	Symbol.TextSize = math.random(10, 16)
	Symbol.TextColor3 = Color3.fromRGB(0, 255, 180)
	Symbol.TextTransparency = 0.3
	Symbol.BackgroundTransparency = 1
	Symbol.Size = UDim2.new(0, 20, 0, 20)
	
	local StartX = math.random(0, 260)
	Symbol.Position = UDim2.new(0, StartX, 0, -20)
	Symbol.ZIndex = 1
	Symbol.Parent = MatrixContainer
	
	local Duration = math.random(20, 40) / 10
	local Tween = TweenService:Create(Symbol, TweenInfo.new(Duration, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0, StartX, 1, 10),
		TextTransparency = 1
	})
	
	Tween:Play()
	Tween.Completed:Connect(function()
		Symbol:Destroy()
	end)
end

-- تشغيل الرموز المتساقطة بشكل دوري
task.spawn(function()
	while true do
		task.wait(0.2)
		if IsOpen then
			CreateSymbol()
		end
	end
end)

-- [3] العنوان (Title Bar)
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 38)
Title.BackgroundTransparency = 1
Title.Text = "⚡ Coordinate Saver"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.ZIndex = 2
Title.Parent = Frame

-- [4] زر الحفظ (Save Button)
local SaveButton = Instance.new("TextButton")
SaveButton.Size = UDim2.new(0.86, 0, 0, 42)
SaveButton.Position = UDim2.new(0.07, 0, 0.28, 0)
SaveButton.Text = "💾 حفظ الإحداثيات"
SaveButton.Font = Enum.Font.GothamBold
SaveButton.TextSize = 15
SaveButton.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveButton.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
SaveButton.BorderSizePixel = 0
SaveButton.ZIndex = 2
SaveButton.Parent = Frame

local C1 = Instance.new("UICorner")
C1.CornerRadius = UDim.new(0, 10)
C1.Parent = SaveButton

-- [5] زر الانتقال (Teleport Button)
local TeleportButton = Instance.new("TextButton")
TeleportButton.Size = UDim2.new(0.86, 0, 0, 42)
TeleportButton.Position = UDim2.new(0.07, 0, 0.58, 0)
TeleportButton.Text = "📍 الانتقال إلى الحفظ"
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.TextSize = 15
TeleportButton.TextColor3 = Color3.fromRGB(255, 255, 255)
TeleportButton.BackgroundColor3 = Color3.fromRGB(0, 122, 255)
TeleportButton.BorderSizePixel = 0
TeleportButton.ZIndex = 2
TeleportButton.Parent = Frame

local C2 = Instance.new("UICorner")
C2.CornerRadius = UDim.new(0, 10)
C2.Parent = TeleportButton

-- [6] زر الفتح/الغلق السلس (Toggle Button)
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleBtn.Position = UDim2.new(0, 15, 0.5, -22)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
ToggleBtn.Text = "⚙️"
ToggleBtn.TextSize = 20
ToggleBtn.Parent = ScreenGui

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(1, 0)
ToggleCorner.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = Color3.fromRGB(0, 170, 255)
ToggleStroke.Thickness = 1.5
ToggleStroke.Parent = ToggleBtn

-- [7] ميزة سحب الواجهة (Smooth Dragging System)
local Dragging, DragInput, DragStart, StartPos

local function UpdateDrag(input)
	local Delta = input.Position - DragStart
	local TargetPos = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)
	TweenService:Create(Frame, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = TargetPos}):Play()
end

Frame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = input.Position
		StartPos = Frame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

Frame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		DragInput = input
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if input == DragInput and Dragging then
		UpdateDrag(input)
	end
end)

-- [8] ميزة الفتح والغلق السلس (Smooth Open/Close)
local OriginalSize = UDim2.new(0, 280, 0, 180)

ToggleBtn.MouseButton1Click:Connect(function()
	IsOpen = !IsOpen
	if IsOpen then
		Frame.Visible = true
		TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = OriginalSize,
			BackgroundTransparency = 0
		}):Play()
	else
		local HideTween = TweenService:Create(Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		})
		HideTween:Play()
		HideTween.Completed:Connect(function()
			if not IsOpen then Frame.Visible = false end
		end)
	end
end)

-- [9] تحسين تفاعل الأزرار (Hover & Click Animations)
local function SetupButtonEffects(Btn, NormalColor, HoverColor)
	Btn.MouseEnter:Connect(function()
		TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = HoverColor}):Play()
	end)
	
	Btn.MouseLeave:Connect(function()
		TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3 = NormalColor}):Play()
	end)
	
	Btn.MouseButton1Down:Connect(function()
		TweenService:Create(Btn, TweenInfo.new(0.08), {Size = UDim2.new(Btn.Size.X.Scale, -4, Btn.Size.Y.Scale, -4)}):Play()
	end)
	
	Btn.MouseButton1Up:Connect(function()
		TweenService:Create(Btn, TweenInfo.new(0.08), {Size = UDim2.new(0.86, 0, 0, 42)}):Play()
	end)
end

SetupButtonEffects(SaveButton, Color3.fromRGB(0, 180, 120), Color3.fromRGB(0, 220, 140))
SetupButtonEffects(TeleportButton, Color3.fromRGB(0, 122, 255), Color3.fromRGB(40, 150, 255))

-- [10] أحداث النقر وظائف Buttons
SaveButton.MouseButton1Click:Connect(function()
	SavedCFrame = HumanoidRootPart.CFrame
	SaveButton.Text = "✔ تم حفظ الموقع!"
	task.wait(1.2)
	SaveButton.Text = "💾 حفظ الإحداثيات"
end)

TeleportButton.MouseButton1Click:Connect(function()
	if SavedCFrame then
		HumanoidRootPart.CFrame = SavedCFrame
	else
		TeleportButton.Text = "⚠️ لا يوجد حفظ!"
		task.wait(1.2)
		TeleportButton.Text = "📍 الانتقال إلى الحفظ"
	end
end)
