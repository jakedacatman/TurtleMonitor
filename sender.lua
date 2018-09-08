--2
--dance
 
local version = 2
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/sender.lua")
 
if latest ~= nil then
    local latestVersion = tonumber(string.sub(latest.readLine(), 3))
    if latestVersion > version then
        print("Out of date (version "..latestVersion.." is out).")
        print("Update notes: "..string.sub(latest.readLine(), 3))
        print("Do you wish to update? (y/n)")
        local timeout = os.startTimer(15)
        while true do
            local event = {os.pullEvent()}
            if event[1] == "char" then
                if event[2] == "y" then
                    fs.delete(shell.getRunningProgram())
                    shell.run("wget https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/sender.lua sender.lua")
                    print("Update complete!")
                    print("If you wish to run the new version, then hold CTRL+T and run sender.lua.")
                else
                    print("Not updating.")
                    break
                end
            elseif event[1] == "timer" and event[2] == timeout then
                print("Not updating.")
                break
            end
        end
    else
        print("Up to date! (or Github hasn't pushed my update)")
    end
else
    print("Failed to check for new version.")
end
 
print("Running version "..version)

local args = {...}
local uuid = args[1]
if not fs.exists("/smt.lua") then
    shell.run("wget https://gist.githubusercontent.com/xAnavrins/fbc58e7909ad93ece80ece7343ea62db/raw/e505d624b3bc01abdc0fce20fba2e9585f9a1c6a/smt.min.lua /smt.lua")
end
local smt = require("/smt")
local t = smt("smt.main.transit")
t.openChannel(12455)
local name = os.getComputerLabel()
local serverCID = false
local retryDelay = 30
 
local function split(s, p)
    local t = {}
    s:gsub("([^"..p.."]+)", function(v) t[#t + 1] = v end)
    return t
end
 
local function main()
    local timeout = os.startTimer(retryDelay)
    t.openTunnel(uuid, 12455)
    while true do
        local event, cid, data = os.pullEvent()
        if event == "RLWE-Finish" then
            print("Server online!")
            serverCID = cid
            local location = vector.new(gps.locate(2))
            location = location:tostring() or "unknown"
            t.sendData(serverCID, "label:"..name..":"..location..":"..tostring(turtle.getFuelLevel()))
        elseif event == "timer" and cid == timeout then
            if not serverCID then
                timeout = os.startTimer(retryDelay)
                t.openTunnel(uuid, 12455)
            elseif serverCID then
                timeout = os.startTimer(5)
                local location = vector.new(gps.locate(2))
                location = location:tostring() or "unknown"
                t.sendData(serverCID, "ping:"..name..":"..location..":"..tostring(turtle.getFuelLevel()))
                serverCID = false
            end
        elseif event == "RLWE-Receive" then
            local data = split(data, ":") -- Make new command below
            if data[1] == "pong" then -- Do not delete
                serverCID = cid
                os.cancelTimer(timeout)
                timeout = os.startTimer(retryDelay)
            elseif data[1] == "ping" then
                local location = vector.new(gps.locate(2))
                location = location:tostring() or "unknown"
                t.sendData(serverCID, "pong:"..name..":"..location..":"..tostring(turtle.getFuelLevel()))
            elseif data[1] == "dance" then
                shell.run("dance")
            end
        end
    end
end
 
term.clear()
term.setCursorPos(1, 1)
parallel.waitForAny(t.listener, main)
