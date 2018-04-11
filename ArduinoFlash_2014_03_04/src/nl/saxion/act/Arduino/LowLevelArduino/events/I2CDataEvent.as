/* I2CDataEvent.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Kasper Kamperman      - Art & Technology, Saxion
 *                      Douwe A. van Twillert - Art & Technology, Saxion
 */

package nl.saxion.act.Arduino.LowLevelArduino.events
{
	import flash.events.Event;

	/**
	 * The I2CDataEvent class is used to signal new data event information.
	 * The ArduinoEvent stores the pin number and the new value
	 */
	public class I2CDataEvent extends SysexEvent 
	{
		public static const I2C_DATA_MESSAGE   : String = "LowLevelArduinoI2CDataEvent.i2C_DATA_MESSAGE";

		protected var _address  : uint;
		protected var _register : uint;

		public function I2CDataEvent( type : String , command : uint , address : uint , register : uint, data : Array )
		{
			super( type, command, null, data );
			_address  = address;
			_register = register;
		}

		public override function clone() : Event
		{
			return new I2CDataEvent( type , _command , _address , _register , _data );
		}

		// ================
		// Public functions
		// ================
		public function get address()  : uint { return _address;  }
		public function get register() : uint { return _register; }

		override public function toString() : String
		{
			return super.toString() + ", address=" + address + ", register=" + register + ", data=" + data;
		}
	}
}
