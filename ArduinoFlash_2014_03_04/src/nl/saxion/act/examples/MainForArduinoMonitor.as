/*
   Flash - Arduino Example script

   version 1.2 : 22-may-201

   copyleft : Douwe A. van Twillert - Saxion / ACT

   Example script for ACT_Arduino use. Shows almost all methods from the
   new ACT_Arduino except for the servo motor. writeServe is the same as
   writePWM with a restricted range (0-179)
*/

package nl.saxion.act.examples
{
	import flash.events.Event;
	import flash.display.Sprite;
	
	import nl.saxion.act.utils.ErrorHandler;

	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduinoWithRecovery;
	import nl.saxion.act.Arduino.monitor.ArduinoMonitor;

	
	
	/**
	 * @private		for development in FlashDevelop only
	 * @author 		Douwe A. van Twillert
	 */
	
	public class MainForArduinoMonitor extends Sprite
	{
		// Change this array to the pin configuration you use in your own setup.
		// Digital pin 14 till 53 are set as output directly in arduino for-loop.
		// if you want to change them, add them to this array.
		private var pinConfiguration : Array = new Array(
		    null, 		// Pin 0   null (is RX)
			null        // Pin 1   null (is TX)
		);
		
		// == VARIABLES =========================================================================
		private var arduino          : LowLevelArduino;
		private var monitor          : ArduinoMonitor;


		public function MainForArduinoMonitor()
		{
			ErrorHandler.registerErrorHandlers( this );
			trace( "start of init" );
			arduino = new LowLevelArduinoWithRecovery( pinConfiguration );
			if ( stage != null )
				initialize();
			else
				addEventListener( Event.ADDED_TO_STAGE, initialize );
		}

		private function initialize() : void
		{
			removeEventListener( Event.ADDED_TO_STAGE, initialize );

			monitor = new ArduinoMonitor( arduino, pinConfiguration );
			addChild( monitor );
		}
	}
}
