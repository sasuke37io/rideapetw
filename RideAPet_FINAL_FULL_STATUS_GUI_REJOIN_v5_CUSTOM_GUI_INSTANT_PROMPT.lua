
--========================================================
-- RIDE A PET
-- Full LocalScript - own Roblox experience
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Stats = game:GetService("Stats")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--========================================================
-- CONFIG
--========================================================

local TWEEN_MIN = 0.18
local TWEEN_MAX = 0.50

local ESP_UPDATE_RATE = 0.30
local ESP_MAX_DISTANCE = 100000
local ESP_MAX_OBJECTS = 120

local AUTO_EGG_RATE = 0.12
local PROMPT_WAIT = 8
local PROMPT_RETRY = 2

local UPGRADE_DELAY = 0.5
local REBIRTH_DELAY = 1.0

local DEFAULT_SPEED = 16
local MAX_SPEED = 100

local PLOT_OFFSET = Vector3.new(-8, 3, -14)
local PLOT_MARGIN = 5

--========================================================
-- EGG NAMES
--========================================================

local EGG_NAMES = {
	"Admin Egg",
	"Asteroid Egg",
	"Aurora Egg",
	"Blackhole Egg",
	"Bloom Egg",
	"Brown Egg",
	"Cracked Egg",
	"Crystal Egg",
	"Devil Fruit Egg",
	"Diamond Egg",
	"Dominus Egg",
	"Dragon Egg",
	"Easter Egg",
	"Flaming Egg",
	"Flower Egg",
	"Galaxy Egg",
	"Giant Egg",
	"Glass Egg",
	"Golden Egg",
	"Ice Egg",
	"Leaf Egg",
	"Mushroom Egg",
	"Sinister Egg",
	"Skull Egg",
	"Slime Egg",
	"Tidal Egg",
	"Volcanic Egg",
	"White Egg",
	"Cherub Egg",
	"Solaris Egg",
}

local EGG_SET = {}
local SelectedEggs = {}

for _,name in ipairs(EGG_NAMES) do
	EGG_SET[name] = true
	SelectedEggs[name] = false
end

--========================================================
-- STATE
--========================================================

local State = {
	AutoEgg = false,
	ESP = false,
	AutoUpgrade = false,
	AutoRebirth = false,

	InfJump = false,
	AutoRejoin = false,
	AntiLag = false,

	Speed = DEFAULT_SPEED,

	OwnPlot = nil,
	OwnPlotPart = nil,
	OwnPlotCFrame = nil,

	LastEgg = "-",
	LastPickup = "-",
	LastAction = "Idle",

	AutoEggRunning = false,
	UpgradeRunning = false,
	RebirthRunning = false,
}

local EggCache = {}
local ESPObjects = {}

local PickupConfirmed = false
local PickupTargetName = nil
local PickupWaiting = false

local SavedVisuals = {}
local RejoinConnection = nil

--========================================================
-- CHARACTER HELPERS
--========================================================

local function GetCharacter()
	return Player.Character
end

local function GetRoot()
	local Character = GetCharacter()
	return Character and Character:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
	local Character = GetCharacter()
	return Character and Character:FindFirstChildOfClass("Humanoid")
end

local function ApplySpeed()
	local Humanoid = GetHumanoid()
	if Humanoid then
		Humanoid.WalkSpeed = math.clamp(State.Speed, 0, MAX_SPEED)
	end
end

Player.CharacterAdded:Connect(function()
	task.wait(0.4)
	ApplySpeed()
end)

-- Keep the requested speed applied even when the game changes WalkSpeed.
RunService.Heartbeat:Connect(function()
	local Humanoid = GetHumanoid()
	if Humanoid and math.abs(Humanoid.WalkSpeed - State.Speed) > 0.05 then
		ApplySpeed()
	end
end)

--========================================================
-- GENERIC UI
--========================================================

local Old = PlayerGui:FindFirstChild("RideAPetGUI")
if Old then
	Old:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "RideAPetGUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.DisplayOrder = 9999
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(475, 525)
Main.Position = UDim2.new(0.5, -237, 0.5, -262)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Active = true
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 14)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(68, 68, 78)
MainStroke.Thickness = 1.2
MainStroke.Parent = Main

local MainScale = Instance.new("UIScale")
MainScale.Scale = 1
MainScale.Parent = Main

local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.BackgroundColor3 = Color3.fromRGB(27, 27, 33)
TopBar.BorderSizePixel = 0
TopBar.Parent = Main

local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 14)
TopCorner.Parent = TopBar

local Title = Instance.new("TextLabel")
Title.BackgroundTransparency = 1
Title.Position = UDim2.fromOffset(15, 7)
Title.Size = UDim2.new(1, -65, 0, 22)
Title.Font = Enum.Font.GothamBold
Title.Text = "Ride a Pet"
Title.TextSize = 19
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TopBar

local Subtitle = Instance.new("TextLabel")
Subtitle.BackgroundTransparency = 1
Subtitle.Position = UDim2.fromOffset(16, 29)
Subtitle.Size = UDim2.new(1, -65, 0, 16)
Subtitle.Font = Enum.Font.Gotham
Subtitle.Text = "World Egg • Optimized"
Subtitle.TextSize = 10
Subtitle.TextColor3 = Color3.fromRGB(145,145,155)
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.Parent = TopBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(32,32)
Close.Position = UDim2.new(1,-42,0,11)
Close.BackgroundColor3 = Color3.fromRGB(43,43,51)
Close.BorderSizePixel = 0
Close.AutoButtonColor = false
Close.Text = "×"
Close.TextSize = 20
Close.Font = Enum.Font.GothamBold
Close.TextColor3 = Color3.fromRGB(235,235,240)
Close.Parent = TopBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0,9)
CloseCorner.Parent = Close

local Content = Instance.new("Frame")
Content.Position = UDim2.fromOffset(10,65)
Content.Size = UDim2.new(1,-20,1,-75)
Content.BackgroundTransparency = 1
Content.Parent = Main

--========================================================
-- DRAG
--========================================================

local Dragging = false
local DragStart
local StartPosition

TopBar.InputBegan:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.MouseButton1
		or Input.UserInputType == Enum.UserInputType.Touch then
		Dragging = true
		DragStart = Input.Position
		StartPosition = Main.Position
		Input.Changed:Connect(function()
			if Input.UserInputState == Enum.UserInputState.End then
				Dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(Input)
	if not Dragging then return end
	if Input.UserInputType ~= Enum.UserInputType.MouseMovement
		and Input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	local Delta = Input.Position - DragStart

	Main.Position = UDim2.new(
		StartPosition.X.Scale,
		StartPosition.X.Offset + Delta.X,
		StartPosition.Y.Scale,
		StartPosition.Y.Offset + Delta.Y
	)
end)

--========================================================
-- PAGES
--========================================================

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1,0,0,38)
TabBar.BackgroundTransparency = 1
TabBar.ZIndex = 10
TabBar.Parent = Content

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
TabLayout.Padding = UDim.new(0,5)
TabLayout.Parent = TabBar

local PageHolder = Instance.new("Frame")
PageHolder.Position = UDim2.fromOffset(0,45)
PageHolder.Size = UDim2.new(1,0,1,-45)
PageHolder.BackgroundTransparency = 1
PageHolder.ZIndex = 2
PageHolder.Parent = Content

local Pages = {}
local Tabs = {}

local function CreatePage(Name)
	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name
	Page.Size = UDim2.fromScale(1,1)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 4
	Page.ScrollBarImageColor3 = Color3.fromRGB(85,85,95)
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.CanvasSize = UDim2.new()
	Page.ScrollingEnabled = true
	Page.Active = true
	Page.ZIndex = 3
	Page.Visible = false
	Page.Parent = PageHolder

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0,3)
	Padding.PaddingRight = UDim.new(0,7)
	Padding.PaddingBottom = UDim.new(0,8)
	Padding.Parent = Page

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0,8)
	Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Page

	Pages[Name] = Page
	return Page
end

local MainPage = CreatePage("Main")
local AutoPage = CreatePage("Auto")
local StatusPage = CreatePage("Status")
local PlayerPage = CreatePage("Player")

local function SelectTab(Name)
	for pageName,Page in pairs(Pages) do
		Page.Visible = (pageName == Name)
		if pageName == Name then
			Page.CanvasPosition = Vector2.new(0,0)
		end
	end

	for tabName,Button in pairs(Tabs) do
		Button.BackgroundColor3 =
			tabName == Name
			and Color3.fromRGB(65,105,210)
			or Color3.fromRGB(31,31,38)
	end
end

local function CreateTab(Name)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromOffset(85,32)
	Button.BackgroundColor3 = Color3.fromRGB(31,31,38)
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = Name
	Button.Font = Enum.Font.GothamBold
	Button.TextSize = 10
	Button.TextColor3 = Color3.fromRGB(235,235,240)
	Button.ZIndex = 21
	Button.Active = true
	Button.Parent = TabBar

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,9)
	Corner.Parent = Button

	Tabs[Name] = Button
	Button.MouseButton1Click:Connect(function()
		SelectTab(Name)
	end)
end

CreateTab("Main")
CreateTab("Auto")
CreateTab("Status")
CreateTab("Player")

local function SectionTitle(Parent, Text, Order)
	local Label = Instance.new("TextLabel")
	Label.Size = UDim2.new(1,0,0,24)
	Label.BackgroundTransparency = 1
	Label.Text = Text
	Label.Font = Enum.Font.GothamBold
	Label.TextSize = 13
	Label.TextColor3 = Color3.fromRGB(255,255,255)
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.LayoutOrder = Order
	Label.ZIndex = 4
	Label.Parent = Parent
	return Label
end

local function InfoBox(Parent, Text, Height, Order)
	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.new(1,0,0,Height)
	Frame.BackgroundColor3 = Color3.fromRGB(25,25,31)
	Frame.BorderSizePixel = 0
	Frame.LayoutOrder = Order
	Frame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,10)
	Corner.Parent = Frame

	local Label = Instance.new("TextLabel")
	Label.BackgroundTransparency = 1
	Label.Position = UDim2.fromOffset(12,0)
	Label.Size = UDim2.new(1,-24,1,0)
	Label.Text = Text
	Label.Font = Enum.Font.Gotham
	Label.TextSize = 10
	Label.TextColor3 = Color3.fromRGB(150,150,160)
	Label.TextWrapped = true
	Label.TextXAlignment = Enum.TextXAlignment.Left
	Label.TextYAlignment = Enum.TextYAlignment.Center
	Label.Parent = Frame
	return Frame
end

