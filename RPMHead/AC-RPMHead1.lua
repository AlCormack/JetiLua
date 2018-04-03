 --[[
	---------------------------------------------------------
    Takes a sensor and applies a Gear Ratio and Poles correction to get headspeed.

	---------------------------------------------------------
	Based on Percentage application that is part of RC-Thoughts Jeti Tools.
	
	14th Oct 2017 - Rev 1.2 - Added logging support - Alastair.Cormack @ gmail.com
	1st Apr 2018 - Rev 1.3 - Changed logging to use new Lua API
	---------------------------------------------------------
	Based on code by Tero @ RC-Thoughts.com 2016
	---------------------------------------------------------
--]]
collectgarbage()
----------------------------------------------------------------------
-- Locals for the application
local label, sens, sensid, senspa, main, pinion, poles, id, param
local telem, telemVal
local result, tvalue, limit
local ratio
local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}
local switch
local result = 0
----------------------------------------------------------------------
-- Read translations
local function setLanguage()

end
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Do gear Ratio and pole calc - precalculate this so the loop does not need to waste CPU cycles - main is divided by 10 as we have 1 decimal place
local function setRatio()
    ratio = ((main / 10) / pinion) * poles
end
----------------------------------------------------------------------
-- Read available sensors for user to select
local sensors = system.getSensors()
for i,sensor in ipairs(sensors) do
	if (sensor.label ~= "") then
		table.insert(sensorLalist, string.format("%s", sensor.label))
		table.insert(sensorIdlist, string.format("%s", sensor.id))
		table.insert(sensorPalist, string.format("%s", sensor.param))
	end
end
----------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelemetry()
	if (telemVal == "-") then
		lcd.drawText(145 - lcd.getTextWidth(FONT_BIG,"-"),0,"-",FONT_BIG)

    else
		lcd.drawText(145 - lcd.getTextWidth(FONT_BIG,string.format("%dRPM", telemVal)),0,string.format("%dRPM", telemVal),FONT_BIG)

	end
end

----------------------------------------------------------------------
-- Store settings when changed by user


local function sensorChanged(value)
	sens=value
	sensid=value
	senspa=value
	system.pSave("sens",value)
	system.pSave("sensid",value)
	system.pSave("senspa",value)
	id = string.format("%s", sensorIdlist[sensid])
	param = string.format("%s", sensorPalist[senspa])
	if (id == "...") then
		id = 0
		param = 0
	end
	system.pSave("id", id)
	system.pSave("param", param)
end

local function pinionChanged(value)
	if (value == nil) then
		value = 1
	end
	pinion=value
	system.pSave("pinion",value)
    setRatio()
end

local function mainChanged(value)
	if (value == nil) then
		value = 1
	end
	main=value
	system.pSave("main",value)
	setRatio()
end

local function polesChanged(value)
    if (value == nil) then
        value = 1
    end
    poles=value
    system.pSave("poles",value)
    setRatio()
end

local function switchChanged(value)
  switch=value
  system.pSave("switch",value)
end
----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)


	form.addRow(2)
	form.addLabel({label="Select Sensor"})
	form.addSelectbox(sensorLalist,sens,true,sensorChanged)

	
	form.addRow(2)
	form.addLabel({label="Pinion"})
	form.addIntbox(pinion,1,99,1,0,1,pinionChanged)
	
	form.addRow(2)
	form.addLabel({label="Main Gear"})
	form.addIntbox(main,1,5000,1,1,1,mainChanged)

	
	form.addRow(2)
	form.addLabel({label="Poles"})
	form.addIntbox(poles,1,60,1,0,1,polesChanged)
	
	form.addRow(2)
  form.addLabel({label="Read RPM"})
  form.addInputbox(switch,true,switchChanged)
    
    collectgarbage()
end
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Runtime functions, read sensor
local function loop()
  local val = system.getInputsVal(switch)
	local sensor = system.getSensorByID(id, param)
	local newTime = system.getTimeCounter() 
  local delta = newTime - lastTime 

	
	if (delta >= 500) then -- want a 2hz cycle here 
	   if(sensor and sensor.valid) then
            result = sensor.value / ratio
            telemVal = result 
     else
        telemVal = "-"
	   end
	
	   if ((val and val>0) and (not system.isPlayback())) then
	       system.playNumber (result, 0,"","Revolution") 
	   end
     collectgarbage()
   end
end
----------------------------------------------------------------------
-- Application initialization
local function init()
	system.registerForm(1,MENU_APPS,"RPM to Headspeed",initForm,keyPressed)
	
	lastTime = system.getTimeCounter()
	
	sens = system.pLoad("sens",0)
	sensid = system.pLoad("sensid",0)
	senspa = system.pLoad("senspa",0)
	main = system.pLoad("main",0)
	pinion = system.pLoad("pinion",0)
	poles = system.pLoad("poles",0)
	id = system.pLoad("id",0)
	param = system.pLoad("param",0)
	switch = system.pLoad("switch")
	telemVal = "-"
	system.registerTelemetry(1,"Headspeed",0,printTelemetry)
	
	setRatio()
	
	system.registerLogVariable("Headspeed","RPM",(
      function(index)
          return result
      end) 
  )
	
  collectgarbage()
end
----------------------------------------------------------------------
--setLanguage()
collectgarbage()
return {init=init, loop=loop, author="AlastairC", version="1.3", name="RPM to Headspeed"}
