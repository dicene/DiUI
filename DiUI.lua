local UEHelpers = require("UEHelpers")

local PrintDebugInfo = false

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

-- CORRECTED: Font is no longer searched for at load time. It will be found on first use in CreateTextBlock.
local KingthingsFont = nil ---@cast KingthingsFont UFont

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

    local outer = UEHelpers.GetGameViewportClient()
    local widget = StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), outer, FName(string.format("DiWindow_%s_%0.0f", name, math.random(1, 1000000)))) ---@cast widget UUserWidget
    printf("Constructed UserWidget: %s, %s", outer:GetFullName(), widget:GetFullName())
    newWindow.Name = widget:GetFullName()
    newWindow.InternalWidget = widget

    local tree = StaticConstructObject(StaticFindObject("/Script/UMG.WidgetTree"), widget) ---@cast tree UWidgetTree
    widget.WidgetTree = tree
    newWindow.InternalTree = tree

    local border = StaticConstructObject(StaticFindObject("/Script/UMG.Border"), widget) ---@cast border UBorder
    
    border:SetBrushColor({A=1,R=0,G=0,B=0})
    border.Background.ImageType = 0
    border:SetContentColorAndOpacity({A=1,R=1,G=1,B=1})
    border.Background.OutlineSettings.RoundingType = 0
    border.Background.OutlineSettings.CornerRadii = {X=5,Y=5,Z=5,W=5}
    border.Background.OutlineSettings.Color = {SpecifiedColor={A=1,R=0.2,G=0.2,B=0.2}, ColorUseRule=0}
    border.Background.OutlineSettings.bUseBrushTransparency = false
    border.Background.OutlineSettings.Width = 2.0
    border:SetPadding({Left=4,Right=4,Top=4,Bottom=4})
    border.Background.DrawAs = 4

    widget.WidgetTree.RootWidget = border
    newWindow.InternalBorder = border

    local vBox = StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), widget) ---@cast vBox, UVerticalBox
    newWindow.InternalVBox = vBox

    border:AddChild(vBox)

    widget:SetPositionInViewport({X=pos.X,Y=pos.Y}, false)
    printf("Finished creating new DiWindow.")
    return newWindow
end

---@param newPos FVector2D
function DiWindow:SetPos(newPos, bRemoveDPIScale)
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

function DiWindow:CreateScrollBox()
    return DiUI.CreateScrollBox(self.InternalWidget)
end

function DiWindow:CreateEditableTextBox()
    return DiUI.CreateEditableTextBox(self.InternalWidget)
end

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

function DiUI.DestroyWidgetsByName(name)
    local widgets = FindAllOf("UserWidget") or {}
    for i = 1, #widgets do
        local widget = widgets[i]
        if widget:GetFullName():match(name) then
            printf("Killing widget %s", widget:GetFullName())
            widget:RemoveFromParent()
        end
    end
end

function DiUI.DestroyAllWidgets()
    DiUI.DestroyWidgetsByName("DiWindow_")
end

local function GetInternalWidget(parent)
    if parent and parent.InternalWidget then
        return parent.InternalWidget
    end
    return parent
end

