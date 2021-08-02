#
#
#
#
#   _    _   _    _        _   _   _____   _   _   ____
#  | |  | | \ \  / /      | | | | | ____| | \ | | / ___|
#  \ \  / /  \ \/ /       | |_| | |  _|   |  \| | \___ \
#   \ \/ /    \  /        |  _  | | |___  | |\  |  ___) |
#    \__/      |_|        |_| |_| |_____| |_| \_| |____/
#
#
#

# A pycom lopy4 script for the HEN COOP of VILLA YDDINGE

#
# The basic idea is to enable certain automation and remote control of lights,
# heating and door for the hen coop. This lopy and script will have some
# sensors and controls as well as a web interface for commands and led display
# for status.
#

   ##################################################################
   ##################################################################
   ## This script is done as a project for the 2021 summer cource: ##
   ##                    1DT305 - Applied IoT                      ##
   ## through the        Linné University in Sweden                ##
   ## Done by:           Conal Lewer-Allen                         ##
   ## with student id    cl223vs                                   ##
   ##################################################################
   ##################################################################

SCRIPT_VERSION = "0.2"
SCRIPT_NAME = "VY HENS " + SCRIPT_VERSION


# **** INTERFACES ****
#
# * Digital Sensors *
#      Inside  temperature
#      Outside temperature
#      Inside  humidity
#      Outside humidity
#
# * Analogue Sensors *
#      Chicken door state
#      ** Switches / buttons **
#          Inside  light chicken button
#          Outside light chicken enterance button
#          Chicken door button
#
# * Output *
#      Inside  light chickens
#      Outside light chicken run
#      Outside light enterance
#      Heating lamp
#      Open  chicken door
#      Close chicken door
#
# * miscelaneous *
#
# * future *
#      Fan on
#      motion detection store
#      store light
#      rain sensor
#      wind sensor
#      chicken coop door sensor
#      store door sensor
#      gas detector
#      store enterance light
#      store enterance light button


# IIIII MM    MM PPPPPP   OOOOO  RRRRRR  TTTTTTT
#  III  MMM  MMM PP   PP OO   OO RR   RR   TTT
#  III  MM MM MM PPPPPP  OO   OO RRRRRR    TTT
#  III  MM    MM PP      OO   OO RR  RR    TTT
# IIIII MM    MM PP       OOOO0  RR   RR   TTT

# general imports for wlan and status
from network import WLAN
import sys
import machine
import os
import urequests as requests
import time
from machine import Pin
import lopy_lcd as myDisplay    # for display
from machine import UART
import pycom
import keys     # for private wifi keys
import pins     # for named pins
from relay import Relay    # for relays
from sensor import Sensor  # for sensors


#  SSSSS  EEEEEEE TTTTTTT UU   UU PPPPPP
# SS      EE        TTT   UU   UU PP   PP
#  SSSSS  EEEEE     TTT   UU   UU PPPPPP
#      SS EE        TTT   UU   UU PP
#  SSSSS  EEEEEEE   TTT    UUUUU  PP

# from ubidots example.... not sure it is still needed
uart = UART(0, baudrate=115200)
os.dupterm(uart)

# indicate starting up
print('\n.oO STARTING Oo.\n')
pycom.heartbeat(False)
pycom.rgbled(0x110000)  # red

# setup relay
# do this as soon as possible in case relay goes on with load
relays = {}
relays["Heating Lamp"] = Relay(pins.HEATING_LAMP_PIN, "Heating Lamp", toggleInterval = 600)
relays["Coop Light"] = Relay(pins.COOP_LIGHT_PIN, "Coop Light")
relays["Run Light"] = Relay(pins.RUN_LIGHT_PIN, "Run Light")

# indicate relay should be off now
pycom.rgbled(0x000011)  # blue

# setup and join wifi
print('Searching for Network')
wlan = WLAN(mode=WLAN.STA)
wlan.ifconfig(config='dhcp')
myIP = ''
for net in wlan.scan():
    if net.ssid == keys.wifi_ssid:
        print('Network found!')
        wlan.connect(net.ssid, auth=(net.sec, keys.wifi_password), timeout=5000)
        while not wlan.isconnected():       # could get stuck!!
            machine.idle() # save power while waiting
        print('WLAN connection succeeded!')
        print(wlan.ifconfig())
        myIP = wlan.ifconfig()[0]
        print("My IP Address is : " + myIP)
        break

# setup display
displayType = myDisplay.kDisplaySPI128x64
myDisplay.initialize(displayType)
if myDisplay.isConnected():
    myDisplay.set_contrast(128) # 1-255
    myDisplay.displayOn()
    myDisplay.clearBuffer()
    # add some info
    myDisplay.addString(0, 0,  sys.platform + " " + sys.version)
    myDisplay.addString(0, 1,  "---")
    myDisplay.addString(0, 2,  "CPU: {} MHz".format(machine.freq()/1000000))
    myDisplay.addString(0, 4,  "Version: {}".format(os.uname().release))
    myDisplay.addString(0, 5,  "  ")
    myDisplay.addString(0, 6,  "My IP Address is")
    myDisplay.addString(0, 7,  myIP)
    myDisplay.drawBuffer()
else:
    print("Error: LCD not found")

# add sensors
sensors = {}
sensors["COOP_th"] = Sensor(
                            pin = pins.SENSOR_IN_PIN,
                            measurementID = keys.SENSOR_COOP,
                            controllerUUID = keys.controllerUUID,   # needed at least once
                            name = "INSIDE COOP",
                            type = "dht22",
                            log = False)
sensors["OUTSIDE_th"] = Sensor(
                            pin = pins.SENSOR_OUT_PIN,
                            measurementID = keys.SENSOR_OUTSIDE,
                            name = "OUTSIDE",
                            type = "dht22",
                            log = False)
