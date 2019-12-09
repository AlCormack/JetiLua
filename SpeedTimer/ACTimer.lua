 --[[
	---------------------------------------------------------
    Timer for Speed Application.

	---------------------------------------------------------
	
	30th Nov 2019 - Initial Version
	---------------------------------------------------------
	(C) Alastair Cormack 2019
	---------------------------------------------------------
--]]
collectgarbage()
----------------------------------------------------------------------
-- Locals for the application
local clength = 200
local lastTime 
local id, idr, param, paramr
local csaverage = 0
local ctaverage = 0

local result = 0
local lButtonPressed = 1
local rButtonPressed = 1
local blTimerStarted = false
local brTimerStarted = false

local lButtonHeldDown = 1
local rButtonHeldDown = 1

local switch

local startTime = 0
local lTime = 0
local rTime = 0

local curPassNum = 1
local passNum = {1,2,3,4,5,6,7,8,9,10,11}
local passDir = {"-","-","-","-","-","-","-","-","-","-","-"}
local passTime = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}
local passSpeedTotal = 0
local passFastest = 0
local speedLogResult = 0

local sensorLalist = {"..."}
local sensorIdlist = {"..."}
local sensorPalist = {"..."}

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
-- Read translations
local function setLanguage()

end
----------------------------------------------------------------------
-- Draw the telemetry windows
local function printTelemetry()
		lcd.drawText(0,0,string.format("L:%.2fs",lTime),FONT_MAXI)
		lcd.drawText((lcd.width / 2),0,string.format("R:%.2fs",rTime),FONT_MAXI)
    lcd.drawText(0,(lcd.height - 93),"Course Length:"..clength.."m",FONT_MINI)
	  
	  
	  lcd.drawText((lcd.width / 2),40,"#",FONT_MINI)
	  lcd.drawText((lcd.width / 2)+15,40,"Dir",FONT_MINI)
	  lcd.drawText((lcd.width / 2)+35,40,"Speed(kph)",FONT_MINI)
	  lcd.drawText((lcd.width / 2)+105,40,"Time(s)",FONT_MINI)
	  csbest = 0
	  ctbest = 0
	  csaverage = 0
	  ctaverage = 0
	  
	  for val = 1, 10 do
	    lcd.drawText((lcd.width / 2),43+ (val*10),""..passNum[val],FONT_MINI)
      lcd.drawText((lcd.width / 2)+15,43+ (val*10),passDir[val],FONT_MINI)
      if passTime[val] > 0.0 then
          cspeed = (clength / 1000.0) / ((passTime[val] / 60.0) /60.0)
      else
          cspeed = 0
      end
      lcd.drawText((lcd.width / 2)+35,43+ (val*10),string.format("%.2f",cspeed),FONT_MINI)
      lcd.drawText((lcd.width / 2)+105,43+ (val*10),string.format("%.2f",passTime[val]),FONT_MINI)
      if (val <= curPassNum) then
          csaverage = csaverage + cspeed
          ctaverage = ctaverage + passTime[val]
          speedLogResult = cspeed
          if (cspeed > csbest) then 
            csbest = cspeed
            ctbest = passTime[val]
          end
      end
	  end
	  
	  if (curPassNum>1) then
	   csaverage = csaverage / (curPassNum - 1)
	   ctaverage = ctaverage / (curPassNum - 1)
	  end
	  lcd.drawText(0,37,string.format("Average"), FONT_BOLD)
	  lcd.drawText(0,55,string.format("Speed: %.2f kph",csaverage))
	  lcd.drawText(0,72,string.format("Time: %.2f s",ctaverage))
	  
	  lcd.drawText(0,93,string.format("Best"),FONT_BOLD)
    lcd.drawText(0,110,string.format("Speed: %.2f kph",csbest))
    lcd.drawText(0,127,string.format("Time: %.2f s",ctbest))

end

----------------------------------------------------------------------
-- Store settings when changed by user

local function sensorLeftChanged(value)
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

local function sensorRightChanged(value)
  sensr=value
  sensrid=value
  sensrpa=value
  system.pSave("sensr",value)
  system.pSave("sensrid",value)
  system.pSave("sensrpa",value)
  idr = string.format("%s", sensorIdlist[sensrid])
  paramr = string.format("%s", sensorPalist[sensrpa])
  if (idr == "...") then
    idr = 0
    paramr = 0
  end
  system.pSave("idr", idr)
  system.pSave("paramr", paramr)
end

local function switchChanged(value)
  switch=value
  system.pSave("switch",value)
end

local function clChanged(value)
	if (value == nil) then
		value = 200
	end
	clength=value
	system.pSave("clength",value)
end