local function CreateToggle(
	Parent,
	Name,
	Description,
	GetState,
	SetState,
	Callback,
	Order
)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1,0,0,65)
	Button.BackgroundColor3 = Color3.fromRGB(29,29,35)
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = ""
	Button.LayoutOrder = Order
	Button.Active = true
	Button.ZIndex = 4
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,12)
	Corner.Parent = Button

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(60,60,70)
	Stroke.Transparency = 0.3
	Stroke.Parent = Button

	local NameLabel = Instance.new("TextLabel")
	NameLabel.BackgroundTransparency = 1
	NameLabel.Position = UDim2.fromOffset(14,7)
	NameLabel.Size = UDim2.new(1,-110,0,23)
	NameLabel.Font = Enum.Font.GothamBold
	NameLabel.Text = Name
	NameLabel.TextSize = 14
	NameLabel.TextColor3 = Color3.fromRGB(240,240,245)
	NameLabel.TextXAlignment = Enum.TextXAlignment.Left
	NameLabel.Parent = Button

	local Desc = Instance.new("TextLabel")
	Desc.BackgroundTransparency = 1
	Desc.Position = UDim2.fromOffset(14,32)
	Desc.Size = UDim2.new(1,-110,0,18)
	Desc.Font = Enum.Font.Gotham
	Desc.Text = Description
	Desc.TextSize = 10
	Desc.TextColor3 = Color3.fromRGB(135,135,145)
	Desc.TextXAlignment = Enum.TextXAlignment.Left
	Desc.Parent = Button

	local Toggle = Instance.new("Frame")
	Toggle.Size = UDim2.fromOffset(50,28)
	Toggle.Position = UDim2.new(1,-64,0.5,-14)
	Toggle.BackgroundColor3 = Color3.fromRGB(65,65,73)
	Toggle.BorderSizePixel = 0
	Toggle.Parent = Button

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(1,0)
	ToggleCorner.Parent = Toggle

	local Circle = Instance.new("Frame")
	Circle.Size = UDim2.fromOffset(22,22)
	Circle.Position = UDim2.fromOffset(3,3)
	Circle.BackgroundColor3 = Color3.fromRGB(238,238,242)
	Circle.BorderSizePixel = 0
	Circle.Parent = Toggle

	local CircleCorner = Instance.new("UICorner")
	CircleCorner.CornerRadius = UDim.new(1,0)
	CircleCorner.Parent = Circle

	local Status = Instance.new("TextLabel")
	Status.BackgroundTransparency = 1
	Status.Size = UDim2.fromOffset(45,13)
	Status.Position = UDim2.new(1,-61,1,-16)
	Status.Font = Enum.Font.GothamBold
	Status.Text = "OFF"
	Status.TextSize = 8
	Status.TextColor3 = Color3.fromRGB(135,135,145)
	Status.Parent = Button

	local function Update()
		if GetState() then
			Toggle.BackgroundColor3 = Color3.fromRGB(65,105,210)
			Circle.Position = UDim2.fromOffset(25,3)
			NameLabel.TextColor3 = Color3.fromRGB(150,190,255)
			Status.Text = "ON"
			Status.TextColor3 = Color3.fromRGB(110,170,255)
		else
			Toggle.BackgroundColor3 = Color3.fromRGB(65,65,73)
			Circle.Position = UDim2.fromOffset(3,3)
			NameLabel.TextColor3 = Color3.fromRGB(240,240,245)
			Status.Text = "OFF"
			Status.TextColor3 = Color3.fromRGB(135,135,145)
		end
	end

	Button.MouseButton1Click:Connect(function()
		local Value = not GetState()
		SetState(Value)
		Update()
		if Callback then
			Callback(Value)
		end
	end)

	Update()
	return Button
end

--========================================================
-- PLOT OWNER
--========================================================

local function ReadOwnerValue(Owner)
	if not Owner then return nil end

	if Owner:IsA("ObjectValue") then
		if Owner.Value and Owner.Value:IsA("Player") then
			return Owner.Value.UserId
		end
		return nil
	end

	if Owner:IsA("IntValue") or Owner:IsA("NumberValue") then
		return tonumber(Owner.Value)
	end

	if Owner:IsA("StringValue") then
		local Numeric = tonumber(Owner.Value)
		if Numeric then
			return Numeric
		end

		if Owner.Value == Player.Name
			or Owner.Value == Player.DisplayName then
			return Player.UserId
		end
	end

	local Attribute = Owner:GetAttribute("Value")
	if Attribute ~= nil then
		return tonumber(Attribute)
	end

	return nil
end

local function GetPlotOwnerId(Plot)
	if not Plot then return nil end

	local Data = Plot:FindFirstChild("Data")
	if not Data then
		return nil
	end

	local Owner = Data:FindFirstChild("Owner")
	return ReadOwnerValue(Owner)
end

local function GetAllPlots()
	local Result = {}
	local Seen = {}

	for _,Object in ipairs(workspace:GetDescendants()) do
		if Object:IsA("Model") or Object:IsA("Folder") then

			local Data = Object:FindFirstChild("Data")

			if Data
				and Data:FindFirstChild("Owner") then

				if not Seen[Object] then
					Seen[Object] = true
					table.insert(Result,Object)
				end
			end
		end
	end

	return Result
end

local function FindOwnPlot()
	for _,Plot in ipairs(GetAllPlots()) do

		if GetPlotOwnerId(Plot) ==
			Player.UserId then

			local Part =
				Plot:FindFirstChild(
					"Spawn",
					true
				)
				or Plot:FindFirstChild(
					"PlotSpawn",
					true
				)
				or Plot:FindFirstChild(
					"Center",
					true
				)
				or Plot:FindFirstChild(
					"Home",
					true
				)

			if not Part
				or not Part:IsA(
					"BasePart"
				) then

				if Plot:IsA(
					"Model"
				) then

					Part =
						Plot.PrimaryPart
						or Plot:FindFirstChildWhichIsA(
							"BasePart",
							true
						)
				end
			end

			if Part then
				State.OwnPlot = Plot
				State.OwnPlotPart = Part
				State.OwnPlotCFrame = Part.CFrame
				return true
			end
		end
	end

	return false
end

local function FindPlotFromPoint(Position)
	for _,Plot in ipairs(
		GetAllPlots()
	) do

		local Part =
			Plot:FindFirstChild(
				"Spawn",
				true
			)
			or Plot:FindFirstChild(
				"PlotSpawn",
				true
			)
			or Plot:FindFirstChild(
				"Center",
				true
			)
			or Plot:FindFirstChild(
				"Home",
				true
			)

		if not Part
			or not Part:IsA("BasePart") then

			if Plot:IsA("Model") then
				Part =
					Plot.PrimaryPart
					or Plot:FindFirstChildWhichIsA(
						"BasePart",
						true
					)
			end
		end

		if Part then
			local BoxCFrame, BoxSize =
				Plot:GetBoundingBox()

			local Local =
				BoxCFrame:PointToObjectSpace(Position)

			-- fallback: use distance to a known plot point
			if (
				Position -
				Part.Position
			).Magnitude <= 12 then
				return Plot
			end

		end
	end

	return nil
end

local function IsInsideAnyPlot(Data)

	if not Data or not Data.Object then
		return false
	end

	local Current =
		Data.Object

	while Current
		and Current ~= workspace do

		if Current:IsA("Model")
			or Current:IsA("Folder") then

			local OwnerId =
				GetPlotOwnerId(
					Current
				)

			if OwnerId ~= nil then
				return true
			end
		end

		Current =
			Current.Parent
	end

	return false
end

local function GetReturnCFrame()

	if not State.OwnPlot then
		FindOwnPlot()
	end

	if not State.OwnPlot then
		return nil
	end

	local Part =
		State.OwnPlotPart

	if not Part then
		FindOwnPlot()
		Part =
			State.OwnPlotPart
	end

	if not Part then
		return nil
	end

	local Target =
		Part.CFrame *
		CFrame.new(
			PLOT_OFFSET
		)

	-- Keep target near/inside the detected own plot.
	local BoxCFrame, BoxSize =
		State.OwnPlot:GetBoundingBox()

	local Local =
		BoxCFrame:PointToObjectSpace(
			Target.Position
		)

	local Margin =
		math.min(
			PLOT_MARGIN,
			BoxSize.X / 4,
			BoxSize.Z / 4
		)

	Local =
		Vector3.new(
			math.clamp(
				Local.X,
				-BoxSize.X/2 + Margin,
				BoxSize.X/2 - Margin
			),
			math.clamp(
				Local.Y,
				-BoxSize.Y/2 + 2,
				BoxSize.Y/2 + 4
			),
			math.clamp(
				Local.Z,
				-BoxSize.Z/2 + Margin,
				BoxSize.Z/2 - Margin
			)
		)

	return
		CFrame.new(
			BoxCFrame:PointToWorldSpace(Local)
		)
end

--========================================================
-- EGG RESOLVE / CACHE
--========================================================

local function GetEggPart(Object)
	if Object:IsA("BasePart") then
		return Object
	end

	if Object:IsA("Model") then
		return Object.PrimaryPart
			or Object:FindFirstChildWhichIsA(
				"BasePart",
				true
			)
	end

	return nil
end

local function ResolveEgg(Object)

	if not Object then
		return nil
	end

	if EGG_SET[Object.Name] then
		local Part =
			GetEggPart(Object)

		if Part then
			return {
				Object = Object,
				Part = Part,
				Name = Object.Name
			}
		end
	end

	if Object.Name == "Egg" then

		local Current = Object.Parent

		for _ = 1,8 do

			if not Current then
				break
			end

			if EGG_SET[Current.Name] then

				local Part =
					GetEggPart(Current)
					or GetEggPart(Object)

				if Part then
					return {
						Object = Current,
						Part = Part,
						Name = Current.Name
					}
				end
			end

			Current = Current.Parent
		end
	end

	return nil
end

local function CacheEgg(Object)

	if Object.Name ~= "Egg"
		and not EGG_SET[
			Object.Name
		] then

		return
	end

	local Data =
		ResolveEgg(Object)

	if Data
		and Data.Part
		and Data.Part.Parent then

		EggCache[
			Data.Object
		] = Data
	end
end

task.spawn(function()

	task.wait(0.5)

	for _,Object in ipairs(
		workspace:GetDescendants()
	) do

		if Object.Name == "Egg"
			or EGG_SET[
				Object.Name
			] then

			CacheEgg(
				Object
			)
		end
	end
end)

workspace.DescendantAdded:Connect(
	function(Object)

		if Object.Name == "Egg"
			or EGG_SET[
				Object.Name
			] then

			task.defer(
				CacheEgg,
				Object
			)
		end
	end
)

