--5
--added optional "all" to ping instead of a name
 
local version = 5
 
local latest = http.get("https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/server.lua")
 
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
                    shell.run("wget https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/server.lua server.lua")
                    print("Update complete!")
                    print("If you wish to run the new version, then hold CTRL+T and run server.lua.")
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

if not fs.exists("/smt.lua") then
    shell.run("wget https://gist.githubusercontent.com/xAnavrins/fbc58e7909ad93ece80ece7343ea62db/raw/e505d624b3bc01abdc0fce20fba2e9585f9a1c6a/smt.min.lua /smt.lua")
end
local smt = require("/smt")
local t = smt("smt.main.transit")
local turtles = {}
local cmdHist = {}
t.openChannel(12455)
local curTerm, tW, tH = term.current(), term.current().getSize()
local headTerm = window.create(curTerm, 1, 1, tW, 1)
local logTerm  = window.create(curTerm, 1, 2, tW, tH-2)
local cmdTerm = window.create(curTerm, 1, tH, tW, 1)
 
local function split(s, p)
    local t = {}
    s:gsub("([^"..p.."]+)", function(v) t[#t + 1] = v end)
    return t
end
 
local function writeTo(txt, scr)
    term.redirect(scr)
    print(txt)
    term.redirect(cmdTerm)
end
 
local function writeColor(text, before, after, scr)
    term.redirect(scr)
    term.setTextColor(after)
    write(text)
    term.setTextColor(before)
    term.redirect(cmdTerm)
end
 
local function main()
    while true do
        local event, cid, data = os.pullEvent()
        if event == "RLWE-Finish" then
        elseif event == "RLWE-Receive" then
            local data = split(data, ":")
            if data[1] == "label" then
                turtles[data[2]] = cid
                writeColor(data[2]..": ", colors.white, colors.red, logTerm)
                writeColor(data[3].."  ", colors.white, colors.blue, logTerm)
                writeColor(data[4].." blocks", colors.white, colors.pink, logTerm)
                writeTo("", logTerm)
            elseif data[1] == "ping" then
                t.sendData(cid, "pong")
            elseif data[1] == "pong" then 
                writeColor("response -> ", colors.white, colors.white, logTerm)            
                writeColor(data[2]..": ", colors.white, colors.red, logTerm)
                writeColor(data[3].."  ", colors.white, colors.blue, logTerm)
                writeColor(data[4].." blocks", colors.white, colors.pink, logTerm)
                writeTo("", logTerm)
            end
        end
    end
end
 
local function command()
    while true do
        write("> ")
        local input = read(nil, cmdHist)
        if input ~= cmdHist[#cmdHist] then table.insert(cmdHist, input) end
 
        local cmd = split(input, " ")
        if cmd[1] == "list" then
            for label, cid in pairs(turtles) do writeTo("-> "..label, logTerm) end
        elseif cmd[1] == "ping" then
            if cmd[2] ~= "all" then
                if turtles[cmd[2]] then t.sendData(turtles[cmd[2]], "ping")
                else writeTo(cmd[2].." is offline", logTerm)
                end
            else
                for i,v in pairs(turtles) do
                    t.sendData(v, "ping")
                end
            end
        elseif cmd[1] == "exit" then break
        else
            writeTo("Invalid command", logTerm)
        end
    end
end
 
term.clear()
headTerm.setCursorPos(1,1)
headTerm.setTextColor(colors.yellow)
headTerm.write("This server's UUID is " .. t.uuid)
cmdTerm.setTextColor(colors.lightGray)
 
local oldterm = term.redirect(cmdTerm)
parallel.waitForAny(t.listener, main, command)
term.redirect(oldterm)
