/* Assert.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 * Based on ideas by Christopher Herreman
 */

 package nl.saxion.act.utils
{

    /**
     * Assert class that verifies expressions to be true. It helps in finding programming errors.
     * @author Douwe A. van Twillert
     */

    public class Assert {
        /**
         * Checks an expression to be <code>true</code>. Throws an <code>AssertError</code> if the expression is not <code>true</code>.
         * <pre class="code">Assert.isTrue(value, message, argu\mentsd);</pre>
         * @param expression a boolean expression
         * @param message the error message to use if the assertion fails
         * @param ...varargs optional arguments in the message string, expressed as %1 %2 etc.
         * @throws saxion.act.utils.AssertError if the expression is not <code>true</code>
         */
        public static function isTrue( expression : Boolean , message : String , ...varargs ) : void {
            if ( ! expression ) {
                throwAssertError( message, "[Assertion failed] - this expression should be true", varargs );
            }
        }


		/**
         * Checks if an object is *not* <code>null</code>.  Throws an <code>AssertError</code> if the object is <code>null</code>.
         * <pre class="code">Assert.notNull(value, "The value must not be null");</pre>
         * @param message the error message to use if the assertion fails
         * @param ...varargs optional arguments in the message string, expressed as %1 %2 etc.
         * @throws saxion.act.utils.AssertError if the objects is <code>null</code>
         */
        public static function notNull( object : Object , message : String = "" , ...varargs ) : void
		{
            if ( object == null ) {
                throwAssertError( message, "[Assertion failed] - argument is null, should not be null", varargs );
            }
        }


		/**
		 * @private functions
		 */
		// =================
		// Private functions
		// =================
		private static function throwAssertError( message : String , alternative : String , args : Array ) : void
		{
			if ( message == null || message == "" ) {
				if ( alternative == null || message == "" ) {
					message = "[Assertion failed] - programming error, no default and no alternative message given";
				} else {
					message = alternative;
				}
			}
			for ( var i : int = 0 ; i < args.length ; i++ ) {
				message += ( i == 0 ? " (" : "," ) + (i+1) + "='" + args[i] + "'"
			}
			if ( args.length > 0 ) {
				message += ")";
			}
			trace( message );
			throw new AssertError( message );
		}
	}
}
