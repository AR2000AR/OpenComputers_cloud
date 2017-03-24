local component = require("component")
local term = require("term")
local text = require("text")
local event = require("event")

try = 2

modem = component.modem
modem.open(22)

function find_cloud()
  i=0
  repeat
    print("Try ".. i+1 .."/"..try)
    __,__,add,port,__,message1,message2 = event.pull(3,"modem_message")
    i=i+1
  until i==try or add ~= nil
  if add == nil then
    return flase
  elseif message1 == "CLOUD" then
    cloud_name = message2
    return true
  end
end

while true do
  if find_cloud() then
    term.write("Stop CLOUD "..cloud_name.." [Y/N] ")
    input = term.read()
    if input == "y\n" or input == "Y\n" then
      modem.send(add,port,"TERMINATE")
      break
    else
      term.write("Try to find a other cloud ? [Y/N] ")
      if input == "n\n" or input == "N\n" then
        break
      end
    end
  else
    print("NO CLOUD FOUND ON PORT : 22")
    break
  end
end