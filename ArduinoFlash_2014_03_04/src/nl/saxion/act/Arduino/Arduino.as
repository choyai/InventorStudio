/* Arduino.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


 package nl.saxion.act.Arduino
{
	import flash.events.EventDispatcher;

	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduinoWithRecovery;
	
	import nl.saxion.act.utils.Assert;


	/**
	 * This is a convenience (proxy) class to easy programming for the Arduino.
	 * It uses the lowLevelArduino class and only shows necessary details
	 *
	 * @author Douwe A. van Twillert, Saxion
	 *
	 * TODO: CHECK if using analog pins as digital input (PORTC or PORT#=2) works.
	 */
	 public class Arduino extends EventDispatcher
	{
		private static const _value2led_brightness : Array = [
			0,   1,   1,   2,   2,   2,   2,   2,   2,   3,   3,   3,   3,   3,   3,   3,
			3,   3,   3,   3,   3,   3,   3,   4,   4,   4,   4,   4,   4,   4,   4,   4,
			4,   4,   4,   5,   5,   5,   5,   5,   5,   5,   5,   5,   5,   6,   6,   6,
			6,   6,   6,   6,   6,   7,   7,   7,   7,   7,   7,   7,   8,   8,   8,   8,
			8,   8,   9,   9,   9,   9,   9,   9,   10,  10,  10,  10,  10,  11,  11,  11,
			11,  11,  12,  12,  12,  12,  12,  13,  13,  13,  13,  14,  14,  14,  14,  15,
			15,  15,  16,  16,  16,  16,  17,  17,  17,  18,  18,  18,  19,  19,  19,  20,
			20,  20,  21,  21,  22,  22,  22,  23,  23,  24,  24,  25,  25,  25,  26,  26,
			27,  27,  28,  28,  29,  29,  30,  30,  31,  32,  32,  33,  33,  34,  35,  35,
			36,  36,  37,  38,  38,  39,  40,  40,  41,  42,  43,  43,  44,  45,  46,  47,
			48,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,
			63,  64,  65,  66,  68,  69,  70,  71,  73,  74,  75,  76,  78,  79,  81,  82,
			83,  85,  86,  88,  90,  91,  93,  94,  96,  98,  99,  101, 103, 105, 107, 109,
			110, 112, 114, 116, 118, 121, 123, 125, 127, 129, 132, 134, 136, 139, 141, 144,
			146, 149, 151, 154, 157, 159, 162, 165, 168, 171, 174, 177, 180, 183, 186, 190,
			193, 196, 200, 203, 207, 211, 214, 218, 222, 226, 230, 234, 238, 242, 248, 255,
		];


		private var _lowLevelArduino : LowLevelArduinoWithRecovery;

		/**
		 * Constructor. You must specify the pinNr configuration and can specify the tcp port
		 *
		 * @param pinConfiguration  Array with pinNr configuration, first two are null, others are { pwmOut or digitalIn or digitalOut or servo }
		 * @param tcpPort         	The tcp port to listen to, see also the as2arduinoGlue configuration file
		 * @param host              the host on which the serialproxy port can be found.
		 */
		public function Arduino( pinConfiguration : Array , tcpPort : uint = 5331 , host : String = "localhost"  )
		{
			_lowLevelArduino = new LowLevelArduinoWithRecovery( pinConfiguration , tcpPort , host );
			_lowLevelArduino.addEventListener( ArduinoEvent.INITIALIZED  , onArduinoInitialized  );
			_lowLevelArduino.addEventListener( ArduinoEvent.DISCONNECTED , onArduinoDisconnected );
		}


		// ================
		// Public functions
		// ================

		// Getters and setters                                                                                                  /** Returns <code>true</code> if the connected Arduino is an Mega arduino. */
		public function get isMega()          : Boolean         { return _lowLevelArduino.isMega;                            }  /** Returns the firmware version in a single number (2.3 translates to 23). Can be 0. */
		public function get firmwareVersion() : uint            { return _lowLevelArduino.firmwareVersion;                   }  /** Returns the name of the firmware, can be <code>null</code>. */
		public function get firmwareName()    : String          { return _lowLevelArduino.firmwareName;                      }  /** Returns number of digital pins. */
		public function get nrOfDigitalPins() : uint            { return _lowLevelArduino.nrOfDigitalPins;                   }  /** Returns number of analog pins. */
		public function get nrOfAnalogPins()  : uint            { return _lowLevelArduino.nrOfAnalogPins;                    }  /** Returns the total number of pins. Is the same as the sum of the number of analog and digital pins. */
		public function get nrOfPins()        : uint            { return _lowLevelArduino.nrOfPins;                          }  /** Returns <code>true</code> if an Arduino is connected and initialized and <code>false</code> otherwise. */
		public function get isConnected()     : Boolean         { return _lowLevelArduino.isProperlyInitializedAndConnected; }  /** returns the associated <code>lowLevelArduino</code> class. Arduino itself is a convenience class. */
		public function get lowLevelArduino() : LowLevelArduino { return _lowLevelArduino;                                   }


		/**
		 * Returns true if a that pin has a specific capability
		 * 
		 * @param pinNr       The pin number of which a pin capability is queried. Analog pins can be queries by their real (high) pin number.
		 * @param capability  The capability as a number. Same as the pinMode setting in setMode().
		 */
		public function isCapabilityOfDigitalPin( pinNr : uint , capability : uint )  : Boolean
		{
			return _lowLevelArduino.isCapabilityOfDigitalPin( pinNr, capability );
		}


		/**
		 * Returns true if an analog pin has a certain capability
		 * 
		 * @param pinNr       The analog pin number of which a pin capability is queried.
		 * @param capability  The capability as a number. Same as the pinMode setting in setPinMode().
		 */
		public function isCapabilityOfAnalogPin( pinNr : uint , capability : uint )  : Boolean
		{
			return _lowLevelArduino.isCapabilityOfAnalogPin( pinNr, capability );
		}


		/**
		 * Returns true if a certain pin has a certain capability
		 * 
		 * @param pinNr       The pin of which a pin capability is queried.
		 * @param capability  The capability as a number. Same as the pinMode setting in setPinMode().
		 */
		public function isCapabilityOfPin( pinNr : uint , capability : uint )  : Boolean
		{
			return _lowLevelArduino.isCapabilityOfPin( pinNr , capability );
		}


		/**
		 * Sets analog pin reporting to a certain mode. See the firmata protocol for details.
		 * 
		 * @param pinNr  The analog pin number.
		 * @param mode   The mode as a number. Same as the pinMode setting in setMode().
		 */
		public function reportAnalogPin( pinNr : uint , mode : uint ) : void
		{
			_lowLevelArduino.reportAnalogPin( pinNr, mode );
		}


		/**
		 * Sets digital pin reporting on or off for a certain pin. Analog pins can also be set by their real (high) pin number.
		 * 
		 * @param pinNr  The digital pin number.
		 * @param mode   The mode as a number. Same as the pinMode setting in setMode().
		 */
		public function reportDigitalPinRange( pinNr : uint , isEnabled : Boolean ) : void
		{
			_lowLevelArduino.reportDigitalPinRange( pinNr / 8 , isEnabled );
		}


		/**
		 * Sets a specific pin to a certain mode. Analog pins can also be set by their real (high) pin number.
		 * 
		 * @param pinNr    The pin number
		 * @param pinMode  The mode as a number (INPUT/OUTPUT/ANALOG/PWM/SERVO, 0/1/2/3/4) See firmata protocol and Firmata.as for details
		 */
		public function setPinMode( pinNr : uint , pinMode : Number ) : void
		{
			_lowLevelArduino.setPinMode( pinNr , pinMode );
		}


		/**
		 * Sets a pin to servo mode and sets up the servo parameters.
		 * 
		 * @param pinNr     The pin number.
		 * @param angle     The initial angle.
		 * @param minPulse  The minimum pulse. Determines the slowest movements.
		 * @param maxPulse  The initial angle. Determines the fastest movements.
		 */
		public function setupServo( pinNr : uint , angle : uint , minPulse : uint = 544, maxPulse : uint = 2400 ) : void
		{
			_lowLevelArduino.setupServo( pinNr , angle , minPulse , maxPulse );
		}


		/**
		 * Returns the value of a analog input. Values range between 0 and 1023. The pinNr values range between 0 and 6.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be read. Between 0 and 6
		 */
		public function readAnalog( pinNr : uint ) : uint
		{
			return _lowLevelArduino.readAnalog( pinNr );
		}


		/**
		 * Requests and returns the value of a digital input. The pin must be configured as digitalIn. Returns a boolean (true/false).
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be read. Between 2 and 13 for normal and between 2-53 for ArduinoMega.
		 */
		public function readDigital( pinNr : uint ) : Boolean
		{
			return _lowLevelArduino.readDigital( pinNr );
		}


		/**
		 * Sets an output to a boolean. The pin must be configured as digitalOut. True means ~5V (40 mA) out and false ~0V.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be read. Between 2 and 13 for normal and between 2-53 for ArduinoMega.
		 */
		public function writeDigital( pinNr : uint, isOn : Boolean ) : void
		{
			_lowLevelArduino.writeDigital( pinNr , isOn );
		}


		/**
		 * Writes a value (0-255) to a pwm output. The pin must be configured as pwmOut.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be set. Must be 3, 5, 6, 9, 10 or 11. The Arduino mega and others have different configurations.
		 */
		public function writePWM( pinNr : uint, value : uint ) : void
		{
			Assert.isTrue( value < 256 , "Value too large, maximum 255 for PWM" );

			_lowLevelArduino.writeAnalogPin( pinNr, value );
		}


		/**
		 * Writes a brightness value to a pwm output. The pin must be configured as pwmOut. The brightness (0-255) is a converted to appear linear for a human.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be set. Must be 3, 5, 6, 9, 10 or 11.
		 */
		public function writeLed( pinNr : uint, value : uint ) : void
		{
			Assert.isTrue( value < 256 , "Value too large, maximum 255 for Led" );

			_lowLevelArduino.writeAnalogPin( pinNr, _value2led_brightness[value] );
		}

		/**
		 * Writes a value (0-180) to a servo output. The pin must be configured as servo.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be set. Must be 9 or 10.
		 */
		public function writeServo( pinNr : uint, value : uint ) : void
		{
			Assert.isTrue( value <= 180 , "Value too large, maximum 180 for servo" );

			_lowLevelArduino.writeAnalogPin( pinNr, value );
		}


		/**
		 * @private
		 */
		// =====================
		// Socket event handlers
		// =====================
		private function onArduinoInitialized( event : ArduinoEvent )  : void
		{
			Assert.isTrue( event.currentTarget == _lowLevelArduino , "arduino event not for this low level Arduino" );

			dispatchEvent( new ArduinoEvent( ArduinoEvent.INITIALIZED , event.nrOfInitializations ) );
		}


		private function onArduinoDisconnected( event : ArduinoEvent ) : void
		{
			Assert.isTrue( event.currentTarget == _lowLevelArduino , "arduino event not for this low level Arduino" );

			dispatchEvent( new ArduinoEvent( ArduinoEvent.DISCONNECTED , event.nrOfInitializations ) );
		}
	}
}