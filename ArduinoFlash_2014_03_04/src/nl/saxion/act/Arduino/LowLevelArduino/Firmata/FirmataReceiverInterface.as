/* FirmataReceiverInterface.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology
 */

 
package nl.saxion.act.Arduino.LowLevelArduino.Firmata
{
	/**
	 * @private
	 * @author Douwe A. van Twillert, Saxion
	 * The FirmataReceiverInterface shows all callback functions for all firmata messages
	 * The FirmataCommandReceiver uses these function to call a specific receiver
	 * Based on ideas from Erik Sjodin, eriksjodin.net Bjoern Hartmann, bjoern.org and
	 * Mochammad Effendi (Arduino Mega)
	 * @author Douwe A. van Twillert, Saxion
	 */
	public interface FirmataReceiverInterface
	{
		function    analog_IO_MessageReceived( pin     : uint , value : uint ) : void;
		function   digital_IO_MessageReceived( channel : uint , value : uint ) : void;

		function        queryFirmwareReceived( majorVersion : uint , minorVersion : uint ) : void;

		// all Sysex methods
		function queryFirmwareAndNameReceived( majorVersion   : uint ,    minorVersion : uint   , name : String              ) : void;
		function          sysexStringReceived( command        : uint ,         message : String                              ) : void;
		function            sysexDataReceived( command        : uint ,            data : Array                               ) : void;
		function      pinCapabilitiesReceived( nrOfAnalogPins : uint , nrOfDigitalPins : uint   , capabilitiesPerPin : Array ) : void;
		function     pinStateResponseReceived(            pin : uint ,    currentState : uint   ,       currentValue : uint  ) : void;
		function             I2CReplyReceived(        address : uint ,        register : uint   ,               data : Array ) : void;

		function       unknownCommandReceived( command : uint                ) : void;
		function  unknownSysexCommandReceived( command : uint , data : Array ) : void;
	}
}