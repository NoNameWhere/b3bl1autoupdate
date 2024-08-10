script_name = 'b3bl1'
script_author = 'b3bl1'
-- imports -- 
require("lib.moonloader")
require("lib.sampfuncs")
local dlstatus = require("moonloader").dlstatus
local imgui = require('mimgui')
local ffi = require('ffi')
local encoding = require('encoding')
encoding.default = 'CP1251'
local u8 = encoding.UTF8
local inicfg = require("inicfg")
local sampev = require('lib.samp.events')
local hotkey = require('mimgui_hotkeys')
local mem = require("memory")
--local mimgui_blur = require("mimgui_blur")
local sizeX, sizeY = getScreenResolution()
local inifilename = 'b3bl1.ini'
local jiasfjiasdfjidjfajs
local ver = 2
local ver_text = "1.3"

local update_url = "https://raw.githubusercontent.com/NoNameWhere/b3bl1autoupdate/master/update.ini"
local update_path = getWorkingDirectory() .. "/update.ini"

local script_url = "https://github.com/NoNameWhere/b3bl1autoupdate/raw/main/b3bl1.lua"
local script_path = thisScript().path
local ini = inicfg.load({
    settings = {
        cj = false,
        fastRun = false,
        infrun = false,
        fastcheck = false,
        wallhacking = false,
        antiBhop = false,
        checkbox = false,
        defoltSkin = '',

        commandmenu = 'b3bl1'
    }
}, inifilename)
local status = inicfg.load(ini, inifilename)
if not doesFileExist('moonloader/config/b3bl1.ini') then inicfg.save(ini, inifilename) end
inicfg.save(ini, inifilename);
-- locals --
local prefix = "{F09B10}b3bl1 {F3F3F2}script: "
local encoding = require 'encoding';
encoding.default = 'CP1251';
local u8 = encoding.UTF8;
local str = ffi.string
local new = imgui.new;
local fastRun = imgui.new.bool(ini.settings.fastRun)
local cj = imgui.new.bool(ini.settings.cj)
local infrun = imgui.new.bool(ini.settings.infrun)
local checkbox = imgui.new.bool(ini.settings.checkbox)
local wallHack = imgui.new.bool(ini.settings.wallhacking)

