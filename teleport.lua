--[[
    XClientMenuV2 - Teleports Module
    Разработчик: geragori11
    Функции: Быстрый телепорт к игрокам с определёнными ролями в MM2
--]]

return function(Window)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

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

    -- Функция безопасного телепорта к цели
    local function TeleportToRole(RoleName)
        local LocalChar = LocalPlayer.Character
        local LocalHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
        
        if not LocalHRP then 
            return Window:Notify({Title = "Ошибка", Content = "Твой персонаж не найден!", Duration = 3})
        end

        local TargetPlayer = nil
        
        -- Ищем первого попавшегося игрока с нужной ролью
        for _, P in ipairs(Players:GetPlayers()) do
            if P ~= LocalPlayer and GetPlayerRole(P) == RoleName then
                local Char = P.Character
                if Char and Char:FindFirstChild("HumanoidRootPart") then
                    TargetPlayer = P
                    break
                end
            end
        end

        -- Если нашли — телепортируемся чуть выше него, чтобы не застрять в текстурах
        if TargetPlayer then
            local TargetHRP = TargetPlayer.Character.HumanoidRootPart
            LocalHRP.CFrame = TargetHRP.CFrame * CFrame.new(0, 3, 0)
            
            Window:Notify({
                Title = "Телепорт",
                Content = "Успешно телепортирован к " .. TargetPlayer.Name .. " (" .. RoleName .. ")",
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Ошибка",
                Content = "Игрок с ролью '" .. RoleName .. "' не найден на карте!",
                Duration = 3
            })
        end
    end

    -- Создаем вкладку Teleports
    local TeleportTab = Window:CreateTab("Teleports", 4483362458)

    TeleportTab:CreateSection("Быстрый телепорт по ролям")

    TeleportTab:CreateButton({
        Name = "🔪 Телепорт к Убийце (Murderer)",
        Callback = function()
            TeleportToRole("Murderer")
        end
    })

    TeleportTab:CreateButton({
        Name = "🔫 Телепорт к Шерифу (Sheriff)",
        Callback = function()
            TeleportToRole("Sheriff")
        end
    })

    TeleportTab:CreateButton({
        Name = "🍃 Телепорт к Случайному Невинному (Innocent)",
        Callback = function()
            TeleportToRole("Innocent")
        end
    })
end