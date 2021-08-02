#
#  RRRRRR  EEEEEEE LL        AAA   YY   YY        CCCCC  LL        AAA    SSSSS   SSSSS
#  RR   RR EE      LL       AAAAA  YY   YY       CC    C LL       AAAAA  SS      SS
#  RRRRRR  EEEEE   LL      AA   AA  YYYYY        CC      LL      AA   AA  SSSSS   SSSSS
#  RR  RR  EE      LL      AAAAAAA   YYY         CC    C LL      AAAAAAA      SS      SS
#  RR   RR EEEEEEE LLLLLLL AA   AA   YYY          CCCCC  LLLLLLL AA   AA  SSSSS   SSSSS
#

from machine import Pin
import time

class Relay:
# A relay is a simple electromechanical or solid-state realy that is to be
# controlled on and off. That is to say a relay that is controlled with a single
# digital signal to change the state of the relay (throw the relay).
# More advanced relays (time delayed, latched, overload protection, etc) are not
# covered.
#
# The class simply alows for a relay to be set on or off or toggled. The state of
# the relay can be gotten.
    __numRelays = 0   # no code for delete!

    def __init__(self, pin, name = "", state = "off", active = False, toggleInterval = 5, log = True):
        # relay is often active low
        self.RELAY_ON = active
        self.RELAY_OFF = not self.RELAY_ON
        Relay.__numRelays = Relay.__numRelays + 1
        self.id = Relay.__numRelays
        self.name = name
        self.__toggleInterval = toggleInterval
        self.__log = log
        self.Pin = Pin(pin, mode=Pin.OUT)
        if state == "off":
            self.relayOFF()
        else:
            self.relayON()

    def toggle(self):
        nowTime = time.time()
        if nowTime - self.__changeTime > self.__toggleInterval:
            self.Pin.toggle()
            self.__changeTime = time.time()
            self.__logState()
        else:
            print("NOT toggling, to soon since last change {}".format(nowTime - self.__changeTime))    # ignore toggle if to soon after last toggle

    def relayOFF(self):
        self.Pin(self.RELAY_OFF)
        self.__changeTime = time.time()
        self.__logState()

    def relayON(self):
        self.Pin(self.RELAY_ON)
        self.__changeTime = time.time()
        self.__logState()

    def state(self):
        return "off" if self.Pin.value() == self.RELAY_OFF else "on"

    def __logState(self):
        if self.__log:
            # could log to server?!? TODO
            print("Relay {}:{} is {}".format(self.id, self.name, self.state()))
