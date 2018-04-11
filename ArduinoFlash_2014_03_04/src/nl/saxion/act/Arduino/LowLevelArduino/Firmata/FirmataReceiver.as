/* FirmataReceiver.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.Arduino.LowLevelArduino.Firmata
{
	import flash.events.Event;
	import flash.events.ProgressEvent;

	import flash.net.Socket;

	import nl.saxion.act.utils.Assert;
	//import nl.saxion.act.utils.Tracer;  changed to make asDoc work as it incorrectly reported undefined due to only static method usage


	/**
	 * @private
	 * @author Douwe A. van Twillert, Saxion
	 * The FirmataCommandReceiver class receives commands according to the Firmata V2 protocol.
	 * Works with an Arduino and the StandardFirmata firmware.
	 * Based on ideas from Erik Sjodin, eriksjodin.net Bjoern Hartmann, bjoern.org and
	 * Mochammad Effendi (Arduino Mega)
	 * @author Douwe A. van Twillert, Saxion
	 */
	public class FirmataReceiver
	{
		// =========
		// Variables
		// =========
		private var _socket   : Socket;
		private var _data     : Array = null;
		private var _receiver : FirmataReceiverInterface;

		public function FirmataReceiver( commandSender : FirmataSender , receiver : FirmataReceiverInterface = null )
		{
			Assert.notNull( commandSender, "commandSender may not be null" );

			_socket   = commandSender.socket;
			_receiver = receiver != null ? receiver : FirmataReceiverInterface( this );

			_socket.addEventListener( ProgressEvent.SOCKET_DATA , onSocketData  );
			_socket.addEventListener(         Event.CLOSE       , onSocketClose );
		}


		// ==============
		// Event handlers
		// ==============
		private function onSocketData( event : ProgressEvent ) : void
		{
			try {
				if ( isStillScanningForFirmwareVersion() ) {
					scanForFirmwareVersion();
					if ( isStillScanningForFirmwareVersion() )
						return;
				}
				while ( _socket.bytesAvailable > 0 ) {
				    _data.push( int( _socket.readUnsignedByte() ) );
				}
				while ( _data.length > 0 && isAFullMessageAvailable() ) {
					processMessage()
				}
			} catch ( error : Error ) {
				trace( "error caught while decoding arduino command message:" );
				trace( "error =" + error );
				trace( error.getStackTrace() );

				throw error;
			}
		}


		protected function onSocketClose( event : Event ) : void
		{
			_data = null;
		}


		/**
		 * @private functions
		 */
		// =================
		// Private functions
		// =================
		private function isStillScanningForFirmwareVersion() : Boolean
		{
			return _data == null;
		}


		private function scanForFirmwareVersion() : void
		{
			var byte : int;
			do {
				byte = _socket.bytesAvailable > 0 ? _socket.readUnsignedByte() : -1
			}
			while ( byte != Firmata.REPORT_VERSION && byte != -1 )
				
			if ( byte == Firmata.REPORT_VERSION ) {
				_data = [];
				_data.push( byte );
			}
		}


		private function isAFullMessageAvailable() : Boolean
		{
			Assert.isTrue( _data.length > 0, "isAFullMessageAvailable() called without data" );

			var command : int = getCommandWithoutChannel( _data[0] ) ;
			switch( command ) {
				case Firmata.DIGITAL_MESSAGE:
				case Firmata.REPORT_VERSION:
				case Firmata.ANALOG_MESSAGE:
					return _data.length > 2;
				case Firmata.SYSEX_START:
					for ( var i : uint = 1 ; i < _data.length ; i++ ) {
						if ( _data[i] == Firmata.SYSEX_END ) {
							return true;
						}
					}
					return false;
			}
			return _data.length > 3;  // you will get decoding errors, but comm errors are skipped
		}


		private function processMessage() : void
		{
			Assert.isTrue( _data.length > 0, "processMessage() called without data" );
			var command : uint = _data.shift();
			switch ( getCommandWithoutChannel( command ) ) {
				case Firmata.DIGITAL_MESSAGE:     processDigitalMessage( command ) ; break ;
				case Firmata.ANALOG_MESSAGE:      processAnalogMessage ( command ) ; break ;
				case Firmata.REPORT_VERSION:      processReportVersion( command )  ; break ;
				case Firmata.SYSEX_START:         processSysexMessage()            ; break ;
				default:                          processUnknownCommand( command ) ;
			}
		}


		private function getCommandWithoutChannel( command : uint ) : uint
		{
			return command >= 0xF0 ? command : command & 0xF0;
		}


		private function getChannelOrPort( command : uint ) : uint
		{
			return command & 0x0F;
		}


		private function processSysexMessage() : void
		{
			checkSysexMessageAndForProperNextMessage();

			var sysexCommand : uint = _data.shift();
			switch ( sysexCommand ) {
				case Firmata.REPORT_FIRMWARE:     processReportFirmware()          ; break ;
				case Firmata.STRING_DATA:         processStringData()              ; break ;
				case Firmata.CAPABILITY_RESPONSE: processCapabilityResponse()      ; break ;
				case Firmata.PIN_STATE_RESPONSE:  processPinStateResponse()	       ; break ;
				case Firmata.I2C_REPLY:           processI2CReply()                ; break ;
			    default: 						  processSysexData( sysexCommand ) ;
			}
		}


		private function processDigitalMessage( command : uint ) : void
		{
			var bits0_6  : int = getNonSysexByte();
			var bits7_13 : int = getNonSysexByte();

			_receiver.digital_IO_MessageReceived( getChannelOrPort( command ), ( bits7_13 & 127 ) * 128 + ( bits0_6 & 127 ) );

			checkForProperNextMessage( command, bits0_6, bits7_13 );
		}


		private function processAnalogMessage( command : uint ) : void
		{
			var leastSignificantByte : int = getNonSysexByte();
			var mostSignificantByte  : int = getNonSysexByte();

			_receiver.analog_IO_MessageReceived( getChannelOrPort( command ), ( mostSignificantByte & 127 ) * 128 + ( leastSignificantByte & 127 ) );

			checkForProperNextMessage( command, leastSignificantByte, mostSignificantByte );
		}


		private function processReportVersion( command : uint ) : void
		{
			var majorVersion : int = getNonSysexByte();
			var minorVersion : int = getNonSysexByte();

			_receiver.queryFirmwareReceived( majorVersion, minorVersion );

			checkForProperNextMessage( command, majorVersion, minorVersion );
		}


		private function processReportFirmware() : void
		{
			var majorVersion : int = getNonSysexByte();
			var minorVersion : int = getNonSysexByte();

			_receiver.queryFirmwareAndNameReceived( majorVersion, minorVersion , readSysexString() );
		}


		private function processUnknownCommand( command : uint ) : void
		{
			trace( "processMessage(): unknown command -> command=" + command.toString( 16 ) + " channel=" + getChannelOrPort( command ) );

			_receiver.unknownCommandReceived( command );
		}


		private const END_OF_CURRENT_PIN : uint = 127;

		private function processCapabilityResponse() : void
		{
			var pin                : uint  = 0;
		    var nrOfDigitalPins    : uint  = 0;
		    var nrOfAnalogPins     : uint  = 0;
			var capabilitiesPerPin : Array = [];
			var pinCapabilities    : Array = [];
			
			for ( var capability : int = _data.shift() ; capability != Firmata.SYSEX_END ;  capability = _data.length ? _data.shift() : Firmata.SYSEX_END ) {
				if ( capability == END_OF_CURRENT_PIN ) {
					if ( pinCapabilities[ Firmata.ANALOG ] ) {
						nrOfAnalogPins++;
					} else {
						nrOfDigitalPins++;
					}
					capabilitiesPerPin[ pin ] = pinCapabilities;
					pinCapabilities           = [];
					pin++;
				} else {
					var resolution : int = _data.shift();
					Assert.isTrue( resolution < 128, "all resolutions should be < 128" );
					pinCapabilities[ capability ] = resolution;
				}
			}

			_receiver.pinCapabilitiesReceived(  nrOfAnalogPins , nrOfDigitalPins , capabilitiesPerPin );
		}


		private function processPinStateResponse() : void
		{
			var pin   : uint = getNonSysexByte();
			var mode  : uint = getNonSysexByte();
			var value : uint = 0;

			for ( var sysexByte : uint = _data.shift() ; sysexByte != Firmata.SYSEX_END ; sysexByte = _data.length ? _data.shift() : Firmata.SYSEX_END ) {
				value = value * 128 + sysexByte;
			}

			// TODO recovery for illegal values like >127 for pin numbers and mode
			_receiver.pinStateResponseReceived( pin , mode , value )
		}


		private function processI2CReply() : void
		{
			var address   : uint = getIntFromNextTwoDataItems();
			var register  : uint = getIntFromNextTwoDataItems();

			_receiver.I2CReplyReceived( address , register , readSysexData() );
		}


		private function processStringData() : void
		{

			_receiver.sysexStringReceived( Firmata.STRING_DATA, readSysexString() );
		}
		

		private function processSysexData( sysexCommand : int ) : void
		{
			_receiver.sysexDataReceived( sysexCommand, readSysexData() );
		}


		private function readSysexString() : String
		{
			var sysexString : String = "";

			for ( var sysexByte : int = _data.shift() ; sysexByte != Firmata.SYSEX_END ;  sysexByte = _data.length ? _data.shift() : Firmata.SYSEX_END ) {
				var value : int = sysexByte;
		
				sysexByte = _data.length ? _data.shift() : Firmata.SYSEX_END
				if ( sysexByte != Firmata.SYSEX_END ) {
					value += sysexByte * 128;
				}
				if ( value != 0 ) {
					sysexString += String.fromCharCode( value );
				}
			}
			
			return sysexString;
		}


		private function readSysexData() : Array
		{
			var index : int = 0;
			while ( index < _data.length && _data[ index ] != Firmata.SYSEX_END ) {
				index++;
			}
			var sysexData : Array = _data.splice( 0, index );

			if ( _data[ 0 ] ==  Firmata.SYSEX_END ) {
				_data.shift();
			}
			
			convertTwoByteArrayToValues( sysexData );
			
			return sysexData;
		}


		private function getNonSysexByte() : int
		{
			Assert.isTrue( _data.length > 0, "getNonSysexByte() called without enough data (%1 at least 2)", _data.length );
			Assert.isTrue( _data[ 0 ] < 128, "getNonSysexByte() data too large (%1)", _data[ 0 ] );

			if ( _data.length > 0 && _data[ 0 ] < 128 ) {
				return _data.shift();
			} else {
				return 0;
			}
		}


		private function getIntFromNextTwoDataItems() : uint
		{
			Assert.isTrue( _data.length > 1, "getIntFromNextTwoDataItems() called without enough data (%1 at least 2)", _data.length );
			
			var leastSignificantByte : int = getNonSysexByte();
			var mostSignificantByte  : int = getNonSysexByte();

			return ( mostSignificantByte & 127 ) * 128 + ( leastSignificantByte & 127 );
		}


		private function convertTwoByteArrayToValues( array : Array ) : void
		{
			for ( var toIndex : uint = 0 ; toIndex < array.length / 2 ; toIndex++ ) {
				var fromIndex : uint = toIndex * 2 ;
				array[ toIndex ] = ( array[ fromIndex ] & 127 ) + 128 * ( array[ fromIndex + 1 ] & 127 );
			}
			array.splice( toIndex );
		}


		private function checkForProperNextMessage( previousCommand : uint, firstByte : uint, secondByte : uint ) : void
		{
			if ( _data.length != 0 ) {
				if ( isImproperNextCommandAtIndex( 0 ) ) {
					trace( "Decoding Error for next message, current message =" + previousCommand.toString(16) + ", " + firstByte.toString(16)
						   + ", " + secondByte.toString(16) + ", _data=" + nl.saxion.act.utils.Tracer.formatArray( _data , -1, 16 ) );
				}
			}
		}


		private const NOT_YET_ENOUGH_DATA_RECEIVED : Boolean = false;
		
		private function isImproperNextCommandAtIndex( index : uint ) : Boolean
		{
			Assert.isTrue( _data.length > 0, "isImproperNextCommand() called without enough data (%1 at least 3)", _data.length );

			var nextCommand : int = _data[index] >= 0xF0 ? _data[index] : _data[index] & 0xF0;

			switch( nextCommand ) {
				case Firmata.DIGITAL_MESSAGE:
				case Firmata.REPORT_VERSION:
				case Firmata.ANALOG_MESSAGE:
					if ( _data.length < ( index + 2 ) )
						return NOT_YET_ENOUGH_DATA_RECEIVED;
					return ( ( _data[1] & 128 ) | ( _data[2] & 128 ) ) != 0;
				case Firmata.SYSEX_START:
					if ( _data.length <= ( index + 1 ) ) {
						return NOT_YET_ENOUGH_DATA_RECEIVED;
					}
					var sysexCommand : uint = _data[ index + 1 ];
					switch ( sysexCommand ) {
						case Firmata.REPORT_FIRMWARE:
						case Firmata.STRING_DATA:
						case Firmata.CAPABILITY_RESPONSE:
						case Firmata.PIN_STATE_RESPONSE:
						case Firmata.I2C_REPLY:
							return false;

					}
			}
			return true;
		}


		private function checkSysexMessageAndForProperNextMessage() : void
		{
			Assert.isTrue( _data.length > 2, "checkSysexMessageAndForProperNextMessage() called without enough data (%1 at least 3)", _data.length );
			var i : int = 2;
			var decodingErrors : int = 0;
			while ( i < _data.length && _data[i] != Firmata.SYSEX_END ) {
				if ( _data[i] & 128 ) {
					decodingErrors++;
				}
				i++;
			}
			if ( decodingErrors ) {
				trace( "Warning: Decoding error(s) for sysex message, " + decodingErrors + " byte(s) have high bit set (message=" + nl.saxion.act.utils.Tracer.formatArray( _data, -1, 16 ) + ")"  )
			}

			if ( ( i + 1 ) < _data.length ) {
				if ( isImproperNextCommandAtIndex( i + 1 ) ) {
					trace( "Warning: Decoding Error for next message after sysex message (command=" +  _data[ i + 1 ] + " index=" + ( i + 1 ) + "), current data="
					       + nl.saxion.act.utils.Tracer.formatArray( _data, -1, 16 ) );
				}
			}
		}
	}
}