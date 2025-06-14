local UEHelpers = require("UEHelpers")

local PrintDebugInfo = true

local printf = function(s,...) if PrintDebugInfo then if not s:match("\n$") then s = "[DiUI] " .. s .. "\n" end return print(s:format(...)) end end

local FindByName = function (class, name)
    if name == nil then
        class, name = class:match("^(%w+) (.+)$")
    end

    if class == nil or name == nil then return CreateInvalidObject() end

    local objs = FindAllOf(class) or {}

    for i = 1, #objs, 1 do
        if objs[i]:GetFullName():match(name) then
            return objs[i]
        end
    end

    return CreateInvalidObject()
end

local KingthingsFont = FindByName("Font", "Font_Kingthings_Localized") or CreateInvalidObject() ---@cast KingthingsFont UFont

local DiUI = { }

---@class DiWindow
---@field Name string
---@field Title string
---@field Pos FVector2D
---@field public InternalWidget ?UUserWidget
---@field public InternalTree ?UWidgetTree
---@field public InternalBorder? UBorder
---@field public InternalVBox? UVerticalBox
local DiWindow = {}
DiUI.DiWindow = DiWindow

---@return DiWindow
function DiWindow:New(name, title, pos)
    printf("Creating new DiWindow: %s, %s, (X=%0.0f,Y=%0.0f)", name, title, pos.X, pos.Y)
    ---@type DiWindow
    local newWindow = {}
    setmetatable(newWindow, {__index = DiWindow})

    newWindow.Name = name
    newWindow.Title = title
    newWindow.Pos = pos

    -- printf("Constructing UserWidget")
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), UEHelpers.GetWorldContextObject(), FName(string.format("DiWindow_%s_%0.0f", name, math.random(1, 1000000)))) ---@cast widget UUserWidget
    newWindow.InternalWidget = widget

    -- printf("Constructing Tree")
    local tree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget) ---@cast tree UWidgetTree
    widget.WidgetTree = tree
    newWindow.InternalTree = tree

    -- printf("Constructing Border")
    local border = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), widget.WidgetTree) ---@cast border UBorder

    -- printf("Setting up Border")
    -- border.BrushColor = {A=0.2,R=.8,G=.4,B=.1}
    border:SetBrushColor({A=1,R=0,G=0,B=0})
    -- border:SetBrushFromTexture(nil)
    border.Background.ImageType = 0
    -- border.Background.TintColor = {SpecifiedColor={A=1,R=0,G=0,B=0}, ColorUseRule=0}
    border:SetContentColorAndOpacity({A=1,R=1,G=1,B=1})
    border.Background.OutlineSettings.RoundingType = 0
    border.Background.OutlineSettings.CornerRadii = {X=5,Y=5,Z=5,W=5}
    border.Background.OutlineSettings.Color = {SpecifiedColor={A=1,R=0.2,G=0.2,B=0.2}, ColorUseRule=0}
    border.Background.OutlineSettings.bUseBrushTransparency = false
    border.Background.OutlineSettings.Width = 2.0
    -- border.Color

    border:SetDesiredSizeScale({X=1,Y=1})
    border:SetPadding({Left=4,Right=4,Top=4,Bottom=4})
    border.Background.DrawAs = 4
    -- tree.RootWidget = border
    widget.WidgetTree.RootWidget = border
    newWindow.InternalBorder = border
    -- tree.RootWidget = border

    -- printf("Constructing VerticalBox")
    local vBox = StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), border) ---@cast vBox, UVerticalBox
    newWindow.InternalVBox = vBox

    -- border:AddChild(vBox)
    widget.WidgetTree.RootWidget:AddChild(vBox)

    -- widget:AddToViewport(99)
    -- widget:SetPositionInViewport({X=200,Y=200}, false)
    widget:SetPositionInViewport({X=pos.X,Y=pos.Y}, false)
    -- printf("Setting Widget up in Viewport")
    -- widget:SetDesiredSizeInViewport({X=200, Y=200})
    -- widget:SetPositionInViewport({X=pos.X,Y=pos.Y}, false)
    printf("Finished creating new DiWindow.")
    return newWindow
end

---@param newPos FVector2D
function DiWindow:SetPos(newPos, bRemoveDPIScale)
    -- printf("Setting DiWindow Position: (X=%0.0f, Y=%0.0f)", newPos.X, newPos.Y)
    self.Pos = newPos
    self.InternalWidget:SetPositionInViewport({X=newPos.X,Y=newPos.Y}, bRemoveDPIScale)
