--- === SalaryCounter ===
---
--- Display real-time salary earnings counter in the menu bar.
--- Shows "$" when idle. Click to show a running YTD counter.
--- Second/minute/hour/day only count during working hours (Mon-Fri, configurable).
--- Month and year are based on total salary spread across the calendar.

local obj = {}
obj.__index = obj
obj.name = "SalaryCounter"
obj.version = "1.1.0"
obj.author = "Anton Kropp"
obj.license = "MIT"

--- SalaryCounter.yearlySalary
--- Variable
--- Gross yearly salary in dollars. Default: 282000
obj.yearlySalary = 282000

--- SalaryCounter.taxRate
--- Variable
--- Tax rate as a decimal (0.30 = 30%). Default: 0.30
obj.taxRate = 0.30

--- SalaryCounter.workStartHour
--- Variable
--- Start of working day in local time (24h). Default: 9
obj.workStartHour = 9

--- SalaryCounter.workEndHour
--- Variable
--- End of working day in local time (24h). Default: 17
obj.workEndHour = 17

function obj:init()
    self.menuBarItem = nil
    self.active = false
    self.fuckOffStart = nil
    self.fuckOffLast = nil
    self._cachedWorkingDays = nil
    self._cachedYear = nil
    self.timer = hs.timer.new(1, function() self:tick() end)
    return self
end

function obj:start()
    if self.menuBarItem then self:stop() end
    self.active = false
    self.menuBarItem = hs.menubar.new()
    self.menuBarItem:setTitle("$")
    self.menuBarItem:setMenu(function() return self:buildMenu() end)
    return self
end

function obj:stop()
    self.timer:stop()
    if self.menuBarItem then
        self.menuBarItem:delete()
        self.menuBarItem = nil
    end
    return self
end

function obj:tick()
    if not self.menuBarItem then return end
    if self.active then
        local yearEarned = self:secondsSinceStartOfYear() * self:calendarPerSecond()
        self.menuBarItem:setTitle(self:formatMoney(yearEarned))
    end
end

------------------------------------------------------------------------
-- Rates
------------------------------------------------------------------------

function obj:netAnnual()
    return self.yearlySalary * (1 - self.taxRate)
end

function obj:calendarPerSecond()
    local year = os.date("*t").year
    local isLeap = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
    local daysInYear = isLeap and 366 or 365
    return self:netAnnual() / (daysInYear * 86400)
end

function obj:workingPerSecond()
    return self:netAnnual() / self:workingSecondsInYear()
end

------------------------------------------------------------------------
-- Working time helpers
------------------------------------------------------------------------

function obj:workingDaysInYear()
    local year = os.date("*t").year
    if self._cachedWorkingDays and self._cachedYear == year then
        return self._cachedWorkingDays
    end
    local count = 0
    local isLeap = (year % 4 == 0 and year % 100 ~= 0) or (year % 400 == 0)
    local totalDays = isLeap and 366 or 365
    local t = os.time({year = year, month = 1, day = 1, hour = 12})
    for _ = 1, totalDays do
        local wday = os.date("*t", t).wday
        if wday >= 2 and wday <= 6 then count = count + 1 end
        t = t + 86400
    end
    self._cachedWorkingDays = count
    self._cachedYear = year
    return count
end

function obj:workingSecondsInYear()
    return self:workingDaysInYear() * (self.workEndHour - self.workStartHour) * 3600
end

function obj:isWorkingTime()
    local t = os.date("*t")
    if t.wday < 2 or t.wday > 6 then return false end
    local sec = t.hour * 3600 + t.min * 60 + t.sec
    return sec >= self.workStartHour * 3600 and sec < self.workEndHour * 3600
end

function obj:workingSecondsToday()
    local t = os.date("*t")
    if t.wday < 2 or t.wday > 6 then return 0 end
    local sec = t.hour * 3600 + t.min * 60 + t.sec
    local workStart = self.workStartHour * 3600
    local workEnd = self.workEndHour * 3600
    if sec <= workStart then return 0 end
    if sec >= workEnd then return workEnd - workStart end
    return sec - workStart
end

function obj:workingSecondsThisHour()
    if not self:isWorkingTime() then return 0 end
    local t = os.date("*t")
    return t.min * 60 + t.sec
end

function obj:workingSecondsThisMinute()
    if not self:isWorkingTime() then return 0 end
    return os.date("*t").sec
end

function obj:workingSecondsBetween(startTime, endTime)
    if startTime >= endTime then return 0 end
    local total = 0
    local current = startTime
    while current < endTime do
        local t = os.date("*t", current)
        if t.wday >= 2 and t.wday <= 6 then
            local dayStart = os.time({year=t.year, month=t.month, day=t.day,
                hour=self.workStartHour, min=0, sec=0})
            local dayEnd = os.time({year=t.year, month=t.month, day=t.day,
                hour=self.workEndHour, min=0, sec=0})
            local effectiveStart = math.max(current, dayStart)
            local effectiveEnd = math.min(endTime, dayEnd)
            if effectiveStart < effectiveEnd then
                total = total + (effectiveEnd - effectiveStart)
            end
        end
        current = os.time({year=t.year, month=t.month, day=t.day+1, hour=0, min=0, sec=0})
    end
    return total