----------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm(subform)	
	form.addRow(2)
	form.addLabel({label="Course Length"})
	form.addIntbox(clength,50,1000,200,0,10,clChanged)
	
	form.addRow(2)
  form.addLabel({label="Left Button"})
  form.addSelectbox(sensorLalist,sens,true,sensorLeftChanged)
  
  form.addRow(2)
  form.addLabel({label="Right Button"})
  form.addSelectbox(sensorLalist,sensr,true,sensorRightChanged)
  
  form.addRow(2)
  form.addLabel({label="Reset Switch"})
  form.addInputbox(switch,true,switchChanged)
  
  form.addRow(1)
  form.addLabel({label="AlastairC - Speed Timer - v."..SpeedTimerVersion.." ",font=FONT_MINI, alignRight=true})

  collectgarbage()
end
----------------------------------------------------------------------

----------------------------------------------------------------------
-- Runtime functions, read sensor
local function loop()
  local val = system.getInputsVal(switch)
  local sensor = system.getSensorByID(id, param)
  local sensorr = system.getSensorByID(idr, paramr)
 
	local newTime = system.getTimeCounter() 
  local delta = newTime - lastTime 

  lButtonPressed=1
  rButtonPressed=1
  if (val and val>0) then -- reset has been clicked so resent everything
    curPassNum = 1
    passDir = {"-","-","-","-","-","-","-","-","-","-","-"}
    passTime = {0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0}
    passSpeedTotal = 0
    passFastest = 0
    brTimerStarted = false
    blTimerStarted = false
    lTime = 0
    rTime = 0
  end
	
	if (delta >= 50) then -- want a 20hz cycle here 
	   --lets check what button is pressed
	   if(sensor and sensor.valid) then
	     if (sensor.value == nil) then
	       
	     else
	       if (sensor.value == 1) then
	         lButtonHeldDown = 1
	       else
	         if (lButtonHeldDown == 1) then
	             lButtonPressed = 0
	             lButtonHeldDown = 0
	         end
	       end
	     end
	   end
	   if(sensorr and sensorr.valid) then
       if (sensorr.value == nil) then
      
       else
         if (sensorr.value == 1) then
            rButtonHeldDown = 1
         else
            if (rButtonHeldDown == 1) then
               rButtonPressed = 0
               rButtonHeldDown = 0
           end
         end
       end
     end
     --end checking what button was pressed
     
	   if (lButtonPressed == 0) then
	     if (brTimerStarted == true) then
             brTimerStarted = false
             passDir[curPassNum] = "R"
             passTime[curPassNum] = rTime 
             curPassNum = curPassNum + 1
	     else
	       if (blTimerStarted ==false) then
	         lTime = 0.0
	         startTime = system.getTimeCounter() 
	         blTimerStarted = true
	       end
	     end
	   elseif  (rButtonPressed == 0) then
	     if blTimerStarted then
	           blTimerStarted = false
	           passDir[curPassNum] = "L"
             passTime[curPassNum] = lTime 
	           curPassNum = curPassNum + 1
	     else
	       if (brTimerStarted ==false) then
	         rTime = 0.0
	         startTime = system.getTimeCounter() 
           brTimerStarted = true
         end
	     end
	   end
	   if (brTimerStarted) then
         rTime = (system.getTimeCounter() - startTime) / 1000.0
     elseif (blTimerStarted) then
         lTime = (system.getTimeCounter() - startTime) / 1000.0
	   end
	     
	   
	   --if we have more than 10 then loop back to the beginning. In the future could make 1 become 11 and repeat through the list.
	   if (curPassNum > 10) then
	     curPassNum = 1
	   end
	   
	   printTelemetry()
     collectgarbage()
   end
end
----------------------------------------------------------------------
-- Application initialization
local function init()
	system.registerForm(1,MENU_APPS,"Speed Timer",initForm,keyPressed)
	
	lastTime = system.getTimeCounter()
	
	clength = system.pLoad("clength",200)
	
	system.registerTelemetry(1,"Speed Timer",4,printTelemetry)
	
	
	sens = system.pLoad("sens",0)
  sensid = system.pLoad("sensid",0)
  senspa = system.pLoad("senspa",0)
  id = system.pLoad("id",0)
  param = system.pLoad("param",0)
  
  sensr = system.pLoad("sensr",0)
  sensrid = system.pLoad("sensrid",0)
  sensrpa = system.pLoad("sensrpa",0)
  idr = system.pLoad("idr",0)
  paramr = system.pLoad("paramr",0)
  
  switch = system.pLoad("switch")
	
	system.registerLogVariable("Speed Timer","kph",(
      function(index)
          return speedLogResult
      end) 
  )
	
  collectgarbage()
end
----------------------------------------------------------------------
SpeedTimerVersion = "1.0"
collectgarbage()
return {init=init, loop=loop, author="AlastairC", version="1.0", name="ACTimer"}
