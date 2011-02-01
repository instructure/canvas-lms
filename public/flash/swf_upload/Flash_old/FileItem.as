package {
	import flash.net.FileReference;

	internal class FileItem
	{
		private static var file_id_sequence:Number = 0;		// tracks the file id sequence

		private var postObject:Object;
		public var file_reference:FileReference;
		public var id:String;
		public var index:Number = -1;
		public var file_status:int = 0;
		private var js_object:Object;
		
		public static var FILE_STATUS_QUEUED:int		= -1;
		public static var FILE_STATUS_IN_PROGRESS:int	= -2;
		public static var FILE_STATUS_ERROR:int			= -3;
		public static var FILE_STATUS_SUCCESS:int		= -4;
		public static var FILE_STATUS_CANCELLED:int		= -5;
		public static var FILE_STATUS_NEW:int			= -6;	// This file status should never be sent to JavaScript
		
		public function FileItem(file_reference:FileReference, control_id:String, index:Number)
		{
			this.postObject = {};
			this.file_reference = file_reference;
			this.id = control_id + "_" + (FileItem.file_id_sequence++);
			this.file_status = FileItem.FILE_STATUS_NEW;
			this.index = index;
			
			this.js_object = {
				id: this.id,
				index: this.index,
				post: this.GetPostObject()
			};
			
			// Cleanly attempt to retrieve the FileReference info
			// this can fail and so is wrapped in try..catch
			try {
				this.js_object.name = this.file_reference.name;
				this.js_object.size = this.file_reference.size;
				this.js_object.type = this.file_reference.type || "";
				this.js_object.creationdate = this.file_reference.creationDate || new Date(0);
				this.js_object.modificationdate = this.file_reference.modificationDate || new Date(0);
			} catch (ex:Error) {
				this.file_status = FileItem.FILE_STATUS_ERROR;
			}
			
			this.js_object.filestatus = this.file_status;
		}
		
		public function AddParam(name:String, value:String):void {
			this.postObject[name] = value;
		}
		
		public function RemoveParam(name:String):void {
			delete this.postObject[name];
		}
		
		public function GetPostObject(escape:Boolean = false):Object {
			if (escape) {
				var escapedPostObject:Object = { };
				for (var k:String in this.postObject) {
					if (this.postObject.hasOwnProperty(k)) {
						var escapedName:String = FileItem.EscapeParamName(k);
						escapedPostObject[escapedName] = this.postObject[k];
					}
				}
				return escapedPostObject;
			} else {
				return this.postObject;
			}
		}
		
		// Create the simply file object that is passed to the browser
		public function ToJavaScriptObject():Object {
			this.js_object.filestatus = this.file_status;
			this.js_object.post = this.GetPostObject(true);
		
			return this.js_object;
		}
		
		public function toString():String {
			return "FileItem - ID: " + this.id;
		}
		
		/*
		// The purpose of this function is to escape the property names so when Flash
		// passes them back to javascript they can be interpretted correctly.
		// ***They have to be unescaped again by JavaScript.**
		//
		// This works around a bug where Flash sends objects this way:
		//		object.parametername = "value";
		// instead of
		//		object["parametername"] = "value";
		// This can be a problem if the parameter name has characters that are not
		// allowed in JavaScript identifiers:
		// 		object.parameter.name! = "value";
		// does not work but,
		//		object["parameter.name!"] = "value";
		// would have worked.
		*/
		public static function EscapeParamName(name:String):String {
			name = name.replace(/[^a-z0-9_]/gi, FileItem.EscapeCharacter);
			name = name.replace(/^[0-9]/, FileItem.EscapeCharacter);
			return name;
		}
		public static function EscapeCharacter():String {
			return "$" + ("0000" + arguments[0].charCodeAt(0).toString(16)).substr(-4, 4);
		}
		
	}
}