/* ClassInfo.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 */


package nl.saxion.act.utils
{
	import flash.utils.getQualifiedClassName;
	
	/**
	 * Class to retrieve a class name from an instance name. Used in conjunction with error handling.
	 * @author Douwe A. van Twillert
	 */
	public class ClassInfo
	{
		/**
		 * Returns the class name of an instance (object).
		 *
		 * @param object The object which class name is needed.
		 */
		public static function getClassName( instance : Object ) : String
		{
			var qualifiedName : String = getQualifiedClassName( instance );

			var i : int = qualifiedName.length - 1;
			while ( i >= 0 ) {
				i--;
				if ( qualifiedName.charAt( i ) == '.' || qualifiedName.charAt( i ) == ':' ) {
					i++;
					break;
				}
			}
			
			return qualifiedName.substr( i );
		}
	}
}