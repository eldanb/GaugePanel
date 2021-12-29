#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>


#define SERVICE_UUID        "93e842a1-9cb9-476d-aaf0-7183ff7c3551"
#define CHARACTERISTIC_GAUGE1_UUID "24d71d3e-79e0-4458-ba98-6ad86421a10b"
#define CHARACTERISTIC_GAUGE2_UUID "34d72d3e-79e0-4458-ba98-6ad86421a10b"

#define BUILTIN_LED 2

class GaugeDriver : public BLECharacteristicCallbacks {
public:
	GaugeDriver(const char *charaId, int gaugePin, int gaugeChannel) 
    : _charaId(charaId), _gaugePin(gaugePin), _gaugeChannel(gaugeChannel),
      _displayValue(0), _lastWrittenValue(0) {

  }
  
  virtual void onWrite(BLECharacteristic* pCharacteristic) {
    uint8_t *data = pCharacteristic->getData();
    _displayValue = data ? *data : 0; 
  }


  void initOnService(BLEService *service) {
    ledcAttachPin(_gaugePin, _gaugeChannel);
    ledcSetup(_gaugeChannel, 2000, 8);
    ledcWrite(_gaugeChannel, 0);
    _lastWrittenValue = 0;

    BLECharacteristic *pCharacteristic = service->createCharacteristic(
                                          _charaId,
                                          BLECharacteristic::PROPERTY_READ |
                                          BLECharacteristic::PROPERTY_WRITE);
                                        
    pCharacteristic->setCallbacks(this);
  }

  void loop() {
    int dataDiff = _displayValue - _lastWrittenValue;
    if(!dataDiff) {
      return;
    }

    if(dataDiff < 5 && dataDiff > -5) {
      _lastWrittenValue = _displayValue;
    } else {
      _lastWrittenValue += dataDiff /2;
    }
    
    ledcWrite(_gaugeChannel, _lastWrittenValue);
  }

  void setDisplayValue(uint8_t v, bool force = false) {
    _displayValue = v;
    if(force) {
      _lastWrittenValue = _displayValue;
      ledcWrite(_gaugeChannel, _lastWrittenValue);
    }
  }

private:
  const char *_charaId;
  int _gaugeChannel;
  int _gaugePin;

  uint8_t _displayValue;
  uint8_t _lastWrittenValue;

} ;

GaugeDriver gauge1(CHARACTERISTIC_GAUGE1_UUID, 27, 0);
GaugeDriver gauge2(CHARACTERISTIC_GAUGE2_UUID, 32, 1);

class ServerCallbacks : public BLEServerCallbacks {
	virtual void onDisconnect(BLEServer* pServer) {
    gauge1.setDisplayValue(0);
    gauge2.setDisplayValue(0);
    BLEDevice::startAdvertising();
  }
} serverCallbacks;


void animateGauges() {
  for(int i=0; i<240; i+=16) {
    gauge1.setDisplayValue(i, true);
    gauge2.setDisplayValue(i, true);
    delay(50);
  }

  gauge1.setDisplayValue(255, true);
  gauge2.setDisplayValue(255, true);

  delay(500);

  for(int i=240; i>=0; i-=16) {
    gauge1.setDisplayValue(i, true);
    gauge2.setDisplayValue(i, true);
    delay(50);
  }

  delay(500);
}

void setup() {
  pinMode(BUILTIN_LED, OUTPUT);

  Serial.begin(115200);
  Serial.println("Starting BLE work!");

  BLEDevice::init("DeskGauge");
  BLEServer *pServer = BLEDevice::createServer();
  BLEService *pService = pServer->createService(SERVICE_UUID);
  pServer->setCallbacks(&serverCallbacks);

  gauge1.initOnService(pService);
  gauge2.initOnService(pService);

  pService->start();

  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();

  animateGauges();  
}

void loop() {
  // put your main code here, to run repeatedly:
  delay(100);
  gauge1.loop();
  gauge2.loop();
}