workspace.DescendantRemoving:Connect(
	function(Object)

		EggCache[
			Object
		] = nil

		local Visual =
			ESPObjects[
				Object
			]

		if Visual then

			if Visual.Highlight then
				Visual.Highlight:Destroy()
			end

			if Visual.Billboard then
				Visual.Billboard:Destroy()
			end

			ESPObjects[
				Object
			] = nil
		end
	end
)

--========================================================
-- WORLD EGG LIST
--========================================================

local function GetWorldEggs()

	local Result =
		{}

	for _,Data in pairs(
		EggCache
	) do

		if Data.Object.Parent
			and Data.Part
			and Data.Part.Parent
			and SelectedEggs[
				Data.Name
			]
			and not IsInsideAnyPlot(
				Data
			) then

			table.insert(
				Result,
				Data
			)
		end
	end

	return Result
end

local function GetNearestEgg(List)

	local Root =
		GetRoot()

	if not Root then
		return nil
	end

	local Best
	local BestDistance =
		math.huge

	for _,Data in ipairs(
		List
	) do

		local Distance =
			(
				Root.Position
				-
				Data.Part.Position
			).Magnitude

		if Distance <
			BestDistance then

			BestDistance =
				Distance

			Best =
				Data
		end
	end

	return Best
end

--========================================================
-- ESP
--========================================================

local function DestroyESP(Object)

	local Visual =
		ESPObjects[
			Object
		]

	if not Visual then
		return
	end

	if Visual.Highlight then
		Visual.Highlight:Destroy()
	end

	if Visual.Billboard then
		Visual.Billboard:Destroy()
	end

	ESPObjects[
		Object
	] = nil
end

local function CreateESP(Data)

	if ESPObjects[
		Data.Object
	] then
		return
	end

	local Highlight =
		Instance.new(
			"Highlight"
		)

	Highlight.Name =
		"RideAPetESP"

	Highlight.Adornee =
		Data.Object

	Highlight.FillColor =
		Color3.fromRGB(
			255,40,40
		)

	Highlight.FillTransparency =
		0.45

	Highlight.OutlineColor =
		Color3.fromRGB(
			255,255,255
		)

	Highlight.OutlineTransparency =
		0

	Highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	Highlight.Parent =
		Data.Object

	local Billboard =
		Instance.new(
			"BillboardGui"
		)

	Billboard.Name =
		"RideAPetEggInfo"

	Billboard.Adornee =
		Data.Part

	Billboard.AlwaysOnTop =
		true

	Billboard.Size =
		UDim2.fromOffset(
			230,38
		)

	Billboard.StudsOffset =
		Vector3.new(
			0,4,0
		)

	Billboard.MaxDistance =
		ESP_MAX_DISTANCE

	Billboard.Parent =
		Data.Part

	local Label =
		Instance.new(
			"TextLabel"
		)

	Label.BackgroundTransparency =
		1

	Label.Size =
		UDim2.fromScale(
			1,1
		)

	Label.Font =
		Enum.Font.GothamBold

	Label.TextSize =
		13

	Label.TextColor3 =
		Color3.fromRGB(
			255,60,60
		)

	Label.TextStrokeColor3 =
		Color3.fromRGB(
			255,255,255
		)

	Label.TextStrokeTransparency =
		0

	Label.Text =
		Data.Name

	Label.Parent =
		Billboard

	ESPObjects[
		Data.Object
	] = {
		Highlight = Highlight,
		Billboard = Billboard,
		Text = Label
	}
end

task.spawn(function()

	while Gui.Parent do

		if State.ESP then

			local Root =
				GetRoot()

			if Root then

				local Candidates =
					{}

				for _,Data in pairs(
					EggCache
				) do

					if Data.Object.Parent
						and Data.Part
						and Data.Part.Parent
						and not IsInsideAnyPlot(
							Data
						) then

						local Distance =
							(
								Root.Position
								-
								Data.Part.Position
							).Magnitude

						if Distance <=
							ESP_MAX_DISTANCE then

							table.insert(
								Candidates,
								{
									Data = Data,
									Distance = Distance
								}
							)
						end
					end
				end

				table.sort(
					Candidates,
					function(A,B)
						return A.Distance <
							B.Distance
					end
				)

				local Allowed =
					{}

				for Index = 1,
					math.min(
						#Candidates,
						ESP_MAX_OBJECTS
					) do

					local Data =
						Candidates[
							Index
						].Data

					Allowed[
						Data.Object
					] = true

					CreateESP(
						Data
					)

					local Visual =
						ESPObjects[
							Data.Object
						]

					if Visual then

						Visual.Text.Text =
							Data.Name
							..
							" • "
							..
							math.floor(
								Candidates[
									Index
								].Distance
							)
							..
							" studs"
					end
				end

				for Object in pairs(
					ESPObjects
				) do

					if not Allowed[
						Object
					] then

						DestroyESP(
							Object
						)
					end
				end
			end

		else

			for Object in pairs(
				ESPObjects
			) do

				DestroyESP(
					Object
				)
			end
		end

		task.wait(
			ESP_UPDATE_RATE
		)
	end
end)

--========================================================
-- PICKUP REMOTE LISTENER
--========================================================

local EggPickupEvent

task.spawn(function()

	local Success,Event =
		pcall(function()

			return ReplicatedStorage
				:WaitForChild(
					"Remotes",
					5
				)
				:WaitForChild(
					"Game",
					5
				)
				:WaitForChild(
					"EggPickup",
					5
				)
		end)

	if Success
		and Event
		and Event:IsA(
			"RemoteEvent"
		) then

		EggPickupEvent =
			Event

		EggPickupEvent.OnClientEvent:Connect(
			function(
				Action,
				EggName,
				UUID
			)

				if Action ==
					"PickedUp"
					and PickupWaiting then

					PickupConfirmed =
						true

					State.LastPickup =
						tostring(
							EggName
						)

					State.LastAction =
						"Pickup Confirmed"
				end
			end
		)
	end
end)

--========================================================
-- PROMPT
--========================================================

local function FindPrompt(Object)

	if not Object then
		return nil
	end

	local Current =
		Object

	for _ = 1,8 do

		if not Current then
			break
		end

		local Prompt =
			Current:FindFirstChildWhichIsA(
				"ProximityPrompt",
				true
			)

		if Prompt
			and Prompt.Enabled then

			return Prompt
		end

		Current =
			Current.Parent
	end

	return nil
end

local function WaitForPrompt(
	Object,
	Timeout
)

	local Start =
		os.clock()

	local Limit =
		Timeout
		or PROMPT_WAIT

	while State.AutoEgg
		and
		os.clock() - Start <
		Limit do

		local Prompt =
			FindPrompt(
				Object
			)

		if Prompt
			and Prompt.Enabled then

			return Prompt
		end

		task.wait(
			0.05
		)
	end

	return nil
end

local function ActivatePrompt(
	Object
)

	local Prompt =
		FindPrompt(
			Object
		)

	if not Prompt
		or not Prompt.Enabled then

		return false
	end

	local Success =
		pcall(function()

			-- Make the egg prompt instant for this client.
			-- Uses Roblox's normal ProximityPrompt input API; no exploit-only prompt function.
			local OldHold = Prompt.HoldDuration
			local OldClickable = Prompt.ClickablePrompt

			Prompt.HoldDuration = 0
			Prompt.ClickablePrompt = true

			Prompt:InputHoldBegin()
			Prompt:InputHoldEnd()

			task.wait(0.05)

			pcall(function()
				Prompt.HoldDuration = OldHold
				Prompt.ClickablePrompt = OldClickable
			end)
		end)

	return Success
end

--========================================================
-- TWEEN
--========================================================

local NoclipConnection
local NoclipParts = {}
local NoclipActive = false

local function SetTweenNoclip(
	Enabled
)

	local Character =
		GetCharacter()

	if not Character then
		return
	end

	if Enabled then

		if NoclipActive then
			return
		end

		NoclipActive =
			true

		NoclipParts =
			{}

		for _,Part in ipairs(
			Character:GetDescendants()
		) do

			if Part:IsA(
				"BasePart"
			) then

				NoclipParts[
					Part
				] =
					Part.CanCollide

				Part.CanCollide =
					false
			end
		end

		NoclipConnection =
			RunService.Stepped:Connect(
				function()

					if not NoclipActive then
						return
					end

					for Part in pairs(
						NoclipParts
					) do

						if Part
							and Part.Parent then

							Part.CanCollide =
								false
						end
					end
				end
			)

	else

		NoclipActive =
			false

		if NoclipConnection then

			NoclipConnection:Disconnect()

			NoclipConnection =
				nil
		end

		for Part,OldValue in pairs(
			NoclipParts
		) do

			if Part
				and Part.Parent then

				Part.CanCollide =
					OldValue
			end
		end

		NoclipParts =
			{}
	end
end

local function TweenTo(Target)

	local Root =
		GetRoot()

	if not Root then
		return false
	end

	local Distance =
		(
			Root.Position
			-
			Target.Position
		).Magnitude

	if Distance <= 2 then
		return true
	end

	local Alpha =
		math.clamp(
			Distance / 1000,
			0,1
		)

	local Duration =
		TWEEN_MIN
		+
		(
			TWEEN_MAX -
			TWEEN_MIN
		)
		*
		Alpha

	local Humanoid =
		GetHumanoid()

	local OldAutoRotate =
		Humanoid
		and Humanoid.AutoRotate

	SetTweenNoclip(
		true
	)

	if Humanoid then
		Humanoid.AutoRotate =
			false
	end

	local Tween =
		TweenService:Create(
			Root,
			TweenInfo.new(
				Duration,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				CFrame = Target
			}
		)

	Tween:Play()

	local Finished =
		false

	local Connection =
		Tween.Completed:Connect(
			function()
				Finished =
					true
			end
		)

	local Start =
		os.clock()

	while not Finished
		and Root.Parent
		and os.clock() - Start <
		Duration + 1 do

		RunService.Heartbeat:Wait()
	end

	Connection:Disconnect()

	if Humanoid
		and Humanoid.Parent then

		Humanoid.AutoRotate =
			OldAutoRotate
			~= nil
			and OldAutoRotate
			or true
	end

	SetTweenNoclip(
		false
	)

	return Finished
end

--========================================================
-- AUTO EGG
--========================================================

