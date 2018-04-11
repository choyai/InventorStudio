/* ArduinoController.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


 package nl.saxion.act.Arduino
{
	import flash.events.EventDispatcher;

	import nl.saxion.act.utils.Assert;

	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;


	/**
	 * This is a class to easy event programming for the Arduino. It attaches an event
	 * listener to either a clock or another event dispatcher.
	 *
	 * @author Douwe A. van Twillert, Saxion
	 */
	 public class ArduinoController
	{
		private var _arduinos   : Array;
		private var _dispatcher : EventDispatcher;
		private var _eventType       : String;
		private var _listeners  : Array;

		/**
		 * Constructor. You must specify a dispatcher and an event type
		 *
		 * @param pinConfiguration  Array with pinNr configuration, first two are null, others are { pwmOut or digitalIn or digitalOut or servo }
		 * @param tcpPort         	The tcp port to listen to, see also the as2arduinoGlue configuration file
		 * @param host              the host on which the serialproxy tcpPort can be found.
		 */
		public function ArduinoController( dispatcher : EventDispatcher , eventType : String , listener : Function = null )
		{
			Assert.notNull( dispatcher , "empty dispatcher, must be non null" );
			Assert.notNull( eventType  , "empty type, must be non null"       );

			_arduinos   = [];
			_listeners  = [];
			_dispatcher = dispatcher;
			_eventType  = eventType;
			if ( listener != null ) {
				addListener( listener );
			}
		}


		// ================
		// Public functions
		// ================                                                    /** returns the current number of Arduino's added to this controller. */
		public function get nrOfArduinos() : int { return _arduinos.length; }


		public function addArduino( arduino : Arduino ) : void
		{
			Assert.notNull( arduino , "empty arduino, must be non null" );
			addLowLevelArduino( arduino.lowLevelArduino );
		}


		public function addLowLevelArduino( lowLevelArduino : LowLevelArduino ) : void
		{
			Assert.notNull( lowLevelArduino , "empty LowLevelArduino, must be non null" );
			if ( add( _arduinos , lowLevelArduino ) ) {
				if ( lowLevelArduino.isProperlyInitializedAndConnected == false ) {
					trace( "waiting for Arduino initialization" );
					lowLevelArduino.addEventListener( ArduinoEvent.INITIALIZED , onArduinoIntialized );
					removeListeners();
				} else {
					lowLevelArduino.addEventListener( ArduinoEvent.DISCONNECTED , onArduinoDisconnected );
					checkForAllInitialized();
				}
			}
		}

		public function removeArduino( arduino : Arduino ) : void
		{
			if ( remove( _arduinos , arduino ) ) {
				checkForAllInitialized();
			}
		}

		public function addListener( listener : Function ) : void
		{
			Assert.notNull( listener , "empty listener, must not be null" );

			if ( add( _listeners , listener ) ) {
				if ( areAllArduinosInitialized() ) {
					_dispatcher.addEventListener( _eventType, listener );
				}
			}
		}

		public function removeListener( listener : Function ) : void
		{
			if ( remove( _listeners, listener ) ) {
				_dispatcher.removeEventListener( _eventType, listener );
			}
		}


		public function areAllArduinosInitialized() : Boolean
		{
			for each ( var lowLevelArduino : LowLevelArduino in _arduinos ) {
				if ( lowLevelArduino && ! lowLevelArduino.isProperlyInitializedAndConnected )
					return false;
			}
			return _arduinos.length > 0;
		}


		/**
		 * @private
		 */
		// ==============
		// Event handlers
		// ==============
		private function onArduinoIntialized( event : ArduinoEvent ) : void
		{
			event.currentTarget.removeEventListener( ArduinoEvent.INITIALIZED  , onArduinoIntialized   );
			event.currentTarget.addEventListener   ( ArduinoEvent.DISCONNECTED , onArduinoDisconnected );
			trace( "Arduino initialized: " + event.nrOfInitializations );

			checkForAllInitialized();
		}


		private function onArduinoDisconnected( event : ArduinoEvent ) : void
		{
			event.currentTarget.removeEventListener( ArduinoEvent.DISCONNECTED , onArduinoDisconnected );
			event.currentTarget.addEventListener   ( ArduinoEvent.INITIALIZED  , onArduinoIntialized   );

			removeListeners();
		}


		// =================
		// Private functions
		// =================
		private function checkForAllInitialized() : void
		{
			if ( areAllArduinosInitialized() ) {
				addListeners();
			}
		}


		private function addListeners() : void
		{
			for each ( var listener : Function in _listeners ) {
				_dispatcher.addEventListener( _eventType, listener );
			}
		}


		private function removeListeners() : void
		{
			for each ( var listener : Function in _listeners ) {
				_dispatcher.removeEventListener( _eventType, listener );
			}
		}


		static private function add( array : Array, object : Object ) : Boolean
		{
			var index : int = array.indexOf( object );
			if ( index == -1 ) {
				array.push( object )
			}
			return index == -1;
		}


		static private function remove( array : Array, object : Object ) : Boolean
		{
			var index : int = array.indexOf( object );
			if ( index != -1 ) {
				array.splice( index, 1 )
			}
			return index != -1;
		}
	}
}