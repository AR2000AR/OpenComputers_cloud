local fs = require("filesystem")
local component = require("component")
local event = require("event")
local serialization = require("serialization")
local io = require("io")
local term = require("term")
local os = require("os")
local text = require("text")

cloud_name = nil
modem = component.modem
i = 0
try = 2
default_timeout = 4
path = "/"
wd=os.getenv("PWD")

modem.open(22)

function recive()
  message1 = nil
  message2 = nil
  i=0
  repeat
    __,__,__,__,__,message1,message2 = event.pull(default_timeout,"modem_message")
    i = i+1
  until i == 2 or message1 ~= nil
  if message1 == nil then
    return false
  else
    return true
  end
end

function find_cloud()
  repeat
    print("Try ".. i+1 .."/"..try)
    __,__,add,port,__,message1,message2 = event.pull(default_timeout,"modem_message")
    i=i+1
  until i==try or add ~= nil
  if add == nil then
    return flase
  elseif message1 == "CLOUD" then
    cloud_name = message2
    return true
  end
end

function download_file(d_path,name)
  modem.send(add,port,"!file",d_path)
  if recive() then
    if message1 == "!file" then
      print("Save as :")
      print("1) "..wd..d_path)
      print("2) "..wd.."/"..name)
      while true do
        input = term.read()
        if input == "1\n" then
          if fs.exists(wd..path)==false or fs.isDirectory(wd..path)==false then
            fs.makeDirectory(wd..path)
          end
          f_path = wd..path..name
          break
        elseif input == "2\n" then
          f_path = wd.."/"..name
          break
        end
      end
      file=io.open(f_path,"w")
      file:write(message2)
      file:close()
      term.clear()
      print("CONECTED TO CLOUD "..cloud_name)
      print("Download done")
      print("Saved as "..f_path)
      os.sleep(2)
    elseif message1 == "ERROR" then
      print(message1.." "..message2)
      os.sleep(2)
    else
      print("UKNOWN ERROR")
      os.sleep(2)
    end
  else
    print("ERROR TIMEOUT")
  end
end

if find_cloud() then
  while cloud_name ~= nil do
    term.clear()
    print("CONNECTED TO CLOUD "..cloud_name)
    modem.send(add,port,"!ls",path)
   
    if recive() == true and message1 == "!ls" then
      dir = serialization.unserialize(message2)
      for i,v in ipairs(dir) do
        print(v)
      end
      term.write(path)
      input = term.read()
      
      if input == "!exit\n" then
        break
      
      elseif input == "!d\n" then
        print("Quelle fichier télécharger ?")
        input = term.read()
        for i,k in ipairs(dir) do
          if k.."\n" == input then
            download_file(path..k,k)
          end
        end

      elseif input == "!u\n" then
        term.write("Adresse du fichier : ")
        input=term.read()
        tmp = text.wrap(input,2,2)
        if tmp == "/" then
        else
          input=wd.."/"..text.trim(input)
        end
        if fs.exists(text.trim(input)) and fs.isDirectory(text.trim(input)) == false then
          term.write("Nom pour la sauvegarde : ")
          name=term.read()
          file=io.open(text.trim(input),"r")
          content=file:read("*a")
          modem.send(add,port,"!upload",path.."/"..text.trim(name),content)
        elseif fs.exists(text.trim(input))==false then
          print("ERROR FILE NOT FOUND")
          os.sleep(2)
        else
          print("ERROR NOT A FILE")
        end

      elseif input == "!mk\n" then
        term.write("Nom du dossié : ")
        input = term.read()
        modem.send(add,port,"!mk",path..text.trim(input))

      elseif input == "!rm\n" then
        print("ATTENTION L'OPERATION EST IREVERSIBLE")
        print("Laiser vide pour annuler")
        term.write("Nom du fichier/dossier à suprimer : ")
        input = term.read()
        if input ~= "\n" then
          modem.send(add,port,"!rm",path..text.trim(input))
        end

      elseif input == "?\n" then
        term.clear()
        print("AIDE")
        print("!d : Télécharger")
        print("!u : Uploader")
        print("!mk : Créer un dossier")
        print("!rm : Suprimer")
        print("!exit : quitter")
        print("APPUILLER SUR UNE TOUCHE POUR CONTINUER")
        event.pull("key_up")
        event.pull("key_down")

      else
        for i,k in ipairs(dir) do
          if k.."\n" == input then
            path=path..k
          end
        end
      end
    
    elseif message1 == "CLOUD" then
      modem.send(add,port,"!ls",path)

    else
      print("SERVEUR NOT RESPONDING") 
      break
    end
  end
else
  print("NO CLOUD FOUND")
end