# add adc
adc = machine.ADC()
button = adc.channel(pin=pins.BUTTON_PIN)

# constants
DELAY = 1  # Delay in seconds
measurementInterval = 30    # sec. Change to more realistic times for real world deployment, eg 5 min
turnHeatingLampOff = 5  # turn off above 5 C
turnHeatingLampOn = 3  # turn on below 3 C

#   __     __   __                   ___  ___     ___
#  |  \ | /__` |__) |     /\  \ /     |  |__  \_/  |
#  |__/ | .__/ |    |___ /~~\  |      |  |___ / \  |
#
def displayText(textToDisplay):
    myDisplay.clearBuffer()
    row = 0
    for text in textToDisplay:
        myDisplay.addString(0, row, text)
        row = row + 1
    myDisplay.drawBuffer()

#   __               __           __   __
#  |__) |  | | |    |  \       | /__` /  \ |\ |
#  |__) \__/ | |___ |__/    \__/ .__/ \__/ | \|
#
# Builds the json to send the request
# TODO check
# from ubidots example
def buildJson(variable1, value1, variable2, value2):
    try:
        data = {variable1: {"value": value1},
                variable2: {"value": value2}}
        return data
    except:
        return None

#   __   __   __  ___               __
#  |__) /  \ /__`  |     \  /  /\  |__)
#  |    \__/ .__/  |      \/  /~~\ |  \
#
# Sends the request. Please reference the REST API reference https://ubidots.com/docs/api/
# TODO check
# from ubidots example
def postVar(device, value1, value2):
    try:
        url = "https://industrial.api.ubidots.com/"
        url = url + "api/v1.6/devices/" + device
        headers = {"X-Auth-Token": keys.ubidotsToken, "Content-Type": "application/json"}
        data = buildJson("Temp", value1, "Humidity", value2)
        if data is not None:
#            print(data)
            req = requests.post(url=url, headers=headers, json=data)
            return req.json()
        else:
            pass
    except:
        pass

#        __     __   __  ___  __      ___                 __        ___
#  |  | |__) | |  \ /  \  |  /__`    |__  \_/  /\   |\/| |__) |    |__
#  \__/ |__) | |__/ \__/  |  .__/    |___ / \ /~~\  |  | |    |___ |___
#
# from ubidots example
def ubidotsExample(sensor, temp, humidity):
    postVar("hens" + sensor, temp, humidity)

#   __   ___       __   __   __   __         __   ___       __
#  /__` |__  |\ | /__` /  \ |__) /__`       |__) |__   /\  |  \
#  .__/ |___ | \| .__/ \__/ |  \ .__/       |  \ |___ /~~\ |__/
#
def sensorsRead():
    for sensor in sensors:
        if sensors[sensor].type == "dht22":
            temp, humidity = sensors[sensor].read()
            ubidotsExample(sensor, temp, humidity)

#   __     __   __                       __   ___       __   __   __
#  |  \ | /__` |__) |     /\  \ /       /__` |__  |\ | /__` /  \ |__)
#  |__/ | .__/ |    |___ /~~\  |        .__/ |___ | \| .__/ \__/ |  \
#
def displaySensor(sensorToDisplay):
    displayText(sensors[sensorToDisplay].display())

#   __        ___  __                   ___      ___         __                         __
#  /  ` |__| |__  /  ` |__/       |__| |__   /\   |  | |\ | / _`       |     /\   |\/| |__)
#  \__, |  | |___ \__, |  \       |  | |___ /~~\  |  | | \| \__>       |___ /~~\  |  | |
#
def checkHeatingLamp():
    lampStatus = relays["Heating Lamp"].state()
    temp = sensors["COOP_th"].temperature
    if lampStatus == "on" and temp > turnHeatingLampOff:
        relays["Heating Lamp"].toggle()
    elif lampStatus == "off" and temp < turnHeatingLampOn:
        relays["Heating Lamp"].toggle()

#   __        ___  __              __       ___ ___  __
#  /  ` |__| |__  /  ` |__/       |__) |  |  |   |  /  \ |\ |
#  \__, |  | |___ \__, |  \       |__) \__/  |   |  \__/ | \|
#
def checkButton():
    buttonVal = button()
    if buttonVal > 100:
        pycom.rgbled(0x777777)  # red
        time.sleep(0.2)
        pycom.rgbled(0x000000)  # off
        relays["Coop Light"].toggle()


# indicate end of startup
pycom.rgbled(0x007700)  # green
time.sleep(0.2)
pycom.rgbled(0x000000)  # off
#   ___       __         __   ___        __   ___ ___       __
#  |__  |\ | |  \       /  \ |__        /__` |__   |  |  | |__)
#  |___ | \| |__/       \__/ |          .__/ |___  |  \__/ |
#

##############################################

#  WW      WW HH   HH IIIII LL      EEEEEEE       LL       OOOOO   OOOOO  PPPPPP
#  WW      WW HH   HH  III  LL      EE            LL      OO   OO OO   OO PP   PP
#  WW   W  WW HHHHHHH  III  LL      EEEEE         LL      OO   OO OO   OO PPPPPP
#   WW WWW WW HH   HH  III  LL      EE            LL      OO   OO OO   OO PP
#    WW   WW  HH   HH IIIII LLLLLLL EEEEEEE       LLLLLLL  OOOO0   OOOO0  PP
#
previousMeasurementTime = 0
while True:
    nowTime = time.time()
    for sensorToDisplay in sensors:
        if nowTime - previousMeasurementTime > measurementInterval:
            sensorsRead()
            previousMeasurementTime = nowTime
            checkHeatingLamp()
        displaySensor(sensorToDisplay)
        checkButton()
        time.sleep(DELAY*2)
