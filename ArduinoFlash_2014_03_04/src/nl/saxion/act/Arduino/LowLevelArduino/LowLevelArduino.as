/* LowLevelArduino.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.Arduino.LowLevelArduino
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.EventDispatcher;

	import nl.saxion.act.Arduino.ArduinoEvent;
	import nl.saxion.act.utils.ArrayHelper;

	import nl.saxion.act.Arduino.LowLevelArduino.events.I2CDataEvent;
	import nl.saxion.act.Arduino.LowLevelArduino.events.NewDataEvent;
	import nl.saxion.act.Arduino.LowLevelArduino.events.PinStateEvent;
	import nl.saxion.act.Arduino.LowLevelArduino.events.SysexEvent;

	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.Firmata;
	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.FirmataReceiver;
	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.FirmataReceiverInterface;
	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.FirmataSender;

	import nl.saxion.act.utils.Assert;
	//import nl.saxion.act.utils.ClassInfo;     changed to make asDoc work as it incorrectly reported undefined due to only static method usage
	import nl.saxion.act.utils.ErrorHandler;


	/**
	 * The LowLevelArduino class sends and receives commands according to the Firmata V2.2 protocol.
	 * Works with a Arduino and the StandardFirmata firmware. It remembers the state
	 * of the pins, input and output values.
	 * Based on ideas from Erik Sjodin, eriksjodin.net Bjoern Hartmann, bjoern.org,
	 * Mochammad Effendi (Arduino Mega) and Kasper Kamperman
	 *
	 * @author Douwe A. van Twillert, Saxion
	 *
	 * TODO: CHECK if using analog pins as digital I/O (PORTC or PORT#=2) works.
	 */
	public class LowLevelArduino extends EventDispatcher implements FirmataReceiverInterface
	{
		protected var _sender            : FirmataSender;
		protected var _receiver          : FirmataReceiver;
	
		private var _nrOfInitializations : uint    = 0;
		private var _firmwareVersion     : uint;
		private var _firmwareVersionName : String;
		private var _firmwareName        : String;
		private var _nrOfDigitalPins     : uint    = 0;
		private var _nrOfAnalogPins      : uint    = 0;
		private var _hasBeenConnected    : Boolean = false;

		private var _pinCapabilities     : Array;
		private var _currentPinMode      : Array   = [];
		private var _pinConfiguration    : Array   = [];

		private var _analogInputData     : Array   = [ Firmata.MAX_NR_OF_PINS ];
		private var _analogOutputData    : Array   = [ Firmata.MAX_NR_OF_PINS ];
		private var _pwmOutputData       : Array   = [ Firmata.MAX_NR_OF_PINS ];
		private var _digitalInputData    : Array   = [ Firmata.MAX_CHANNELS   ];
		private var _digitalOutputData   : Array   = [ Firmata.MAX_CHANNELS   ];
		
		/**
		 * Constructor. You must specify the pin configuration and can specify the tcp port and if it is an Arduino Mega
		 *
		 * @param pinConfiguration  Array with pin configuration, first two are null, others are { pwmOut or digitalIn or digitalOut or servo }
		 * @param tcpPort         	The tcp port to listen to, see also the as2arduinoGlue configuration file
		 * @param isArduinoMega     Whether or not this Arduino is a Mega arduino with more in/outputs.
		 */
		public function LowLevelArduino( pinConfiguration : Array , tcpPort : uint = 5331 , host : String = "localhost"  )
		{
			ArrayHelper.initializeArray( _analogInputData,    0 );
			ArrayHelper.initializeArray( _analogOutputData,  -1 );  // an illegal value, so every first value is always written
			ArrayHelper.initializeArray( _pwmOutputData,      0 );
			ArrayHelper.initializeArray( _digitalInputData,   0 );
			ArrayHelper.initializeArray( _digitalOutputData,  0 );

			_pinConfiguration = pinConfiguration;
			
			_sender   = new FirmataSender  ( host    , tcpPort );
			_receiver = new FirmataReceiver( _sender , this    );

			// listen for connection
			_sender.socket.addEventListener(        Event.CONNECT  , onSocketConnect );
			_sender.socket.addEventListener(        Event.CLOSE    , onSocketClose   );
			_sender.socket.addEventListener( IOErrorEvent.IO_ERROR , errorHandler    );
			trace( "[Start new "+ nl.saxion.act.utils.ClassInfo.getClassName( this ) + "( host=" + host + " , port=" + tcpPort + " )]" );
		}


		// ================
		// Public functions
		// ================

		// Getters and setters
		                                                                                                                                 /** Returns <code>true</code> if the connected Arduino is an Mega arduino. */
		public function get isMega()                            : Boolean { return _nrOfDigitalPins == 54;                            }  /** Returns the firmware version in a single number (2.3 translates to 23). Can be 0 .*/
		public function get firmwareVersion()                   : uint    { return _firmwareVersion;                                  }  /** Returns the firmware version as a string. Can be <code>null</code>. */
		public function get firmwareVersionString()             : String  { return _firmwareVersionName;                              }  /** Returns the name of the firmware, can be <code>null</code> */
		public function get firmwareName()                      : String  { return _firmwareName;                                     }  /** Returns number of digital pins. */
		public function get nrOfDigitalPins()                   : uint    { return _nrOfDigitalPins;                                  }  /** Returns number of analog pins. */
		public function get nrOfAnalogPins()                    : uint    { return _nrOfAnalogPins;                                   }  /** Returns the total number of pins. Is the same as the sum of the number of analog and digital pins. */
		public function get nrOfPins()                          : uint    { return _nrOfDigitalPins + _nrOfAnalogPins;                }  /** Returns <code>true</code> if an Arduino is connected and <code>false</code> otherwise. */
		public function get isConnected()                       : Boolean { return _sender.isConnected;                               }  /** Returns <code>true</code> if an Arduino is or has been connected and <code>false</code> otherwise. */
		public function get hasBeenConnected()                  : Boolean { return _hasBeenConnected;                                 }  /** Returns <code>true</code> if an Arduino is connected and initialized and <code>false</code> otherwise. */
		public function get isProperlyInitializedAndConnected() : Boolean { return _firmwareVersion != 0 && _pinCapabilities != null; }


		/**
		 * Returns true if a certain pin has a certain capability.
		 * 
		 * @param pinNr       The pin number of which a pin capability is queried. Analog pins can also be queries by their real (high) pin number.
		 * @param capability  The capability as a number. Same as the pinMode setting in setMode().
		 */
		public function isCapabilityOfDigitalPin( pin : uint , capability : uint )  : Boolean {
			Assert.isTrue( pin < _nrOfDigitalPins , "pin (%1) must be less than maximum (%2)", pin , _nrOfDigitalPins );

			return isCapabilityOfPin( pin, capability );
		}


		/**
		 * Returns true if an analog pin has a specific capability.
		 * 
		 * @param pinNr       the analog pin number of which a pin capability is queried.
		 * @param capability  the capability as a number. Same as the pinMode setting in setPinMode().
		 */
		public function isCapabilityOfAnalogPin( pin : uint , capability : uint )  : Boolean {
			Assert.isTrue( pin < _nrOfAnalogPins , "pin (%1) must be less than maximum (%2)", pin , _nrOfAnalogPins );

			return isCapabilityOfPin( pin + _nrOfDigitalPins, capability );
		}


		/**
		 * Returns true if a certain pin has a specific capability.
		 * 
		 * @param pinNr       the pin of which a pin capability is queried.
		 * @param capability  the capability as a number. Same as the pinMode setting in setPinMode().
		 */
		public function isCapabilityOfPin( pin : uint , capability : uint )  : Boolean {
			Assert.isTrue( pin < nrOfPins, "pin (%1) must be less than maximum (%2)", pin , nrOfPins );
			Assert.isTrue( capability < Firmata.TOTAL_PIN_MODES , "capability (%1) must be less than maximum (%2)", capability , Firmata.TOTAL_PIN_MODES );

			return _pinCapabilities[ pin ][ capability ];
		}


		/**
		 * Sets analog pin reporting to a certain mode. See the firmata protocol for details.
		 * 
		 * @param pinNr  The analog pin number.
		 * @param mode   The mode as a number. Same as the pinMode setting in setMode().
		 */
		public function reportAnalogPin( pin : uint , mode : uint ) : void
		{
			Assert.isTrue(  pin <  16 || pin >= _nrOfDigitalPins, "pin (%1) must be between 0 and 15 or real analog pin mapping" , pin );
			Assert.isTrue( mode < 256 , "mode (%1) for pin (%2) must be between 0 and 255" , mode, pin );

			if ( isProperlyInitializedAndConnected ) {
				_sender.reportAnalogPin( pin, mode );
			}
		}


		/**
		 * Sets digital pin reporting on or off for a certain pin. Analog pins can also be set by their real (high) pin number.
		 * 
		 * @param pinNr  The digital pin number.
		 * @param mode   The mode as a number. Same as the pinMode setting in setMode().
		 */
		public function reportDigitalPinRange( port : uint , isEnabled : Boolean ) : void
		{
			Assert.isTrue( port < _nrOfDigitalPins , "port (%1) must be between 0 and maximum (%2)" , port , 15 );

			if ( isProperlyInitializedAndConnected ) {
				_sender.reportDigitalPort( port, isEnabled );
			}
		}


		/**
		 * Sets a specific pin to a certain mode. Analog pins can also be set by their real (high) pin number.
		 * 
		 * @param pinNr    The pin number.
		 * @param pinMode  The mode as a number (INPUT/OUTPUT/ANALOG/PWM/SERVO, 0/1/2/3/4) See firmata protocol and Firmata.as for details.
		 */
		public function setPinMode( pinNr : uint , pinMode : Number ) : void {
			Assert.isTrue(   pinNr < nrOfPins                , "pin (%1) must be between 0 and total number of pins (%2)", pinNr   , nrOfPins                );
			Assert.isTrue( pinMode < Firmata.TOTAL_PIN_MODES , "mode (%1) must be between 0 and maximum pin mode (%2)"   , pinMode , Firmata.TOTAL_PIN_MODES );

			if ( isProperlyInitializedAndConnected ) {
				if ( pinMode == Firmata.SERVO ) {
					_sender.setupServo    ( pinNr , 0 );
					_sender.writeAnalogPin( pinNr , 0 ); // write set start position to 0 otherwise it turns directly to 90 degrees.
				} else {
					_sender.setPinMode( pinNr , pinMode );
				}
			}
			_currentPinMode[ pinNr ] = pinMode;
			if ( pinNr >= _nrOfDigitalPins && pinMode == Firmata.ANALOG ) {
				reportAnalogPin( pinNr - _nrOfDigitalPins, Firmata.ENABLE );
			}
		}


		/**
		 * Sets a pin to servo mode and sets up the servo parameters.
		 * 
		 * @param pinNr     The pin number.
		 * @param angle     The initial angle.
		 * @param minPulse  The minimum pulse. Determines the slowest movements.
		 * @param maxPulse  The initial angle. Determines the fastest movements.
		 */
		public function setupServo( pin : uint , angle : uint , minPulse : uint = 544, maxPulse : uint = 2400 ) : void
		{
			Assert.isTrue( pin < _nrOfDigitalPins , "pin (%1) must be between 0 and max (%2)" , pin , _nrOfDigitalPins );
			Assert.isTrue( _currentPinMode[ pin ] == Firmata.SERVO , "pin (%1) must be configured as servo but was (%2)" , pin , _currentPinMode[ pin ] );

			if ( isProperlyInitializedAndConnected ) {
				// TODO, remember angle, minPulse and maxPulse
				_sender.setupServo( pin , angle , minPulse , maxPulse );
			}
		}


		/**
		 * Writes a value (0-255) to an PWM or servo output. The pin must be configured as PWM or SERVO.
		 *
		 * @param pinNr  Arduino pinNr number of the pinNr to be set. Must be 3, 5, 6, 9, 10 or 11 for an DueMilaNove or Uno. The Arduino mega and others have different configurations.
		 */
		public function writeAnalogPin( pinNr : uint , value : uint ) : void
		{
			Assert.isTrue( pinNr <= nrOfPins, "pin (%1) must be between 0 and max (%2)" , pinNr , nrOfPins );
			Assert.isTrue( _currentPinMode[ pinNr ] == Firmata.PWM || _currentPinMode[ pinNr ] == Firmata.SERVO ,
			               "pin (%1) must be configured as pwm or servo but was (%2=%3)" ,
						   pinNr , _currentPinMode[ pinNr ], Firmata.capability2string( _currentPinMode[ pinNr ] ) );

			if ( isProperlyInitializedAndConnected ) {
				// TODO, add timed writes (sometimes necessary)
				if ( _analogOutputData[ pinNr ] != value ) {
					_analogOutputData[ pinNr ] = value;
					//trace( "# write analog value " + value );
					if ( pinNr < Firmata.MAX_ANALOG_PIN ) {
						_sender.writeAnalogPin        ( pinNr, value );
					} else {
						_sender.extendedWriteAnalogPin( pinNr, value );
					}
				}
			}
		}

		/**
		 * Returns the value of a analog input. Values range between 0 and 1023. The pin values range between 0 and 6.
		 *
		 * @param pin  Arduino pin number of the pin to be read. Between 0 and 6
		 */
		public function readAnalog( pin : uint ) : uint
		{
			Assert.isTrue( pin < _nrOfAnalogPins , "pin (%1) larger than possible for this Arduino (%2)", pin, _nrOfAnalogPins - 1 );

			return _analogInputData[ pin ];
		}

		/**
		 * Requests and returns the value of a digital input. Must be configured as digitalIn. Returns a boolean (true/false).
		 *
		 * @param pin  Arduino pin number of the pin to be read. Between 2 and 13 for normal and between 2-53 for ArduinoMega.
		 */
		public function readDigital( pin : uint ) : Boolean
		{
			Assert.isTrue( pin <= nrOfPins, "pin (%1) must be between 0 and max (%2)" , pin , nrOfPins );
			
			var channel : int = pin >> 3 ;
			var mask    : int =   1 << ( pin % 8 ) ;

			return _digitalInputData[ channel ] &  mask ? true : false ;
		}

		/**
		 * Sets an output to a boolean. Must be configured as digitalOut. True means ~5V (40 mA) out and false ~0V.
		 *
		 * @param pin  Arduino pin number of the pin to be read. Between 2 and 13 for normal and between 2-53 for ArduinoMega.
		 */
		public function writeDigital( pin : uint, isOn : Boolean ) : void
		{
			Assert.isTrue( pin <= nrOfPins, "pin (%1) must be between 0 and max (%2)" , pin , nrOfPins );
			
			var channel : int = pin >> 3 ;
			var mask    : int =   1 << ( pin % 8 ) ;
			if ( isOn ) {
				_digitalOutputData[ channel ] |=  mask;
			} else {
				_digitalOutputData[ channel ] &= ~mask;
			}

			if ( isProperlyInitializedAndConnected ) {
				_sender.writeDigitalPins( channel , _digitalOutputData[ channel ] );
			}
		}


		/**
		 * Writes a value (0-255) to a pwm output. Must be configured as pwmOut.
		 *
		 * @param pin  Arduino pin number of the pin to be set. Must be 3, 5, 6, 9, 10 or 11.
		 */
		public function writeAnalog( pin : uint, value : uint ) : void
		{
			checkArduinoInitAndPinConfig( pin , _currentPinMode[ pin ] );
			if ( isProperlyInitializedAndConnected ) {
				_sender.writeAnalogPin( pin, value );
			}
			_pwmOutputData[ pin ] = value;
		}


		/**
		 * Sends a system reset request to the arduino.
		 */
		public function systemReset() : void
		{
			_sender.systemReset();
		}


		/**
		 * Sends an I2C write request to the Arduino.
		 *
		 * @param slaveAddress	the address which was set for the I2C device 
		 * @param data			the data to be writte nto the I2C device
		 */
		public function sendI2CwriteRequest( slaveAddress : uint , data : Array ) : void
		{
			_sender.sendI2CwriteRequest( slaveAddress , data );
		}


		/**
		 * Sends an I2C write request to the Arduino.
		 *
		 * @param slaveAddress		the address which was set for the I2C device 
		 * @param numberOfBytes		the number of bytes to be read
		 */
		public function sendI2CreadOnceRequest( slaveAddress : uint, numberOfBytes : uint ) : void
		{
			_sender.sendI2CreadOnceRequest( slaveAddress, numberOfBytes );
		}


		public function sendI2CreadContiniouslyRequest( slaveAddress : uint ) : void
		{
			_sender.sendI2CreadContiniouslyRequest( slaveAddress );
		}


		public function sendI2CstopReadingRequest( slaveAddress : uint ) : void
		{
			_sender.sendI2CstopReadingRequest( slaveAddress );
		}


		public function sendI2Cconfig( powerPinSetting : Boolean , delay : uint ) : void
		{
			_sender.sendI2Cconfig( powerPinSetting , delay );
		}


		public function setSamplingInterval( intervalInMilliseconds : uint ) : void
		{
			_sender.setSamplingInterval( intervalInMilliseconds );
		}


		/**
		 * @private functions
		 */
		// ==============
		// Event handlers
		// ==============
		public function analog_IO_MessageReceived( pin : uint, newValue : uint )  : void
		{
			var oldValue : uint = _analogInputData[ pin ];
			_analogInputData[ pin ] = newValue;
			if ( oldValue != newValue && isProperlyInitializedAndConnected  ) {
				dispatchEvent( new NewDataEvent( NewDataEvent.NEW_ANALOG_DATA , pin , newValue ) );
			}
		}


		public function digital_IO_MessageReceived( channel : uint, newValue : uint ) : void
		{
			var oldValue : uint = _digitalInputData[ channel ];
			_digitalInputData[ channel ] = newValue;
			
			for ( var channelPin : int = 0 ; channelPin < 8 ; channelPin++ ) {
				var mask : uint = 1 << channelPin;
				if ( ( oldValue & mask ) != ( newValue & mask ) && isProperlyInitializedAndConnected ) {
					if ( hasEventListener( NewDataEvent.NEW_DIGITAL_DATA ) ) {
						dispatchEvent( new NewDataEvent( NewDataEvent.NEW_DIGITAL_DATA , channel * 8 + channelPin , newValue & mask ? 1 : 0 ) );
					}
				}
			}
		}


		public function queryFirmwareReceived( majorVersion : uint, minorVersion : uint ) : void
		{
			if ( firmwareVersion == 0 )
				_sender.requestCapabilities();
			_firmwareVersion     = majorVersion * 10 + minorVersion;
			_firmwareVersionName = majorVersion + "." + minorVersion;
			
			Assert.isTrue( _firmwareVersion >= 20 , "Firmware version (%1), too low for this software, at least 2.0 expected", _firmwareVersionName );
		}


		public function queryFirmwareAndNameReceived( majorVersion : uint, minorVersion : uint , name : String ) : void
		{
			queryFirmwareReceived( majorVersion, minorVersion );
			_firmwareName = name;
		}


		public function I2CReplyReceived( address : uint , register : uint , data : Array ) : void
		{
			if ( hasEventListener( I2CDataEvent.I2C_DATA_MESSAGE ) ) {
				dispatchEvent( new I2CDataEvent( I2CDataEvent.I2C_DATA_MESSAGE , Firmata.I2C_REPLY , address , register , data ) );
			}
		}


		public function sysexStringReceived( command : uint , message : String ) : void
		{
			trace( "[Sysex string received: '"  + message + "']" );
			if ( hasEventListener( SysexEvent.SYSEX_STRING_MESSAGE ) ) {
				dispatchEvent( new SysexEvent( SysexEvent.SYSEX_STRING_MESSAGE , command , message , null ) );
			}
		}


		public function sysexDataReceived( command : uint , data : Array ) : void
		{
			trace( "[Sysex data received: data="  + data.toString(16) +"]");
			if ( hasEventListener( SysexEvent.SYSEX_DATA_MESSAGE ) ) {
				dispatchEvent( new SysexEvent( SysexEvent.SYSEX_DATA_MESSAGE , command , "" , data ) );
			}
		}


		public function unknownCommandReceived( command : uint ) : void
		{
			trace( "[unknown command received: command="  + command +"]");
			//dispatchEvent( new UnknownCommandEvent( UnknownSysexCommandEvent.ARDUINO_NEW_ANALOG_DATA , command , message ) );
		}


		public function unknownSysexCommandReceived( command : uint , data : Array ) : void
		{
			trace( "[unknown sysex command received: command="  + command + " data='"  + data.toString(16) + "']" );
			//dispatchEvent( new UnknownSysexCommandEvent( UnknownSysexCommandEvent.ARDUINO_NEW_ANALOG_DATA , command , message ) );
		}


		public function pinCapabilitiesReceived( nrOfAnalogPins : uint , nrOfDigitalPins : uint , pinCapabilities : Array ) : void
		{
			if ( waitForFirmware == false ) {
				_nrOfAnalogPins  = nrOfAnalogPins;
				_nrOfDigitalPins = nrOfDigitalPins;
				_pinCapabilities = pinCapabilities;
				initialize();
				if ( _firmwareVersion > 21 ) {
					for ( var i : int = 2 ; i < nrOfDigitalPins + nrOfAnalogPins ; i++ ) {
						_sender.requestPinState( i );
					}
				}
			}
		}


		public function pinStateResponseReceived( pin : uint , state : uint , value : uint ) : void
		{
			if ( isProperlyInitializedAndConnected ) {
				if ( pin >= _pinConfiguration.length && ( pin < _nrOfDigitalPins + _nrOfAnalogPins ) ) {
					_currentPinMode[ pin ] = state;
					// FIXME, value always seems to be 0, so don't overwrite previously stored values
					tracePinConfig( pin, Firmata.capability2string( state ) )
				}
				if ( hasEventListener( PinStateEvent.PIN_STATE_RECEIVED ) ) {
					dispatchEvent( new PinStateEvent( PinStateEvent.PIN_STATE_RECEIVED , pin , state , value ) );
				}
			}
		}


		// ===================
		// Protected functions
		// ===================
		// =====================
		// Socket event handlers
		// =====================
		protected function errorHandler( errorEvent : IOErrorEvent ) : void
		{
			if ( waitForFirmware && !isConnected ) {
				ErrorHandler.displayWarning( "- " + errorEvent.text + "\n*** Did you start a serial proxy? ***" );
			}
		}


		protected function onSocketConnect( event : Event ) : void
		{
			trace( "[Connected with Serproxy requesting firmware version]" );
			
			_hasBeenConnected = true;
			_sender.requestReportVersion();  // check for firmware version
		}


		protected function onSocketClose( event : Event ) : void
		{
			trace( "[Connection with Serproxy closed.]" );
			reconnect();
		}
	

		protected function reconnect() : void
		{
			trace( "[Arduino reinitialization attempt]" );
			_firmwareVersion = 0;
			_pinCapabilities = null;
			_sender.reconnect();
			if ( hasEventListener( ArduinoEvent.DISCONNECTED ) ) {
				dispatchEvent( new ArduinoEvent( ArduinoEvent.DISCONNECTED, _nrOfInitializations ) );
			}
		}


		// =================
		// Private functions
		// =================
		protected function initialize() : void
		{
			Assert.isTrue( waitForFirmware == false, "Oops, initializing, while still waiting for firmware response??" );

			trace( "[Connected to Arduino with Firmata version: " + firmwareVersionString + "]" );

			if ( _currentPinMode.length == nrOfPins ) {
				setRememberedPinModes();
			} else {
				assertAndAssignArduinoPinConfiguration();
			}
			turnOnAnalogAndDigitalPinReporting();

			if ( hasEventListener( ArduinoEvent.INITIALIZED ) ) {
				dispatchEvent( new ArduinoEvent( ArduinoEvent.INITIALIZED, ++_nrOfInitializations ) );
			}
		}


		protected function get waitForFirmware() : Boolean {
			return _firmwareVersion == 0;
		}


		private function assertAndAssignArduinoPinConfiguration() : void
		{
			Assert.isTrue( waitForFirmware == false, "Oops, initializing, while still waiting for firmware response??" );
			Assert.notNull( _pinConfiguration , "Illegal (null) pinConfiguration passed to new Arduino" );
			Assert.isTrue ( _pinConfiguration.length <= nrOfPins , "pin (%1) configuration too long for this Arduino (%2)", _pinConfiguration.length, nrOfPins  );

			trace( "Arduino pin configuration:" );
			for ( var i : int = 0 ; i < _pinConfiguration.length ; i++ ) {
				var capabilities : String = pinCapabilities2String( i );
				if ( capabilities == "" ) {
					Assert.isTrue( _pinConfiguration[ i ] == null ||  _pinConfiguration[ i ] == "", "pin (%1) has no capabilities (%2), use null or empty string", i, _pinConfiguration[ i ] );

					_currentPinMode[ i ] = -1;
				} else {
					Assert.isTrue( isCapabilityOfPin( i , _pinConfiguration[ i ] ), "pin (%1) is not properly configured (%2)", i, _pinConfiguration[ i ] );

					setPinMode( i , Firmata.pinConfig2firmataCommand( _pinConfiguration[ i ] ) );
				}
				tracePinConfig( i , _pinConfiguration[ i ] );
			}
			/* TODO check if this is still necessary
			for ( i =  _pinConfiguration.length ; i < nrOfPins ; i++ ) {
				var capabilities : String = pinCapabilities2String( i );
				if ( capabilities == "" ) {
					_currentPinMode[ i ] = -1;
				}
				tracePinConfig( i , "<no config>" );
			}*/
		}


		private function tracePinConfig( pin : uint, configuration : String ) : void
		{
			var capabilities : String = pinCapabilities2String( pin );
			if ( capabilities != "" ) {
				capabilities = "\t(possible modes=" + capabilities + ")";
			}
			//if ( isCapabilityOfPin( pin, Firmata.ANALOG ) )
			//	capabilities += "\t(currentValue = " +  readAnalog( realPinToAnalogPin( pin ) ) + ")";
			//else
			//	capabilities += "\t(currentValue = " + readDigital( pin                       ) + ")";
				
			trace( "    pin " + pin + " -> " + configuration + "\t" + capabilities );
		}


		private function pinCapabilities2String( pin : uint ) : String
		{
			var capabilities : String = "";

			for ( var capability : uint = 0 ; capability < Firmata.TOTAL_PIN_MODES ; capability++ ) {
				if ( ( pin < _nrOfDigitalPins + _nrOfAnalogPins ) && _pinCapabilities[ pin ][ capability ] ) {
					capabilities = capabilities + ( capabilities.length == 0 ? "" : ", " ) + Firmata.capability2string( capability );
					if ( _pinCapabilities[ pin ][ capability ] > 1 )
						capabilities = capabilities + "(" + _pinCapabilities[ pin ][ capability ] + ")"
				}
			}

			return capabilities;
		}
	

		private function setRememberedPinModes() : void
		{
			for ( var i : int = 0 ; i < _currentPinMode.length ; i++ )	{
				if ( _currentPinMode[ i ] && _currentPinMode[ i ] != -1 ) {
					setPinMode( i, _currentPinMode[ i ] );
				}
			}
		}


		private function checkArduinoInitAndPinConfig( pin : int , pinType : int ) : void
		{
			Assert.notNull( _pinCapabilities                  , "Arduino is not (yet) initialized or disconnected, use ArduinoEvent" );
			Assert.isTrue ( pin < _nrOfDigitalPins            , "pin (%1) larger than possible for this Arduino (%2)", pin, _nrOfDigitalPins );
			Assert.isTrue ( _currentPinMode[ pin ] == pinType , "pin (%1) not configured for (%2) but for (%3)"      , pin, pinType, _currentPinMode[ pin ] );
		}


		private function turnOnAnalogAndDigitalPinReporting() : void
		{
			Assert.isTrue( isProperlyInitializedAndConnected , "Oops, already initializing while still waiting for firmware response??" );

			for ( var pin : int = 0 ; pin < _nrOfAnalogPins ; pin++ ) {
				_sender.reportAnalogPin( pin, Firmata.ENABLE );
			}

			for( var port : int = analogPinToRealPin( _nrOfAnalogPins  - 1) / 8 ; port >= 0 ; port-- ) {
				_sender.reportDigitalPort( port, true );
			}
		}
		
		protected function analogPinToRealPin( analogPin : uint ) : uint {
			Assert.isTrue( _nrOfAnalogPins > analogPin , "analogPin (%1) too large for nrOfAnalogPins(%2)" , analogPin, _nrOfAnalogPins );
			Assert.isTrue( _nrOfDigitalPins > 0 , "no digital pins" );

			return _nrOfDigitalPins + analogPin;
		}

		protected function realPinToAnalogPin( realPin : uint ) : uint {
			Assert.isTrue( realPin <= nrOfPins        , "realPin (%1) must be between %2 and max (%3)"   , realPin, _nrOfDigitalPins, nrOfPins );
			Assert.isTrue( realPin >=_nrOfDigitalPins , "realPin (%1) too small for nrOfDigitalPins(%2)" , realPin, _nrOfDigitalPins           );

			return realPin - _nrOfDigitalPins;
		}
	}
}