local function ReturnToOwnPlot()

	if not State.OwnPlot
		or not State.OwnPlotPart then

		if not FindOwnPlot() then
			return false
		end
	end

	local Target =
		GetReturnCFrame()

	if not Target then
		return false
	end

	State.LastAction =
		"Tween → Own Plot"

	local Success =
		TweenTo(
			Target
		)

	if not Success then
		return false
	end

	local Root =
		GetRoot()

	if not Root then
		return false
	end

	local Start =
		os.clock()

	while State.AutoEgg
		and os.clock() - Start <
		3 do

		local Distance =
			(
				Root.Position
				-
				Target.Position
			).Magnitude

		if Distance <= 10 then

			State.LastAction =
				"Inside Own Plot"

			task.wait(
				0.15
			)

			return true
		end

		task.wait(
			0.05
		)
	end

	return false
end

local function CollectEgg(
	Target
)

	State.LastEgg =
		Target.Name

	State.LastAction =
		"Tween → "
		..
		Target.Name

	local TargetCF =
		CFrame.new(
			Target.Part.Position
			+
			Vector3.new(
				0,
				3.2,
				0
			)
		)

	if not TweenTo(
		TargetCF
	) then
		return false
	end

	if not State.AutoEgg then
		return false
	end

	-- Prompt may appear after the model is loaded.
	local Prompt =
		WaitForPrompt(
			Target.Object,
			PROMPT_WAIT
		)

	if not Prompt then
		State.LastAction =
			"Waiting Prompt"
		return false
	end

	PickupConfirmed =
		false

	PickupTargetName =
		Target.Name

	PickupWaiting =
		true

	State.LastAction =
		"Pickup → "
		..
		Target.Name

	if not ActivatePrompt(
		Target.Object
	) then

		PickupWaiting =
			false

		return false
	end

	local Start =
		os.clock()

	while State.AutoEgg
		and not PickupConfirmed do

		if os.clock() - Start >= PROMPT_RETRY then

			Start =
				os.clock()

			-- Retry the same prompt, never a new egg.
			local Retry =
				FindPrompt(
					Target.Object
				)

			if Retry
				and Retry.Enabled then

				State.LastAction =
					"Retry Prompt → "
					..
					Target.Name

				ActivatePrompt(
					Target.Object
				)
			else

				WaitForPrompt(
					Target.Object,
					1
				)
			end
		end

		State.LastAction =
			"Waiting Pickup Remote → "
			..
			Target.Name

		task.wait(
			0.05
		)
	end

	PickupWaiting =
		false

	if not State.AutoEgg then
		return false
	end

	if not PickupConfirmed then
		return false
	end

	PickupTargetName =
		nil

	-- IMPORTANT:
	-- no next egg until return to the locked own plot succeeds.
	while State.AutoEgg do

		if ReturnToOwnPlot() then
			break
		end

		State.LastAction =
			"Return Retry → Own Plot"

		task.wait(
			0.25
		)
	end

	return State.AutoEgg
end

local function StartAutoEgg()

	if State.AutoEggRunning then
		return
	end

	State.AutoEggRunning =
		true

	task.spawn(function()

		-- Lock the own plot once before collecting.
		while State.AutoEgg
			and not FindOwnPlot() do

			State.LastAction =
				"Scanning Own Plot"

			task.wait(
				1
			)
		end

		while State.AutoEgg do

			local Eggs =
				GetWorldEggs()

			local Target =
				GetNearestEgg(
					Eggs
				)

			if not Target then

				State.LastAction =
					"Waiting World Egg"

				task.wait(
					AUTO_EGG_RATE
				)

				continue
			end

			if not CollectEgg(
				Target
			) then

				-- Keep the current world egg target available.
				-- Never silently jump into another action.
				task.wait(
					0.15
				)
			end
		end

		State.AutoEggRunning =
			false
	end)
end

--========================================================
-- AUTO REMOTES
--========================================================

local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local GameRemotes =
	Remotes
	and Remotes:FindFirstChild("Game")

local PlotRemotes =
	GameRemotes
	and GameRemotes:FindFirstChild("Plot")

local UpgradeRemote =
	PlotRemotes
	and PlotRemotes:FindFirstChild(
		"Upgrades"
	)

local RebirthRemote =
	GameRemotes
	and GameRemotes:FindFirstChild(
		"[Rebirth]"
	)

local function FireRemote(
	Remote
)

	if not Remote then
		return false
	end

	return pcall(function()

		if Remote:IsA(
			"RemoteEvent"
		) then

			Remote:FireServer()

		elseif Remote:IsA(
			"RemoteFunction"
		) then

			Remote:InvokeServer()
		end
	end)
end

local function StartAutoUpgrade()

	if State.UpgradeRunning then
		return
	end

	State.UpgradeRunning =
		true

	task.spawn(function()

		while State.AutoUpgrade do

			if not UpgradeRemote
				or not UpgradeRemote.Parent then

				UpgradeRemote =
					PlotRemotes
					and PlotRemotes:FindFirstChild(
						"Upgrades"
					)
			end

			if UpgradeRemote then

				FireRemote(
					UpgradeRemote
				)

				State.LastAction =
					"Upgrade"
			else

				State.LastAction =
					"Upgrade Remote Missing"
			end

			task.wait(
				UPGRADE_DELAY
			)
		end

		State.UpgradeRunning =
			false
	end)
end

local function StartAutoRebirth()

	if State.RebirthRunning then
		return
	end

	State.RebirthRunning =
		true

	task.spawn(function()

		while State.AutoRebirth do

			if not RebirthRemote
				or not RebirthRemote.Parent then

				RebirthRemote =
					GameRemotes
					and GameRemotes:FindFirstChild(
						"[Rebirth]"
					)
			end

			if RebirthRemote then

				FireRemote(
					RebirthRemote
				)

				State.LastAction =
					"Rebirth"
			end

			task.wait(
				REBIRTH_DELAY
			)
		end

		State.RebirthRunning =
			false
	end)
end

--========================================================
-- PLAYER FEATURES
--========================================================

local function ApplyAntiLag(
	Enabled
)

	if Enabled then

		for _,Object in ipairs(
			workspace:GetDescendants()
		) do

			if Object:IsA(
				"ParticleEmitter"
			)
			or Object:IsA(
				"Trail"
			)
			or Object:IsA(
				"Beam"
			)
			or Object:IsA(
				"Smoke"
			)
			or Object:IsA(
				"Fire"
			)
			or Object:IsA(
				"Sparkles"
			) then

				if SavedVisuals[
					Object
				] == nil then

					SavedVisuals[
						Object
					] =
						Object.Enabled
				end

				Object.Enabled =
					false
			end
		end

	else

		for Object,OldValue in pairs(
			SavedVisuals
		) do

			if Object
				and Object.Parent then

				Object.Enabled =
					OldValue
			end
		end

		SavedVisuals =
			{}
	end
end

workspace.DescendantAdded:Connect(
	function(Object)

		if State.AntiLag then

			if Object:IsA(
				"ParticleEmitter"
			)
			or Object:IsA(
				"Trail"
			)
			or Object:IsA(
				"Beam"
			)
			or Object:IsA(
				"Smoke"
			)
			or Object:IsA(
				"Fire"
			)
			or Object:IsA(
				"Sparkles"
			) then

				SavedVisuals[
					Object
				] =
					Object.Enabled

				Object.Enabled =
					false
			end
		end
	end
)

UserInputService.JumpRequest:Connect(
	function()

		if State.InfJump then

			local Humanoid =
				GetHumanoid()

			if Humanoid then

				Humanoid:ChangeState(
					Enum.HumanoidStateType.Jumping
				)
			end
		end
	end
)

local function Rejoin()
	State.LastAction =
		"Rejoining"

	pcall(function()
		TeleportService:Teleport(
			game.PlaceId,
			Player
		)
	end)
end

-- True public-server hopping needs the own game to provide a target JobId.
local function ServerHop()
	State.LastAction = "Server Hop"

	local ServerHopRemote = nil
	pcall(function()
		local RemotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
		local GameFolder = RemotesFolder and RemotesFolder:FindFirstChild("Game")
		ServerHopRemote = GameFolder and GameFolder:FindFirstChild("ServerHop")
	end)

	if not ServerHopRemote then
		State.LastAction = "Server Hop Remote Missing"
		return false
	end

	local Success, JobId = pcall(function()
		if ServerHopRemote:IsA("RemoteFunction") then
			return ServerHopRemote:InvokeServer()
		elseif ServerHopRemote:IsA("RemoteEvent") then
			ServerHopRemote:FireServer()
			return nil
		end
	end)

	if Success and type(JobId) == "string" and JobId ~= "" and JobId ~= game.JobId then
		State.LastAction = "Server Hop → " .. JobId
		pcall(function()
			TeleportService:TeleportToPlaceInstance(game.PlaceId, JobId, Player)
		end)
		return true
	end

	if Success and ServerHopRemote:IsA("RemoteEvent") then
		State.LastAction = "Server Hop Requested"
		return true
	end

	State.LastAction = "Server Hop JobId Missing"
	return false
end

RejoinConnection =
	TeleportService.TeleportInitFailed:Connect(
		function(PlayerWhoFailed)

			if PlayerWhoFailed
				== Player
				and State.AutoRejoin then

				task.wait(
					2
				)

				Rejoin()
			end
		end
	)

--========================================================
-- MAIN PAGE
--========================================================

SectionTitle(
	MainPage,
	"AUTO EGG",
	1
)

CreateToggle(
	MainPage,
	"Auto Egg",
	"World Egg → Tween → Prompt → Pickup Remote → Own Plot",

	function()
		return State.AutoEgg
	end,

	function(Value)
		State.AutoEgg =
			Value
	end,

	function(Value)

		if Value then

			if not FindOwnPlot() then

				State.AutoEgg =
					false

				State.LastAction =
					"Own Plot Not Found"
				return
			end

			StartAutoEgg()
		end
	end,

	2
)

SectionTitle(
	MainPage,
	"EGG LIST",
	3
)

local EggList =
	Instance.new(
		"ScrollingFrame"
	)

EggList.Size =
	UDim2.new(
		1,
		0,
		0,
		245
	)

EggList.BackgroundColor3 =
	Color3.fromRGB(
		23,
		23,
		28
	)

EggList.BorderSizePixel =
	0

EggList.ScrollBarThickness =
	4

EggList.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

EggList.CanvasSize =
	UDim2.new()

EggList.ScrollingEnabled =
	true

EggList.Active =
	true

EggList.LayoutOrder =
	4

EggList.Parent =
	MainPage

local EggCorner =
	Instance.new("UICorner")

EggCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

EggCorner.Parent =
	EggList

local EggPadding =
	Instance.new("UIPadding")

EggPadding.PaddingTop =
	UDim.new(
		0,
		5
	)

EggPadding.PaddingBottom =
	UDim.new(
		0,
		5
	)

EggPadding.PaddingLeft =
	UDim.new(
		0,
		5
	)

