/* PinMonitorObj.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Kasper Kamperman      - Art & Technology
 *                      Douwe A. van Twillert - Art & Technology
 */


package nl.saxion.act.Arduino.monitor
{
	import com.bit101.components.PushButton;
	import com.bit101.components.Slider;
	import com.bit101.components.Text;

	import fl.controls.ProgressBar;
	import fl.controls.ProgressBarMode;
	import fl.controls.ProgressBarDirection;

	import flash.events.*;

	import flash.display.Sprite;
	import flash.display.MovieClip;
	
	import nl.saxion.act.Arduino.LowLevelArduino.Firmata.Firmata;
	import nl.saxion.act.Arduino.LowLevelArduino.LowLevelArduino;
	
	import nl.saxion.act.utils.TransparantBackgroundText;


	/**
	 * @private class, used by ArduinoMonitor
	 */
	public class PinMonitorObj extends MovieClip
  	{
		// =========
		// Constants
		// =========
		private const DIGITAL_OUT_BACKGROUND : uint = 0x60B09E;  //  0x00665e;
		private const  DIGITAL_IN_BACKGROUND : uint = 0x88C4EC; //  0x3293BD;  //  0x081272;
		private const   ANALOG_IN_BACKGROUND : uint = 0xD08090;  //  0xBD3F70;  //  0x3f046f;
		private const     PWM_OUT_BACKGROUND : uint = 0xFFFFC0;  //  0x2e3784;
		private const       SERVO_BACKGROUND : uint = 0xFFBB00;  //  0xCC9941;  //  0x2e37aa;

		private const         PWM_MAXIMUM    : uint = 255;
		private const       SERVO_MAXIMUM    : uint = 180;       // TODO, check if it in reality is 179


		// =========
		// Variables
		// =========
		private var _pin                  : int;
		private var _pinState             : String;

		private var _pinNrText            : Text;
		private var _pinModeText          : Text;
		private var _pinValueText         : Text;

		private var _arduino              : LowLevelArduino;
		
		private var _monitor              : Sprite;
		private var _background           : Sprite;
		private var _analogInBackground   : Sprite;
		private var _digitalOutBackground : Sprite;
		private var _digitalInBackground  : Sprite;
		private var _pwmOutBackground     : Sprite;
		private var _servoBackground      : Sprite;

		private var _button               : PushButton;
		private var _progressBar          : ProgressBar;
		private var _slider               : Slider;
		private var _servoSlider          : Slider;
		


  		public function PinMonitorObj( arduino : LowLevelArduino , pin : int )
		{
			_arduino              = arduino;
			_pin                  = pin;
			_pinState             = _arduino.isCapabilityOfPin( _pin, Firmata.ANALOG ) ? "analogIn" : "digitalIn" ;

			_background           = new Sprite();
			_pinNrText            = createTransparantBackgroundText(  4 , "pin " + displayPinNr );
			_pinModeText          = createTransparantBackgroundText( 49 , "no Config yet"       );
			_pinModeText.width    = 68;
			_pinValueText         = createTransparantBackgroundText( _pinModeText.x + _pinModeText.width + 10 + 128 + 5, "000" );
			_monitor              = new Sprite();
			
			_digitalOutBackground = createBackground( DIGITAL_OUT_BACKGROUND );
			_digitalInBackground  = createBackground(  DIGITAL_IN_BACKGROUND );
			_analogInBackground   = createBackground(   ANALOG_IN_BACKGROUND );
			_pwmOutBackground     = createBackground(     PWM_OUT_BACKGROUND );
			_servoBackground      = createBackground(       SERVO_BACKGROUND );
		
			setXandWidthOfMonitorElement( createDigitalOutButton() );
			setXandWidthOfMonitorElement( createProgressBar()      );
			setXandWidthOfMonitorElement( createSlider()           );

			addChild( _background   );
			addChild( _pinNrText    );
			addChild( _pinModeText );
			addChild( _pinValueText );
			addChild( _monitor      );

			displayGuiElement();
		}
		
		public function update( data : Number = 0 ) : void
		{
		    if ( _pinState == "digitalIn" || _pinState == "analogIn" )
		    {
			    _progressBar.setProgress( data, _pinState == "analogIn" ? 1023 : 1 );
			
			    _pinValueText.text = String( data );
		    }
		}
		
		public function updatePinConfig( newMode : String ) : void
		{
			_background.removeChild( getBackground( _pinState ) );
			   _monitor.removeChild( getGuiElement( _pinState ) );
			_pinState = newMode;
			displayGuiElement();
		}


		private function get displayPinNr() : uint
		{
			return _pin < _arduino.nrOfDigitalPins ? _pin : _pin - _arduino.nrOfDigitalPins;
		}


		private function displayGuiElement() : void
		{
			_pinModeText.text  = "[ " + _pinState + " ]";
			_pinValueText.text = "0";
			
			_background.addChild( getBackground( _pinState ) );
			   _monitor.addChild( getGuiElement( _pinState ) );
		}


		private function getBackground( pinName : String ) : Sprite
		{	switch (_pinState ) {
				case "digitalOut" : return _digitalOutBackground ;
				case "digitalIn"  : return  _digitalInBackground ;
				case "analogIn"   : return   _analogInBackground ;
				case "pwmOut"     : return     _pwmOutBackground ;
				case "servo"      : return      _servoBackground ;
			}
			return null;
		}


		private function getGuiElement( pinName : String ) : Sprite
		{
			switch (_pinState ) {
				case "digitalOut" :                                                      return _button       ;
				case "digitalIn"  :                                                      return _progressBar  ;
				case "analogIn"   :                                                      return _progressBar  ;
				case "pwmOut"     : _slider.maximum = PWM_MAXIMUM   ; _slider.value = 0; return _slider       ;
				case "servo"      : _slider.maximum = SERVO_MAXIMUM ; _slider.value = 0; return _slider       ;
			}
			return null;
		}


		private function createTransparantBackgroundText( x : int, label : String ) : Text
		{
			var text : Text = new TransparantBackgroundText( this, x, 0, label );

			text.selectable = false;
			
			return text;
		}


		private function createProgressBar() : ProgressBar
		{
			_progressBar           = new ProgressBar();
			_progressBar.move( 0 , 4 );
			_progressBar.width     = 128;
			_progressBar.height    = 15
			_progressBar.direction = ProgressBarDirection.RIGHT;
			_progressBar.mode      = ProgressBarMode.MANUAL;
			_progressBar.minimum   = 0;
			_progressBar.maximum   = 1023;

			return _progressBar;
		}

		private function createDigitalOutButton() : PushButton
		{
			_button = new PushButton( null, 0, 2, "LOW", buttonClickHandler );
			_button.toggle = true;
			_button.addEventListener( MouseEvent.CLICK , buttonClickHandler );

			return _button;
		}

		private function createSlider() : Slider
		{
			_slider = new Slider( Slider.HORIZONTAL, null, 0, 4, slideChangeHandler );

			_slider.width   = 128;
			_slider.tick    = 1
			_slider.maximum = 100;
			_slider.value    = 0;
			
			return _slider;
		}
		
		
		private function buttonClickHandler( event : Event ) : void
		{
			_button.label = _button.selected ? "HIGH" : "LOW";
			_arduino.writeDigital( _pin, _button.selected );
			_pinValueText.text = _button.selected ? "1" : "0";
		}
		

		private function slideChangeHandler( event : Event ) : void
		{
			_arduino.writeAnalogPin( _pin , _slider.value );
		    _pinValueText.text = String( _slider.value );
		}

		private function createBackground( color : uint ) : Sprite
		{
			var  background : Sprite = new Sprite();
			with( background.graphics )
			{
				beginFill( color );
				drawRoundRect( 0 , 0 , 300 , 24 , 6 );
				endFill();
			}

			return background;
		}


		private function setXandWidthOfMonitorElement( child : Sprite ) : void
		{
			child.x = _pinModeText.x + _pinModeText.width + 10;
		}
  	}
}