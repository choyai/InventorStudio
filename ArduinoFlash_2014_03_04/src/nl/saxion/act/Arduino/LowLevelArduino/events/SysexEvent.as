/* SysexEvent.as
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
	public class SysexEvent extends Event
	{
		public static const SYSEX_DATA_MESSAGE   : String = "LowLevelArduinoSysexEvent.SYSEX_DATA_MESSAGE";
		public static const SYSEX_STRING_MESSAGE : String = "LowLevelArduinoSysexEvent.SYSEX_STRING_MESSAGE";

		protected var _command : int;
		protected var _string  : String;
		protected var _data    : Array;

		public function SysexEvent( type : String , command : int , string : String , data : Array )
		{
			super( type );
			_command = command;
			_string  = string;
			_data    = data;
		}

		public override function clone() : Event
		{
			return new SysexEvent( type, _command, _string, _data );
		}

		// ================
		// Public functions
		// ================
		public function get command() : uint   { return _command; }
		public function get string()  : String { return _string;  }
		public function get data()    : Array  { return _data;    }
	}
}
