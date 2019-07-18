 --[[
	---------------------------------------------------------
    Generates all the alarms and average speed needed for a typical 
    speed pilot using the MHSFA rules.
    
    (c) Alastair Cormack - alastair.cormack@gmail.com
    
    Ver 1.1 - 22nd Dec 2017 - Added in average speed and corrected title of displayed telemetry
    Ver 1.2 - 2nd Apr 2018 - Updated to add support for native Jeti logging
    Ver 1.3 - 14th April 2018 - Allowed faster update rate and fixed average pass logging
    Ver 1.4 - 13th July 2019 - Added altitude in and out of course for each direction and added alarm if too high

--]]
collectgarbage()

----------------------------------------------------------------------
-- Locals for the application
local label, sens, sensid, senspa, id, param
local speedsens, speedsensid, speedsenspa, speedid, speedparam, altsens, altsensid, altsensparam
local altid, altparam
local telem, telemVal
local result, tvalue, limit
local toptoflDist,fltocourseDist,courseWidth,courseAlt,courseLength,prestageLength,incourseALM,outcourseALM,outprestageALM,tooHighAudio,incouseAudio,outcouseAudio,outprestageAudio,averagespeedALM

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
local maxA, maxB, blnDonePassA, maxAalt, maxBalt, maxAaltout, maxBaltout, altout,altin  -- keeps track of pass in direction a or b (can't do left or right as dont have heading)
local diveEnterCourseHeight
local avgspeed

local tmp

local goingout = true
local bDisplayAlt = false

----------------------------------------------------------------------
-- Set Dsitances
-- Pre calculate some value so we dont need to burn CPU cylces each time
local function setDistances()
  -- do some pythagoras
  tmp = (toptoflDist + fltocourseDist + (courseWidth / 2))
  outDist = math.sqrt(((tmp * tmp) + ((courseLength) * (courseLength))))
  preoutDist = math.sqrt(((tmp * tmp) + (((courseLength) + prestageLength) * ((courseLength) + prestageLength)))) 
  --print(preoutDist,outDist)
end

----------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelemetry()
    local strAv = string.format("- %dav -", (maxA + maxB)/2)
    lcd.drawText(3,0,string.format("%d", maxB),FONT_BIG)
    lcd.drawText(73 - (lcd.getTextWidth(FONT_BIG,strAv) / 2),0,strAv,FONT_BIG) -- 73 is from 152 / 2 and taken to the nearest integer. Save the CPU some time calculating each time
    lcd.drawText(145 - lcd.getTextWidth(FONT_BIG,string.format("%d", maxA)),0,string.format("%d", maxA),FONT_BIG)
    --alt in
    lcd.drawText(3,lcd.getTextHeight(FONT_NORMAL) + 4 ,string.format("%d", maxBalt),FONT_NORMAL)
    lcd.drawText(145 - lcd.getTextWidth(FONT_NORMAL,string.format("%d", maxAalt)),lcd.getTextHeight(FONT_NORMAL) + 4,string.format("%d", maxAalt),FONT_NORMAL)
    --draw units
    lcd.drawText(73 - lcd.getTextWidth(FONT_NORMAL,"entry(m)") / 2,lcd.getTextHeight(FONT_NORMAL) + 4,"entry(m)",FONT_NORMAL)
    lcd.drawText(73 - lcd.getTextWidth(FONT_NORMAL,"exit(m)") / 2,lcd.getTextHeight(FONT_NORMAL) * 2 + 4,"exit(m)",FONT_NORMAL)
    --alt out
    lcd.drawText(3,lcd.getTextHeight(FONT_NORMAL) * 2 + 4 ,string.format("%d", maxBaltout),FONT_NORMAL)
    lcd.drawText(145 - lcd.getTextWidth(FONT_NORMAL,string.format("%d", maxAaltout)),lcd.getTextHeight(FONT_NORMAL) * 2 + 4,string.format("%d", maxAaltout),FONT_NORMAL)

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

  
local function altitudesensorChanged(value)
  altsens=value
  altsensid=value
  altsenspa=value
  system.pSave("altsns",value)
  system.pSave("altsnid",value)
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

local function courseAltChanged(value)
  if (value == nil) then
    value = 35
  end
  courseAlt=value
  system.pSave("courseAlt",value)  
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
    value = 20
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
  incourseALM =  not value
  if (incourseALM) then
    system.pSave("inALM","True")
  else
    system.pSave("inALM","False")
  end
  form.setValue(incourseIndex,incourseALM)  
end

local function outcourseALMChanged(value)
  outcourseALM =  not value
  if (outcourseALM) then
    system.pSave("outALM","True")
  else
    system.pSave("outALM","False")
  end

  form.setValue(outcourseIndex,outcourseALM)  
end

local function outprestageALMChanged(value)
  outprestageALM =  not value
  if (outprestageALM) then
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

local function tooHighAudioChanged(value)
  tooHighAudio=value
  system.pSave("tooHighAudio",tooHighAudio)      
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
    form.addLabel({label="GPS Altitude Sensor",font=FONT_MINI})
    form.addSelectbox(sensorLalist,altsens,true,altitudesensorChanged)

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
    form.addLabel({label="Course Max Alt",font=FONT_MINI})
    form.addIntbox(courseAlt,5,100,1,0,1,courseAltChanged)
		
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
    
    form.addRow(2)
    form.addLabel({label="Too High Audio File",font=FONT_MINI})
    form.addAudioFilebox(tooHighAudio, tooHighAudioChanged)
    
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



  if (delta >= 100) then -- want a 10hz cycle here as not going to get gps fixes any faster and can use this for avg speed
    lastTime = newTime
    local distsensor = system.getSensorByID(id, param)
    local speedsensor = system.getSensorByID(speedid, speedparam)
    local altsensor = system.getSensorByID(altid, altparam)
    
    --check we have some valid values from all the sensors
    if ((distsensor and distsensor.valid) and (speedsensor and speedsensor.valid)) then
      -- out of pre-stage
      if (distsensor.value >= preoutDist) then   
        --if (distsensor >= preoutDist) then
        if (blnoutStage == false) then 
          if (altsensor and altsensor.valid) then 
              altout = altsensor.value
          end 
          if (outprestageALM) then
            if (outprestageAudio ~= "") then
              system.playFile(outprestageAudio,AUDIO_QUEUE)
            end
          end 
          if (altsensor and altsensor.valid) then 
            if (altsensor.value >=courseAlt) then -- check if we are too high
                  if (tooHighAudio ~= "") then
                    system.playFile(tooHighAudio,AUDIO_QUEUE) -- we dont need to know immediatelly so can wait for the speed to be announced
                  end
            end
          end
          --print("pre-stage")  
        end
        blnoutStage = true
        -- inside pre-stage

      elseif ((distsensor.value >= outDist) and (distsensor.value < preoutDist)) then
        if ((outcourseALM) and (blnOutCourse == false)) then
          --check we have some values to play the average speed
          if ((speedtotal > 0) and (speedcounter > 0)) then 
            avgspeed = speedtotal / speedcounter
            system.playNumber (avgspeed, 0, "km/h")
            --print(avgspeed)
            speedcounter = 0
            speedtotal = 0  
            bDisplayAlt = true
            if (blnDonePassA) then
              if (avgspeed > maxA) then 
                maxA = avgspeed
              end
            else
              if (avgspeed > maxB) then 
                maxB = avgspeed 
              end
            end
            
            blnDonePassA = not blnDonePassA
            printTelemetry()
          end

          --print("out course")
          blnTiming = false
          blnOutCourse = true
        elseif ((blnoutStage) and (blnOutCourse)) then--we are coming back in
          if (outprestageAudio ~= "") then
            system.playFile(outprestageAudio,AUDIO_QUEUE)
          end
          if (altsensor and altsensor.valid) then 
              if (altsensor.value >=courseAlt) then -- check if we are too high
                  if (tooHighAudio ~= "") then
                    system.playFile(tooHighAudio,AUDIO_QUEUE) -- we dont need to know immediatelly so can wait for the speed to be announced
                  end
                  altin = altsensor.value
              end
            end
          --print("into pre-stage")  
          blnoutStage = false
        end


      else
        --we are in the course
        if ((incourseALM) and (blnTiming == false)) then 
          if (incouseAudio ~= "") then
            system.playFile(incouseAudio,AUDIO_IMMEDIATE)
          end
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
  if bDisplayAlt then
    if blnDonePassA then
      maxBalt = altin
      maxBaltout = altout
    else
      maxAalt = altin
      maxAaltout = altout
    end
    bDisplayAlt = false
  end
  --print("Mem: ",collectgarbage("count"))
  collectgarbage()
end


----------------------------------------------------------------------
-- Application initialization
local function init()
  system.registerForm(1,MENU_APPS,"MHSFA Course",initForm,keyPressed)
	 
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
  
  altsens = system.pLoad("altsns",0)
  altsensid = system.pLoad("altsnsid",0)
  altenspa = system.pLoad("altsspa",0)
  
  altid = system.pLoad("altid",0)
  altparam = system.pLoad("altparam",0)
  
	toptoflDist = system.pLoad("toptoflDist",10)
	
	courseAlt= system.pLoad("courseAlt",35)
  tooHighAudio = system.pLoad("tooHighAudio","")
	
	fltocourseDist = system.pLoad("fltocourseDist",20)
	courseWidth = system.pLoad("courseWidth",20)
	courseLength = system.pLoad("courseLength",100)
	prestageLength = system.pLoad("prestageLength",100)
	
	if (system.pLoad("inALM","True") == "True") then
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
  
  --init variables
  maxA = 0
  maxB = 0
  maxAalt = 0
  maxBalt = 0
  altin = 0
  altout = 0
  maxAaltout = 0
  maxBaltout = 0
  speedtotal  = 0
  speedcounter = 0
  blnDonePassA = false 
	
  --setup telemetry 
	system.registerTelemetry(1,"MHSFA Passes (km/h)",2,printTelemetry)

	setDistances()
	
  --setup logging
	system.registerLogVariable("Course Speed","km/h",(
      function(index)
          return avgspeed
      end) 
  )
  system.registerLogVariable("Course Average","km/h",(
      function(index)
          return (maxA + maxB)/2.0
      end) 
  )

  
  collectgarbage()
end
----------------------------------------------------------------------
--setLanguage()
MHSFAVersion = "1.4"
return {init=init, loop=loop, author="AlastairC", version="1.4", name="MHSFACourse"}
