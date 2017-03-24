local filesystem = require("filesystem")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local os = require("os")
local table = require("table")
local io = require("io")
local text = require("text")
local term = require("term")

name = "ALPHA"
modem = component.modem
default_timeout = 2
liste = {}
--wd = "mnt/"..text.wrap(component.filesystem.address,4,3)
wd = "/mnt/507"
local_port = 22

modem.open(local_port)
gpu = term.gpu()
gpu.setResolution(20,5)
term.clear()
print("CLOUD "..name)
print("STATUS : ONLINE")
print("PORT : "..local_port)
print("TIMEOUT : "..default_timeout.."s")
print("HHD : "..wd)

function notice()
  modem.broadcast(22,"CLOUD",name)
end

function recive()
  __,__,add,port,__,message1,message2,message3 = event.pull(default_timeout,"modem_message")
  if message1 == nil or message2 == nil then
    return false
  else
    return false
  end
end

function send_file(file_path)
  os.sleep(0.1)
  file=io.open(file_path,"r")
  text=file:read("*a")
  modem.send(add,port,"!file",text)
  file:close()
end

function recive_file()
  file=io.open(wd..message2,"w")
  file:write(message3)
  file:close()
end

while true do
  liste={}
  notice()
  recive()
  if message1 == "!ls" then
    for file in  filesystem.list(wd..message2) do
      table.insert(liste,file)
    end
    modem.send(add,port,"!ls",serialization.serialize(liste))
  elseif message1 == "TERMINATE" then
    gpu.setResolution(50,16)
    break
  elseif message1 == "!file" then
    send_file(wd..message2)
  elseif message1 == "!upload" then
    recive_file()
  elseif message1 == "!mk" then
    filesystem.makeDirectory(wd.."/"..message2)
  elseif message1 == "!rm" then
    filesystem.remove(wd.."/"..message2)
  end
end