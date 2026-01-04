-- Number of frames to capture during profiling
local framesToRecord = 300
-- Minimum millisecond delay required to trigger automatic profiling
local hitchThreshold = 300

local hasRecorded = false
RegisterConsoleListener(function(channel, message)
    if channel ~= 'citizen-server-impl' and channel ~= 'cmd' then return end
    if not hasRecorded and message:find('server thread hitch warning') then
        local hitchTime = message:match('server thread hitch warning: timer interval of (%d+) milliseconds')
        if not hitchTime then return end
        hitchTime = tonumber(hitchTime)
        if hitchTime < hitchThreshold then return end
        hasRecorded = true
        ExecuteCommand(('profiler record %s'):format(framesToRecord))
    elseif hasRecorded and message:find('Stopped the recording') then
        hasRecorded = false
        ExecuteCommand(('profiler save auto_profiler_%s.bin'):format(os.date('%m-%d-%Y_%I-%M-%S-%p')))
    end
end)