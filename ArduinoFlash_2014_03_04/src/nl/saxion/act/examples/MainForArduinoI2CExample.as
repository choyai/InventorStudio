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
	import flash.display.Sprite;

	import flash.utils.Timer;

	import flash.events.Event;
	import flash.events.TimerEvent;

	import nl.saxion.act.Arduino.ArduinoEvent;
	import nl.saxion.act.Arduino.LowLevelArduino.events.I2CDataEvent;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduinoWithRecovery;
	import nl.saxion.act.Arduino.ArduinoController;

	import nl.saxion.act.utils.Assert;
	import nl.saxion.act.utils.ErrorHandler;
	
	
	/**
	 * @private		for development in FlashDevelop only
	 * @author 		Douwe A. van Twillert
	 */
	
	public class MainForArduinoI2CExample extends Sprite
	{
		public const       TICKS_PER_SECOND : uint =   20;
		public const MILLSECONDS_PER_SECOND : uint = 1000;


		// Change this array to the pin configuration you use in your own setup.
		// For the Arduin0 Mega, digital pin 14 till 53 are set as output.
		// Modify the array if you like to use them as inputs.
		private var pinConfiguration : Array = new Array(
			null, 		   // Pin 0   null (is RX)
			null, 		   // Pin 1   null (is TX)
			'digitalOut',  // Pin 2   digitalIn or digitalOut
			'digitalOut',  // Pin 3   pwmOut or digitalIn or digitalOut
			'digitalOut',  // Pin 4   digitalIn or digitalOut
			'digitalOut',  // Pin 5   pwmOut or digitalIn or digitalOut
			'digitalOut',  // Pin 6   pwmOut or digitalIn or digitalOut
			'digitalOut',  // Pin 7   digitalIn or digitalOut
			'digitalOut',  // Pin 8   digitalIn or digitalOut
			'digitalOut',  // Pin 9   pwmOut or digitalIn or digitalOut or servo
			'digitalOut',  // Pin 10  pwmOut or digitalIn or digitalOut or servo
			'digitalOut',  // Pin 11  pwmOut or digitalIn or digitalOut
			'digitalOut',  // Pin 12  digitalIn or digitalOut
			'digitalOut',  // Pin 13  digitalIn or digitalOut ( led connected )
			'analogIn',    // Pin 14  (==Analog 0)
			'digitalOut',  // Pin 15  (==Analog 1)
			'digitalOut',  // Pin 16  (==Analog 2)
			'digitalOut',  // Pin 17  (==Analog 3)
			'i2c',         // Pin 18  (==Analog 4)
			'i2c'          // Pin 19  (==Analog 5)
		);
		
		// == VARIABLES =========================================================================
		private var lowLevelArduino        : LowLevelArduino;
		private var arduinoController      : ArduinoController;
		
		private var timer                  : Timer;
		private var tickCounter            : uint    = 0;

		private var distance               : int     = -1;
		private var tickToSendRangeRequest : int     = -1;
		
		private var isWithin1MeterRange    : Boolean = true;


		public function MainForArduinoI2CExample()
		{
			ErrorHandler.registerErrorHandlers( this );
			initialize();
		}

		private function initialize() : void
		{
			timer = new Timer( MILLSECONDS_PER_SECOND / TICKS_PER_SECOND )
			lowLevelArduino = new LowLevelArduinoWithRecovery( pinConfiguration );
			arduinoController = new ArduinoController( timer, TimerEvent.TIMER );
			arduinoController.addLowLevelArduino( lowLevelArduino );
			arduinoController.addListener( onTick  );
			lowLevelArduino.addEventListener( I2CDataEvent.I2C_DATA_MESSAGE, onI2CDataAvailable   );
			lowLevelArduino.addEventListener( ArduinoEvent.INITIALIZED,      onArduinoInitialized );

			// For debugging purposes
			//addChild( new ArduinoMonitor( lowLevelArduino ) );
			timer.start();
		}


		private function onArduinoInitialized( event : Event ) : void
		{
			trace( "I2Cconfig" );
			lowLevelArduino.sendI2Cconfig( false, 70 );
			lowLevelArduino.setSamplingInterval( 1000 );
		}


		private function onI2CDataAvailable( event : I2CDataEvent ) : void
		{
			Assert.isTrue( event.address == I2Caddress , "Event from i2c device on other address (%1) received, expected (%2)" , event.address     , I2Caddress );
			Assert.isTrue( event.data.length >= 2      , "Event data too short (%1) expected 2"                                , event.data.length              );

			distance = 256 * event.data[0] + event.data[1];
			trace( "distance=" + distance );
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
			if ( tickCounter % 10 == 9 ) {
				tickToSendRangeRequest = tickCounter;
			}
			if ( distance > 0 && distance < 100 ) {
				isWithin1MeterRange = true
			} else {
				isWithin1MeterRange = false;
			}
		}


		private static const I2Caddress : uint = 0x70;
		private static const I2Ccommand : uint = 0x00;
		private static const rangeInCm  : uint = 0x51;
		private static const readRange  : uint = 0x02;
		
		private static var I2Crequest_rangeInCm : Array = [ I2Ccommand , rangeInCm ];
		private static var I2Crequest_readRange : Array = [ readRange ];

		private function writeArduinoOutputs() : void
		{
			if ( tickToSendRangeRequest == tickCounter ) {
				lowLevelArduino.sendI2CwriteRequest   ( I2Caddress, I2Crequest_rangeInCm );
			} else if ( ( tickToSendRangeRequest + 1 ) == tickCounter ) {
				lowLevelArduino.sendI2CwriteRequest   ( I2Caddress, I2Crequest_readRange );
				lowLevelArduino.sendI2CreadOnceRequest( I2Caddress, 2 );
			}
			lowLevelArduino.writeDigital( 13, isWithin1MeterRange );
		}
	}
}