EggPadding.PaddingRight =
	UDim.new(
		0,
		5
	)

EggPadding.Parent =
	EggList

local EggLayout =
	Instance.new("UIListLayout")

EggLayout.Padding =
	UDim.new(
		0,
		4
	)

EggLayout.Parent =
	EggList

for _,EggName in ipairs(
	EGG_NAMES
) do

	local Button =
		Instance.new(
			"TextButton"
		)

	Button.Size =
		UDim2.new(
			1,
			-2,
			0,
			34
		)

	Button.BackgroundColor3 =
		Color3.fromRGB(
			33,
			33,
			40
		)

	Button.BorderSizePixel =
		0

	Button.AutoButtonColor =
		false

	Button.Text =
		""

	Button.Parent =
		EggList

	local Corner =
		Instance.new(
			"UICorner"
		)

	Corner.CornerRadius =
		UDim.new(
			0,
			8
		)

	Corner.Parent =
		Button

	local Label =
		Instance.new(
			"TextLabel"
		)

	Label.BackgroundTransparency =
		1

	Label.Position =
		UDim2.fromOffset(
			11,
			0
		)

	Label.Size =
		UDim2.new(
			1,
			-55,
			1,
			0
		)

	Label.Font =
		Enum.Font.GothamBold

	Label.Text =
		EggName

	Label.TextSize =
		10

	Label.TextColor3 =
		Color3.fromRGB(
			185,
			185,
			195
		)

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent =
		Button

	local Check =
		Instance.new(
			"TextLabel"
		)

	Check.BackgroundTransparency =
		1

	Check.Position =
		UDim2.new(
			1,
			-38,
			0,
			0
		)

	Check.Size =
		UDim2.fromOffset(
			30,
			34
		)

	Check.Font =
		Enum.Font.GothamBold

	Check.TextSize =
		16

	Check.Parent =
		Button

	local function Update()

		if SelectedEggs[
			EggName
		] then

			Button.BackgroundColor3 =
				Color3.fromRGB(
					55,
					100,
					205
				)

			Label.TextColor3 =
				Color3.fromRGB(
					255,
					255,
					255
				)

			Check.Text =
				"✓"

			Check.TextColor3 =
				Color3.fromRGB(
					255,
					255,
					255
				)

		else

			Button.BackgroundColor3 =
				Color3.fromRGB(
					33,
					33,
					40
				)

			Label.TextColor3 =
				Color3.fromRGB(
					185,
					185,
					195
				)

			Check.Text =
				""
		end
	end

	Update()

	Button.MouseButton1Click:Connect(
		function()

			SelectedEggs[
				EggName
			] =
				not SelectedEggs[
					EggName
				]

			Update()
		end
	)
end

--========================================================
-- ESP UNDER AUTO EGG
--========================================================

CreateToggle(
	MainPage,
	"ESP Egg",
	"World Egg saja • tidak tampil di plot mana pun",

	function()
		return State.ESP
	end,

	function(Value)
		State.ESP =
			Value
	end,

	nil,

	6
)

--========================================================
-- AUTO PAGE
--========================================================

SectionTitle(
	AutoPage,
	"AUTO",
	1
)

CreateToggle(
	AutoPage,
	"Auto Upgrade",
	"Remote: Remotes.Game.Plot.Upgrades • 0.5s",

	function()
		return State.AutoUpgrade
	end,

	function(Value)
		State.AutoUpgrade =
			Value
	end,

	function(Value)

		if Value then
			StartAutoUpgrade()
		end
	end,

	2
)

CreateToggle(
	AutoPage,
	"Auto Rebirth",
	"Remote: Remotes.Game.[Rebirth]",

	function()
		return State.AutoRebirth
	end,

	function(Value)
		State.AutoRebirth =
			Value
	end,

	function(Value)

		if Value then
			StartAutoRebirth()
		end
	end,

	3
)

--========================================================
-- STATUS PAGE
--========================================================

SectionTitle(
	StatusPage,
	"STATUS",
	1
)

local StatusValues =
	{}

local function StatusRow(
	Name,
	Order
)

	local Frame =
		Instance.new(
			"Frame"
		)

	Frame.Size =
		UDim2.new(
			1,
			0,
					36
		)

	Frame.BackgroundColor3 =
		Color3.fromRGB(
			27,
			27,
			33
		)

	Frame.BorderSizePixel =
		0

	Frame.LayoutOrder =
		Order

	Frame.Parent =
		StatusPage

	local Corner =
		Instance.new(
			"UICorner"
		)

	Corner.CornerRadius =
		UDim.new(
			0,
			9
		)

	Corner.Parent =
		Frame

	local Label =
		Instance.new(
			"TextLabel"
		)

	Label.BackgroundTransparency =
		1

	Label.Position =
		UDim2.fromOffset(
			11,
			0
		)

	Label.Size =
		UDim2.new(
			0.44,
			0,
			1,
			0
		)

	Label.Font =
		Enum.Font.GothamBold

	Label.Text =
		Name

	Label.TextSize =
		10

	Label.TextColor3 =
		Color3.fromRGB(
			145,
			145,
			155
		)

	Label.TextXAlignment =
		Enum.TextXAlignment.Left

	Label.Parent =
		Frame

	local Value =
		Instance.new(
			"TextLabel"
		)

	Value.BackgroundTransparency =
		1

	Value.Position =
		UDim2.new(
			0.44,
			0,
			0,
			0
		)

	Value.Size =
		UDim2.new(
			0.56,
			-11,
			1,
			0
		)

	Value.Font =
		Enum.Font.Gotham

	Value.Text =
		"-"

	Value.TextSize =
		10

	Value.TextColor3 =
		Color3.fromRGB(
			235,
			235,
			240
		)

	Value.TextXAlignment =
		Enum.TextXAlignment.Right
	Value.ZIndex = 5

	Value.Parent =
		Frame

	StatusValues[
		Name
	] =
		Value
end

StatusRow("GUI For",2)
StatusRow("Display Name",3)
StatusRow("Username",4)
StatusRow("User ID",5)
StatusRow("Place ID",6)
StatusRow("Job ID",7)
StatusRow("Players",8)
StatusRow("Ping",9)
StatusRow("Plot",10)
StatusRow("Owner",11)
StatusRow("World Eggs",12)
StatusRow("Selected Eggs",13)
StatusRow("Last Egg",14)
StatusRow("Last Pickup",15)
StatusRow("Action",16)

-- Nilai panjang seperti Job ID dipotong rapi, bukan menghilang.
for Name,Label in pairs(StatusValues) do
	Label.TextTruncate = Enum.TextTruncate.AtEnd
	Label.TextScaled = false
	if Name == "Job ID" then
		Label.TextSize = 8
	end
end

local RefreshPlot =
	Instance.new(
		"TextButton"
	)

RefreshPlot.Size =
	UDim2.new(
		1,
		0,
		0,
		39
	)

RefreshPlot.BackgroundColor3 =
	Color3.fromRGB(
		31,
		31,
		38
	)

RefreshPlot.BorderSizePixel =
	0

RefreshPlot.AutoButtonColor =
	false

RefreshPlot.Text =
	"Rescan Own Plot"

RefreshPlot.Font =
	Enum.Font.GothamBold

RefreshPlot.TextSize =
	11

RefreshPlot.TextColor3 =
	Color3.fromRGB(
		235,
		235,
		240
	)

RefreshPlot.LayoutOrder =
	17

RefreshPlot.Parent =
	StatusPage

local RefreshCorner =
	Instance.new(
		"UICorner"
	)

RefreshCorner.CornerRadius =
	UDim.new(
		0,
		9
	)

RefreshCorner.Parent =
	RefreshPlot

RefreshPlot.MouseButton1Click:Connect(
	function()

		if FindOwnPlot() then

			State.LastAction =
				"Own Plot Rescanned"

		else

			State.LastAction =
				"Own Plot Not Found"
		end
	end
)

--========================================================
-- PLAYER PAGE
--========================================================

SectionTitle(
	PlayerPage,
	"PLAYER",
	1
)

local SpeedBox =
	Instance.new(
		"Frame"
	)

SpeedBox.Size =
	UDim2.new(
		1,
		0,
		0,
		62
	)

SpeedBox.BackgroundColor3 =
	Color3.fromRGB(
		29,
		29,
		35
	)

SpeedBox.BorderSizePixel =
	0

SpeedBox.LayoutOrder =
	2

SpeedBox.Parent =
	PlayerPage

local SpeedCorner =
	Instance.new(
		"UICorner"
	)

SpeedCorner.CornerRadius =
	UDim.new(
		0,
		11
	)

SpeedCorner.Parent =
	SpeedBox

local SpeedLabel =
	Instance.new(
		"TextLabel"
	)

SpeedLabel.BackgroundTransparency =
	1

SpeedLabel.Position =
	UDim2.fromOffset(
		12,
		6
	)

SpeedLabel.Size =
	UDim2.new(
		0.5,
		0,
		0,
		22
	)

SpeedLabel.Text =
	"Speed"

SpeedLabel.TextColor3 =
	Color3.fromRGB(
		240,
		240,
		245
	)

SpeedLabel.Font =
	Enum.Font.GothamBold

SpeedLabel.TextSize =
	13

SpeedLabel.TextXAlignment =
	Enum.TextXAlignment.Left

SpeedLabel.Parent =
	SpeedBox

local SpeedInput =
	Instance.new(
		"TextBox"
	)

SpeedInput.Size =
	UDim2.fromOffset(
		85,
		34
	)

SpeedInput.Position =
	UDim2.new(
		1,
		-97,
		0,
		14
	)

SpeedInput.BackgroundColor3 =
	Color3.fromRGB(
		41,
		41,
		49
	)

SpeedInput.BorderSizePixel =
	0

SpeedInput.Text =
	tostring(
		State.Speed
	)

SpeedInput.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

SpeedInput.Font =
	Enum.Font.GothamBold

SpeedInput.TextSize =
	12

SpeedInput.ClearTextOnFocus =
	false

SpeedInput.Parent =
	SpeedBox

local SpeedInputCorner =
	Instance.new(
		"UICorner"
	)

SpeedInputCorner.CornerRadius =
	UDim.new(
		0,
		8
	)

SpeedInputCorner.Parent =
	SpeedInput

SpeedInput.FocusLost:Connect(
	function()

		local Value =
			tonumber(
				SpeedInput.Text
			)

		if Value then

			State.Speed =
				math.clamp(
					Value,
					0,
					MAX_SPEED
				)

			SpeedInput.Text =
				tostring(
					State.Speed
				)

			ApplySpeed()
		else

			SpeedInput.Text =
				tostring(
					State.Speed
				)
		end
	end
)

