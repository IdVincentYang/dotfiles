local Class = require("c3class")

local _CLASS_NAME = "Window"
local _L = hs.logger.new(_CLASS_NAME, 5)

local Window = Class(_CLASS_NAME)

local _MAXIMIZED_FRAME_TOLERANCE = 32

local function _FrameRight(frame)
    return frame.x + frame.w
end

local function _FrameBottom(frame)
    return frame.y + frame.h
end

local function _NearEqual(a, b, tolerance)
    return math.abs(a - b) <= tolerance
end

local function _IsMaximizedOnCurrentScreen(wind)
    local frame = wind:frame()
    local screen = wind:screen()
    if not frame or not screen then
        return false
    end

    local screenFrame = screen:frame()
    local tolerance = _MAXIMIZED_FRAME_TOLERANCE
    return _NearEqual(frame.x, screenFrame.x, tolerance)
        and _NearEqual(frame.y, screenFrame.y, tolerance)
        and _NearEqual(_FrameRight(frame), _FrameRight(screenFrame), tolerance)
        and _NearEqual(_FrameBottom(frame), _FrameBottom(screenFrame), tolerance)
end

local function _ApplicationName(wind)
    local ok, app = pcall(function()
        return wind:application()
    end)
    if not ok or not app then
        return nil
    end

    ok, app = pcall(function()
        return app:name()
    end)
    if not ok then
        return nil
    end
    return app
end

local function _SaveWindowFrame(savedFrame, wind, windID)
    if not windID then
        return
    end
    savedFrame[windID] = {
        appName = _ApplicationName(wind),
        frame = hs.geometry.copy(wind:frame()),
    }
end

local function _GetSavedWindowFrame(savedFrame, wind, windID)
    if not windID then
        return nil
    end

    local saved = savedFrame[windID]
    if not saved then
        return nil
    end

    if saved.frame then
        local appName = _ApplicationName(wind)
        if saved.appName and appName and saved.appName ~= appName then
            savedFrame[windID] = nil
            return nil
        end
        return saved.frame
    end

    return saved
end

--[[在屏幕之间移动窗口, 改变窗口在屏幕中的位置和尺寸, 同时移动鼠标指针到窗口中心

--  wind<required>: 要移动的窗口
--  part<required>: 当前屏幕的 grid 划分
--  desc[optional]: 目的位置的 grid 描述
]]
Class.Static(Window, "MoveByGrid", function(wind, part, desc)
    hs.grid.setGrid(part)
    if desc then
        if wind:isMaximizable() then
            hs.grid.set(wind, desc)
            hs.mouse.setAbsolutePosition(wind:frame().center)
        else
            local from = wind:frame().center
            local cell = hs.grid.getCell(desc, wind:screen())
            if cell then
                local to = hs.geometry.copy(cell).center
                wind:move(hs.geometry.point(to.x - from.x, to.y - from.y))
                hs.mouse.setAbsolutePosition(to)
            end
        end
    else
        wind:focus()
        hs.grid.show(function()
            hs.mouse.setAbsolutePosition(wind:frame().center)
        end, false)
    end
    return wind
end)

Class.Static(Window, "_saved_window_frame", {})
--[[窗口在当前大小/位置和满屏/居中切换

--  当窗口可改变大小时, 在当前大小和满屏间切换
--  当窗口不可改变大小时, 在当前位置和剧中位置切换

--  wind<required>: 要切换的窗口
]]
Class.Static(Window, "ToggleMaxsizeOrCenterPosition", function(wind)
    local savedFrame = Window._saved_window_frame
    local windID = wind:id()
    local oldFrame = _GetSavedWindowFrame(savedFrame, wind, windID)
    if oldFrame and _IsMaximizedOnCurrentScreen(wind) then
        wind:setFrameInScreenBounds(oldFrame)
        if windID then
            savedFrame[windID] = nil
        end
    elseif _IsMaximizedOnCurrentScreen(wind) then
        return wind
    else
        _SaveWindowFrame(savedFrame, wind, windID)
        if wind:isMaximizable() then
            wind:setFrameInScreenBounds(wind:screen():frame())
        else
            wind:centerOnScreen(nil, true)
        end
    end
    hs.mouse.setAbsolutePosition(wind:frame().center)
    return wind
end)
return Window
