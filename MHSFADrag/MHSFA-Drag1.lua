 --[[
	---------------------------------------------------------
    An Application for drag racing 
    
    (c) Alastair Cormack - alastair.cormack@gmail.com
    
    Ver 1.1 - 2nd Apr 2018 - Updated to add support for native Jeti logging

--]]
collectgarbage()
----------------------------------------------------------------------
-- Locals for the application
local label, sens, sensid, senspa, id, param
local speedsens, speedsensid, speedsenspa, speedid, speedparam

local courseLength,startAudio
local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}

local prevVal = 1

local switch
local endplayed = false

local courseEndSpeed = 0
local courseTime = 0
local playedAudio = false
local startTime = 0
----------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelemetry()
    lcd.drawText(3,0,string.format("%.2fs", courseTime),FONT_BIG)
    lcd.drawText(145 - lcd.getTextWidth(FONT_BIG,string.format("%dkp/h", courseEndSpeed)),0,string.format("%dkp/h", courseEndSpeed),FONT_BIG)
end
----------------------------------------------------------------------
-- Read translations
local function setLanguage()

end

----------------------------------------------------------------------
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

  
local function speedsensorChanged(value)
  speedsens=value
  speedsensid=value
  speedsenspa=value
  system.pSave("spdsns",value)
  system.pSave("spdsnsid",value)
  system.pSave("spdsspa",value)
  speedid = string.format("%s", sensorIdlist[speedsensid])
  speedparam = string.format("%s", sensorPalist[speedsenspa])
  if (speedid == "...") then
    speedid = 0
    speedparam = 0
  end
  system.pSave("spdid", speedid)
  system.pSave("spdparam", speedparam)
end

  

local function courseLengthChanged(value)
  if (value == nil) then
    value = 100
  end
  courseLength=value
  system.pSave("courseLength",value) 
end


local function startAudioChanged(value)
  startAudio=value
  system.pSave("startAudio",startAudio)  
end

local function switchChanged(value)
	switch=value
	system.pSave("switch",value)
end
----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)
	form.addRow(2)
	form.addLabel({label="GPS Distance Sensor",font=FONT_MINI})
	form.addSelectbox(sensorLalist,sens,true,sensorChanged)
		
	form.addRow(2)
    form.addLabel({label="GPS Speed Sensor",font=FONT_MINI})
    form.addSelectbox(sensorLalist,speedsens,true,speedsensorChanged)

	form.addRow(2)
	form.addLabel({label="Course Length",font=FONT_MINI})
	form.addIntbox(courseLength,10,500,1,0,1,courseLengthChanged)
		
	form.addRow(2)
	form.addLabel({label="Start Switch",font=FONT_MINI})
    form.addInputbox(switch,true,switchChanged)
    
    form.addRow(2)
    form.addLabel({label="Start Audio File",font=FONT_MINI})
    form.addAudioFilebox(startAudio, startAudioChanged)
    
    form.addRow(1)
    form.addLabel({label="www.mhsfa.org - v."..MHSFAVersion.." ",font=FONT_MINI, alignRight=true})

    collectgarbage()
end
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Runtime functions, read sensor
local function loop()
   local newTime = system.getTimeCounter() 
  
   local distsensor = system.getSensorByID(id, param)
   local speedsensor = system.getSensorByID(speedid, speedparam)
   local val = system.getInputsVal(switch)
   
   if (val and val>0 and prevVal==0) then
		if (playedAudio == false) then 
		  playedAudio = true
		  system.playFile(startAudio,AUDIO_IMMEDIATE)
		else
		  if (not system.isPlayback()) then	    
		    --print(startTime)
		    startTime = newTime
		    prevVal=1
		  end
	  end
	elseif(val and val<=0) then
	  --print(newTime - startTime)
	  playedAudio = false
		endplayed = false
		prevVal=0
		courseTime = 0
		courseEndSpeed = 0
		printTelemetry()
	end
   --check we have some valid values from all the sensors
   if ((distsensor and distsensor.valid) and (speedsensor and speedsensor.valid) and prevVal==1) then
		-- finished
		if ((distsensor.value >= courseLength)and (endplayed ==false)) then  
			courseTime = (newTime - startTime) / 1000.0
			courseEndSpeed = speedsensor.value
			system.playNumber (courseTime, 0, "s") 
			system.playNumber (courseEndSpeed, 0, "km/h")
			printTelemetry()
			endplayed = true
		end
	end
		
  --print("Mem: ",collectgarbage("count"))
  collectgarbage()
end


----------------------------------------------------------------------
-- Application initialization
local function init()
	system.registerForm(1,MENU_APPS,"MHSFA Drag Racing",initForm,keyPressed)
	 
	sens = system.pLoad("sens",0)
	sensid = system.pLoad("sensid",0)
	senspa = system.pLoad("senspa",0)
	
	id = system.pLoad("id",0)
	param = system.pLoad("param",0)
	
	speedsens = system.pLoad("spdsns",0)
	speedsensid = system.pLoad("spdsnsid",0)
	speedsenspa = system.pLoad("spdsspa",0)
  
	speedid = system.pLoad("spdid",0)
	speedparam = system.pLoad("spdparam",0)
  
	courseLength = system.pLoad("courseLength",50)
	startAudio = system.pLoad("startAudio","")
	switch = system.pLoad("switch")
	
	lastTime = system.getTimeCounter()
	
	system.registerTelemetry(1,"MHSFA Drag Racing",0,printTelemetry)
	
	system.registerLogVariable("Drag Time","s",(
      function(index)
          return (courseTime * 100),2
      end) 
  )
  system.registerLogVariable("Drag End Speed","km/h",(
      function(index)
          return courseEndSpeed
      end) 
  )

	collectgarbage()
end
----------------------------------------------------------------------
--setLanguage()
MHSFAVersion = "1.1"
collectgarbage()
return {init=init, loop=loop, author="AlastairC", version="1.1", name="MHSFADrag"}
