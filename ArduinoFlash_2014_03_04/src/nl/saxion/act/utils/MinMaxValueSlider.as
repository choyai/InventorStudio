/* MinMaxValueSlider.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.utils
{
	import com.bit101.components.HSlider;

	import flash.text.TextField;
	import flash.text.TextFormat;

	import flash.events.Event;

	import flash.display.Sprite;


	 /**
	  * TODO write asdoc comments
	 * @private		for development in FlashDevelop only
	 * @author 		Douwe A. van Twillert
	 */
	
	public class MinMaxValueSlider extends Sprite
	{
		private var _slider    : HSlider;
		private var _isInteger : Boolean;
		private var _handler   : Function;
		private var _value     : TextField;
		private var _format    : TextFormat = new TextFormat();

		/*
		 * @private	this class is for use in
		 */
		public function MinMaxValueSlider( name : String, handler : Function , min : Number, max : Number, initialValue : Number = 0, isInteger : Boolean = false )
		{
			_value = createTextField( initialValue.toString() ,   0 , 10, "center" , 24, 20 );
			         createTextField( min.toString()          ,  24 , 16, "right"  , 24 );
			         createTextField( name                    ,  48 ,  0                );
			         createTextField( max.toString()          , 150 , 16                );
			_slider = new HSlider( this ,  48 , 20 , changeHandler );
			_slider.setSliderParams( min, max, initialValue );
			addChild( _slider );
			_handler   = handler;
			_isInteger = isInteger;
		}


		public function get value() : Number { return _slider.value; }


		private function changeHandler( event : Event ) : void
		{
			_value.text = ( _isInteger ? int( _slider.value ) : _slider.value ).toString();
			_format.font  = "Calibri";
			_format.size = 20;
			_format.align = "center";
			_value.setTextFormat( _format );
			_handler( event );
		}


		private function createTextField( text : String , x : int , y : int, align : String = "left", width : int = -1, textHeight : uint = 14 ) : TextField
		{
			var field  : TextField  = new TextField();
			field.x      = x;
			field.y      = y;
			if ( width != -1 ) field.width = width;
			field.text   = text;
			_format.font  = "Calibri";
			_format.size  = textHeight;
			_format.align = align;
			field.setTextFormat( _format );
			addChild( field  );
			
			return field;
		}
	}
}