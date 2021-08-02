#   SSSSS  EEEEEEE NN   NN  SSSSS   OOOOO  RRRRRR         CCCCC  LL        AAA    SSSSS   SSSSS
#  SS      EE      NNN  NN SS      OO   OO RR   RR       CC    C LL       AAAAA  SS      SS
#   SSSSS  EEEEE   NN N NN  SSSSS  OO   OO RRRRRR        CC      LL      AA   AA  SSSSS   SSSSS
#       SS EE      NN  NNN      SS OO   OO RR  RR        CC    C LL      AAAAAAA      SS      SS
#   SSSSS  EEEEEEE NN   NN  SSSSS   OOOO0  RR   RR        CCCCC  LLLLLLL AA   AA  SSSSS   SSSSS
#

from machine import Pin
from dht import DHT
import keys
import urequests as requests
import sys

class Sensor:

    # supported sensor type strings
    __DHT11 = "dht11"
    __DHT22 = "dht22"

    # class global
    __controllerUUID = 0
    __controllerShortID = 0
    __numSensors = 0

    def __init__(self, pin, measurementID, controllerUUID = 0, name = "", type = "unkown", log = True):
        Sensor.__numSensors = Sensor.__numSensors + 1
        self.id = Sensor.__numSensors
        if controllerUUID and not Sensor.__controllerUUID:  # have passed controller UUID but no class controller UUID
            Sensor.__controllerUUID = controllerUUID
        self.name = name
        self.__log = log
        self.__gotReading = False
        self.type = type
        self.__initialise(pin, measurementID)

    def __initialise(self, pin, measurementID):
        if self.type == Sensor.__DHT11:
            self.__initialiseDHT(pin, measurementID, 0)
        elif self.type == Sensor.__DHT22:
            self.__initialiseDHT(pin, measurementID, 1)
        else:
            raise NotImplementedError("ERROR: Unkown sensor type: {} for sensor {}:{}".format(self.type, self.id, self.name))

    def __initialiseDHT(self, pin, measurementID, type):
        # Type 0 = dht11
        # Type 0 = dht22
        self.__sensor = DHT(Pin(pin, mode=Pin.OPEN_DRAIN), type)
        if "temperature" in measurementID:
            self.__temperatureUUID = measurementID["temperature"]
            self.__temperatureShortID = 0
        else:
            raise NotImplementedError("ERROR: no temperature uuid for sensor {}:{}".format(self.id, self.name))
        if "humidity" in measurementID:
            self.__humidityUUID = measurementID["humidity"]
            self.__humidityShortID = 0
        else:
            raise NotImplementedError("ERROR: no humidity uuid for sensor {}:{}".format(self.id, self.name))

    def read(self):
        if self.type == Sensor.__DHT11:
            return self.__readDHT()
        elif self.type == Sensor.__DHT22:
            return self.__readDHT()

    def __readDHT(self):
        result = self.__sensor.read()
        while not result.is_valid():    # can lock
            time.sleep(.5)
            result = self.__sensor.read()
        self.temperature = result.temperature
        self.humidity = result.humidity
        self.__gotReading = True
        self.sendMeasurement()
        self.__logMsg('Measured Sensor {}:{} Temp: {:.2f} RH: {}'.format(self.id, self.name, self.temperature, self.humidity))
        return self.temperature, self.humidity

    def display(self):
        if not self.__gotReading:
            self.read()
        if self.type == Sensor.__DHT11:
            return self.__displayDHT()
        elif self.type == Sensor.__DHT22:
            return self.__displayDHT()

    def __displayDHT(self):
        self.__logMsg('Display Sensor {}:{} Temp: {:.2f} RH: {}'.format(self.id, self.name, self.temperature, self.humidity))
        return "{}:{}".format(self.id, self.name), "  ", "temp {:.1f}".format(self.temperature), "humidity {}".format(self.humidity)

    def __logMsg(self, msg, force = False):
        if self.__log or force:
            # could log to server?!? TODO
            print(msg)

    def __shortID(self, what = "controller"):
        if what == "controller":
            if not Sensor.__controllerShortID:
                self.__getShortID(what)
            return Sensor.__controllerShortID
        elif what == "temperature":
            if not self.__temperatureShortID:
                self.__getShortID(what)
            return self.__temperatureShortID
        elif what == "humidity":
            if not self.__humidityShortID:
                self.__getShortID(what)
            return self.__humidityShortID

    def __getShortID(self, what = "controller"):
        if what == "controller":
            Sensor.__controllerShortID = self.__readQuery("c" + Sensor.__controllerUUID)
            return Sensor.__controllerShortID
        elif what == "temperature":
            self.__temperatureShortID = self.__readQuery("m" + self.__temperatureUUID)
            return self.__temperatureShortID
        if what == "humidity":
            self.__humidityShortID = self.__readQuery("m" + self.__humidityUUID)
            return self.__humidityShortID

    def __readQuery(self, query):
        dUUID = Sensor.__controllerUUID
        if Sensor.__controllerShortID:
            dUUID = Sensor.__controllerShortID
        url = keys.vyURL + "?d=" + dUUID + "&r=" + query
        responce = requests.get(url=url)
        self.__logMsg("responce to query {} : {}".format(url, responce.text))
        return responce.text

    def sendMeasurement(self):
        url = keys.vyURL + "?d=" + self.__shortID() + "&m="
        if self.type == Sensor.__DHT11:
            url = url + self.__getDHTSendMeasurements()
        elif self.type == Sensor.__DHT22:
            url = url + self.__getDHTSendMeasurements()
        responce = requests.get(url=url)
        self.__logMsg("responce to send measurement(s) query : {}".format(responce.text))

    def __getDHTSendMeasurements(self):
        url = self.__shortID("temperature") + ":{:.2f}".format(self.temperature)
        url = url + ","
        url = url + self.__shortID("humidity") + ":{}".format(self.humidity)
        return url