local commandmenu = new.char[256](u8(ini.settings.commandmenu))
local WinState = new.bool()
local antiBhop = imgui.new.bool(ini.settings.antiBhop)
local tp_dist = 175
local waiting = 2000
local active = imgui.new.bool(false);
local colorList = {u8'Серая (по умолчанию)',u8'Красная',u8'Зеленая', u8'Синяя'}
local colorListNumber = new.int()
local colorListBuffer = new['const char*'][#colorList](colorList)

local sliderBuf = new.int() -- буфер для тестового слайдера
 -- imgui init --
imgui.OnInitialize(function()
    apply_grey_style()
end)
 -- functions --

 function testupdate()
    sampShowDialog(1488, "test", "test", "test", "", 0)
 end

 function math.calculate(MinInt, MaxInt, MinFloat, MaxFloat, CurrentFloat)
    local res = CurrentFloat - MinFloat
    local res2 = MaxFloat - MinFloat
    local res3 = res / res2
    local res4 = res3 * (MaxInt - MinInt)
    return res4 + MinInt
end

 function samp_create_sync_data(sync_type, copy_from_player)
    local ffi = require 'ffi'
    local sampfuncs = require 'sampfuncs'
    local raknet = require 'samp.raknet'
 
    copy_from_player = copy_from_player or true
    local sync_traits = {
        player = {'PlayerSyncData', raknet.PACKET.PLAYER_SYNC, sampStorePlayerOnfootData},
        vehicle = {'VehicleSyncData', raknet.PACKET.VEHICLE_SYNC, sampStorePlayerIncarData},
        passenger = {'PassengerSyncData', raknet.PACKET.PASSENGER_SYNC, sampStorePlayerPassengerData},
        aim = {'AimSyncData', raknet.PACKET.AIM_SYNC, sampStorePlayerAimData},
        trailer = {'TrailerSyncData', raknet.PACKET.TRAILER_SYNC, sampStorePlayerTrailerData},
        unoccupied = {'UnoccupiedSyncData', raknet.PACKET.UNOCCUPIED_SYNC, nil},
        bullet = {'BulletSyncData', raknet.PACKET.BULLET_SYNC, nil},
        spectator = {'SpectatorSyncData', raknet.PACKET.SPECTATOR_SYNC, nil}
    }
    local sync_info = sync_traits[sync_type]
    local data_type = 'struct ' .. sync_info[1]
    local data = ffi.new(data_type, {})
    local raw_data_ptr = tonumber(ffi.cast('uintptr_t', ffi.new(data_type .. '*', data)))
    if copy_from_player then
        local copy_func = sync_info[3]
        if copy_func then
            local _, player_id
            if copy_from_player == true then
                _, player_id = sampGetPlayerIdByCharHandle(PLAYER_PED)
            else
                player_id = tonumber(copy_from_player)
            end
            copy_func(player_id, raw_data_ptr)
        end
    end
    local func_send = function()
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, sync_info[2])
        raknetBitStreamWriteBuffer(bs, raw_data_ptr, ffi.sizeof(data))
        raknetSendBitStreamEx(bs, sampfuncs.HIGH_PRIORITY, sampfuncs.UNRELIABLE_SEQUENCED, 1)
        raknetDeleteBitStream(bs)
    end
    local mt = {
        __index = function(t, index)
            return data[index]
        end,
        __newindex = function(t, index, value)
            data[index] = value
        end
    }
    return setmetatable({send = func_send}, mt)
 end

 function tpcr()
    lua_thread.create(function()

        local bool, bx,by,bz = true, 1143.1805,-1408.3446,13.5240
        if tp then
            sampAddChatMessage(prefix..'Ошибка. {DCDCDC}Уже телепортируемся.', -1)
            return
        end

        if bool then
            percent = 0
            packets = 0
            tp = true
            if incar then
                freezeCarPosition(storeCarCharIsInNoSave(PLAYER_PED), true)
            else
                freezeCharPosition(PLAYER_PED, true)
            end
            -- wait(3000)
            local x,y,z = getCharCoordinates(PLAYER_PED)
            local nx,ny,nz = x,y,z
            local dist = getDistanceBetweenCoords2d(x,y,bx,by)
            local angle = -math.rad(getHeadingFromVector2d(bx - x, by - y))
            local data = samp_create_sync_data(incar and "vehicle" or "player")
            if dist > tp_dist then
                for ds = dist-tp_dist, 0, -tp_dist do
                    data.moveSpeed = {0, 0, incar and -0.1 or -1}
                    for i = nz, -125, -25 do
                        data.position = {nx, ny, i}
                        data.send()
                    end
                    data.moveSpeed = {0, 0, 0}
                    -- data.send()
                    nx, ny, nz = nx + math.sin(angle) * tp_dist, ny + math.cos(angle) * tp_dist, -60
                    
                    -- data.moveSpeed = {math.sin(angle) * 2.85/2, math.cos(angle) * 2.85/2, 0.1}
                    data.position = {nx, ny, nz}
                    data.send()
                    cef_notif('info', 'b3bl1 script:', 'Взлетаем!', 15000)
                    sampAddChatMessage(prefix..'{DCDCDC}Wait{696969}!', -1)
                    percent = math.calculate(0,100,dist,0,ds)
                    setCharCoordinates(PLAYER_PED, nx,ny,nz)
                    packets = packets + 1
                    wait(waiting)
                end
            end
            data.moveSpeed = {0, 0, incar and -0.1 or -1}
            for i = nz, -125, -25 do
                data.position = {nx, ny, i}
                data.send()
            end
            data.position = {bx,by,bz}
            data.send()
            setCharCoordinates(PLAYER_PED, bx,by,bz)
            wait(1500)
            if incar then
                freezeCarPosition(storeCarCharIsInNoSave(PLAYER_PED), false)
            else
                freezeCharPosition(PLAYER_PED, false)
            end
            tp = false
            cef_notif('success', 'b3bl1 script:', 'Прилетели! Надеюсь, это было быстро.', 15000)
        end
    end)
end
 function sampev.onSendPlayerSync(data)
    if bit.band(data.keysData, 0x28) == 0x28 and antiBhop[0] then
		data.keysData = bit.bxor(data.keysData, 0x20)
	end