---@param parent UWidget | DiWindow
---@return UUserWidget
function DiUI.CreateUserWidget(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end
    return StaticConstructObject(StaticFindObject("/Script/UMG.UserWidget"), owner)
end

---@param parent UWidget | DiWindow
---@return UProgressBar
function DiUI.CreateProgressBar(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end

    local progressBar = StaticConstructObject(StaticFindObject("/Script/UMG.ProgressBar"), owner) ---@cast progressBar UProgressBar
    progressBar.ColorAndOpacity = {SpecifiedColor={A=1, R=0, G=0, B=0}, ColorUseRule=0}
    progressBar:SetPercent(0.80)
    progressBar:SetFillColorAndOpacity({A=1, R=0.1, G=1, B=0.0})
    return progressBar
end

---@param parent UWidget | DiWindow
---@param text string
---@return UTextBlock
function DiUI.CreateTextBlock(parent, text)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end

    local text = text or "[Text]"
    local textBlock = StaticConstructObject(StaticFindObject("/Script/UMG.TextBlock"), owner) ---@cast textBlock UTextBlock

    textBlock:SetText(FText(text))
    
    -- Lazily find the font only on the first run, preventing load-time errors.
    if not KingthingsFont or not KingthingsFont:IsValid() then
        KingthingsFont = FindByName("Font", "Font_Kingthings_Localized")
    end
    
    if KingthingsFont and KingthingsFont:IsValid() then
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
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end

    local image = StaticConstructObject(StaticFindObject("/Script/UMG.Image"), owner) ---@cast image UImage
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
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end
    return StaticConstructObject(StaticFindObject("/Script/UMG.HorizontalBox"), owner)
end

---@param parent UWidget | DiWindow
---@return UVerticalBox
function DiUI.CreateVerticalBox(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end
    return StaticConstructObject(StaticFindObject("/Script/UMG.VerticalBox"), owner)
end

---@param parent UWidget | DiWindow
---@return USizeBox
function DiUI.CreateSizeBox(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end
    return StaticConstructObject(StaticFindObject("/Script/UMG.SizeBox"), owner)
end

---@type TMap<string, function>
local ButtonClickCallbacks = {}
local ButtonClickHook

local function RegisterButtonClickHook()
    if not ButtonClickHook then
        ButtonClickHook = RegisterHook("Function /Script/CommonUI.CommonButtonBase:HandleButtonPressed", function(button)
            local btn = button:get()
            local buttonName = btn:GetFullName()
            if ButtonClickCallbacks[buttonName] then
                ButtonClickCallbacks[buttonName]()
            end
        end)
    end
end

---@param parent UWidget | DiWindow
---@return UScrollBox
---@param parent UWidget | DiWindow
---@return UScrollBox
function DiUI.CreateScrollBox(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then
        printf("Invalid parent passed to .")
        return CreateInvalidObject()
    end

    local scrollBox = StaticConstructObject(StaticFindObject("/Script/UMG.ScrollBox"), owner) ---@cast scrollBox UScrollBox
    if not scrollBox or not scrollBox:IsValid() then return CreateInvalidObject() end

    scrollBox:SetOrientation(1) -- Vertical
    scrollBox:SetScrollBarVisibility(5) -- AlwaysShow
    return scrollBox
end


---@param parent UWidget | DiWindow
---@return UEditableTextBox
function DiUI.CreateEditableTextBox(parent)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then return CreateInvalidObject() end

    local textBox = StaticConstructObject(StaticFindObject("/Script/UMG.EditableTextBox"), owner) ---@cast textBox UEditableTextBox
    return textBox
end


---@param parent UWidget | DiWindow
---@param text string
---@param clickFunction function
---@return UWBP_ModernPrefab_Button_C
function DiUI.CreateButton(parent, text, clickFunction)
    local owner = GetInternalWidget(parent)
    if not owner or not owner:IsValid() then
        printf("Invalid parent passed to CreateButton.")
        return CreateInvalidObject()
    end

    local buttonClass = StaticFindObject("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C") or CreateInvalidObject()
    if not buttonClass:IsValid() then
        LoadAsset("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C")
        buttonClass = StaticFindObject("/Game/UI/Modern/Prefabs/Buttons/WBP_ModernPrefab_Button.WBP_ModernPrefab_Button_C") or CreateInvalidObject()
    end
    if not buttonClass:IsValid() then return CreateInvalidObject() end

    local button = StaticConstructObject(buttonClass, owner) or CreateInvalidObject() ---@cast button UWBP_ModernPrefab_Button_C
    if button:IsValid() then
        button:SetButtonText(FText(text))
        button.ShouldFocusOnHover = false
        button.ShouldApplyFocusEffectOnHover = true
        button:SetVisibility(1)

        RegisterButtonClickHook()
        ButtonClickCallbacks[button:GetFullName()] = clickFunction

        ExecuteAsync(function()
            ExecuteInGameThread(function()
                if button and button:IsValid() then
                    if button.ButtonTextWidget and button.ButtonTextWidget:IsValid() then
                        button.ButtonTextWidget:SetColorAndOpacity({SpecifiedColor = { R = 1, G = 1, B = 1, A = 1.0 }, ColorUseRule = 0})
                        button.ButtonTextWidget:SetDefaultFontSize(22)
                    end
                    if button.State_Hover_Left_Fill and button.State_Hover_Left_Fill:IsValid() then
                        button.State_Hover_Left_Fill:SetColorAndOpacity({ A = 1, R = 0.1, G = 0.2, B = 0.2 })
                    end
                    if button.State_Hover_Middle_FIll and button.State_Hover_Middle_FIll:IsValid() then
                        button.State_Hover_Middle_FIll:SetColorAndOpacity({ A = 1, R = 0.1, G = 0.2, B = 0.2 })
                    end
                    if button.State_Hover_Right_Fill and button.State_Hover_Right_Fill:IsValid() then
                        button.State_Hover_Right_Fill:SetColorAndOpacity({ A = 1, R = 0.1, G = 0.2, B = 0.2 })
                    end
                    button:SetVisibility(0)
                end
            end)
        end)
    end
    return button
end

return DiUI
