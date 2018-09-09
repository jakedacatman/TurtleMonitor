--3
--dance+autoupdating
 
local version = 3
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/sender.lua")
 
if latest ~= nil then
    local latestVersion = tonumber(string.sub(latest.readLine(), 3))
    if latestVersion > version then
        print("Out of date (version "..latestVersion.." is out).")
        print("Update notes: "..string.sub(latest.readLine(), 3))
        print("Updating.")
        fs.delete(shell.getRunningProgram())
        shell.run("wget https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/sender.lua sender.lua")
        print("Update complete!")
        os.reboot()
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
local retryDelay = 10
local hasConnected = false
 
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
	    hasConnected = true
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
		local up = turtle.up
		local down = turtle.down
		local forw = turtle.forward
		local function turnAround() turtle.turnLeft() turtle.turnLeft() end						
		for i = 1, 10 do
		    up()
		    down()
		    forw()
		    up()
		    down()
		    turnAround()
		    forw()
		    turnAround()
                end
            end
        end
    end
end

local function updateHome()
    while true do
	if hasConnected then
	    local location = vector.new(gps.locate(2))
            location = location:tostring() or "unknown"
            t.sendData(serverCID, "pong:"..name..":"..location..":"..tostring(turtle.getFuelLevel()))
	end
	sleep(30)
    end
end
 
term.clear()
term.setCursorPos(1, 1)
parallel.waitForAny(t.listener, main, updateHome)
