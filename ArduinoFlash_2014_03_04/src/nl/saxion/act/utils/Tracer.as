/* Tracer.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 * Based on ideas by Christopher Herreman
 */


package nl.saxion.act.utils
{
	import flash.utils.Dictionary;

    /**
     * Tracer utility class that assists in easy tracing. Debugging tool.
     *
     * @author Douwe A. van Twillert
     */
    public class Tracer {
		private static var start : Number = timeSinceStartInSeconds();

        /**
         * Returns an array as a comma separated string.
         * @param array  A boolean expression.
         * @param count  The error message to use if the assertion fails.
         * @param radix  The power of the numbers in the array.
         */
        public static function formatArray( array : Array , count : int = -1 , radix : int = 10 ) : String
		{
			var max : uint = ( count == -1 ) ? array.length : count < array.length ? count : array.length;
			var arrayString : String = "";
            for ( var i : int = 0 ; i < max ; i++ ) {
				if ( arrayString.length == 0 ) {
					arrayString += array[i].toString( radix );
				} else {
					arrayString += ", " + array[i].toString( radix );
				}
			}
			return arrayString;
		}
		
        /**
         * Traces a string preceded with the current time.
         * @param traceMessage  Message to be traced.
         */
		public static function traceWithTime( traceMessage : String ) : void
		{
			var now : Number = timeSinceStartInSeconds();
			
			trace( now + " > " + traceMessage );
		}
		
        /**
         * Returns the number of seconds since the start of the execution.
         */
		public static function timeSinceStartInSeconds() : Number
		{
			return  new Date().getTime() / 1000 - start;
		}
		
		private static var logid2line : Dictionary = new Dictionary();

        /**
         * Only logs data associated with an id, if and only if the *data* has changed.
         */
		public static function traceIfChanged( id : String , line : String )
		{
			if ( logid2line[id] != line ) {
				trace( id + " = " + line );
				logid2line[id] = line;
			}
		}

    }
}