CreateToggle(
	PlayerPage,
	"Inf Jump",
	"JumpRequest → continuous jump",

	function()
		return State.InfJump
	end,

	function(Value)
		State.InfJump =
			Value
	end,

	nil,

	3
)

CreateToggle(
	PlayerPage,
	"Auto Rejoin",
	"Retry teleport saat gagal; disconnect total tidak bisa dideteksi client",

	function()
		return State.AutoRejoin
	end,

	function(Value)
		State.AutoRejoin =
			Value
	end,

	nil,

	4
)

local RejoinNow =
	Instance.new(
		"TextButton"
	)

RejoinNow.Size =
	UDim2.new(
		1,
		0,
		0,
		39
	)

RejoinNow.BackgroundColor3 =
	Color3.fromRGB(
		31,
		31,
		38
	)

RejoinNow.BorderSizePixel =
	0

RejoinNow.AutoButtonColor =
	false

RejoinNow.Text =
	"Server Hop"

RejoinNow.Font =
	Enum.Font.GothamBold

RejoinNow.TextSize =
	11

RejoinNow.TextColor3 =
	Color3.fromRGB(
		235,
		235,
		240
	)

RejoinNow.LayoutOrder =
	5

RejoinNow.Parent =
	PlayerPage

local RejoinCorner =
	Instance.new(
		"UICorner"
	)

RejoinCorner.CornerRadius =
	UDim.new(
		0,
		9
	)

RejoinCorner.Parent =
	RejoinNow

RejoinNow.MouseButton1Click:Connect(
	ServerHop
)

CreateToggle(
	PlayerPage,
	"Anti Lag",
	"Disable particle/trail/beam/smoke/fire lokal",

	function()
		return State.AntiLag
	end,

	function(Value)
		State.AntiLag =
			Value
	end,

	function(Value)
		ApplyAntiLag(
			Value
		)
	end,

	6
)

SectionTitle(
	PlayerPage,
	"PLAYER LIST",
	7
)

local PlayerList =
	Instance.new(
		"ScrollingFrame"
	)

PlayerList.Size =
	UDim2.new(
		1,
		0,
		0,
		165
	)

PlayerList.BackgroundColor3 =
	Color3.fromRGB(
		23,
		23,
		28
	)

PlayerList.BorderSizePixel =
	0

PlayerList.ScrollBarThickness =
	4

PlayerList.AutomaticCanvasSize =
	Enum.AutomaticSize.Y

PlayerList.CanvasSize =
	UDim2.new()

PlayerList.ScrollingEnabled =
	true

PlayerList.Active =
	true

PlayerList.LayoutOrder =
	8

PlayerList.Parent =
	PlayerPage

local PlayerCorner =
	Instance.new(
		"UICorner"
	)

PlayerCorner.CornerRadius =
	UDim.new(
		0,
		10
	)

PlayerCorner.Parent =
	PlayerList

local PlayerPadding =
	Instance.new(
		"UIPadding"
	)

PlayerPadding.PaddingTop =
	UDim.new(
		0,
		5
	)

PlayerPadding.PaddingBottom =
	UDim.new(
		0,
		5
	)

PlayerPadding.PaddingLeft =
	UDim.new(
		0,
		5
	)

PlayerPadding.PaddingRight =
	UDim.new(
		0,
		5
	)

PlayerPadding.Parent =
	PlayerList

local PlayerLayout =
	Instance.new(
		"UIListLayout"
	)

PlayerLayout.Padding =
	UDim.new(
		0,
		4
	)

PlayerLayout.Parent =
	PlayerList

local function RefreshPlayerList()

	for _,Child in ipairs(
		PlayerList:GetChildren()
	) do

		if Child:IsA(
			"TextButton"
		) then

			Child:Destroy()
		end
	end

	for _,Other in ipairs(
		Players:GetPlayers()
	) do

		local Button =
			Instance.new(
				"TextButton"
			)

		Button.Size =
			UDim2.new(
				1,
				-2,
				0,
				34
			)

		Button.BackgroundColor3 =
			Color3.fromRGB(
				33,
				33,
				40
			)

		Button.BorderSizePixel =
			0

		Button.AutoButtonColor =
			false

		Button.Text =
			Other.DisplayName
			..
			"  @"
			..
			Other.Name

		Button.Font =
			Enum.Font.GothamBold

		Button.TextSize =
			10

		Button.TextColor3 =
			Other == Player
			and
			Color3.fromRGB(
				150,
				190,
				255
			)
			or
			Color3.fromRGB(
				220,
				220,
				225
			)

		Button.Parent =
			PlayerList

		local Corner =
			Instance.new(
				"UICorner"
			)

		Corner.CornerRadius =
			UDim.new(
				0,
				8
			)

		Corner.Parent =
			Button
	end
end

Players.PlayerAdded:Connect(
	RefreshPlayerList
)

Players.PlayerRemoving:Connect(
	RefreshPlayerList
)

RefreshPlayerList()

--========================================================
-- STATUS LOOP
--========================================================

task.spawn(function()

	while Gui.Parent do

		local Ping =
			0

		pcall(function()

			local Item =
				Stats.Network.ServerStatsItem[
					"Data Ping"
				]

			if Item then

				Ping =
					math.floor(
						Item:GetValue()
					)
			end
		end)

		local WorldCount =
			0

		for _,Data in pairs(
			EggCache
		) do

			if Data.Object.Parent
				and Data.Part
				and Data.Part.Parent
				and not IsInsideAnyPlot(
					Data
				) then

				WorldCount +=
					1
			end
		end

		local SelectedCount =
			0

		for _,Enabled in pairs(
			SelectedEggs
		) do

			if Enabled then
				SelectedCount += 1
			end
		end

		if StatusValues["GUI For"] then
			StatusValues["GUI For"].Text = Player.DisplayName .. "  @" .. Player.Name
		end

		if StatusValues["Display Name"] then
			StatusValues["Display Name"].Text = Player.DisplayName
		end

		if StatusValues["Username"] then
			StatusValues["Username"].Text = "@" .. Player.Name
		end

		if StatusValues["User ID"] then
			StatusValues["User ID"].Text = tostring(Player.UserId)
		end

		if StatusValues["Place ID"] then
			StatusValues["Place ID"].Text = tostring(game.PlaceId)
		end

		if StatusValues["Job ID"] then
			StatusValues["Job ID"].Text = tostring(game.JobId)
		end

		if StatusValues["Players"] then
			StatusValues["Players"].Text = tostring(#Players:GetPlayers())
		end

		if StatusValues["Plot"] then
			StatusValues["Plot"].Text =
				State.OwnPlot
				and State.OwnPlot.Name
				or
				"Not Found"
		end

		if StatusValues["Owner"] then
			local OwnerId = State.OwnPlot and GetPlotOwnerId(State.OwnPlot)
			StatusValues["Owner"].Text = OwnerId and tostring(OwnerId) or "-"
		end

		if StatusValues["Ping"] then
			StatusValues["Ping"].Text = tostring(Ping) .. " ms"
		end

		if StatusValues["World Eggs"] then
			StatusValues["World Eggs"].Text =
				tostring(WorldCount)
		end

		if StatusValues["Selected Eggs"] then
			StatusValues["Selected Eggs"].Text =
				tostring(SelectedCount)
		end

		if StatusValues["Last Egg"] then
			StatusValues["Last Egg"].Text =
				State.LastEgg
		end

		if StatusValues["Last Pickup"] then
			StatusValues["Last Pickup"].Text =
				State.LastPickup
		end

		if StatusValues["Action"] then
			StatusValues["Action"].Text =
				State.LastAction
		end

		task.wait(
			0.8
		)
	end
end)

--========================================================
-- CHARACTER CLEANUP
--========================================================

Player.CharacterRemoving:Connect(function()

	SetTweenNoclip(
		false
	)

	if State.AntiLag then
		ApplyAntiLag(
			false
		)
	end
end)

--========================================================
-- CUSTOM GUI BRIDGE
-- Uses gui.rbxm imported into ReplicatedStorage as RideAPetTemplate.
--========================================================

local LegacyGui = Gui
local GuiTemplate = ReplicatedStorage:FindFirstChild("RideAPetTemplate")

if not GuiTemplate then
	GuiTemplate = ReplicatedStorage:FindFirstChild("ScreenGui")
end

local CustomGui = nil

if GuiTemplate and GuiTemplate:IsA("ScreenGui") then
	CustomGui = GuiTemplate:Clone()
	CustomGui.Name = "RideAPetGUI"
	CustomGui.ResetOnSpawn = false
	CustomGui.IgnoreGuiInset = true
	CustomGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	CustomGui.DisplayOrder = 1000
	CustomGui.Parent = PlayerGui

	if LegacyGui and LegacyGui.Parent then
		LegacyGui:Destroy()
	end

	Gui = CustomGui
else
	warn("[Ride a Pet] gui.rbxm belum dimasukkan ke ReplicatedStorage sebagai RideAPetTemplate / ScreenGui.")
end

--========================================================
-- CUSTOM GUI HELPERS
--========================================================

local CustomMain
local CustomHeader
local CustomMainTab
local CustomMiscTab
local CustomPlayerTab
local CustomOpenBtn
local CustomCloseBtn
local CustomMainBtn
local CustomMiscBtn
local CustomPlayerBtn

local CustomToggles = {}
local CustomStatus = {}
local CustomPlayerList

local function FindGui(Name, ClassName)
	if not CustomGui then
		return nil
	end

	local Object = CustomGui:FindFirstChild(Name, true)

	if Object
		and (not ClassName or Object:IsA(ClassName)) then
		return Object
	end

	return nil
end

local function GetToggleButton(FrameName)
	local Frame = FindGui(FrameName)
	if not Frame then return nil end

	local Button = Frame:FindFirstChild("Button", true)
	if Button and Button:IsA("TextButton") then
		return Button
	end

	return Frame:FindFirstChildWhichIsA("TextButton", true)
end

local function UpdateCustomToggle(Name, Enabled)
	local Button = CustomToggles[Name]
	if not Button then return end

	Button.Text = Enabled and "On" or "Off"

	pcall(function()
		if Enabled then
			Button.BackgroundColor3 = Color3.fromRGB(70,110,220)
			Button.TextColor3 = Color3.fromRGB(255,255,255)
		else
			Button.BackgroundColor3 = Color3.fromRGB(35,35,42)
			Button.TextColor3 = Color3.fromRGB(210,210,220)
		end
	end)
end

local function BindCustomToggle(FrameName, StateKey, Callback)
	local Button = GetToggleButton(FrameName)
	if not Button then
		return nil
	end

	CustomToggles[StateKey] = Button

	Button.MouseButton1Click:Connect(function()
		State[StateKey] = not State[StateKey]
		UpdateCustomToggle(StateKey, State[StateKey])

		if Callback then
			Callback(State[StateKey])
		end
	end)

	UpdateCustomToggle(StateKey, State[StateKey])
	return Button
end

local function MakePage(Name)
	if not CustomMain then return nil end

	local Page = Instance.new("ScrollingFrame")
	Page.Name = Name
	Page.Size = UDim2.new(1,0,1,0)
	Page.BackgroundTransparency = 1
	Page.BorderSizePixel = 0
	Page.ScrollBarThickness = 4
	Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
	Page.CanvasSize = UDim2.new(0,0,0,0)
	Page.Visible = false
	Page.Parent = CustomMain:FindFirstChild("Tab", true) or CustomMain

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0,8)
	Padding.PaddingRight = UDim.new(0,8)
	Padding.PaddingTop = UDim.new(0,6)
	Padding.PaddingBottom = UDim.new(0,10)
	Padding.Parent = Page

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0,7)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Page

	return Page
