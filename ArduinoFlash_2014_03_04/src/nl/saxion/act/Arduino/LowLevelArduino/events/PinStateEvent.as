/* PinStateEvent.as
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
	public class PinStateEvent extends Event
	{
		public static const PIN_STATE_RECEIVED  : String = "PinStateEvent.PIN_STATE_RECEIVED"  ;

		private var _pin   : int;
		private var _state : int;
		private var _value : int;

		public function PinStateEvent( type : String , pin : uint , state : uint , value : uint )
		{
			super( type );
			_pin   = pin;
			_state = state;
			_value = value;
		}

		public override function clone() : Event
		{
			return new PinStateEvent( type , _pin , _state , _value );
		}

		// ================
		// Public functions
		// ================
		public function get pin()   : uint { return _pin;   }
		public function get state() : uint { return _state; }
		public function get value() : uint { return _value; }

		public override function toString() : String
		{
			return super.toString() + " pin=" + pin + " state=" + state + " value=" + value;
		}
	}
}
