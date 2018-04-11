package nl.saxion.act.utils
{
	
	/**
	 * ...
	 * @author ...
	 */
	public class ArrayHelper 
	{
		static public function initializeArray( array : Array, type: * )
		{
			if ( type is Class ) {
				array.forEach( initWithClass );
			} else {
				array.forEach( initWithValue );
			}

			function initWithClass( element : * , index : int , array : Array ) : void
			{
				array[ index ] = new type();
			}

			function initWithValue( element : *, index : int, array : Array ) : void
			{
				array[ index ] = type;
			}
		}
	}
	
}