end

function DiWindow:Hide()
    self.InternalWidget:SetVisibility(1)
end

function DiWindow:Show()
    self.InternalWidget:SetVisibility(0)
    self.InternalWidget:AddToViewport(99999)
end

---@param text string
---@return UTextBlock
function DiWindow:CreateTextBlock(text)
    return DiUI.CreateTextBlock(self.InternalWidget, text)
end

---@return UProgressBar
function DiWindow:CreateProgressBar()
    return DiUI.CreateProgressBar(self.InternalWidget)
end

---@param image UTexture2D
---@param size FVector2D
---@return UImage
function DiWindow:CreateImage(image, size)
    return DiUI.CreateImage(self.InternalWidget, image, size)
end

---@return UHorizontalBox
function DiWindow:CreateHorizontalBox()
    return DiUI.CreateHorizontalBox(self.InternalWidget)
end

---@return UVerticalBox
function DiWindow:CreateVerticalBox()
    return DiUI.CreateVerticalBox(self.InternalWidget)
end

---@return USizeBox
function DiWindow:CreateSizeBox()
    return DiUI.CreateSizeBox(self.InternalWidget)
end

---@param text string
---@param clickFunction function
---@return UWBP_ModernPrefab_Button_C
function DiWindow:CreateButton(text, clickFunction)
    return DiUI.CreateButton(self.InternalWidget, text, clickFunction)
end

---Destroys all widgets matching a particular name. Be careful with this, and only use widget names that are VERY UNIQUE.
---@param name string
function DiUI.DestroyWidgetsByName(name)
    local widgets = FindAllOf("UserWidget") or {}

    for i = 1, #widgets do
        local widget = widgets[i]
        local fullName = widget:GetFullName()
        if fullName:match(name) then
            printf("Killing widget %s", widget:GetFullName())
            widget:RemoveFromParent()
        end
    end
end

---Destroys all DiWindows
function DiUI.DestroyAllWidgets()
    DiUI.DestroyWidgetsByName("DiWindow_")
end

---@param parent UWidget | DiWindow
---@return UUserWidget
function DiUI.CreateUserWidget(parent)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local userWidget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), parent) ---@cast userWidget UUserWidget

    return userWidget
end

---@param parent UWidget | DiWindow
---@param name string
---@return UProgressBar
function DiUI.CreateProgressBar(parent)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local progressBar = StaticConstructObject(StaticFindObject("/Script/UMG.ProgressBar"), parent) ---@cast progressBar UProgressBar
    progressBar.ColorAndOpacity = {SpecifiedColor={A=1, R=0, G=0, B=0}, ColorUseRule=0}
    progressBar:SetPercent(0.80)
    progressBar:SetFillColorAndOpacity({A=1, R=0.1, G=1, B=0.0})

    return progressBar
end

---@param parent UWidget | DiWindow
---@param name string
---@param text string
---@return UTextBlock
function DiUI.CreateTextBlock(parent, text)
    local parent = parent or CreateInvalidObject()
    printf("Parent: %s", parent)
    parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local text = text or "[Text]"
    local textBlock = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), parent) ---@cast textBlock UTextBlock

    textBlock:SetText(FText(text))
    -- Attempt to grab Kingthings font again if it wasn't already loaded when this script began
    KingthingsFont = KingthingsFont or FindByName("Font", "Font_Kingthings_Localized") or CreateInvalidObject() ---@cast KingthingsFont UFont
    if KingthingsFont:IsValid() then
        textBlock.Font.FontObject = KingthingsFont
    end
    textBlock.Font.Size = 16
    textBlock:SetJustification(1)
    textBlock.ColorAndOpacity = {SpecifiedColor={A=1, R=1, G=1, B=1}, ColorUseRule=0}
    textBlock.ShadowColorAndOpacity = {A=1, R=0, G=0, B=0}

    return textBlock
end

---@param parent UWidget | DiWindow
---@param texture2d UTexture2D
---@param size? FVector2D
---@return UImage
function DiUI.CreateImage(parent, texture2d, size)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), parent) ---@cast image UImage

    if size == nil then
        image:SetBrushFromTexture(texture2d, true)
    else
        image:SetBrushFromTexture(texture2d, false)
        image:SetDesiredSizeOverride(size)
    end

    return image
