--[[
    XClientMenuV2 - Teleports Module (Updated)
    Разработчик: geragori11
    Функции: Быстрый телепорт по ролям + Телепорт к выбранному игроку из списка
--]]

return function(Window)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    -- Переменная для хранения выбранного из списка игрока
    local SelectedPlayerName = nil

    -- Функция для определения роли игрока (копия логики из основного скрипта)
    local function GetPlayerRole(Player)
        if not Player then return "Unknown" end
        local Character = Player.Character
        local Backpack = Player:FindFirstChild("Backpack")

        if (Character and Character:FindFirstChild("Knife")) or (Backpack and Backpack:FindFirstChild("Knife")) then
            return "Murderer"
        elseif (Character and Character:FindFirstChild("Gun")) or (Backpack and Backpack:FindFirstChild("Gun")) then
            return "Sheriff"
        else
            return "Innocent"
        end
    end

    -- Функция безопасного телепорта к конкретному Character игрока
    local function TeleportToCharacter(TargetChar, TargetName)
        local LocalChar = LocalPlayer.Character
        local LocalHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
        
        if not LocalHRP then 
            return Window:Notify({Title = "Ошибка", Content = "Твой персонаж не найден!", Duration = 3})
        end

        local TargetHRP = TargetChar and TargetChar:FindFirstChild("HumanoidRootPart")
        if TargetHRP then
            LocalHRP.CFrame = TargetHRP.CFrame * CFrame.new(0, 3, 0) -- Телепорт чуть выше цели
            Window:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к " .. TargetName,
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Ошибка",
                Content = "Персонаж цели не прогружен или мёртв!",
                Duration = 3
            })
        end
    end

    -- Функция телепорта по роли
    local function TeleportToRole(RoleName)
        local TargetPlayer = nil
        for _, P in ipairs(Players:GetPlayers()) do
            if P ~= LocalPlayer and GetPlayerRole(P) == RoleName then
                if P.Character and P.Character:FindFirstChild("HumanoidRootPart") then
                    TargetPlayer = P
                    break
                end
            end
        end

        if TargetPlayer then
            TeleportToCharacter(TargetPlayer.Character, TargetPlayer.Name .. " (" .. RoleName .. ")")
        else
            Window:Notify({
                Title = "Ошибка",
                Content = "Игрок с ролью '" .. RoleName .. "' не найден!",
                Duration = 3
            })
        end
    end

    -- Создаем вкладку Teleports
    local TeleportTab = Window:CreateTab("Teleports", 4483362458)

    -- СЕКЦИЯ 1: Телепорт по ролям
    TeleportTab:CreateSection("Быстрый телепорт по ролям")

    TeleportTab:CreateButton({
        Name = "🔪 Телепорт к Убийце (Murderer)",
        Callback = function() TeleportToRole("Murderer") end
    })

    TeleportTab:CreateButton({
        Name = "🔫 Телепорт к Шерифу (Sheriff)",
        Callback = function() TeleportToRole("Sheriff") end
    })

    TeleportTab:CreateButton({
        Name = "🍃 Телепорт к Случайному Невинному (Innocent)",
        Callback = function() TeleportToRole("Innocent") end
    })

    -- СЕКЦИЯ 2: Выбор игрока из списка
    TeleportTab:CreateSection("Выбор игрока вручную")

    local PlayerDropdown = TeleportTab:CreateDropdown({
        Name = "Выбрать игрока для ТП",
        Options = {},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "TeleportPlayerDropdown",
        Callback = function(Options)
            -- Так как MultipleOptions = false, имя выбранного игрока будет в первом элементе таблицы
            local SelectedString = Options[1] or ""
            -- Очищаем имя от префикса роли, если он есть (например, из "[Innocent] geragori11" вырежет "geragori11")
            SelectedPlayerName = string.match(SelectedString, "%] (.*)$") or SelectedString
        end
    })

    TeleportTab:CreateButton({
        Name = "🎯 ТЕЛЕПОРТИРОВАТЬСЯ К ВЫБРАННОМУ",
        Callback = function()
            if not SelectedPlayerName or SelectedPlayerName == "" then
                return Window:Notify({Title = "Ошибка", Content = "Сначала выбери игрока из списка!", Duration = 3})
            end

            local TargetPlayer = Players:FindFirstChild(SelectedPlayerName)
            if TargetPlayer and TargetPlayer.Character then
                TeleportToCharacter(TargetPlayer.Character, TargetPlayer.Name)
            else
                Window:Notify({Title = "Ошибка", Content = "Игрок вышел из игры или его персонаж отсутствует!", Duration = 3})
            end
        end
    })

    -- Автоматическое обновление списка игроков во враппере (каждые 1.5 сек)
    local LastCheckStr = ""
    task.spawn(function()
        while task.wait(1.5) do
            local PlayerOptions = {}
            local BuildCheckStr = ""

            for _, P in ipairs(Players:GetPlayers()) do
                if P ~= LocalPlayer then
                    local Role = GetPlayerRole(P)
                    local DisplayString = "[" .. Role .. "] " .. P.Name
                    table.insert(PlayerOptions, DisplayString)
                    BuildCheckStr = BuildCheckStr .. DisplayString
                end
            end

            -- Обновляем Dropdown только если состав сервера поменялся
            if BuildCheckStr ~= LastCheckStr then
                LastCheckStr = BuildCheckStr
                if PlayerDropdown then 
                    PlayerDropdown:Refresh(PlayerOptions, true) 
                end
            end
        end
    end)
end
