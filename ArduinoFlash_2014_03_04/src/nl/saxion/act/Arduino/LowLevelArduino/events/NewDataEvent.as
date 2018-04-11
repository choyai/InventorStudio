/* NewDataEvent.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */

package nl.saxion.act.Arduino.LowLevelArduino.events
{
	import flash.events.Event;

	/**
	 * The LowLevelArduinoNewDataEvent class is used to signal new data event information.
	 * The ArduinoEvent stores the pin number and the new value
	 */
	public class NewDataEvent extends Event
	{
		public static const NEW_ANALOG_DATA  : String = "NewDataEvent_NEW_ANALOG_DATA"  ;
		public static const NEW_DIGITAL_DATA : String = "NewDataEvent_NEW_DIGITAL_DATA" ;

		private var _pin   : int;
		private var _value : int;

		public function NewDataEvent( type : String , pin : uint , value : uint )
		{
			super( type );
			_pin   = pin;
			_value = value;
		}

		public override function clone() : Event
		{
			return new NewDataEvent( type, _pin, _value );
		}

		// ================
		// Public functions
		// ================
		public function get pin()   : uint { return _pin;   }
		public function get value() : uint { return _value; }
	}
}
