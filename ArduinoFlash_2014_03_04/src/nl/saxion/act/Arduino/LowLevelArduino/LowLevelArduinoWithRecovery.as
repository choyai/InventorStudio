/* LowLevelArduinoWithRecovery.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


 package nl.saxion.act.Arduino.LowLevelArduino
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.events.IOErrorEvent;

	import flash.utils.Timer;
	

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
	 public class LowLevelArduinoWithRecovery extends LowLevelArduino
	{
		private const WATCHDOG_TIMER_INTERVAL            : uint = 167;  // milliseconds to wait for live check
		private const MAX_WATCHDOG_REINIT_INTERVAL_COUNT : int =   53;
		private const MAX_WATCHDOG_LIVE_INTERVAL_COUNT   : int =   59;


		private var _watchdogTimer               : Timer = new Timer( WATCHDOG_TIMER_INTERVAL );
		private var _watchdogTimerCount          : int;
		private var _isDisableReportingOnConnect : Boolean;


		/**
		 * Constructor. You must specify the pin configuration and can specify the tcp port and if it is an Arduino Mega
		 *
		 * @param pinConfiguration  Array with pin configuration, first two are null, others are { pwmOut or digitalIn or digitalOut or servo }
		 * @param tcpPort         	The tcp port to listen to, see also the as2arduinoGlue configuration file
		 * @param isArduinoMega     Whether or not this Arduino is a Mega arduino with more in/outputs.
		 */
		public function LowLevelArduinoWithRecovery( pinConfiguration : Array , tcpPort : uint = 5331 , host : String = "localhost" , isDisableReportingOnConnect : Boolean = true )
		{
			super( pinConfiguration , tcpPort , host );
			_isDisableReportingOnConnect = isDisableReportingOnConnect;

			// listen for connection
			_watchdogTimer.addEventListener(   TimerEvent.TIMER    , watchLiveConnection );
			               addEventListener(        Event.CONNECT  , onSocketConnect     );
			               addEventListener(        Event.CLOSE    , onSocketClose       );
			               addEventListener( IOErrorEvent.IO_ERROR , errorHandler        );
			startWatchdogTimer();
		}


		/**
		 * @private
		 */
		// ======================
		// Arduino event handlers
		// ======================
		public override function analog_IO_MessageReceived( pin : uint, newValue : uint )  : void
		{
			super.analog_IO_MessageReceived( pin, newValue );

			if ( isProperlyInitializedAndConnected ) {
				startWatchdogTimer();
			}
		}


		public override function digital_IO_MessageReceived( channel : uint, newValue : uint ) : void
		{
			super.digital_IO_MessageReceived( channel, newValue );

			if ( isProperlyInitializedAndConnected ) {
				startWatchdogTimer();
			}
		}


		public override function queryFirmwareReceived( majorVersion : uint, minorVersion : uint ) : void
		{
			super.queryFirmwareReceived( majorVersion , minorVersion );

			startWatchdogTimer();
		}


		public override function sysexStringReceived( command : uint , message : String ) : void
		{
			super.sysexStringReceived( command , message );

			startWatchdogTimer();
		}


		public override function sysexDataReceived( command : uint , data : Array ) : void
		{
			super.sysexDataReceived( command , data );
			
			startWatchdogTimer();
		}


		public override function unknownCommandReceived( command : uint ) : void
		{
			trace( "unknown command received: command="  + command );
			//dispatchEvent( new LowLevelArduinoUnknownCommandEvent( LowLevelArduinoUnknownSysexCommandEvent.ARDUINO_NEW_ANALOG_DATA , command , message ) );
			if ( isProperlyInitializedAndConnected ) {
				watchLiveConnection( null );
			}
			startWatchdogTimer();
		}


		public override function unknownSysexCommandReceived( command : uint , data : Array ) : void
		{
			trace( "unknown sysex command received: command="  + command + " data='"  + data.toString(16) + "'" );
			//dispatchEvent( new LowLevelArduinoUnknownSysexCommandEvent( LowLevelArduinoUnknownSysexCommandEvent.ARDUINO_NEW_ANALOG_DATA , command , message ) );

			if ( isProperlyInitializedAndConnected ) {
				watchLiveConnection( null );
			}
			startWatchdogTimer();
		}


		public override function pinCapabilitiesReceived( nrOfAnalogPins : uint , nrOfDigitalPins : uint , pinCapabilities : Array ) : void
		{
			if ( waitForFirmware == false ) {
				super.pinCapabilitiesReceived( nrOfAnalogPins , nrOfDigitalPins , pinCapabilities );

				startWatchdogTimer();
			}
		}


		public override function pinStateResponseReceived( pin : uint , state : uint , value : uint ) : void {
			super.pinStateResponseReceived( pin , state , value );
			
			startWatchdogTimer();
		}


		// ==============
		// Event handlers
		// ==============
		protected override function errorHandler( errorEvent : IOErrorEvent ) : void
		{

			super.errorHandler( errorEvent );
			if ( isConnected ) {
				   startWatchdogTimer();
			}
		}


		protected override function onSocketConnect( event : Event ) : void
		{
			if ( _isDisableReportingOnConnect ) {
				for ( var i : int = 0 ; i < 16 ; i++ ) {
					_sender.reportAnalogPin( i , 0 );
					_sender.reportDigitalPort( i , false );
				}
			}
			super.onSocketConnect( event );

			startWatchdogTimer();
		}


		protected override function onSocketClose( event : Event ) : void
		{
			super.onSocketClose( event );
		}
	

		protected override function reconnect() : void
		{
			super.reconnect();
		}


		protected function watchLiveConnection( event : TimerEvent ) : void
		{
			if ( isProperlyInitializedAndConnected ) {
				//trace( "watchLiveConnection() : watchdogTimerCount=" + _watchdogTimerCount );
				if ( ++_watchdogTimerCount % MAX_WATCHDOG_LIVE_INTERVAL_COUNT == 0 ) {
					reconnect();
				}
			} else { // if ( isConnected == false || waitForFirmware ) {
				if ( ++_watchdogTimerCount % MAX_WATCHDOG_REINIT_INTERVAL_COUNT == 0 ) {
					reconnect();
				}
			}
		}


		// =================
		// Private functions
		// =================
		protected override function initialize() : void
		{
			super.initialize();
			startWatchdogTimer();
		}


		protected function startWatchdogTimer() : void
		{
			_watchdogTimer.reset();
			_watchdogTimer.start();
			if ( isConnected ) {
				_watchdogTimerCount = 0;
			}
		}
	}
}