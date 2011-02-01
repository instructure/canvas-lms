/*
 * http://code.google.com/p/as3corelib/ --  New BSD License
 * Modified to work asynchronously
 * */

package
{
	import flash.utils.ByteArray;
	import flash.display.BitmapData;
	import flash.geom.Rectangle;
	import flash.events.EventDispatcher;
	import flash.events.ErrorEvent;
	import flash.utils.setTimeout;
	
	public class PNGEncoder extends EventDispatcher {
		public static const TYPE_NORMAL:uint = 0;
		public static const TYPE_SUBFILTER:uint = 1;
		
		private var img:BitmapData;
		private var png:ByteArray;
		private var IDAT:ByteArray;
		
		private var type:uint;
		private var delay:int;
	
	    public function PNGEncoder(type:uint = PNGEncoder.TYPE_NORMAL, delay:int = 0) {
			super();
			
			this.type = type;
			this.delay = delay;

			PNGEncoder.computeCRCTable();
			
		}
		
		public function encode(img:BitmapData):void {
			try {
				// Create output byte array
				this.png = new ByteArray();
				this.img = img;

				// Write PNG signature
				this.png.writeUnsignedInt(0x89504e47);
				this.png.writeUnsignedInt(0x0D0A1A0A);

				// Build IHDR chunk
				var IHDR:ByteArray = new ByteArray();
				IHDR.writeInt(this.img.width);
				IHDR.writeInt(this.img.height);
				if(img.transparent || this.type == PNGEncoder.TYPE_NORMAL)
				{
					IHDR.writeUnsignedInt(0x08060000); // 32bit RGBA
				}
				else
				{
					IHDR.writeUnsignedInt(0x08020000); //24bit RGB
				}
				
				IHDR.writeByte(0);
				
				PNGEncoder.writeChunk(this.png, 0x49484452, IHDR);
				
				// Build IDAT chunk
				this.IDAT = new ByteArray();
				
				// Start encoding loop
				encodeLoop();
			} catch (ex:Error) {
				this.CleanUp();
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ex.message));
			}
	    }
		
		private function encodeLoop():void {
	        try {
				switch(this.type)
				{
					case PNGEncoder.TYPE_NORMAL:
						setTimeout(this.writeRaw, this.delay);
						break;
					case PNGEncoder.TYPE_SUBFILTER:
						setTimeout(this.writeSub, this.delay);
						break;
					default:
						this.CleanUp();
						break;
				}
			} catch (ex:Error) {
				this.CleanUp();
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ex.message));
			}
			
		}
		
		private function encodeEnd():void {
	        try {
				this.IDAT.compress();
				PNGEncoder.writeChunk(this.png, 0x49444154, this.IDAT);

				// Build IEND chunk
				PNGEncoder.writeChunk(this.png, 0x49454E44, null);

				// trigger complete event
				dispatchEvent(new EncodeCompleteEvent(this.png));
			} catch (ex:Error) {
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ex.message));
			} finally {
				this.CleanUp();
			}
		}
	    
	    private var encodingRow:int = 0;
		private function writeRaw():void
	    {
			try {
				if (this.encodingRow < this.img.height) {
					if (!this.img.transparent) {
						// Get the whole row
						var subImage:ByteArray = this.img.getPixels(new Rectangle(0, encodingRow, this.img.width, 1));
						//Here we overwrite the alpha value of the first pixel
						//to be the filter 0 flag
						subImage[0] = 0;
						this.IDAT.writeBytes(subImage);
						//And we add a byte at the end to wrap the alpha values
						this.IDAT.writeByte(0xff);
					} else {
						// Read and write a whole image row
						this.IDAT.writeByte(0);
						var p:uint;
						for (var j:int = 0; j < this.img.width; j++) {
							p = this.img.getPixel32(j, this.encodingRow);
							this.IDAT.writeUnsignedInt(uint(((p & 0xFFFFFF) << 8) | (p >>> 24)));
						}
					}
					
					this.encodingRow++;
					setTimeout(this.writeRaw, this.delay);
				} else {
					this.encodeEnd();
				}
			} catch (ex:Error) {
				this.CleanUp();
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ex.message));
			}
	    }
	    
	    private function writeSub():void
	    {
			try {
				var r1:uint = 0;
				var g1:uint = 0;
				var b1:uint = 0;
				var a1:uint = 0;
				
				var r2:uint;
				var g2:uint;
				var b2:uint;
				var a2:uint;
				
				var r3:uint;
				var g3:uint;
				var b3:uint;
				var a3:uint;
				
				var p:uint;
				var h:int = this.img.height;
				var w:int = this.img.width;
				
				var j:int = 0;
				
				if (this.encodingRow < h) {
					// no filter
					this.IDAT.writeByte(1);
					if (!this.img.transparent) {
						a1 = 0xff;
						for(j = 0; j < w; j++) {
							p = img.getPixel(j, this.encodingRow);
							
							r2 = p >> 16 & 0xff;
							g2 = p >> 8  & 0xff;
							b2 = p & 0xff;
							
							r3 = (r2 - r1 + 256) & 0xff;
							g3 = (g2 - g1 + 256) & 0xff;
							b3 = (b2 - b1 + 256) & 0xff;
							
							this.IDAT.writeByte(r3);
							this.IDAT.writeByte(g3);
							this.IDAT.writeByte(b3);
							
							r1 = r2;
							g1 = g2;
							b1 = b2;
							a1 = 0;
						}
					} else {
						for(j = 0; j < w; j++) {
							p = img.getPixel32(j, this.encodingRow);
							
							a2 = p >> 24 & 0xff;
							r2 = p >> 16 & 0xff;
							g2 = p >> 8  & 0xff;
							b2 = p & 0xff;
							
							r3 = (r2 - r1 + 256) & 0xff;
							g3 = (g2 - g1 + 256) & 0xff;
							b3 = (b2 - b1 + 256) & 0xff;
							a3 = (a2 - a1 + 256) & 0xff;
							
							this.IDAT.writeByte(r3);
							this.IDAT.writeByte(g3);
							this.IDAT.writeByte(b3);
							this.IDAT.writeByte(a3);
							
							r1 = r2;
							g1 = g2;
							b1 = b2;
							a1 = a2;
						}
					}
					
					this.encodingRow++;
					setTimeout(this.writeSub, this.delay);
				} else {
					this.encodeEnd();
				}
			} catch (ex:Error) {
				this.CleanUp();
				dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, ex.message));
			}
	    }
	
		private function CleanUp():void {
			this.png = null;
			this.img = null;
			this.IDAT = null;
			this.encodingRow = 0;
		}
		
	    private static var crcTable:Array;
	    private static var crcTableComputed:Boolean = false;
	
		private static function computeCRCTable():void {
	        if (!crcTableComputed) {
	            PNGEncoder.crcTableComputed = true;
	            PNGEncoder.crcTable = [];
	            for (var n:uint = 0; n < 256; n++) {
	                var c:uint = n;
	                for (var k:uint = 0; k < 8; k++) {
	                    if (c & 1) {
	                        c = uint(uint(0xedb88320) ^ 
	                            uint(c >>> 1));
	                    } else {
	                        c = uint(c >>> 1);
	                    }
	                }
	                PNGEncoder.crcTable[n] = c;
	            }
	        }
		}
		
	    private static function writeChunk(png:ByteArray, type:uint, data:ByteArray):void {
			var len:uint = 0;
			if (data != null) {
				len = data.length;
			}

			png.writeUnsignedInt(len);

			var p:uint = png.position;

			png.writeUnsignedInt(type);

			if (data != null) {
				png.writeBytes(data);
			}

			var e:uint = png.position;
			png.position = p;

			var c:uint = 0xffffffff;
			for (var i:int = 0; i < (e - p); i++) {
				c = uint(PNGEncoder.crcTable[
					(c ^ png.readUnsignedByte()) & 
					0xff] ^ (c >>> 8));
			}
			
			c = uint(c ^ uint(0xffffffff));
			
			png.position = e;

			png.writeUnsignedInt(c);
	    }
	}
}