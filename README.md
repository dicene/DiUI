# DiUI
A basic UI framework for use in Oblivion Remaster modding.
I'm attempting to build things in an OOP Lua sort of way, so most things are generated with constructors and interacted with by directly calling their methods. I'm also attempting to use valid annotations for everything, which should make it easy to work with in VS Code or another IDE with Lua annotation support.

# Examples

![image](https://github.com/user-attachments/assets/fd7b57e7-5f86-4903-bd7f-7195bf920986)

```lua
local DiUI = require("DiUI")

local printf = function(s,...) if not s:match("\n$") then s = "[DialogueWidget] " .. s .. "\n" end return print(s:format(...)) end

function FindByName(class, name)
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

---@class DialogueWidget : DiWindow
---@field Name string
---
---@field NPC AVPairedPawn
---@field Pos FVector2D
---
---@field ExpandHint UTextBlock
---@field CollapsableBox UVerticalBox
---@field NameText UTextBlock
---@field ReRandomizeButton UWBP_ModernPrefab_Button_C
local DialogueWidget = {
    Name = "name123",
}
setmetatable(DialogueWidget, {__index = DiUI.DiWindow})

---@return DialogueWidget
function DialogueWidget:New(name, pos)

    local newDialogueWidget = DiUI.DiWindow:New(name, name, pos) ---@cast newDialogueWidget HealthWidget
    setmetatable(newDialogueWidget, {__index = DialogueWidget})

    local vBox = newDialogueWidget.InternalVBox

    local header = DiUI.CreateHorizontalBox(newDialogueWidget)
    vBox:AddChildToVerticalBox(header)

    newDialogueWidget.InternalBorder:SetBrushColor({A=1,R=0,G=0,B=0})

    -- local arrowTexture = FindByName("Texture2D /Game/Art/UI/Common/Buttons/T_CharGen_Arrow.T_CharGen_Arrow") or CreateInvalidObject() ---@cast arrowTexture UTexture2D
    -- local arrowTexture = FindByName("Texture2D /Game/Art/UI/Common/Buttons/T_CharGen_Arrow_Hovered.T_CharGen_Arrow_Hovered") or CreateInvalidObject() ---@cast arrowTexture UTexture2D
    -- local arrowTexture = FindByName("Texture2D /Game/Art/UI/Common/Buttons/T_Arrow_Hovered.T_Arrow_Hovered") or CreateInvalidObject() ---@cast arrowTexture UTexture2D
    -- local arrowTexture = FindByName("Texture2D /Game/Art/UI/Common/Buttons/T_ArrowHoverEffect.T_ArrowHoverEffect") or CreateInvalidObject() ---@cast arrowTexture UTexture2D
    local nameDecorationTexture = FindByName("Texture2D /Game/Art/UI/Common/Ornaments/T_UI_HelpPattern1.T_UI_HelpPattern1") or CreateInvalidObject() ---@cast arrowTexture UTexture2D

    if nameDecorationTexture:IsValid() then
        local image = DiUI.CreateImage(newDialogueWidget, nameDecorationTexture)
        image.Brush.ImageSize = {X=64,Y=32}
        header:AddChildToHorizontalBox(image)
    end

    newDialogueWidget.NameText = DiUI.CreateTextBlock(newDialogueWidget, "NameText", "Text")
    newDialogueWidget.NameText.Font.Size = 20
    newDialogueWidget.NameText:SetJustification(1)
    newDialogueWidget.NameText.ColorAndOpacity = {SpecifiedColor={A=1, R=1, G=1, B=1}, ColorUseRule=0}
    newDialogueWidget.NameText.ShadowColorAndOpacity = {A=1, R=0, G=0, B=0}
    header:AddChildToHorizontalBox(newDialogueWidget.NameText)

    if nameDecorationTexture:IsValid() then
        local image = DiUI.CreateImage(newDialogueWidget, nameDecorationTexture, {X=32, Y=32})
        image.Brush.ImageSize = {X=64,Y=32}
        image.RenderTransform.Angle = 180
        header:AddChildToHorizontalBox(image)
    end

    ReRandomizeButton = DiUI.CreateButton(newDialogueWidget, "Re-randomize")
    -- ReRandomizeButton:SetDesiredSizeInViewport({X=50,Y=50})
    newDialogueWidget.InternalVBox:AddChildToVerticalBox(ReRandomizeButton)

    return newDialogueWidget
end

DiUI.DestroyWidgetsByName("DialogueWidget")
DialogueMenu = DialogueWidget:New("DialogueWidget", {X = -1000, Y = -1000})
ReRandomizeButton = DialogueMenu.ReRandomizeButton
DialogueMenu:Show()
```




![image](https://github.com/user-attachments/assets/6b614f1f-43a2-4323-838b-87861f075459)

```lua
local DiUI = require("DiUI")

local printf = function(s,...) if not s:match("\n$") then s = "[HealthWidget] " .. s .. "\n" end return print(s:format(...)) end

function FindByName(class, name)
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

---@class HealthWidget : DiWindow
---@field Name string
---@field CurrentHealth float
---@field MaxHealth float
---@field CurrentMagicka float
---@field MaxMagicka float
---@field CurrentFatigue float
---@field MaxFatigue float
---@field Aggression float
---
---@field NPC AVPairedPawn
---@field Pos FVector2D
---
---@field Header UHorizontalBox
---@field NameText UTextBlock
---@field HostileIcon UImage
---@field HealthBar UProgressBar
---@field MagickaBar UProgressBar
---@field FatigueBar UProgressBar
---
local HealthWidget = {
    Name = "name123",
    CurrentHealth = 100,
    MaxHealth = 100,
    CurrentFatigue = 100,
    MaxFatigue = 100,
    CurrentMagicka = 100,
    MaxMagicka = 100,
    Aggression = 0,
}
setmetatable(HealthWidget, {__index = DiUI.DiWindow})

---@return HealthWidget
function HealthWidget:New(name, pos)
    printf("Creating new HealthWidget: %s, (X=%0.0f,Y=%0.0f)\n", name, pos.X, pos.Y)
    ---@type HealthWidget
    local newHealthWidget = DiUI.DiWindow:New(name, name, pos) ---@cast newHealthWidget HealthWidget
    setmetatable(newHealthWidget, {__index = HealthWidget})

    local vBox = newHealthWidget.InternalVBox

    local header = DiUI.CreateHorizontalBox(newHealthWidget)
    vBox:AddChildToVerticalBox(header)

    newHealthWidget.NameText = DiUI.CreateTextBlock(newHealthWidget, "NameText", "EnemyHealthWidget")
    newHealthWidget.NameText.Font.Size = 20
    newHealthWidget.NameText:SetJustification(1)
    newHealthWidget.NameText.ColorAndOpacity = {SpecifiedColor={A=1, R=1, G=1, B=1}, ColorUseRule=0}
    newHealthWidget.NameText.ShadowColorAndOpacity = {A=1, R=0, G=0, B=0}
    header:AddChildToHorizontalBox(newHealthWidget.NameText)

    newHealthWidget.HealthBar = DiUI.CreateProgressBar(newHealthWidget)
    newHealthWidget.HealthBar:SetFillColorAndOpacity({A=1,R=1,G=0.3,B=0.3})
    vBox:AddChildToVerticalBox(newHealthWidget.HealthBar)

    newHealthWidget.MagickaBar = DiUI.CreateProgressBar(newHealthWidget)
    newHealthWidget.MagickaBar:SetFillColorAndOpacity({A=1,R=0.3,G=0.3,B=1})
    vBox:AddChildToVerticalBox(newHealthWidget.MagickaBar)

    newHealthWidget.FatigueBar = DiUI.CreateProgressBar(newHealthWidget)
    newHealthWidget.FatigueBar:SetFillColorAndOpacity({A=1,R=0.3,G=1,B=0.3})
    vBox:AddChildToVerticalBox(newHealthWidget.FatigueBar)

    local gameplaySettingsTexture = FindByName("Texture2D", "/Game/Art/UI/Modern/MenuLayer/Settings/T_Settings_Gameplay.T_Settings_Gameplay") or CreateInvalidObject() ---@cast gameplaySettingsTexture UTexture2D
    if gameplaySettingsTexture:IsValid() then
        printf("GameplaySettingsTexture: %s", gameplaySettingsTexture:GetFullName())
        newHealthWidget.HostileIcon = DiUI.CreateImage(newHealthWidget, gameplaySettingsTexture, {X=32, Y=32})
        header:AddChildToHorizontalBox(newHealthWidget.HostileIcon)
    else
        printf("Couldn't find GameplaySettingsTexture")
    end
    return newHealthWidget
end

local newHealthWidget = HealthWidget:New("NPCHealthWidget", {X=100,Y=100})
newHealthWidget.NPC = pawn
newHealthWidget:UpdateWidget()
newHealthWidget:Show()
```