end

local function StatusRowNew(Parent, Name, Value, Order)
	local Row = Instance.new("Frame")
	Row.Name = "Status_" .. Name
	Row.Size = UDim2.new(1,0,0,32)
	Row.BackgroundColor3 = Color3.fromRGB(27,27,33)
	Row.BorderSizePixel = 0
	Row.LayoutOrder = Order
	Row.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,8)
	Corner.Parent = Row

	local L = Instance.new("TextLabel")
	L.BackgroundTransparency = 1
	L.Position = UDim2.fromOffset(10,0)
	L.Size = UDim2.new(0.48,-5,1,0)
	L.Font = Enum.Font.GothamBold
	L.Text = Name
	L.TextSize = 10
	L.TextColor3 = Color3.fromRGB(145,145,155)
	L.TextXAlignment = Enum.TextXAlignment.Left
	L.Parent = Row

	local V = Instance.new("TextLabel")
	V.BackgroundTransparency = 1
	V.Position = UDim2.new(0.48,0,0,0)
	V.Size = UDim2.new(0.52,-10,1,0)
	V.Font = Enum.Font.Gotham
	V.Text = tostring(Value or "-")
	V.TextSize = 10
	V.TextColor3 = Color3.fromRGB(235,235,240)
	V.TextXAlignment = Enum.TextXAlignment.Right
	V.Parent = Row

	CustomStatus[Name] = V
end

local function MakePlayerToggle(Parent, Name, StateKey, Order, Callback)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1,0,0,56)
	Button.BackgroundColor3 = Color3.fromRGB(29,29,35)
	Button.BorderSizePixel = 0
	Button.AutoButtonColor = false
	Button.Text = ""
	Button.LayoutOrder = Order
	Button.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0,10)
	Corner.Parent = Button

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Position = UDim2.fromOffset(12,5)
	TitleLabel.Size = UDim2.new(1,-95,0,22)
	TitleLabel.Font = Enum.Font.GothamBold
	TitleLabel.Text = Name
	TitleLabel.TextSize = 12
	TitleLabel.TextColor3 = Color3.fromRGB(235,235,240)
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = Button

	local StateLabel = Instance.new("TextLabel")
	StateLabel.BackgroundTransparency = 1
	StateLabel.Position = UDim2.new(1,-75,0,5)
	StateLabel.Size = UDim2.fromOffset(63,22)
	StateLabel.Font = Enum.Font.GothamBold
	StateLabel.TextSize = 9
	StateLabel.TextXAlignment = Enum.TextXAlignment.Right
	StateLabel.Parent = Button

	local function Update()
		StateLabel.Text = State[StateKey] and "ON" or "OFF"
		StateLabel.TextColor3 = State[StateKey]
			and Color3.fromRGB(110,175,255)
			or Color3.fromRGB(135,135,145)
	end

	Button.MouseButton1Click:Connect(function()
		State[StateKey] = not State[StateKey]
		Update()
		if Callback then Callback(State[StateKey]) end
	end)

	Update()
end