end
 function nameTagOn()
    local pStSet = sampGetServerSettingsPtr()
    NTdist = mem.getfloat(pStSet + 39)
    NTwalls = mem.getint8(pStSet + 47)
    NTshow = mem.getint8(pStSet + 56)
    mem.setfloat(pStSet + 39, 1488.0)
    mem.setint8(pStSet + 47, 0)
    mem.setint8(pStSet + 56, 1)
end
function nameTagOff()
    local pStSet = sampGetServerSettingsPtr()
    mem.setfloat(pStSet + 39, NTdist)
    mem.setint8(pStSet + 47, NTwalls)
    mem.setint8(pStSet + 56, NTshow)
end
 function isKeyCheckAvailable()
	if not isSampLoaded() then
		return true
	end
	if not isSampfuncsLoaded() then
		return not sampIsChatInputActive() and not sampIsDialogActive()
	end
	return not sampIsChatInputActive() and not sampIsDialogActive() and not isSampfuncsConsoleActive()
end
function cefnotif_show()
    cef_notif('error', 'b3bl1 script:', 'err0r!', 15000)
end

function sendCustomPacket(text)
    local bs = raknetNewBitStream()
    raknetBitStreamWriteInt8(bs, 220)
    raknetBitStreamWriteInt8(bs, 18)
    raknetBitStreamWriteInt32(bs, #text)
    raknetBitStreamWriteString(bs, text)
    raknetBitStreamWriteInt32(bs, 0)
    raknetSendBitStream(bs)
    raknetDeleteBitStream(bs)
end
function bitStreamToString(bs)
    local arr, t = {}, {}
    for i = 1, raknetBitStreamGetNumberOfBytesUsed(bs) do table.insert(arr, raknetBitStreamReadInt8(bs)) end
    for k, v in ipairs(arr) do
        if v >= 33 and v <= 255 then
            table.insert(t, string.char(v))
        end
    end
    return table.concat(t, ''), table.concat(arr, ', ')
end
function onReceivePacket(id, bs) 
    if id == 220 then
        local text, ids = bitStreamToString(bs)
        local countKeys = tonumber(text:match('"miniGameKeysCount":(%d+)'))
        if countKeys then
            lua_thread.create(function()
                for i = 1, countKeys do
                    wait(50)
                    sendCustomPacket('miniGame.DebugKeyID|74|74|true')
                end
                sendCustomPacket('miniGame.keyReaction.finish|' .. countKeys)
            end)
            return false
        end
    end
end

function cef_notif(type, title, text, time)
    if MONET_VERSION ~= nil then
        if type == 'info' then
            type = 3
        elseif type == 'error' then
            type = 2
        elseif type == 'success' then
            type = 1
        end
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, 62)
        raknetBitStreamWriteInt8(bs, 6)
        raknetBitStreamWriteBool(bs, true)
        raknetEmulPacketReceiveBitStream(220, bs)
        raknetDeleteBitStream(bs)
        local json = encodeJson({
            styleInt = type,
            title = title,
            text = text,
            duration = time
        })
        local interfaceid = 6
        local subid = 0
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, 84)
        raknetBitStreamWriteInt8(bs, interfaceid)
        raknetBitStreamWriteInt8(bs, subid)
        raknetBitStreamWriteInt32(bs, #json)
        raknetBitStreamWriteString(bs, json)
        raknetEmulPacketReceiveBitStream(220, bs)
        raknetDeleteBitStream(bs)
    else
        local str = ('window.executeEvent(\'event.notify.initialize\', \'["%s", "%s", "%s", "%s"]\');'):format(type, title, text, time)
        local bs = raknetNewBitStream()
        raknetBitStreamWriteInt8(bs, 17)
        raknetBitStreamWriteInt32(bs, 0)
        raknetBitStreamWriteInt32(bs, #str)
        raknetBitStreamWriteString(bs, str)
        raknetEmulPacketReceiveBitStream(220, bs)
        raknetDeleteBitStream(bs)
    end
end
function imgui.Hint(str_id, hint, delay)
    local hovered = imgui.IsItemHovered()
    local animTime = 0.2
    local delay = delay or 0.00
    local show = true

    if not allHints then allHints = {} end
    if not allHints[str_id] then
        allHints[str_id] = {
            status = false,
            timer = 0
        }
    end

    if hovered then
        for k, v in pairs(allHints) do
            if k ~= str_id and os.clock() - v.timer <= animTime  then
                show = false
            end
        end
    end

    if show and allHints[str_id].status ~= hovered then
        allHints[str_id].status = hovered
        allHints[str_id].timer = os.clock() + delay
    end

    if show then
        local between = os.clock() - allHints[str_id].timer
        if between <= animTime then
            local s = function(f)
                return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
            end
            local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
            imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)
            imgui.SetTooltip(hint)
            imgui.PopStyleVar()
        elseif hovered then
            imgui.SetTooltip(hint)
        end
    end
end

function imgui.CenterHeader(text, color)
    local width = imgui.GetWindowWidth()
    local calc = imgui.CalcTextSize(text)
    imgui.SetCursorPosX( width / 2 - calc.x / 2 )
    imgui.TextColored(color, text)
end

function set_player_skin(id, skin)
	local BS = raknetNewBitStream()
	raknetBitStreamWriteInt32(BS, id)
	raknetBitStreamWriteInt32(BS, skin)
	raknetEmulRpcReceiveBitStream(153, BS)
	raknetDeleteBitStream(BS)
end

function sampev.onSendSpawn()
    ini.settings.defoltSkin = getCharModel(PLAYER_PED)
    inicfg.save(ini, inifilename)
    if cj[0] and ini.settings.defoltSkin ~= 74 then set_player_skin(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), 74) end
