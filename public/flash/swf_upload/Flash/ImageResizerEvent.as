package  
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	
	public class ImageResizerEvent extends Event
	{
		public var data:ByteArray;
		public var encoding:Number;
		
		public static const COMPLETE:String = "COMPLETE";
		
		public function ImageResizerEvent (type:String, data:ByteArray, encoding:Number)
		{
			super(type);
			this.data = data;
			this.encoding = encoding;
		}
	}
}