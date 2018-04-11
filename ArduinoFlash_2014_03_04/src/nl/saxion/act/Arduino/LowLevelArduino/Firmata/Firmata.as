/* Firmata.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.Arduino.LowLevelArduino.Firmata
{
	/**
	 * Class that holds all firmate constant command codes according to the firmata V2 protocol.
	 * @author Douwe A. van Twillert, Saxion
	 */
	 public class Firmata
	 {
		// =========
		// Constants
		// =========

		// firmata messages, details from http://firmata.org/wiki/V2.2ProtocolDetails
		// names and comments taken from Firmata.h
		public static const DIGITAL_MESSAGE               : int = 0x90; // send data for a digital pin
		public static const REPORT_ANALOG                 : int = 0xC0; // enable analog input by pin #
		public static const REPORT_DIGITAL                : int = 0xD0; // enable digital input by port pair
		public static const ANALOG_MESSAGE                : int = 0xE0; // send data for an analog pin (or PWM)
		
		public static const SET_PIN_MODE                  : int = 0xF4; // set a pin to INPUT/OUTPUT/PWM/etc
		
		public static const REPORT_VERSION                : int = 0xF9; // report protocol version
		public static const SYSTEM_RESET                  : int = 0xFF; // reset from MIDI

		public static const SYSEX_START		              : int = 0xF0; // start a MIDI Sysex message
		public static const SYSEX_END		              : int = 0xF7; // end a MIDI Sysex message

		// sysex commands
		public static const ANALOG_MAPPING_QUERY          : int = 0x69 // ask for mapping of analog to pin numbers
		public static const ANALOG_MAPPING_RESPONSE       : int = 0x6A // reply with mapping info
		public static const CAPABILITY_QUERY              : int = 0x6B // ask for supported modes and resolution of all pins
		public static const CAPABILITY_RESPONSE           : int = 0x6C // reply with supported modes and resolution
		public static const PIN_STATE_QUERY               : int = 0x6D // ask for a pin's current mode and value
		public static const PIN_STATE_RESPONSE            : int = 0x6E // reply with pin's current mode and value
		public static const EXTENDED_ANALOG               : int = 0x6F // analog write (PWM, Servo, etc) to any pin
		public static const SERVO_CONFIG                  : int = 0x70 // set max angle, minPulse, maxPulse, freq
		public static const STRING_DATA                   : int = 0x71 // a string message with 14-bits per char
		public static const SHIFT_DATA                    : int = 0x75 // a bitstream to/from a shift register
		public static const I2C_REQUEST                   : int = 0x76 // send an I2C read/write request
		public static const I2C_REPLY                     : int = 0x77 // a reply to an I2C read request
		public static const I2C_CONFIG                    : int = 0x78 // config I2C settings such as delay times and power pins
		public static const REPORT_FIRMWARE               : int = 0x79 // report name and version of the firmware
		public static const SAMPLING_INTERVAL             : int = 0x7A // set the poll rate of the main loop
		public static const SYSEX_NON_REALTIME            : int = 0x7E // MIDI Reserved for non-realtime messages
		public static const SYSEX_REALTIME                : int = 0x7F // MIDI Reserved for realtime messages

		// pin modes
		public static const INPUT                         : int = 0x00 // pin in Input mode
		public static const OUTPUT                        : int = 0x01 // pin in Output mode
		public static const ANALOG                        : int = 0x02 // analog pin in analogInput mode
		public static const PWM                           : int = 0x03 // digital pin in PWM output mode
		public static const SERVO                         : int = 0x04 // digital pin in Servo output mode
		public static const SHIFT                         : int = 0x05 // shiftIn/shiftOut mode
		public static const I2C                           : int = 0x06 // pin included in I2C setup
		public static const TOTAL_PIN_MODES               : int = 7;

		public static const ENABLE                        : int = 1;
		public static const DISABLE                       : int = 0;

		// protocol details, depending on how many bits/bytes are used for pins, ports etc.
		public static const MAX_CHANNELS                  : uint = 1 <<  3;
		public static const MAX_NR_OF_PINS                : uint = 1 <<  8;
		public static const MAX_ANALOG_DATA               : uint = 1 << 14;  // TODO, use the retrieved precision
		public static const MAX_ANALOG_PIN                : uint = 15;

		// IC2 constants
		public static const I2C_10_BITS_ADDRESS_MODE      : uint =  1 << 5;
		public static const I2C_REQUEST_WRITE             : uint = 00 << 3;
		public static const I2C_REQUEST_READ_ONCE         : uint = 01 << 3;
		public static const I2C_REQUEST_READ_CONTINUOUSLY : uint = 10 << 3;
		public static const I2C_REQUEST_STOP_READING      : uint = 11 << 3;


		// ================
		// Public functions
		// ================
		public static function pinConfig2firmataCommand( type : String ) : int
		{
			switch( type ) {
				case "digitalIn"  : return INPUT  ; break;
				case "analogIn"   : return ANALOG ; break;
				case "digitalOut" : return OUTPUT ; break;
				case "pwmOut"     : return PWM    ; break;
				case "servo"      : return SERVO  ; break;
				case "i2c"        : return I2C    ; break;
			}
			return -1;
		}
	
		public static function capability2string( capabilityNr : int ) : String
		{
			switch( capabilityNr ) {
				case INPUT  : return "digitalIn"  ; break;
				case ANALOG : return "analogIn"   ; break;
				case OUTPUT : return "digitalOut" ; break;
				case PWM    : return "pwmOut"     ; break;
				case SERVO  : return "servo"      ; break;
				case SHIFT  : return "shift"      ; break;
				case I2C    : return "i2c"        ; break;
			}
			return "<no defined capability for (" + capabilityNr + ")>";
		}
	 }
}