if CustomGui then
	CustomMain = FindGui("MainFrame", "Frame")
	CustomHeader = FindGui("Header", "Frame")
	CustomMainTab = FindGui("MainTab", "ScrollingFrame")
	CustomMiscTab = FindGui("MiscTab", "ScrollingFrame")
	CustomOpenBtn = FindGui("OpenBtn", "ImageButton")
	CustomCloseBtn = FindGui("CloseButtom", "TextButton")
	CustomMainBtn = FindGui("MainBtn", "TextButton")
	CustomMiscBtn = FindGui("MiscBtn", "TextButton")
	CustomPlayerBtn = FindGui("PlayerBtn", "TextButton")

	if CustomMiscBtn then
		CustomMiscBtn.Text = "Status"
	end

	-- Reuse the template's MainTab/MiscTab and add a Player page.
	if CustomMain then
		CustomPlayerTab = MakePage("PlayerTab")
	end

	-- Remove any stale status widgets from previous executions.
	if CustomMiscTab then
		for _,Child in ipairs(CustomMiscTab:GetChildren()) do
			if Child.Name:sub(1,7) == "Status_" then
				Child:Destroy()
			end
		end

		StatusRowNew(CustomMiscTab, "GUI User", Player.DisplayName .. "  @" .. Player.Name, 50)
		StatusRowNew(CustomMiscTab, "User ID", Player.UserId, 51)
		StatusRowNew(CustomMiscTab, "Place ID", game.PlaceId, 52)
		StatusRowNew(CustomMiscTab, "Job ID", game.JobId ~= "" and game.JobId or "Studio/Test", 53)
		StatusRowNew(CustomMiscTab, "Players", "-", 54)
		StatusRowNew(CustomMiscTab, "Ping", "-", 55)
		StatusRowNew(CustomMiscTab, "Plot", "-", 56)
		StatusRowNew(CustomMiscTab, "World Eggs", "-", 57)
		StatusRowNew(CustomMiscTab, "Selected Eggs", "-", 58)
		StatusRowNew(CustomMiscTab, "Last Egg", "-", 59)
		StatusRowNew(CustomMiscTab, "Last Pickup", "-", 60)
		StatusRowNew(CustomMiscTab, "Action", "Idle", 61)
	end

	-- Rebuild the egg selector inside the supplied GUI's EggList.
	local CustomEggList = FindGui("EggList", "ScrollingFrame")
	if CustomEggList then
		for _,Child in ipairs(CustomEggList:GetChildren()) do
			if Child:IsA("TextButton") then
				Child:Destroy()
			end
		end

		for Index,EggName in ipairs(EGG_NAMES) do
			local B = Instance.new("TextButton")
			B.Size = UDim2.new(1,-6,0,30)
			B.BackgroundColor3 = Color3.fromRGB(33,33,40)
			B.BorderSizePixel = 0
			B.AutoButtonColor = false
			B.Text = EggName
			B.TextSize = 10
			B.Font = Enum.Font.GothamBold
			B.TextXAlignment = Enum.TextXAlignment.Left
			B.TextColor3 = Color3.fromRGB(190,190,200)
			B.LayoutOrder = Index
			B.Parent = CustomEggList

			local Pad = Instance.new("UIPadding")
			Pad.PaddingLeft = UDim.new(0,9)
			Pad.Parent = B

			local C = Instance.new("UICorner")
			C.CornerRadius = UDim.new(0,7)
			C.Parent = B

			local function UpdateEgg()
				if SelectedEggs[EggName] then
					B.BackgroundColor3 = Color3.fromRGB(60,100,205)
					B.TextColor3 = Color3.fromRGB(255,255,255)
				else
					B.BackgroundColor3 = Color3.fromRGB(33,33,40)
					B.TextColor3 = Color3.fromRGB(190,190,200)
				end
			end

			UpdateEgg()
			B.MouseButton1Click:Connect(function()
				SelectedEggs[EggName] = not SelectedEggs[EggName]
				UpdateEgg()
			end)
		end
	end

	-- Egg list open/close button from the supplied GUI.
	local OpenEggList = CustomMain and CustomMain:FindFirstChild("Open", true)
	local EggListFrame = CustomMain and CustomMain:FindFirstChild("ListFrame", true)
	if OpenEggList and OpenEggList:IsA("TextButton") and EggListFrame then
		EggListFrame.Visible = false
		OpenEggList.MouseButton1Click:Connect(function()
			EggListFrame.Visible = not EggListFrame.Visible
		end)
	end

	-- Main toggles from the supplied GUI.
	BindCustomToggle("AutoEgg", "AutoEgg", function(Value)
		if Value then
			if not FindOwnPlot() then
				State.AutoEgg = false
				UpdateCustomToggle("AutoEgg", false)
				State.LastAction = "Own Plot Not Found"
				return
			end
			StartAutoEgg()
		end
	end)

	BindCustomToggle("EspEgg", "ESP", nil)
	BindCustomToggle("AutoUpgrade", "AutoUpgrade", function(Value)
		if Value then StartAutoUpgrade() end
	end)
	BindCustomToggle("AutoRebirth", "AutoRebirth", function(Value)
		if Value then StartAutoRebirth() end
	end)

	-- Make the auto-rebirth duplicate and AutoPlace visually harmless if present.
	local AutoPlaceButton = nil
	for _,Obj in ipairs(CustomMain:GetDescendants()) do
		if Obj:IsA("TextLabel") and Obj.Text == "AutoPlace" then
			local ParentFrame = Obj.Parent
			AutoPlaceButton = ParentFrame and ParentFrame:FindFirstChild("Button", true)
			break
		end
	end
	if AutoPlaceButton and AutoPlaceButton:IsA("TextButton") then
		AutoPlaceButton.Text = "OFF"
	end

	-- Tabs.
	local function ShowPage(Page)
		if CustomMainTab then CustomMainTab.Visible = (Page == CustomMainTab) end
		if CustomMiscTab then CustomMiscTab.Visible = (Page == CustomMiscTab) end
		if CustomPlayerTab then CustomPlayerTab.Visible = (Page == CustomPlayerTab) end
	end

	if CustomMainBtn then CustomMainBtn.MouseButton1Click:Connect(function() ShowPage(CustomMainTab) end) end
	if CustomMiscBtn then CustomMiscBtn.MouseButton1Click:Connect(function() ShowPage(CustomMiscTab) end) end
	if CustomPlayerBtn then CustomPlayerBtn.MouseButton1Click:Connect(function() ShowPage(CustomPlayerTab) end) end

	-- Player page.
	if CustomPlayerTab then
		local HeaderText = Instance.new("TextLabel")
		HeaderText.Size = UDim2.new(1,0,0,26)
		HeaderText.BackgroundTransparency = 1
		HeaderText.Text = "PLAYER"
		HeaderText.Font = Enum.Font.GothamBold
		HeaderText.TextSize = 13
		HeaderText.TextColor3 = Color3.fromRGB(245,245,250)
		HeaderText.TextXAlignment = Enum.TextXAlignment.Left
		HeaderText.LayoutOrder = 1
		HeaderText.Parent = CustomPlayerTab

		local SpeedBox = Instance.new("Frame")
		SpeedBox.Size = UDim2.new(1,0,0,52)
		SpeedBox.BackgroundColor3 = Color3.fromRGB(29,29,35)
		SpeedBox.BorderSizePixel = 0
		SpeedBox.LayoutOrder = 2
		SpeedBox.Parent = CustomPlayerTab

		local SC = Instance.new("UICorner")
		SC.CornerRadius = UDim.new(0,9)
		SC.Parent = SpeedBox

		local SL = Instance.new("TextLabel")
		SL.BackgroundTransparency = 1
		SL.Position = UDim2.fromOffset(10,0)
		SL.Size = UDim2.new(0.55,0,1,0)
		SL.Text = "Speed"
		SL.Font = Enum.Font.GothamBold
		SL.TextSize = 12
		SL.TextColor3 = Color3.fromRGB(235,235,240)
		SL.TextXAlignment = Enum.TextXAlignment.Left
		SL.Parent = SpeedBox

		local SI = Instance.new("TextBox")
		SI.Size = UDim2.fromOffset(80,32)
		SI.Position = UDim2.new(1,-90,0.5,-16)
		SI.BackgroundColor3 = Color3.fromRGB(41,41,49)
		SI.BorderSizePixel = 0
		SI.ClearTextOnFocus = false
		SI.Text = tostring(State.Speed)
		SI.TextColor3 = Color3.fromRGB(255,255,255)
		SI.Font = Enum.Font.GothamBold
		SI.TextSize = 12
		SI.Parent = SpeedBox

		local SIC = Instance.new("UICorner")
		SIC.CornerRadius = UDim.new(0,7)
		SIC.Parent = SI

		SI.FocusLost:Connect(function()
			local V = tonumber(SI.Text)
			if V then
				State.Speed = math.clamp(V,0,MAX_SPEED)
			end
			SI.Text = tostring(State.Speed)
			ApplySpeed()
		end)

		MakePlayerToggle(CustomPlayerTab, "Infinite Jump", "InfJump", 3)
		MakePlayerToggle(CustomPlayerTab, "Auto Rejoin", "AutoRejoin", 4)
		MakePlayerToggle(CustomPlayerTab, "Anti Lag", "AntiLag", 5, function(Value)
			ApplyAntiLag(Value)
		end)

		local ServerHop = Instance.new("TextButton")
		ServerHop.Size = UDim2.new(1,0,0,40)
		ServerHop.BackgroundColor3 = Color3.fromRGB(31,31,38)
		ServerHop.BorderSizePixel = 0
		ServerHop.AutoButtonColor = false
		ServerHop.Text = "Server Hop"
		ServerHop.Font = Enum.Font.GothamBold
		ServerHop.TextSize = 11
		ServerHop.TextColor3 = Color3.fromRGB(235,235,240)
		ServerHop.LayoutOrder = 6
		ServerHop.Parent = CustomPlayerTab

		local SHC = Instance.new("UICorner")
		SHC.CornerRadius = UDim.new(0,8)
		SHC.Parent = ServerHop

		ServerHop.MouseButton1Click:Connect(function()
			State.LastAction = "Server Hop"
			pcall(function()
				TeleportService:Teleport(game.PlaceId, Player)
			end)
		end)

		local PLTitle = Instance.new("TextLabel")
		PLTitle.Size = UDim2.new(1,0,0,24)
		PLTitle.BackgroundTransparency = 1
		PLTitle.Text = "PLAYERS"
		PLTitle.Font = Enum.Font.GothamBold
		PLTitle.TextSize = 12
		PLTitle.TextColor3 = Color3.fromRGB(245,245,250)
		PLTitle.TextXAlignment = Enum.TextXAlignment.Left
		PLTitle.LayoutOrder = 7
		PLTitle.Parent = CustomPlayerTab

		CustomPlayerList = Instance.new("ScrollingFrame")
		CustomPlayerList.Size = UDim2.new(1,0,0,160)
		CustomPlayerList.BackgroundColor3 = Color3.fromRGB(23,23,28)
		CustomPlayerList.BorderSizePixel = 0
		CustomPlayerList.ScrollBarThickness = 4
		CustomPlayerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
		CustomPlayerList.CanvasSize = UDim2.new(0,0,0,0)
		CustomPlayerList.LayoutOrder = 8
		CustomPlayerList.Parent = CustomPlayerTab

		local PLC = Instance.new("UICorner")
		PLC.CornerRadius = UDim.new(0,9)
		PLC.Parent = CustomPlayerList

		local PLayout = Instance.new("UIListLayout")
		PLayout.Padding = UDim.new(0,4)
		PLayout.Parent = CustomPlayerList

		local function RefreshCustomPlayers()
			for _,Child in ipairs(CustomPlayerList:GetChildren()) do
				if Child:IsA("TextButton") then Child:Destroy() end
			end
			for _,Other in ipairs(Players:GetPlayers()) do
				local B = Instance.new("TextButton")
				B.Size = UDim2.new(1,-8,0,30)
				B.BackgroundColor3 = Color3.fromRGB(33,33,40)
				B.BorderSizePixel = 0
				B.AutoButtonColor = false
				B.Text = Other.DisplayName .. "  @" .. Other.Name
				B.Font = Enum.Font.GothamBold
				B.TextSize = 10
				B.TextXAlignment = Enum.TextXAlignment.Left
				B.TextColor3 = Other == Player
					and Color3.fromRGB(150,190,255)
					or Color3.fromRGB(220,220,225)
				B.Parent = CustomPlayerList
			end
		end

		RefreshCustomPlayers()
		Players.PlayerAdded:Connect(RefreshCustomPlayers)
		Players.PlayerRemoving:Connect(RefreshCustomPlayers)
	end

	-- Open/close animation.
	local MainScaleNew = CustomMain and CustomMain:FindFirstChildOfClass("UIScale")
	if CustomMain and not MainScaleNew then
		MainScaleNew = Instance.new("UIScale")
		MainScaleNew.Scale = 1
		MainScaleNew.Parent = CustomMain
	end

	local Opened = true

	local function OpenCustom()
		Opened = true
		if CustomMain then
			CustomMain.Visible = true
			if MainScaleNew then
				MainScaleNew.Scale = 0.88
				TweenService:Create(MainScaleNew,TweenInfo.new(0.20,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
			end
		end
		if CustomOpenBtn then CustomOpenBtn.Visible = false end
	end

	local function CloseCustom()
		Opened = false
		if CustomMain then
			if MainScaleNew then
				local T = TweenService:Create(MainScaleNew,TweenInfo.new(0.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Scale=0.88})
				T:Play()
				task.delay(0.18,function()
					if not Opened and CustomMain then CustomMain.Visible = false end
				end)
			else
				CustomMain.Visible = false
			end
		end
		if CustomOpenBtn then CustomOpenBtn.Visible = true end
	end

	if CustomCloseBtn then CustomCloseBtn.MouseButton1Click:Connect(CloseCustom) end
	if CustomOpenBtn then CustomOpenBtn.MouseButton1Click:Connect(OpenCustom) end

	-- Make OpenBtn draggable.
	if CustomOpenBtn then
		local Drag = false
		local Start = nil
		local StartPos = nil

		CustomOpenBtn.InputBegan:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				Drag = true
				Start = Input.Position
				StartPos = CustomOpenBtn.Position
			end
		end)

		UserInputService.InputChanged:Connect(function(Input)
			if not Drag then return end
			if Input.UserInputType ~= Enum.UserInputType.MouseMovement
				and Input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			local D = Input.Position - Start
			CustomOpenBtn.Position = UDim2.new(
				StartPos.X.Scale, StartPos.X.Offset + D.X,
				StartPos.Y.Scale, StartPos.Y.Offset + D.Y
			)
		end)

		CustomOpenBtn.InputEnded:Connect(function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1
				or Input.UserInputType == Enum.UserInputType.Touch then
				Drag = false
			end
		end)
	end

	ShowPage(CustomMainTab)
end

--========================================================
-- SPEED KEEP-ALIVE
--========================================================

RunService.Heartbeat:Connect(function()
	local Humanoid = GetHumanoid()
	if Humanoid and math.abs(Humanoid.WalkSpeed - State.Speed) > 0.1 then
		ApplySpeed()
	end
end)

--========================================================
-- STATUS MIRROR FOR CUSTOM GUI
--========================================================

task.spawn(function()
	while Gui and Gui.Parent do
		if CustomStatus and next(CustomStatus) then
			local Ping = 0
			pcall(function()
				local Item = Stats.Network.ServerStatsItem["Data Ping"]
				if Item then Ping = math.floor(Item:GetValue()) end
			end)

			local WorldCount = 0
			for _,Data in pairs(EggCache) do
				if Data.Object.Parent
					and Data.Part
					and Data.Part.Parent
					and not IsInsideAnyPlot(Data) then
					WorldCount += 1
				end
			end

			local SelectedCount = 0
			for _,Enabled in pairs(SelectedEggs) do
				if Enabled then SelectedCount += 1 end
			end

			local Values = {
				["GUI User"] = Player.DisplayName .. "  @" .. Player.Name,
				["User ID"] = tostring(Player.UserId),
				["Place ID"] = tostring(game.PlaceId),
				["Job ID"] = game.JobId ~= "" and game.JobId or "Studio/Test",
				["Players"] = tostring(#Players:GetPlayers()),
				["Ping"] = tostring(Ping) .. " ms",
				["Plot"] = State.OwnPlot and State.OwnPlot.Name or "Not Found",
				["World Eggs"] = tostring(WorldCount),
				["Selected Eggs"] = tostring(SelectedCount),
				["Last Egg"] = State.LastEgg,
				["Last Pickup"] = State.LastPickup,
				["Action"] = State.LastAction,
			}

			for Name,Value in pairs(Values) do
				if CustomStatus[Name] then CustomStatus[Name].Text = Value end
			end
		end

		task.wait(0.6)
	end
end)

--========================================================
-- START
--========================================================

if not CustomGui then
	SelectTab("Main")
end

task.spawn(function()
	task.wait(0.8)
	FindOwnPlot()
	ApplySpeed()
	print("[Ride a Pet] Ready")
end)
