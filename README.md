# TurtleMonitor
Sends the location and fuel level of the turtle to a server. Uses https://forums.computercraft.cc/index.php?topic=7.0 and code from https://github.com/xAnavrins (who's the real MVP here)

# wget https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/server.lua server.lua 
# wget https://raw.githubusercontent.com/jakedacatman/TurtleMonitor/master/sender.lua sender.lua 

make the startup file of the turtle(s) the following line:
shell.run("sender.lua <uuid>") 
obviously replace "<uuid>" with the server's uuid

todo: make sender an API so you can call it from other programs(securely send data to the server)
