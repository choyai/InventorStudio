/* AssertError.as
 *
 * Released under MIT license: http://www.opensource.org/licenses/mit-license.php
 * Copyright (C) 2013   Douwe A. van Twillert - Art & Technology, Saxion
 * Based on ideas by Christopher Herreman
 */

package nl.saxion.act.utils
{
	/**
	 * An Error class to help in handling programming errors.
	 *
	 * @author Douwe A. van Twillert
	 */
	public class AssertError extends Error {
		/**
		 * Constructs a new <code>AssertError</code>.
		 *
		 * @param message The assert error message describing the cause.
		 */
		public function AssertError( message : String = "" ) {
				super( message );
		}
	}
}
