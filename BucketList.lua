local BucketList = {}
local BucketListFrame
local contextMenuIndex -- index the shared right-click menu currently acts on

-- Variable pour stocker la liste (sera sauvegardée par WoW)
BucketList.data = {}

-- Popup de confirmation avant suppression (evite les pertes accidentelles au clic droit)
StaticPopupDialogs["BUCKETLIST_CONFIRM_DELETE"] = {
    text = BucketListL.CONFIRM_DELETE_FMT,
    button1 = BucketListL.DELETE,
    button2 = BucketListL.CANCEL,
    OnAccept = function(self, data)
        BucketList:RemoveItem(data)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Fonction pour créer l'interface utilisateur
function BucketList:CreateUI()
    if BucketListFrame then return end

    BucketListFrame = CreateFrame("Frame", "BucketListFrame", UIParent, "BackdropTemplate")
    BucketListFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    BucketListFrame:SetSize(400, 500)
    if BucketList.position then
        local pos = BucketList.position
        BucketListFrame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        BucketListFrame:SetPoint("CENTER")
    end
    BucketListFrame:SetMovable(true)
    BucketListFrame:EnableMouse(true)
    BucketListFrame:SetUserPlaced(true)
    BucketListFrame:RegisterForDrag("LeftButton")
    BucketListFrame:SetScript("OnDragStart", BucketListFrame.StartMoving)
    BucketListFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        BucketList:SavePosition()
    end)
    BucketListFrame:Hide()

    -- Titre de la fenêtre
    BucketListFrame.TitleText = BucketListFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    BucketListFrame.TitleText:SetPoint("TOP", 0, -10)
    BucketListFrame.TitleText:SetText(BucketListL.TITLE)

    -- Bouton Fermer
    BucketListFrame.CloseButton = CreateFrame("Button", nil, BucketListFrame, "UIPanelCloseButton")
    BucketListFrame.CloseButton:SetPoint("TOPRIGHT", -5, -5)
    BucketListFrame.CloseButton:SetScript("OnClick", function() BucketListFrame:Hide() end)

    -- ScrollFrame pour la liste
    BucketListFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, BucketListFrame, "UIPanelScrollFrameTemplate")
    BucketListFrame.ScrollFrame:SetPoint("TOPLEFT", 10, -40)
    BucketListFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 80)
    BucketListFrame.ScrollFrame:SetVerticalScroll(0)

    -- Contenu scrollable
    BucketListFrame.ScrollChild = CreateFrame("Frame", nil, BucketListFrame.ScrollFrame)
    BucketListFrame.ScrollChild:SetWidth(360) -- Doit être ajusté si la fenêtre change
    BucketListFrame.ScrollChild:SetHeight(10) -- Hauteur initiale, sera ajustée

    BucketListFrame.ScrollFrame:SetScrollChild(BucketListFrame.ScrollChild)

    -- Champ de saisie pour ajouter un élément
    BucketListFrame.InputBox = CreateFrame("EditBox", nil, BucketListFrame, "InputBoxTemplate")
    BucketListFrame.InputBox:SetPoint("BOTTOMLEFT", 20, 50)
    BucketListFrame.InputBox:SetWidth(280)
    BucketListFrame.InputBox:SetHeight(20)
    BucketListFrame.InputBox:SetText(BucketListL.PLACEHOLDER)
    BucketListFrame.InputBox:SetTextColor(0.5, 0.5, 0.5)
    BucketListFrame.InputBox.isPlaceholder = true
    BucketListFrame.InputBox:SetScript("OnEditFocusGained", function(self)
        if self.isPlaceholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
            self.isPlaceholder = false
        end
    end)
    BucketListFrame.InputBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(BucketListL.PLACEHOLDER)
            self:SetTextColor(0.5, 0.5, 0.5)
            self.isPlaceholder = true
        end
    end)
    BucketListFrame.InputBox:SetScript("OnEnterPressed", function(self)
        if not self.isPlaceholder then
            BucketList:AddItem(self:GetText())
        end
        self:SetText("")
        self:ClearFocus()
    end)
    BucketListFrame.InputBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    -- Bouton Ajouter
    BucketListFrame.AddButton = CreateFrame("Button", nil, BucketListFrame, "UIPanelButtonTemplate")
    BucketListFrame.AddButton:SetPoint("BOTTOMRIGHT", -10, 50)
    BucketListFrame.AddButton:SetWidth(80)
    BucketListFrame.AddButton:SetHeight(22)
    BucketListFrame.AddButton:SetText(BucketListL.ADD_BUTTON)
    BucketListFrame.AddButton:SetScript("OnClick", function()
        if not BucketListFrame.InputBox.isPlaceholder then
            BucketList:AddItem(BucketListFrame.InputBox:GetText())
        end
        BucketListFrame.InputBox:SetText("")
        BucketListFrame.InputBox:ClearFocus()
    end)

    -- Menu contextuel du clic droit (creee une seule fois et reutilisee, plutot
    -- qu'une nouvelle frame anonyme a chaque clic : UIDropDownMenuTemplate a besoin
    -- d'un vrai nom pour que ses sous-widgets $parent... se resolvent correctement).
    BucketListFrame.ContextMenu = CreateFrame("Frame", "BucketListContextMenu", UIParent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(BucketListFrame.ContextMenu, function(self, level, menuList)
        UIDropDownMenu_AddButton({text = BucketListL.MOVE_UP, func = function() BucketList:MoveUp(contextMenuIndex) end})
        UIDropDownMenu_AddButton({text = BucketListL.MOVE_DOWN, func = function() BucketList:MoveDown(contextMenuIndex) end})
        UIDropDownMenu_AddButton({text = BucketListL.DELETE, func = function()
            local item = BucketList.data[contextMenuIndex]
            if item then
                StaticPopup_Show("BUCKETLIST_CONFIRM_DELETE", item.text, nil, contextMenuIndex)
            end
        end})
    end, "MENU")

    BucketList:UpdateListDisplay()
end

-- Fonction pour sauvegarder la position actuelle de la fenêtre (persistee via
-- BucketListPosition dans PLAYER_LOGOUT, voir OnEvent plus bas).
function BucketList:SavePosition()
    if not BucketListFrame then return end
    local point, _, relativePoint, x, y = BucketListFrame:GetPoint()
    self.position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

-- Fonction pour ajouter un élément
function BucketList:AddItem(text)
    if not text or strtrim(text) == "" then return end
    table.insert(self.data, {text = strtrim(text), completed = false, date = nil})
    self:UpdateListDisplay()
end

-- Fonction pour supprimer un élément
function BucketList:RemoveItem(index)
    if self.data[index] then
        table.remove(self.data, index)
        self:UpdateListDisplay()
    end
end

-- Fonction pour marquer/démarquer un élément
function BucketList:ToggleCompletion(index)
    if self.data[index] then
        self.data[index].completed = not self.data[index].completed
        if self.data[index].completed then
            self.data[index].date = date("%d/%m/%Y") -- Format DD/MM/YYYY
        else
            self.data[index].date = nil
        end
        self:UpdateListDisplay()
    end
end

-- Fonction pour monter un élément
function BucketList:MoveUp(index)
    if index > 1 and self.data[index] then
        local item = self.data[index]
        table.remove(self.data, index)
        table.insert(self.data, index - 1, item)
        self:UpdateListDisplay()
    end
end

-- Fonction pour descendre un élément
function BucketList:MoveDown(index)
    if index < #self.data and self.data[index] then
        local item = self.data[index]
        table.remove(self.data, index)
        table.insert(self.data, index + 1, item)
        self:UpdateListDisplay()
    end
end

-- Fonction pour actualiser l'affichage de la liste
function BucketList:UpdateListDisplay()
    local scrollChild = BucketListFrame.ScrollChild
    if not scrollChild then return end

    -- Nettoyer les éléments précédents
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        child:Hide()
        -- Potentiellement, réutiliser ces frames au lieu de les recréer
        -- Pour la simplicité ici, on les cache
    end

    local yOffset = 0
    local lineHeight = 20

    for i, item in ipairs(self.data) do
        local lineFrame = _G["BucketListItem" .. i]
        if not lineFrame then
            lineFrame = CreateFrame("Frame", "BucketListItem" .. i, scrollChild)
            lineFrame:SetPoint("TOPLEFT", 0, 0) -- Sera ajusté par yOffset
            lineFrame:SetSize(scrollChild:GetWidth(), lineHeight)
            lineFrame:SetScript("OnMouseUp", function(self, button)
                if button == "LeftButton" then
                    BucketList:ToggleCompletion(self.index)
                elseif button == "RightButton" then
                    -- Menu contextuel pour supprimer, monter, descendre (frame partagee,
                    -- voir BucketListFrame.ContextMenu cree dans CreateUI)
                    contextMenuIndex = lineFrame.index
                    ToggleDropDownMenu(1, 1, BucketListFrame.ContextMenu, "cursor", 0, 0)
                end
            end)

            lineFrame.StatusIcon = lineFrame:CreateTexture(nil, "OVERLAY")
            lineFrame.StatusIcon:SetSize(16, 16)
            lineFrame.StatusIcon:SetPoint("LEFT", 0, 0)

            lineFrame.Text = lineFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
            lineFrame.Text:SetPoint("LEFT", 20, 0)
            lineFrame.Text:SetPoint("RIGHT", 0, 0)
            lineFrame.Text:SetJustifyH("LEFT")
            lineFrame.Text:SetWordWrap(false)
            lineFrame.Text:SetMaxLines(1)
        end

        lineFrame.index = i
        lineFrame:SetPoint("TOPLEFT", 0, -yOffset)
        lineFrame:Show()

        if item.completed then
            lineFrame.StatusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready") -- Coche verte
            lineFrame.Text:SetTextColor(0, 1, 0) -- Vert
            lineFrame.Text:SetText(item.text .. (item.date and " (" .. item.date .. ")" or ""))
        else
            lineFrame.StatusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady") -- Croix rouge
            lineFrame.Text:SetTextColor(1, 0, 0) -- Rouge
            lineFrame.Text:SetText(item.text)
        end

        yOffset = yOffset + lineHeight
    end

    -- Ajuster la hauteur du ScrollChild pour permettre le défilement
    scrollChild:SetHeight(yOffset)
    scrollChild:SetWidth(BucketListFrame.ScrollFrame:GetWidth() - 20) -- ajuster pour la barre de défilement si nécessaire

    -- Forcer le rafraîchissement de la barre de défilement
    BucketListFrame.ScrollFrame:SetVerticalScroll(0)
    BucketListFrame.ScrollFrame:SetScript("OnUpdate", function(self)
        self:SetScript("OnUpdate", nil)
        self:UpdateScrollChildRect()
    end)
end

-- Fonction pour partager la liste
function BucketList:ShareList(channel, limit)
    local message = BucketListL.SHARE_HEADER
    local count = 0
    local maxItems = limit or #self.data

    for i, item in ipairs(self.data) do
        if count >= maxItems then break end
        local status = item.completed and "|cff00ff00[V]|r" or "|cffff0000[X]|r"
        local itemText = item.text .. (item.date and " (" .. item.date .. ")" or "")
        -- Tenter de lier les objets/quêtes si le texte est un nom d'objet/quête connu du client.
        -- Ceci est la partie la plus difficile sans une base de données interne.
        -- Une solution est d'utiliser GetItemLink("Nom de l'objet") ou GetQuestLink("ID de la quête").
        -- Mais GetItemLink nécessite d'avoir l'objet dans votre cache ou inventaire.
        -- Pour les quêtes, il faudrait connaître l'ID, ce qui n'est pas trivial.
        -- Pour une solution simple, on part du principe que l'utilisateur copiera/collera les liens complets s'il le souhaite.
        -- GetQuestLink attend un index de quete (nombre), pas un texte libre : l'appeler avec item.text provoquait une erreur Lua qui interrompait le partage.
        -- Il n'existe pas de moyen simple de retrouver un lien à partir d'un nom. Si l'utilisateur a collé un lien complet (shift-clic) dans le texte, il sera envoyé tel quel.
        message = message .. status .. " " .. itemText .. "\n"
        count = count + 1
    end

    -- "GROUP" n'est pas un type de canal valide pour SendChatMessage : il faut le
    -- resoudre en "RAID" ou "PARTY" selon le contexte (meme logique que VoteAnon).
    if channel == "GROUP" then
        if IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        end
    elseif channel == "RAID" then
        if IsInRaid() then
            SendChatMessage(message, "RAID")
        end
    elseif channel == "GUILD" then
        if IsInGuild() then
            SendChatMessage(message, "GUILD")
        end
    elseif channel == "SAY" then
        SendChatMessage(message, "SAY")
    elseif channel == "YELL" then
        SendChatMessage(message, "YELL")
    else -- Par defaut : canal "dire" local (SendChatMessage sans type retombe deja sur SAY)
        SendChatMessage(message, "SAY")
    end
end

-- Sauvegarde et chargement des données
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and select(1, ...) == "BucketList" then
        -- Charger les données si elles existent
        if BucketListData then
            BucketList.data = BucketListData
        end
        if BucketListPosition then
            BucketList.position = BucketListPosition
        end
        BucketList:CreateUI()
        BucketList:UpdateListDisplay()
    elseif event == "PLAYER_LOGOUT" then
        -- Sauvegarder les données à la déconnexion
        BucketListData = BucketList.data
        BucketListPosition = BucketList.position
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGOUT")
eventFrame:SetScript("OnEvent", OnEvent)

-- Commande de chat pour ouvrir la fenêtre
SLASH_BUCKETLIST1 = "/bucketlist"
SLASH_BUCKETLIST2 = "/bl"
function SlashCmdList.BUCKETLIST(msg)
    if BucketListFrame then
        if BucketListFrame:IsShown() then
            BucketListFrame:Hide()
        else
            BucketListFrame:Show()
            BucketListFrame:SetScale(UIParent:GetScale()) -- S'assurer que la fenêtre s'affiche correctement
            BucketList:UpdateListDisplay() -- Rafraîchir l'affichage
        end
    end

    -- Gestion des commandes de partage
    local _, _, command, arg1, arg2 = string.find(msg, "^(%S+)%s*(%S*)%s*(%S*)$")
    if command and string.lower(command) == "share" then
        local channel = string.upper(arg1 or "")
        local limit = tonumber(arg2)
        BucketList:ShareList(channel, limit)
    end
end

-- Lien des objets/quêtes: Pour que les liens fonctionnent quand ils sont ajoutés,
-- l'utilisateur doit coller le lien *complet* de l'objet/quête (Shift+Click dans le chat/inventaire).
-- Le code LUA ci-dessus ne peut pas générer un lien à partir d'un simple nom d'objet/quête sans un système
-- de base de données complexe ou une interaction directe avec le client pour l'objet/quête en question.
-- Par exemple, pour ajouter un objet, vous devez entrer: "|cff0070dd|Hitem:12345:0:0:0:0:0:0:0:0|h[Nom de l'Objet]|h|r"
-- et non pas juste "Nom de l'Objet".
