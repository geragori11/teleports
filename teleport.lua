--[[
    XClientMenuV2 - Teleports Module (Updated)
    Разработчик: geragori11
    Функции: Быстрый телепорт по ролям + Выбор игрока + Телепорт на карту (без спавнов 1-10) + Телепорт в лобби (спавны 1-10)
--]]

return function(Window)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local LocalPlayer = Players.LocalPlayer

    -- Переменная для хранения выбранного из списка игрока
    local SelectedPlayerName = nil

    -- Функция для определения роли игрока
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

    -- Функция сбора спавнов карты (исключая лобби и спавны 1-10)
    local function GetMapSpawns()
        local validSpawns = {}
        local globalCounter = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Обработка стандартных SpawnLocation (в MM2 это обычно спавны лобби)
            if obj:IsA("SpawnLocation") then
                globalCounter = globalCounter + 1
            elseif (obj.Name == "Spawns" or obj.Name == "SpawnPoints" or obj.Name == "PlayerSpawns") and (obj:IsA("Folder") or obj:IsA("Model")) then
                for _, spawnPart in ipairs(obj:GetChildren()) do
                    if spawnPart:IsA("BasePart") then
                        globalCounter = globalCounter + 1

                        -- 1. Проверка: находится ли объект внутри папки/модели Lobby
                        local isInLobby = false
                        local current = spawnPart
                        while current and current ~= Workspace do
                            if string.find(string.lower(current.Name), "lobby") then
                                isInLobby = true
                                break
                            end
                            current = current.Parent
                        end

                        -- 2. Проверка по названию объекта (например, Spawn1, Spawn 5, 8 и т.д.)
                        local nameLower = string.lower(spawnPart.Name)
                        local numInName = tonumber(string.match(nameLower, "spawn[%s_%-]*([0-9]+)")) or tonumber(string.match(nameLower, "^([0-9]+)$"))
                        local isExcludedByName = numInName and (numInName >= 1 and numInName <= 10)

                        -- 3. Проверка по глобальному счетчику ESP (точки 1-10)
                        local isExcludedByIndex = (globalCounter >= 1 and globalCounter <= 10)

                        if not isInLobby and not isExcludedByName and not isExcludedByIndex then
                            table.insert(validSpawns, spawnPart)
                        end
                    end
                end
            end
        end

        -- Запасной поиск: если отсеяло всё, ищем любые части в Spawns активной карты вне Lobby
        if #validSpawns == 0 then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                if (obj.Name == "Spawns" or obj.Name == "SpawnPoints") and (obj:IsA("Folder") or obj:IsA("Model")) then
                    local parent = obj
                    local isInLobby = false
                    while parent and parent ~= Workspace do
                        if string.find(string.lower(parent.Name), "lobby") then
                            isInLobby = true
                            break
                        end
                        parent = parent.Parent
                    end

                    if not isInLobby then
                        for _, p in ipairs(obj:GetChildren()) do
                            if p:IsA("BasePart") then
                                table.insert(validSpawns, p)
                            end
                        end
                    end
                end
            end
        end

        return validSpawns
    end

    -- Функция сбора спавнов лобби (точки 1-10, объекты в модели Lobby и стандартные SpawnLocation)
    local function GetLobbySpawns()
        local lobbySpawns = {}
        local globalCounter = 0

        for _, obj in ipairs(Workspace:GetDescendants()) do
            -- Стандартные SpawnLocation (в MM2 это спавны площадки лобби)
            if obj:IsA("SpawnLocation") then
                globalCounter = globalCounter + 1
                table.insert(lobbySpawns, obj)
            elseif (obj.Name == "Spawns" or obj.Name == "SpawnPoints" or obj.Name == "PlayerSpawns") and (obj:IsA("Folder") or obj:IsA("Model")) then
                for _, spawnPart in ipairs(obj:GetChildren()) do
                    if spawnPart:IsA("BasePart") then
                        globalCounter = globalCounter + 1

                        -- 1. Проверка на нахождение внутри папки/модели Lobby
                        local isInLobby = false
                        local current = spawnPart
                        while current and current ~= Workspace do
                            if string.find(string.lower(current.Name), "lobby") then
                                isInLobby = true
                                break
                            end
                            current = current.Parent
                        end

                        -- 2. Проверка по названию объекта (Spawn 1-10)
                        local nameLower = string.lower(spawnPart.Name)
                        local numInName = tonumber(string.match(nameLower, "spawn[%s_%-]*([0-9]+)")) or tonumber(string.match(nameLower, "^([0-9]+)$"))
                        local isLobbyByName = numInName and (numInName >= 1 and numInName <= 10)

                        -- 3. Проверка по сквозному глобальному индексу (точки 1-10)
                        local isLobbyByIndex = (globalCounter >= 1 and globalCounter <= 10)

                        if isInLobby or isLobbyByName or isLobbyByIndex then
                            table.insert(lobbySpawns, spawnPart)
                        end
                    end
                end
            end
        end

        -- Запасной поиск: явный поиск спавнов внутри контейнера Lobby
        if #lobbySpawns == 0 then
            local lobbyModel = Workspace:FindFirstChild("Lobby")
            if lobbyModel then
                for _, desc in ipairs(lobbyModel:GetDescendants()) do
                    if desc:IsA("SpawnLocation") or (desc:IsA("BasePart") and string.find(string.lower(desc.Name), "spawn")) then
                        table.insert(lobbySpawns, desc)
                    end
                end
            end
        end

        return lobbySpawns
    end

    -- Функция телепорта на случайный спавн карты
    local function TeleportToMapSpawn()
        local LocalChar = LocalPlayer.Character
        local LocalHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
        
        if not LocalHRP then 
            return Window:Notify({Title = "Ошибка", Content = "Твой персонаж не найден!", Duration = 3})
        end

        local mapSpawns = GetMapSpawns()

        if #mapSpawns > 0 then
            local randomSpawn = mapSpawns[math.random(1, #mapSpawns)]
            LocalHRP.CFrame = randomSpawn.CFrame * CFrame.new(0, 3, 0)
            
            Window:Notify({
                Title = "Телепорт на карту",
                Content = "Успешно телепортирован на случайный спавн карты!",
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Ошибка",
                Content = "Спавны карты не найдены! Возможно, раунд ещё не начался.",
                Duration = 3
            })
        end
    end

    -- Функция телепорта на случайный спавн лобби
    local function TeleportToLobby()
        local LocalChar = LocalPlayer.Character
        local LocalHRP = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
        
        if not LocalHRP then 
            return Window:Notify({Title = "Ошибка", Content = "Твой персонаж не найден!", Duration = 3})
        end

        local lobbySpawns = GetLobbySpawns()

        if #lobbySpawns > 0 then
            local randomSpawn = lobbySpawns[math.random(1, #lobbySpawns)]
            LocalHRP.CFrame = randomSpawn.CFrame * CFrame.new(0, 3, 0)
            
            Window:Notify({
                Title = "Телепорт в лобби",
                Content = "Успешно телепортирован на спавн лобби!",
                Duration = 3
            })
        else
            Window:Notify({
                Title = "Ошибка",
                Content = "Точки спавна лобби не найдены!",
                Duration = 3
            })
        end
    end

    -- Создаем вкладку Teleports
    local TeleportTab = Window:CreateTab("Teleports", 4483362458)

    -- СЕКЦИЯ 1: Телепорт на локацию
    TeleportTab:CreateSection("Телепорт на локацию")

    TeleportTab:CreateButton({
        Name = "🗺️ Телепорт на карту (Случайный спавн)",
        Callback = function() 
            TeleportToMapSpawn() 
        end
    })

    TeleportTab:CreateButton({
        Name = "🏠 Телепорт в Лобби (Спавны 1-10)",
        Callback = function() 
            TeleportToLobby() 
        end
    })

    -- СЕКЦИЯ 2: Телепорт по ролям
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

    -- СЕКЦИЯ 3: Выбор игрока из списка
    TeleportTab:CreateSection("Выбор игрока вручную")

    local PlayerDropdown = TeleportTab:CreateDropdown({
        Name = "Выбрать игрока для ТП",
        Options = {},
        CurrentOption = {},
        MultipleOptions = false,
        Flag = "TeleportPlayerDropdown",
        Callback = function(Options)
            local SelectedString = Options[1] or ""
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

            if BuildCheckStr ~= LastCheckStr then
                LastCheckStr = BuildCheckStr
                if PlayerDropdown then 
                    PlayerDropdown:Refresh(PlayerOptions, true) 
                end
            end
        end
    end)
end