end

------------------------------------------------------------------------
-- Calendar helpers (for month/year)
------------------------------------------------------------------------

function obj:secondsSinceStartOfYear()
    local now = os.time()
    local t = os.date("*t", now)
    return now - os.time({year = t.year, month = 1, day = 1, hour = 0, min = 0, sec = 0})
end

function obj:secondsSinceStartOfMonth()
    local now = os.time()
    local t = os.date("*t", now)
    return now - os.time({year = t.year, month = t.month, day = 1, hour = 0, min = 0, sec = 0})
end

------------------------------------------------------------------------
-- Menu
------------------------------------------------------------------------

function obj:buildMenu()
    if not self.active then
        -- Activate: start the counter
        self.active = true
        self.timer:start()
        self:tick()
        return {
            { title = "Counter started", disabled = true },
        }
    end

    local working = self:isWorkingTime()
    local wRate = self:workingPerSecond()
    local cRate = self:calendarPerSecond()

    local secondEarned = working and wRate or 0
    local minuteEarned = self:workingSecondsThisMinute() * wRate
    local hourEarned   = self:workingSecondsThisHour()   * wRate
    local dayEarned    = self:workingSecondsToday()       * wRate
    local monthEarned  = self:secondsSinceStartOfMonth()  * cRate
    local yearEarned   = self:secondsSinceStartOfYear()   * cRate

    local status = working and "On the clock" or "Off the clock"

    local menu = {
        { title = "Earnings Breakdown (" .. status .. ")", disabled = true },
        { title = "-" },
        { title = "Second:  " .. self:formatMoney(secondEarned), disabled = true },
        { title = "Minute:  " .. self:formatMoney(minuteEarned), disabled = true },
        { title = "Hour:    " .. self:formatMoney(hourEarned),   disabled = true },
        { title = "Day:     " .. self:formatMoney(dayEarned),    disabled = true },
        { title = "Month:   " .. self:formatMoney(monthEarned),  disabled = true },
        { title = "Year:    " .. self:formatMoney(yearEarned),   disabled = true },
        { title = "-" },
    }

    -- Fuck Off Timer
    if self.fuckOffStart then
        local workingSecs = self:workingSecondsBetween(self.fuckOffStart, os.time())
        local earned = workingSecs * wRate
        local wallElapsed = os.time() - self.fuckOffStart
        table.insert(menu, { title = string.format("Fuck Off Timer: %s (%s worked)",
            self:formatMoney(earned), self:formatElapsed(workingSecs)), disabled = true })
        if wallElapsed ~= workingSecs then
            table.insert(menu, { title = string.format("  wall time: %s",
                self:formatElapsed(wallElapsed)), disabled = true })
        end
        table.insert(menu, { title = "Stop Fuck Off Timer", fn = function()
            local finalSecs = self:workingSecondsBetween(self.fuckOffStart, os.time())
            self.fuckOffLast = { elapsed = finalSecs, earned = finalSecs * self:workingPerSecond() }
            self.fuckOffStart = nil
        end })
    else
        if self.fuckOffLast then
            table.insert(menu, { title = string.format("Last Fuck Off: %s (%s)",
                self:formatMoney(self.fuckOffLast.earned),
                self:formatElapsed(self.fuckOffLast.elapsed)), disabled = true })
        end
        table.insert(menu, { title = "Start Fuck Off Timer", fn = function()
            self.fuckOffStart = os.time()
        end })
    end

    table.insert(menu, { title = "-" })
    table.insert(menu, { title = string.format("Gross: $%s/yr | Tax: %d%%",
        self:formatWithCommas(self.yearlySalary), self.taxRate * 100), disabled = true })
    table.insert(menu, { title = string.format("Net:   $%s/yr",
        self:formatWithCommas(self:netAnnual())), disabled = true })
    table.insert(menu, { title = string.format("Hours: %d:00-%d:00 Mon-Fri",
        self.workStartHour, self.workEndHour), disabled = true })
    table.insert(menu, { title = "-" })
    table.insert(menu, { title = "Hide Counter", fn = function()
        self.active = false
        self.timer:stop()
        self.menuBarItem:setTitle("$")
    end })

    return menu
end

------------------------------------------------------------------------
-- Formatting
------------------------------------------------------------------------

function obj:formatElapsed(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    if h > 0 then
        return string.format("%dh %dm %ds", h, m, s)
    elseif m > 0 then
        return string.format("%dm %ds", m, s)
    else
        return string.format("%ds", s)
    end
end

function obj:formatMoney(amount)
    if amount == 0 then
        return "$0.00"
    elseif amount < 0.01 then
        return string.format("$%.6f", amount)
    elseif amount < 1 then
        return string.format("$%.4f", amount)
    else
        return "$" .. self:formatWithCommas(amount, true)
    end
end

function obj:formatWithCommas(n, withCents)
    local intPart = math.floor(n)
    local formatted = tostring(intPart)
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    if withCents then
        return formatted .. string.format(".%02d", math.floor((n - intPart) * 100 + 0.5))
    end
    return formatted
end

return obj
