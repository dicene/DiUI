local UEHelpers = require("UEHelpers")

local PrintDebugInfo = true
local DiUtils = require("DiUtils")
local FindByName = DiUtils.FindByName

local printf = function (text, ...) if not PrintDebugInfo then return end DiUtils.Printf(DiUtils.ColorizeText(200, 180, 120, "ReturningArrows"), text, ...) end

local KingthingsFont = FindByName("Font", "Font_Kingthings_Localized") or CreateInvalidObject() ---@cast KingthingsFont UFont

-- local printf = function(s,...) if not PrintDebugInfo then return end if not s:match("\n$") then s = "[DiUI] " .. s .. "\n" end return print(s:format(...)) end

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

---Destroys all widgets matching a particular name
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
---@param name string
---@return UProgressBar
function DiUI.CreateProgressBar(parent)
    local parent = parent ~= nil and parent.InternalWidget ~= nil and parent.InternalWidget or parent ---@cast parent UWidget
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
function DiUI.CreateTextBlock(parent, name, text)
    local parent = parent ~= nil and parent.InternalWidget ~= nil and parent.InternalWidget or parent ---@cast parent UWidget
    local textBlock = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), parent) ---@cast textBlock UTextBlock

    textBlock:SetText(FText(text))
    KingthingsFont = FindByName("Font", "Font_Kingthings_Localized") or CreateInvalidObject() ---@cast KingthingsFont UFont
    if KingthingsFont:IsValid() then
        printf("Kingthings font found: %s", KingthingsFont:GetFullName())
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
    local parent = parent ~= nil and parent.InternalWidget ~= nil and parent.InternalWidget or parent ---@cast parent UWidget
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
    local parent = parent ~= nil and parent.InternalWidget ~= nil and parent.InternalWidget or parent ---@cast parent UWidget
    local hBox = StaticConstructObject(StaticFindObject("/Script/UMG.HorizontalBox"), parent) ---@cast hBox UHorizontalBox

    return hBox
end

---@param parent UWidget | DiWindow
---@return UVerticalBox
function DiUI.CreateVerticalBox(parent)
    local parent = parent ~= nil and parent.InternalWidget ~= nil and parent.InternalWidget or parent ---@cast parent UWidget
    local hBox = StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), parent) ---@cast hBox UVerticalBox

    return hBox
end

return DiUI
