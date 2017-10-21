 --[[
	---------------------------------------------------------
    Generates all the alarms and average speed needed for a typical 
    speed pilot using the MHSFA rules.
    
    (c) Alastair Cormack - alastair.cormack@gmail.com

--]]
collectgarbage()
----------------------------------------------------------------------
-- Locals for the application
local label, sens, sensid, senspa, id, param
local speedsens, speedsensid, speedsenspa, speedid, speedparam
local telem, telemVal
local result, tvalue, limit
local toptoflDist,fltocourseDist,courseWidth,courseLength,prestageLength,incourseALM,outcourseALM,outprestageALM,incouseAudio,outcouseAudio,outprestageAudio,averagespeedALM
local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}
local prestageIndex,outcourseIndex,incourseIndex,diveIndex,averagespeedIndex
local outDist,preoutDist
local lastTime
local blnOutCourse = false
local blnTiming = true   --set true so we dont say this when we are in the course
local blnoutStage = false

local speedtotal
local speedcounter
local maxA, maxB, blnDonePassA -- keeps track of pass in direction a or b (can't do left or right as dont have heading)
local diveEnterCourseHeight

local tmp

local goingout = true

----------------------------------------------------------------------
-- Set Dsitances
local function setDistances()
  -- do some pythagoras
  tmp = (toptoflDist + fltocourseDist + (courseWidth / 2))
  outDist = math.sqrt(((tmp * tmp) + ((courseLength / 2) * (courseLength /2))))
  preoutDist = math.sqrt(((tmp * tmp) + (((courseLength / 2) + prestageLength) * ((courseLength / 2) + prestageLength)))) 
  --print(preoutDist,outDist)
end

----------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelemetry()
    lcd.drawText(3,0,string.format("%d", maxB),FONT_BIG)
    lcd.drawText(145 - lcd.getTextWidth(FONT_BIG,string.format("%d", maxA)),0,string.format("%d", maxA),FONT_BIG)
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

  
local function altsensorChanged(value)
  altsens=value
  altsensid=value
  altsenspa=value
  system.pSave("altsens",value)
  system.pSave("altsid",value)
  system.pSave("altsspa",value)
  altid = string.format("%s", sensorIdlist[altsensid])
  altparam = string.format("%s", sensorPalist[altsenspa])
  if (altid == "...") then
    altid = 0
    altparam = 0
  end
  system.pSave("altid", altid)
  system.pSave("altparam", altparam)
end



local function toptoflDistChanged(value)
	if (value == nil) then
		value = 10
	end
	toptoflDist=value
	system.pSave("toptoflDist",value)
	setDistances()
end


local function fltocourseDistChanged(value)
  if (value == nil) then
    value = 20
  end
  fltocourseDist=value
  system.pSave("fltocourseDist",value)  
  setDistances()
end

local function courseWidthChanged(value)
  if (value == nil) then
    value = 40
  end
  courseWidth=value
  system.pSave("courseWidth",value)  
  setDistances()
end

local function courseLengthChanged(value)
  if (value == nil) then
    value = 100
  end
  courseLength=value
  system.pSave("courseLength",value) 
  setDistances()
end


local function prestageLengthChanged(value)
   if (value == nil) then
    value = 100
  end
  prestageLength=value
  system.pSave("prestageLength",value)  
  setDistances()
end

local function incourseALMChanged(value)
  incourseALM = not value
  if (value) then
    system.pSave("inALM","True")
  else
    system.pSave("inALM","False")
  end
  form.setValue(incourseIndex,incourseALM)  
end

local function outcourseALMChanged(value)
  outcourseALM = not value
  if (value) then
    system.pSave("outALM","True")
  else
    system.pSave("outALM","False")
  end

  form.setValue(outcourseIndex,outcourseALM)  
end

local function outprestageALMChanged(value)
  outprestageALM = not value
  if (value) then
    system.pSave("outpALM","True")
  else
    system.pSave("outpALM","False")
  end

  form.setValue(prestageIndex,outprestageALM)  
end

local function incouseAudioChanged(value)
  incouseAudio=value
  system.pSave("inAudio",incouseAudio)  
end

local function outprestageAudioChanged(value)
  outprestageAudio=value
  system.pSave("outpAudio",outprestageAudio)      
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
    form.addLabel({label="Takeoff to Flightline",font=FONT_MINI})
    form.addIntbox(toptoflDist,1,50,1,0,1,toptoflDistChanged)
    
    
		form.addRow(2)
		form.addLabel({label="Flightline to Course",font=FONT_MINI})
		form.addIntbox(fltocourseDist,1,50,1,0,1,fltocourseDistChanged)
		
		form.addRow(2)
		form.addLabel({label="Course Width",font=FONT_MINI})
		form.addIntbox(courseWidth,10,100,1,0,1,courseWidthChanged)

		
		form.addRow(2)
		form.addLabel({label="Course Length",font=FONT_MINI})
		form.addIntbox(courseLength,25,200,1,0,1,courseLengthChanged)
		
		form.addRow(2)
    form.addLabel({label="Pre Stage Length",font=FONT_MINI})
    form.addIntbox(prestageLength,25,200,1,0,1,prestageLengthChanged)

		form.addRow(2)
    form.addLabel({label="In Course Alarm",font=FONT_MINI,width=270})
    incourseIndex = form.addCheckbox(incourseALM,incourseALMChanged)
    
    form.addRow(2)
    form.addLabel({label="In Course Audio File",font=FONT_MINI})
    form.addAudioFilebox(incouseAudio, incouseAudioChanged)
    
    form.addRow(2)
    form.addLabel({label="Out Course Alarm",font=FONT_MINI,width=270})
    outcourseIndex = form.addCheckbox(outcourseALM,outcourseALMChanged)
 
    form.addRow(2)
    form.addLabel({label="Pre-Stage Alarm",font=FONT_MINI,width=270})
    prestageIndex = form.addCheckbox(outprestageALM,outprestageALMChanged)
    
    form.addRow(2)
    form.addLabel({label="Pre-Stage Audio File",font=FONT_MINI})
    form.addAudioFilebox(outprestageAudio, outprestageAudioChanged)
    
    form.addRow(1)
    form.addLabel({label="www.mhsfa.org - v."..MHSFAVersion.." ",font=FONT_MINI, alignRight=true})

    collectgarbage()
end
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Runtime functions, read sensor
local function loop()
  local newTime = system.getTimeCounter() 
  local delta = newTime - lastTime 
  
  
	
	if (delta >= 200) then -- want a 5hz cycle here as not going to get gps fixes any faster and can use this for avg speed
	   lastTime = newTime
	   local distsensor = system.getSensorByID(id, param)
	   local speedsensor = system.getSensorByID(speedid, speedparam)
	   
	   --check we have some valid values from all the sensors
	   if ((distsensor and distsensor.valid) and (speedsensor and speedsensor.valid)) then
            -- out of pre-stage
            if (distsensor.value >= preoutDist) then   
            --if (distsensor >= preoutDist) then
                if ((outprestageALM) and (blnoutStage == false)) then 
                    system.playFile(outprestageAudio,AUDIO_BACKGROUND) 
                    --print("pre-stage")  
                end
                blnoutStage = true
            -- inside pre-stage
            
            elseif ((distsensor.value >= outDist) and (distsensor.value < preoutDist)) then
                if ((outcourseALM) and (blnOutCourse == false)) then
                    --check we have some values to play the average speed
                    if ((speedtotal > 0) and (speedcounter > 0)) then 
                        local avgspeed = speedtotal / speedcounter
                        system.playNumber (avgspeed, 0, "km/h")
                        --print(avgspeed)
                        speedcounter = 0
                        speedtotal = 0   
                        if (blnDonePassA) then
                            if (avgspeed > maxA) then maxA = avgspeed end
                        else
                            if (avgspeed > maxB) then maxB = avgspeed end
                        end
                        blnDonePassA = not blnDonePassA
                        printTelemetry()
                    end
                    
                    --print("out course")
                    blnTiming = false
                    blnOutCourse = true
                elseif ((blnoutStage) and (blnOutCourse)) then--we are coming back in
                    system.playFile(outprestageAudio,AUDIO_BACKGROUND) 
                    --print("into pre-stage")  
                    blnoutStage = false
                end
                
                
            else
                --we are in the course
                if ((incourseALM) and (blnTiming == false)) then 
                    system.playFile(incouseAudio,AUDIO_IMMEDIATE)
                    --print("incourse")
                    blnTiming = true
                    blnoutStage = false   
                    blnOutCourse = false
                end
        
                speedcounter = speedcounter + 1
                speedtotal = speedtotal + speedsensor.value
                --speedtotal = speedtotal + speedsensor
            end
	   end
  end
  --print("Mem: ",collectgarbage("count"))
  collectgarbage()
end


----------------------------------------------------------------------
-- Application initialization
local function init()
	 system.registerForm(1,MENU_APPS,"MHSFA Course Alarms",initForm,keyPressed)
	 
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
  
	toptoflDist = system.pLoad("toptoflDist",1)
	
	
	fltocourseDist = system.pLoad("fltocourseDist",2)
	courseWidth = system.pLoad("courseWidth",10)
	courseLength = system.pLoad("courseLength",50)
	prestageLength = system.pLoad("prestageLength",25)
	
	if (system.pLoad("incALM","True") == "True") then
	   incourseALM = true
	else
	   incourseALM = false
	end
	if (system.pLoad("outALM","True") == "True") then
     outcourseALM = true
  else
     outcourseALM = false
  end
  if (system.pLoad("outpALM","True") == "True") then
     outprestageALM = true
  else
     outprestageALM = false
  end
	
	incouseAudio = system.pLoad("inAudio","")
	outprestageAudio = system.pLoad("outpAudio","")
	
	lastTime = system.getTimeCounter()
	
	maxA = 0
  maxB = 0
  
	system.registerTelemetry(1,"MHSFA Passes (kp/h)",0,printTelemetry)
	
	speedtotal  = 0
  speedcounter = 0
  blnDonePassA = false 

	setDistances()
  collectgarbage()
end
----------------------------------------------------------------------
--setLanguage()
MHSFAVersion = "1.0"
collectgarbage()
return {init=init, loop=loop, author="AlastairC", version="1.0", name="MHSFACourse"}
