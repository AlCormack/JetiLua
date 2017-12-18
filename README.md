# JetiLua
Jeti Lua Applications for Speed Freaks and Geeks. To download click on the "Clone or download" button and then click "Download Zip"

* 17th Oct 2017 - Rev 0 : Initial Release
* 17th Dec 2017 - Rev 1 : Updated user Manual to correct the variable that should be selected for Headspeed display on the transmitter.

MHSFAApp
------
![alt text](https://github.com/AlCormack/JetiLua/blob/master/images/SpeedDisplay.jpg "MHSFAApp")
Some speed pilots have been setting alarms on their Jeti Tx’s to use the GPS Distance measure provided by a GPS such as the PowerBox GPS Sensor II as a way of telling when you go into the course and out and looking at the data after the flight to get a rough idea of the average speed. With the advent of Jeti’s latest transmitter firmware they have added the capability to make applications that can use the telemetry going to the transmitter and do cool things with it! Enter the MHSFA Course alarm application for Jeti. The application allows you to enter course details, either the MHSFA ones or ones of your own choosing and then it warns you when you enter the course, go in and out of the pre-stage and reads out the average speed when you have left the course on each pass. It will also store the fastest of each pass in each direction.


MHSFADrag
------
![alt text](https://github.com/AlCormack/JetiLua/blob/master/images/DragRacing.bmp "MHSFAApp")
To continue with the applications using the GPS with the Jeti and the release of the drag racing rules, here is an application that lets you set a switch to start a audio file (‘ready steady go’ is included). As soon as the helicopter reaches a set distance from the start up point the elapsed time and the end of run speed is read out. Also as long as the switch remains in the ‘go’ position, there is a readout on the screen of the time and end speed.

RPMHead
------
![alt text](https://github.com/AlCormack/JetiLua/blob/master/images/HeadspeedGraph.bmp "MHSFAApp")
Some ESC’s don't output head speed and only output motor RPM. This app lets you enter the motor poles and gear ratio. The main gear has a decimal input to allow calculation for two-stage drive like the Gaui R5. The application will also optionally speak out the head speed continually when a user- defined switch is active. The final new feature is to write a log file in the same format as the jeti logs. This enables review of the head speed in the Data Analyser application.
