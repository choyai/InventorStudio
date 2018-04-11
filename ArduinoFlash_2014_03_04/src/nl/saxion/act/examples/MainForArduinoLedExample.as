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
	import flash.utils.Timer;
	import flash.events.Event;
	import flash.events.TimerEvent
	import flash.events.IOErrorEvent;
	import flash.display.Sprite;
	import nl.saxion.act.Arduino.ArduinoController;
	
	import nl.saxion.act.utils.ErrorHandler;
	import nl.saxion.act.Arduino.Arduino;
	import nl.saxion.act.Arduino.ArduinoEvent;
	
	/**
	 * @private		for development in FlashDevelop only
	 * @author 		Douwe A. van Twillert
	 */
	
	public class MainForArduinoLedExample extends Sprite
	{
		public const       TICKS_PER_SECOND : uint =   50;
		public const MILLSECONDS_PER_SECOND : uint = 1000;


		// Change this array to the pin configuration you use in your own setup.
		// For the Arduine Mega, digital pin 14 till 53 are set as output.
		// Modify the array if you like to use them as inputs.
		private var pinConfiguration : Array = new Array(
			null, 		  // Pin 0   null (is RX)
			null, 		  // Pin 1   null (is TX)
			'digitalIn',  // Pin 2   digitalIn or digitalOut
			'digitalIn',  // Pin 3   pwmOut or digitalIn or digitalOut
			'digitalIn',  // Pin 4   digitalIn or digitalOut
			'digitalIn',  // Pin 5   pwmOut or digitalIn or digitalOut
			'digitalIn',  // Pin 6   pwmOut or digitalIn or digitalOut
			'digitalIn',  // Pin 7   digitalIn or digitalOut
			'digitalOut', // Pin 8   digitalIn or digitalOut
			'pwmOut',     // Pin 9   pwmOut or digitalIn or digitalOut or servo
			'pwmOut',     // Pin 10  pwmOut or digitalIn or digitalOut or servo
			'pwmOut',     // Pin 11  pwmOut or digitalIn or digitalOut
			'digitalOut', // Pin 12  digitalIn or digitalOut
			'digitalOut'  // Pin 13  digitalIn or digitalOut ( led connected )
		);
		
		// == VARIABLES =========================================================================
		private var arduino             : Arduino;
		private var arduinoController   : ArduinoController;
		private var timer               : Timer  = new Timer( MILLSECONDS_PER_SECOND / TICKS_PER_SECOND );
		private var smoothFactor        : Number = 0.99;
		private var tickCounter         : uint   = 0;
		private var ledBrightness       : uint   = 0;

		public function MainForArduinoLedExample()
		{
			ErrorHandler.registerErrorHandlers( this );
			initialize();
		}


		private function initialize() : void
		{
			arduino           = new Arduino( pinConfiguration );
			arduinoController = new ArduinoController( timer, TimerEvent.TIMER );
			arduinoController.addArduino ( arduino );
			arduinoController.addListener( onTick  );
			timer.start();
		}


		private function onTick( event : Event ) : void
		{
			readArduinoInputs();
			processData();
			writeArduinoOutputs();
		}


		private function readArduinoInputs() : void
		{
		}


		private function processData() : void
		{
			tickCounter++;
			ledBrightness = ( ledBrightness + 5 ) % 510;
		}


		private function writeArduinoOutputs() : void
		{
			arduino.writeLed(  9 , Math.abs( 255 - ledBrightness ) );
			arduino.writePWM( 10 , Math.abs( 255 - ledBrightness ) );
			arduino.writeLed( 11 , Math.abs( ledBrightness - 255 ) );
			arduino.writeDigital(  13 , tickCounter % 2 == 1 );
		}


		public function applySmoothening( oldValue : Number , newValue : Number , factor : Number ) : Number
		{
			return factor * oldValue + ( 1 - factor ) * newValue;
		}
	}
}