end


imgui.OnFrame(function() return WinState[0] end, function(player)   
    local windowWidth = 580
    local buttonWidth, buttonHeight = 140, 41
    imgui.SetNextWindowPos(imgui.ImVec2(sizeX / 2, sizeY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
    imgui.Begin(u8"b3bl1 script", WinState, imgui.WindowFlags.AlwaysAutoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
    if imgui.BeginTabBar('Tabs') then
        if imgui.BeginTabItem(u8'Информация') then -- задаём название первой вкладки
            imgui.CenterHeader(u8"b3bl1 script ", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                    imgui.CenterHeader(u8"b3bl1 script оснащён разными рода функциями", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                    imgui.CenterHeader(u8"от легальных до запрещённых.", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                    imgui.CenterHeader(u8"Будьте осторожны при их использовании!", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                    imgui.CenterHeader(u8"В скрипте присутствует автосохранение настроек.", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                    imgui.CenterHeader(u8"d3bug: 1.2 (с3f l0ad3d)", imgui.ImVec4(1.00, 1.00, 1.00, 1.00))
                   
            -- конец содержимого вкладки
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem(u8'Функции') then -- задаём название второй вкладки
            -- далее идёт содержимое вкладки
               -- далее идёт содержимое вкладки
            if imgui.Combo(u8'Темы',colorListNumber,colorListBuffer, #colorList) then
                theme[colorListNumber[0]+1].change()
            end
            imgui.Hint('themesHint',u8'Внимание!\nНе все темы поддерживают данный тип вкладок, который в скрипте.')
            if imgui.Checkbox(u8"Бесконечный бег", infrun) then
                ini.settings.infrun = infrun[0]
                inicfg.save(ini, inifilename)
                end
            imgui.Hint('infrun', u8'Вы можете бегать без усталости, на любом скине! (полезно для шахтёров)')
            if infrun[0] then
                mem.setint8(0xB7CEE4, 1)
            end
            if imgui.Checkbox(u8"Wallhack", wallHack) then
                if wallHack[0] then
                    nameTagOn()
                else
                    nameTagOff()
                end
                ini.settings.wallhacking = wallHack[0]
                inicfg.save(ini, inifilename)
            end
            imgui.Hint('wallHack', u8"Функция показывает неймтеги людей сквозь стены.")
            if imgui.Checkbox(u8"Анти Bunnyhop", antiBhop) then
                ini.settings.antiBhop = antiBhop[0]
                inicfg.save(ini, inifilename)
            end
            imgui.Hint('antiBhop', u8"Функция позволяет bunnyhop'ить.")
            if imgui.Checkbox(u8"Быстрый бег", fastRun) then
                ini.settings.fastRun = fastRun[0]
                inicfg.save(ini, inifilename)
            end
            imgui.Hint('fastRun', u8"Функция будет автоматически быстро кликать клавишу пробела, чтобы персонаж бежал быстрее. (баг)\nАктивация: зажать клавишу [1] при беге.\nОна может быть запрещена на серверах!\nЭта функция имеет баг, всегда держите ее включенной, чтобы вы могли ее использовать!")
        
            if imgui.Checkbox(u8"Скин CJ'я", cj) then
                local skinNow = getCharModel(PLAYER_PED)
                if cj[0] and sampGetGamestate() == 3 and skinNow ~= 74 then 
                    set_player_skin(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), 74)
                else
                    set_player_skin(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED)), ini.settings.defoltSkin)
                end
                ini.settings.cj = cj[0]
                inicfg.save(ini, inifilename)
            end
            imgui.Hint('cj', u8"Функция включает скин CJ'я.")
            if imgui.Checkbox(u8"Флип", checkbox) then
                ini.settings.checkbox = checkbox[0]
                inicfg.save(ini, inifilename)
            end
            imgui.Hint('flip', u8"Обычный флип. Активация на DEL (не зажимайте, будет крутилка!)")
            -- конец содержимого вкладки
            imgui.EndTabItem()
        end
        if imgui.BeginTabItem(u8'Настройки') then
            if imgui.Checkbox(u8"test 172372173712378186732675367129875", checkbox) then
                ini.settings.checkbox = checkbox[0]
                inicfg.save(ini, inifilename)
            end
            if imgui.InputTextWithHint(u8"Команда активации скрипта (цифры не допускаются!)", u8'Введите команду', commandmenu, 256) then
                if u8:decode(str(commandmenu)) ~= '' and string.gsub(u8:decode(str(commandmenu)), "%A", '') ~= '' then
                    sampUnregisterChatCommand(ini.settings.commandmenu)
                    ini.settings.commandmenu = string.gsub(u8:decode(str(commandmenu)), "%A", '')
                    inicfg.save(ini, inifilename)
                    sampRegisterChatCommand(ini.settings.commandmenu, function() WinState[0] = not WinState[0] end)
                    commandmenu = new.char[16](u8(ini.settings.commandmenu))
                else
                    sampUnregisterChatCommand(ini.settings.commandmenu)
                    ini.settings.commandmenu = 'b3bl1'
                    inicfg.save(ini, 'minetools.ini')
                    sampRegisterChatCommand(ini.settings.commandmenu, function() WinState[0] = not WinState[0] end)
                    commandmenu = new.char[256]('b3bl1')
                end
            end
            imgui.EndTabItem()
        end
        imgui.EndTabBar()
        imgui.End()
    end
end)


function main()
    while not isSampAvailable() do wait (200) end
    sampRegisterChatCommand("testupdate", testupdate)
    sampAddChatMessage("", -1)
    sampAddChatMessage(prefix.."Скрипт {2EB62B}запущен!", -1)
    sampAddChatMessage(prefix.. "Активация скрипта: /" .. ini.settings.commandmenu, -1)
    sampAddChatMessage(prefix.."Удачи!", -1)
    sampAddChatMessage("", -1)
    cef_notif('success', 'b3bl1 script:', 'loaded! Activation: /b3bl1', 15000)
    hotkey.Text.NoKey = u8'Пусто'
    hotkey.Text.WaitForKey = u8'Ожидание клавиши...'
    sampRegisterChatCommand(ini.settings.commandmenu, function() WinState[0] = not WinState[0]end)
    sampRegisterChatCommand('cefnotif', cefnotif_show)
    sampRegisterChatCommand('tpcr', tpcr)
    wait(-1)
    if wallHack[0] then nameTagOn() end
    downloadUrlToFile(update_url, update_path, function(id, status)
        if status == dlstatus.STATUS_ENDDOWNLOADDATA then
            updateIni = inicfg.load(nil, update_path)
            if tonumber(updateIni.info.script_ver) > ver then
                sampAddChatMessage(prefix .. 'Обновление найдено! Обновляю..', -1)
                update_state = true
            end
            os.remove(update_path)
        end
    end)
end

theme = {
    {
        change = function()
            local style = imgui.GetStyle()
            local colors = style.Colors
            style.Alpha = 1;
            style.WindowPadding = imgui.ImVec2(15.00, 15.00);
            style.WindowRounding = 0;
            style.WindowBorderSize = 1;
            style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
            style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50);
            style.ChildRounding = 0;
            style.ChildBorderSize = 1;
            style.PopupRounding = 0;
            style.PopupBorderSize = 1;
            style.FramePadding = imgui.ImVec2(8.00, 7.00);
            style.FrameRounding = 10;
            style.FrameBorderSize = 0;
            style.ItemSpacing = imgui.ImVec2(8.00, 8.00);
            style.ItemInnerSpacing = imgui.ImVec2(10.00, 6.00);
            style.IndentSpacing = 25;
            style.ScrollbarSize = 13;
            style.ScrollbarRounding = 0;
            style.GrabMinSize = 6;
            style.GrabRounding = 0;
            style.TabRounding = 0;
            style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
            style.SelectableTextAlign = imgui.ImVec2(0.00, 0.00);
            colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
            colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.60, 0.56, 0.56, 1.00);
            colors[imgui.Col.WindowBg] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00);
            colors[imgui.Col.ChildBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
            colors[imgui.Col.PopupBg] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
            colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
            colors[imgui.Col.FrameBg] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00);
            colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.TitleBg] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
            colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51);
            colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
            colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.19, 0.19, 0.19, 1.00);
            colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
            colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
            colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
            colors[imgui.Col.CheckMark] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
            colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
            colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
            colors[imgui.Col.Button] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.32, 0.32, 0.32, 1.00);
            colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.Header] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.Separator] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.Tab] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.TabHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.TabActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
            colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
            colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
            colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
            colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.33, 0.33, 0.33, 0.50);
            colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
            colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00);
            colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
            colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
            colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
        end
    },
    {
        change = function()
            local ImVec4 = imgui.ImVec4
            imgui.SwitchContext()
            imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
            imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
            imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(1.00, 1.00, 1.00, 0.00)
            imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
            imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
            imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
            imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.48, 0.16, 0.16, 0.54)
            imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.98, 0.26, 0.26, 0.40)
            imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.98, 0.26, 0.26, 0.67)
            imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.48, 0.16, 0.16, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
            imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
            imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.88, 0.26, 0.24, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.98, 0.26, 0.26, 0.40)
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.98, 0.06, 0.06, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.98, 0.26, 0.26, 0.31)
            imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.98, 0.26, 0.26, 0.80)
            imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
            imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.75, 0.10, 0.10, 0.78)
            imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.75, 0.10, 0.10, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.98, 0.26, 0.26, 0.25)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.98, 0.26, 0.26, 0.67)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.98, 0.26, 0.26, 0.95)
            imgui.GetStyle().Colors[imgui.Col.Tab]                    = ImVec4(0.98, 0.26, 0.26, 0.40)
            imgui.GetStyle().Colors[imgui.Col.TabHovered]             = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TabActive]              = ImVec4(0.98, 0.06, 0.06, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TabUnfocused]           = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive]     = ImVec4(0.98, 0.26, 0.26, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.98, 0.26, 0.26, 0.35)
        end
    },
    {
        change = function()
            local ImVec4 = imgui.ImVec4
            imgui.SwitchContext()
            imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.60, 0.60, 0.60, 1.00)
            imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.10, 0.10, 0.10, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.70, 0.70, 0.70, 0.40)
            imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
            imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.15, 0.15, 0.15, 1.00)
            imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.19, 0.19, 0.19, 0.71)
            imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.34, 0.34, 0.34, 0.79)
            imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.00, 0.69, 0.33, 0.80)
            imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.00, 0.74, 0.36, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.00, 0.69, 0.33, 0.50)
            imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.00, 0.80, 0.38, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.16, 0.16, 0.16, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.00, 0.82, 0.39, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.00, 1.00, 0.48, 1.00)
            imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.00, 0.77, 0.37, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.00, 0.82, 0.39, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.00, 0.87, 0.42, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.00, 0.76, 0.37, 0.57)
            imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.00, 0.88, 0.42, 0.89)
            imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(1.00, 1.00, 1.00, 0.40)
            imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(1.00, 1.00, 1.00, 0.60)
            imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(1.00, 1.00, 1.00, 0.80)
            imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.00, 0.76, 0.37, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.00, 0.86, 0.41, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(0.00, 0.74, 0.36, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.00, 0.69, 0.33, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(0.00, 0.80, 0.38, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.00, 0.69, 0.33, 0.72)
        end
    },
    {
        change = function()
            local ImVec4 = imgui.ImVec4
            imgui.SwitchContext()
            imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.08, 0.08, 0.08, 1.00)
            imgui.GetStyle().Colors[imgui.Col.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
            imgui.GetStyle().Colors[imgui.Col.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
            imgui.GetStyle().Colors[imgui.Col.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
            imgui.GetStyle().Colors[imgui.Col.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
            imgui.GetStyle().Colors[imgui.Col.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
            imgui.GetStyle().Colors[imgui.Col.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
            imgui.GetStyle().Colors[imgui.Col.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
            imgui.GetStyle().Colors[imgui.Col.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
            imgui.GetStyle().Colors[imgui.Col.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
            imgui.GetStyle().Colors[imgui.Col.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
            imgui.GetStyle().Colors[imgui.Col.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
            imgui.GetStyle().Colors[imgui.Col.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
            imgui.GetStyle().Colors[imgui.Col.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
            imgui.GetStyle().Colors[imgui.Col.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
            imgui.GetStyle().Colors[imgui.Col.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
            imgui.GetStyle().Colors[imgui.Col.WindowBg]               = ImVec4(0.06, 0.53, 0.98, 0.70)
            imgui.GetStyle().Colors[imgui.Col.ChildBg]                = ImVec4(0.10, 0.10, 0.10, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PopupBg]                = ImVec4(0.06, 0.53, 0.98, 0.70)
            imgui.GetStyle().Colors[imgui.Col.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
            imgui.GetStyle().Colors[imgui.Col.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
            imgui.GetStyle().Colors[imgui.Col.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
            imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
            imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
        end
    },
    {
        change = function()
            local style = imgui.GetStyle()
            local colors = style.Colors
            style.Alpha = 1;
            style.WindowPadding = imgui.ImVec2(15.00, 15.00);
            style.WindowRounding = 0;
            style.WindowBorderSize = 1;
            style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
            style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50);
            style.ChildRounding = 0;
            style.ChildBorderSize = 1;
            style.PopupRounding = 0;
            style.PopupBorderSize = 1;
            style.FramePadding = imgui.ImVec2(8.00, 7.00);
            style.FrameRounding = 10;
            style.FrameBorderSize = 0;
            style.ItemSpacing = imgui.ImVec2(8.00, 8.00);
            style.ItemInnerSpacing = imgui.ImVec2(10.00, 6.00);
            style.IndentSpacing = 25;
            style.ScrollbarSize = 13;
            style.ScrollbarRounding = 0;
            style.GrabMinSize = 6;
            style.GrabRounding = 0;
            style.TabRounding = 0;
            style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
            style.SelectableTextAlign = imgui.ImVec2(0.00, 0.00);
            colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
            colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.60, 0.56, 0.56, 1.00);
            colors[imgui.Col.WindowBg] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00);
            colors[imgui.Col.ChildBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
            colors[imgui.Col.PopupBg] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
            colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
            colors[imgui.Col.FrameBg] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00);
            colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.TitleBg] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
            colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51);
            colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
            colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.19, 0.19, 0.19, 1.00);
            colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
            colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
            colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
            colors[imgui.Col.CheckMark] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
            colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
            colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
            colors[imgui.Col.Button] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.32, 0.32, 0.32, 1.00);
            colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.Header] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.Separator] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
            colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.Tab] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.TabHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
            colors[imgui.Col.TabActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
            colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
            colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
            colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
            colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
            colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
            colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.33, 0.33, 0.33, 0.50);
            colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
            colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00);
            colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
            colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
            colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
        end
    }
}

function apply_grey_style()

    local style = imgui.GetStyle()
    local colors = style.Colors
    style.Alpha = 1;
    style.WindowPadding = imgui.ImVec2(15.00, 15.00);
    style.WindowRounding = 0;
    style.WindowBorderSize = 1;
    style.WindowMinSize = imgui.ImVec2(32.00, 32.00);
    style.WindowTitleAlign = imgui.ImVec2(0.50, 0.50);
    style.ChildRounding = 0;
    style.ChildBorderSize = 1;
    style.PopupRounding = 0;
    style.PopupBorderSize = 1;
    style.FramePadding = imgui.ImVec2(8.00, 7.00);
    style.FrameRounding = 10;
    style.FrameBorderSize = 0;
    style.ItemSpacing = imgui.ImVec2(8.00, 8.00);
    style.ItemInnerSpacing = imgui.ImVec2(10.00, 6.00);
    style.IndentSpacing = 25;
    style.ScrollbarSize = 13;
    style.ScrollbarRounding = 0;
    style.GrabMinSize = 6;
    style.GrabRounding = 0;
    style.TabRounding = 0;
    style.ButtonTextAlign = imgui.ImVec2(0.50, 0.50);
    style.SelectableTextAlign = imgui.ImVec2(0.00, 0.00);
    colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.60, 0.56, 0.56, 1.00);
    colors[imgui.Col.WindowBg] = imgui.ImVec4(0.16, 0.16, 0.16, 1.00);
    colors[imgui.Col.ChildBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.PopupBg] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.Border] = imgui.ImVec4(0.43, 0.43, 0.50, 0.50);
    colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[imgui.Col.FrameBg] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00);
    colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.TitleBg] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
    colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.00, 0.00, 0.00, 0.51);
    colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.19, 0.19, 0.19, 1.00);
    colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.23, 0.23, 0.23, 1.00);
    colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00);
    colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.CheckMark] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
    colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.42, 0.43, 0.43, 1.00);
    colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[imgui.Col.Button] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.32, 0.32, 0.32, 1.00);
    colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.Header] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.Separator] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.22, 0.22, 0.22, 1.00);
    colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.Tab] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.TabHovered] = imgui.ImVec4(0.33, 0.32, 0.32, 1.00);
    colors[imgui.Col.TabActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.26, 0.26, 0.26, 1.00);
    colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.38, 0.38, 0.38, 1.00);
    colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00);
    colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00);
    colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00);
    colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.33, 0.33, 0.33, 0.50);
    colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90);
    colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00);
    colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70);
    colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20);
    colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.35);
