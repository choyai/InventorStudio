/* ArduinoMonitor.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2011   Kasper Kamperman      - Art & Technology
 *               2013   Douwe A. van Twillert - Art & Technology
 */

 
package  nl.saxion.act.Arduino.monitor
{	/* Monitor object
       Problem switch servo - pwm doesn't work without restarting.
	*/
	
	import flash.utils.Timer;
	import flash.events.TimerEvent;

	import flash.text.TextField;
	import flash.events.Event;
	import flash.display.MovieClip;

	import fl.controls.TextArea;
	import fl.controls.ScrollPolicy;
	
	import com.bit101.components.Style;
	import com.bit101.components.ScrollPane;

	import nl.saxion.act.Arduino.ArduinoEvent;

	import nl.saxion.act.Arduino.monitor.PinConfigObj;
	import nl.saxion.act.Arduino.monitor.PinMonitorObj;

	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduinoWithRecovery;

	import nl.saxion.act.Arduino.LowLevelArduino.events.*;
	
	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.Firmata;
	import flash.text.TextFormat;


	public class ArduinoMonitor extends MovieClip
  	{
		// =========
		// Constants
		// =========
		public const       TICKS_PER_SECOND : uint =  20;
		public const MILLSECONDS_PER_SECOND : uint = 1000;
		public const BACKGROUND             : uint = 0x081272;
		public const FOREGROUND             : uint = 0x000000;


		// =========
		// Variables
		// =========
		private var _arduino                     : LowLevelArduino;
		private var _timer                       : Timer      = new Timer( MILLSECONDS_PER_SECOND / TICKS_PER_SECOND );
		private var _numEvents                   : uint       = 0;
		private var _logTextLines                : uint       = 2;
		private var _loggingTextArea             : TextArea;
		private var _scrollPane                  : ScrollPane = null;
		private var _configObjects               : Array = [];
		private var _monitorObjects              : Array = [];
		private var _waveMonitorOjects           : Array = [];
		private var _textFormat                  : TextFormat = new TextFormat();
		private var _firstTimeForSerProxyWarning : Boolean    = true;


		/**
		 * This is a class to ease monitoring inputs and controlling outputs for the Arduino.
		 * It uses the lowLevelArduino class to display the input/output status. It can also
		 * be used to add to the stage/sprite as a debbuging tool while developing.
		 *
		 * @author Kasper Kamperman / Douwe A. van Twillert, Saxion
		 *
		 * TODO: make i2c communicating pins show up properly.
		 */
		public function ArduinoMonitor( arduino : LowLevelArduino, defaultPinConfiguration : Array = null )
		{
			_arduino = arduino;

			setMinimalComponentsStyle();
			setTextFormat();
			addloggingTextArea();
			addCopyrightText();
			addWarningText();
			
			_timer = new Timer( 500, 2 );
			_timer.start();
			_timer.addEventListener( TimerEvent.TIMER_COMPLETE , checkForConnectedArduino );
	
			arduino.addEventListener( ArduinoEvent.INITIALIZED , onArduinoInitialized );
			addLineToLogArea( "Waiting for Arduino initialization" );
		}


		/**
		 * @private functions
		 */
		// ==============
		// Event handlers
		// ==============
		private function onTick( event : Event ) : void
		{
			for( var i : uint = 0; i < _arduino.nrOfAnalogPins; i++)
			{
				var analogPinNr : int = i + _arduino.nrOfDigitalPins;
				if (  _waveMonitorOjects[analogPinNr] ) {
					_waveMonitorOjects[analogPinNr].amplitude = _arduino.readAnalog( i );
					_waveMonitorOjects[analogPinNr].refreshPlot();
				}
			}
		}

		private function checkForConnectedArduino( event : Event ) : void
		{
			_timer.removeEventListener( "timer", checkForConnectedArduino );
			_timer = null;
			if ( ! _arduino.hasBeenConnected ) {
			    addLineToLogArea( "No socket connection, did you start serproxy?" );
			}
		}


		private function onArduinoInitialized( event : ArduinoEvent ) : void
		{
			_arduino.removeEventListener(  ArduinoEvent.INITIALIZED , onArduinoInitialized );

			if ( ( _arduino.nrOfDigitalPins + _arduino.nrOfAnalogPins ) != _monitorObjects.length ) {
				if ( _scrollPane ) {
					removeChild( _scrollPane );
				}
				_monitorObjects     = new Array();
				_configObjects      = new Array();
				_waveMonitorOjects  = new Array();
				addScrollPane();
				createMonitorElementsAndAddToScrollPane();
				addChild( _scrollPane );
				_scrollPane.update();
			}

			_arduino.addEventListener   (  ArduinoEvent.DISCONNECTED         , onArduinoDisconnected       );
			_arduino.addEventListener   (    SysexEvent.SYSEX_DATA_MESSAGE   , onReceiveSysexDataMessage   );
			_arduino.addEventListener   (    SysexEvent.SYSEX_STRING_MESSAGE , onReceiveSysexStringMessage );
			_arduino.addEventListener   (  NewDataEvent.NEW_ANALOG_DATA      , onReceiveAnalogData         );
			_arduino.addEventListener   (  NewDataEvent.NEW_DIGITAL_DATA     , onReceiveDigitalData        );
			_arduino.addEventListener   ( PinStateEvent.PIN_STATE_RECEIVED   , onArduinoPinState           );

			_timer = new Timer( 50 );
			_timer.start();
			_timer.addEventListener( "timer", onTick );

			var firmware : String = ", version=" + _arduino.firmwareVersionString + ( _arduino.firmwareName ? ( ", version name= '" + _arduino.firmwareName + "'" ) : "" )
			addLineToLogArea( "Arduino initialized: initializations=" + event.nrOfInitializations + firmware);
		}


		private function onArduinoDisconnected( event : Event ) : void
		{
			addLineToLogArea( "Arduino disconnected" );

			_arduino.addEventListener   (  ArduinoEvent.INITIALIZED          , onArduinoInitialized        );
			_arduino.removeEventListener(  ArduinoEvent.DISCONNECTED         , onArduinoDisconnected       );
			_arduino.removeEventListener(    SysexEvent.SYSEX_DATA_MESSAGE   , onReceiveSysexDataMessage   );
			_arduino.removeEventListener(    SysexEvent.SYSEX_STRING_MESSAGE , onReceiveSysexStringMessage );
			_arduino.removeEventListener(  NewDataEvent.NEW_ANALOG_DATA      , onReceiveAnalogData         );
			_arduino.removeEventListener(  NewDataEvent.NEW_DIGITAL_DATA     , onReceiveDigitalData        );
			_arduino.removeEventListener( PinStateEvent.PIN_STATE_RECEIVED   , onArduinoPinState           );
			
			if ( _timer ) _timer.removeEventListener( "timer" , onTick );
			_timer = null;
		}


		private function onReceiveSysexDataMessage( event : SysexEvent ) : void
		{
			trace( " Data: " + event.data.toString() );
			addLineToLogArea( "SysexData message received: " + event.data.toString() );
		}


		private function onReceiveSysexStringMessage( event : SysexEvent ) : void
		{
			trace( " String: " + event.string.toString() );
			addLineToLogArea( "SysexString message received: '" + event.string + "'" );
		}


		private function onReceiveAnalogData( event : NewDataEvent ) : void
		{
			var analogPin : int = _arduino.nrOfDigitalPins + event.pin;
			if ( _monitorObjects[analogPin] != null ) {
				_monitorObjects[analogPin].update( event.value );
			}
		}


		private function onReceiveDigitalData( event : NewDataEvent ) : void
		{
			if ( _monitorObjects[event.pin] != null ) {
				_monitorObjects[event.pin].update( event.value );
			}
		}


		private function onArduinoPinState( event : PinStateEvent ) : void
		{
			if ( _configObjects[event.pin] == null ) {
				createPinElementsAndAddToScrollPane( event.pin )
			}
			if ( _configObjects.length > event.pin ) {
				_configObjects[event.pin].update( event.state );
			} else {
				addLineToLogArea( "Warning, pin state event received for pin " + event.pin
								  + " while array is smaller (" + _configObjects.length + ")" )
			}
		}


		// =================
		// Private functions
		// =================
		private function setMinimalComponentsStyle() : void
		{
			Style.INPUT_TEXT      = FOREGROUND;
			Style.LABEL_TEXT      = FOREGROUND;
		}


		private function setTextFormat() : void
		{
			_textFormat.font = "arial";
			_textFormat.size = 10;
		}


		private function addLineToLogArea( line : String ) : void
		{
			_loggingTextArea.appendText( line + "\n" );
			_loggingTextArea.verticalScrollPosition = ++_logTextLines;
		}


		private function addloggingTextArea():void
		{
			_loggingTextArea        = new TextArea();
			_loggingTextArea.x      =  10;
			_loggingTextArea.y      =  10;
			_loggingTextArea.width  = 740;
			_loggingTextArea.height =  58;

			_loggingTextArea.text                 = "";
			_loggingTextArea.wordWrap             = true;
			_loggingTextArea.editable             = false;
			_loggingTextArea.verticalScrollPolicy = ScrollPolicy.AUTO;
		
			addChild( _loggingTextArea );
		}


		private function addScrollPane() : void
		{
			_scrollPane        = new ScrollPane();
			_scrollPane.y      = _loggingTextArea.height + 10 ;
			_scrollPane.width  = 760 ;
			_scrollPane.height = 720 - 80 - _loggingTextArea.height;
			
			// Not add yet as the children will first have to be added
		}


		private function createMonitorElementsAndAddToScrollPane() : void
		{
			for ( var pin : uint = 2 ; pin < _arduino.nrOfPins ; pin++ )
				createPinElementsAndAddToScrollPane( pin )
		}


		private function createPinElementsAndAddToScrollPane( pin : int ) : void
		{
			if ( isPinWithAtLeastOneCapability( pin ) )
			{
				_monitorObjects[ pin ] = new PinMonitorObj( _arduino , pin );
				_monitorObjects[ pin ].x = 118;
				_monitorObjects[ pin ].y = 10 + ( 29 * ( pin - 2 ) );

				_configObjects[pin] = new PinConfigObj( _arduino, pin, _monitorObjects[ pin ] );
				_configObjects[pin].x = 10;
				_configObjects[pin].y = 10 + ( 29 * ( pin - 2 ) );

				_scrollPane.addChild( _monitorObjects[ pin ] );
				_scrollPane.addChild( _configObjects[pin] );
		
				addWaveMonitors( pin );
			}
		}


		private function isPinWithAtLeastOneCapability( pin : uint ) : Boolean
		{
			for ( var capability : int = Firmata.INPUT ; capability < Firmata.TOTAL_PIN_MODES ; capability++ ) {
				if ( _arduino.isCapabilityOfPin( pin , capability ) ) {
					return true;
				}
			}
			return false;
		}


		private function addWaveMonitors( pin : int ) : void
		{
			const waveWidth  : uint = 256;
			const waveHeight : uint = _arduino.nrOfAnalogPins > 6 ? 48 : ( 720 - 80 - _loggingTextArea.height ) / 7;
			
			if ( _arduino.isCapabilityOfPin( pin, Firmata.ANALOG ) )
			{
				var analogPinNr : int = pin - _arduino.nrOfDigitalPins;
				_waveMonitorOjects[pin] = new WavePlot( "analog pin " + analogPinNr , waveWidth , waveHeight );
				_waveMonitorOjects[pin].y = 10 + analogPinNr * ( waveHeight + 10 );
				_waveMonitorOjects[pin].x = 430;
	
				_scrollPane.addChild( _waveMonitorOjects[pin] );
			}
		}


		private function addWarningText() : void
		{
			var warning : TextField = new TextField();

			warning.x      = 7;
			warning.y      = 640 + 10;
			warning.width  = 740;
			warning.height = 40;
			warning.text   = "'bug' in servo support. When you switch a pin to servo they cannot be used as PWM outputs anymore.\nSwitching back to PWM doesn't work then.";
			_textFormat.color = 0xAA0000;
			warning.setTextFormat( _textFormat );

			addChild( warning );
		}


		private function addCopyrightText() : void
		{
			var copyright : TextField = new TextField();

			copyright.x      = 7;
			copyright.y      = 680 + 10;
			copyright.width  = 740;
			copyright.height = 40;
			copyright.text   = "Arduino - AS3Glue / Firmata monitor -  V3.0 - Kasper Kamperman / Douwe A. van Twillert - 2013";
			copyright.setTextFormat( _textFormat );

			addChild( copyright );
		}
  	}
}