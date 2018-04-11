/* Text.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (c) 2011   Keith Peters
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 *
 * A Text component for displaying multiple lines of text.
 */



package nl.saxion.act.utils
{
	import flash.text.TextFieldType;
	import flash.display.DisplayObjectContainer;
	
	import com.bit101.components.Text;
	import com.bit101.components.Component;
	
    /**
     * Class to make use of backgroundless Text fields like the minimal component text fields.
     *
     * @author Douwe A. van Twillert
     */
	public class TransparantBackgroundText extends Text
	{
		public const component : Namespace = new Namespace( "com.bit101.components.Component" );

		public function TransparantBackgroundText( parent : DisplayObjectContainer = null, xpos : Number = 0, ypos : Number =  0, text : String = "" )
		{
			super( parent, xpos , ypos , text );
			_tf.background = false;
			_panel.alpha = 0;
		}
	}
}