end

lua_thread.create( function()
    while true do wait(100)
        if fastRun[0] then
            if isCharOnFoot(playerPed) and isKeyDown(0x31) and isKeyCheckAvailable() then
                setGameKeyState(16, 256)
                wait(10)
                setGameKeyState(16, 0)
            elseif isCharInWater(playerPed) and isKeyDown(0x31) and isKeyCheckAvailable() then
                setGameKeyState(16, 256)
                wait(10)
                setGameKeyState(16, 0)
            end
        end
        if wasKeyPressed(VK_F3) and not sampIsCursorActive() then -- Если нажата клавиша R и не активен самп курсор (во избежании активации при открытом чате/диалоге)
            WinState[0] = not WinState[0]
        end
    end
    end)

lua_thread.create(function ()
    while true do wait(0)
        if checkbox[0] then
            if isCharInAnyCar(PLAYER_PED) and not sampIsChatInputActive() and not sampIsDialogActive() and not sampIsCursorActive() then
                if isKeyDown(VK_DELETE) then
                    addToCarRotationVelocity(storeCarCharIsInNoSave(PLAYER_PED), 0.0, -0.15, 0.0)
                elseif isKeyDown(VK_END) then
                    addToCarRotationVelocity(storeCarCharIsInNoSave(PLAYER_PED), 0.0, 0.15, 0.0)
                end
            end
        end
    end
end)

lua_thread.create(function() 
    while true do wait (0)
        if update_state then
            downloadUrlToFile(script_url, script_path, function(id, status)
                if status == dlstatus.STATUS_ENDDOWNLOADDATA then
                    sampAddChatMessage( prefix .. 'Скрипт обновлен!', -1)
                end
            end)
            break
        end
    end
end)