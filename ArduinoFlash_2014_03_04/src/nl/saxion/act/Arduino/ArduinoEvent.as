/* ArduinoEvent.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.Arduino
{
	import flash.events.Event;

	/**
	 * The ArduinoEvent class is used to contain the event information about the Arduino is
	 * either initialized or disconnected. The ArduinoEvent stores the number of initializations.
	 */
	public class ArduinoEvent extends Event
	{
		public static const INITIALIZED  : String = "ArduinoEvent.INITIALIZED"  ;
		public static const DISCONNECTED : String = "ArduinoEvent.DISCONNECTED" ;

		private var _nrOfInitializations : uint;

		public function ArduinoEvent( arduinoEvent : String , nrOfInitializations : uint )
		{
			super( arduinoEvent );
			_nrOfInitializations = nrOfInitializations;
		}

		public override function clone() : Event
		{
			return new ArduinoEvent( type , _nrOfInitializations );
		}
		
		// ================
		// Public functions
		// ================
		/** The number of initialization since program start. A recovered connection counts as a reinitialization. */
		public function get nrOfInitializations() : uint { return _nrOfInitializations; }
	}
}