end

---@param parent UWidget | DiWindow
---@return UHorizontalBox
function DiUI.CreateHorizontalBox(parent)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local hBox = StaticConstructObject(StaticFindObject("/Script/UMG.HorizontalBox"), parent) ---@cast hBox UHorizontalBox

    return hBox
end

---@param parent UWidget | DiWindow
---@return UVerticalBox
function DiUI.CreateVerticalBox(parent)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local hBox = StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), parent) ---@cast hBox UVerticalBox

    return hBox
end

---@param parent UWidget | DiWindow
---@return USizeBox
function DiUI.CreateSizeBox(parent)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local sizeBox = StaticConstructObject(StaticFindObject("/Script/UMG.SizeBox"), parent) ---@cast sizeBox USizeBox

    return sizeBox
end

---@type TMap<string, function>
local ButtonClickCallbacks = {}

---@type number
local ButtonClickHook

local function RegisterButtonClickHook()
    if not ButtonClickHook then
        ButtonClickHook = RegisterHook("Function /Script/CommonUI.CommonButtonBase:HandleButtonPressed", function(button)
            local button = button:get()
            local buttonName = button:GetFullName()
            if ButtonClickCallbacks[buttonName] ~= nil then
                ButtonClickCallbacks[buttonName]()
            end
        end)
    end
end

-- if not (StaticFindObject("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C") or CreateInvalidObject()):IsValid() then
--     ExecuteInGameThread(function()
--         LoadAsset("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C")

--         RegisterHook("Function /Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C:OnInitButtonWidgets", function(button)
--             printf("OnInitButtonWidgets()")
--         end)
--     end)
-- else
--     RegisterHook("Function /Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C:OnInitButtonWidgets", function(button)
--         printf("OnInitButtonWidgets()")
--     end)
-- end

---@param parent UWidget | DiWindow
---@param text string
---@param clickFunction function
---@return UWBP_ModernPrefab_Button_C
function DiUI.CreateButton(parent, text, clickFunction)
    local parent = parent or CreateInvalidObject()
    local parent = parent:IsValid() and parent.InternalWidget:IsValid() and parent.InternalWidget or parent ---@cast parent UWidget

    if not parent:IsValid() then
        return CreateInvalidObject()
    end

    local buttonClass = StaticFindObject("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C") or CreateInvalidObject()

    if not buttonClass:IsValid() then
        printf("Loading button asset!")
        LoadAsset("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C")
        buttonClass = StaticFindObject("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C") or CreateInvalidObject()
    end

    if not buttonClass:IsValid() then
        printf("Failed to load ModernPrefab_Button.")
        return CreateInvalidObject()
    end
    -- printf("ButtonClass: %s", buttonClass:GetFullName())
    local button = StaticConstructObject(buttonClass, parent) or CreateInvalidObject() ---@cast button UWBP_ModernPrefab_Button_C

    if button:IsValid() then
        button:SetButtonText(FText(text))
        button.ShouldFocusOnHover = false
        button.ShouldApplyFocusEffectOnHover = true
        button:SetVisibility(1)

        RegisterButtonClickHook()
        ButtonClickCallbacks[button:GetFullName()] = clickFunction

        ExecuteAsync(function()
            ExecuteInGameThread(function ()
                if button.ButtonTextWidget:IsValid() then
                    button.ButtonTextWidget:SetColorAndOpacity({SpecifiedColor={R=1,G=1,B=1,A=1.000000}, ColorUseRule=0})
                    button.ButtonTextWidget:SetDefaultFontSize(22)
                end
                if button.State_Hover_Left_Fill:IsValid() then button.State_Hover_Left_Fill:SetColorAndOpacity({A=1,R=0.1,G=0.2,B=0.2}) end
                if button.State_Hover_Middle_FIll:IsValid() then button.State_Hover_Middle_FIll:SetColorAndOpacity({A=1,R=0.1,G=0.2,B=0.2}) end
                if button.State_Hover_Right_Fill:IsValid() then button.State_Hover_Right_Fill:SetColorAndOpacity({A=1,R=0.1,G=0.2,B=0.2}) end
                button:SetVisibility(0)
            end)
        end)
    end

    -- button:SetDesiredSizeInViewport({X=50,Y=50})

    return button
end

return DiUI