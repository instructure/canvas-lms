import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.display.SimpleButton;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

class Clippy {
  // Main
  static function main() {
    var text:String = flash.Lib.current.loaderInfo.parameters.text;
    
    // label
    
    var label:TextField = new TextField();
    var format:TextFormat = new TextFormat("Arial", 10);
    
    label.text = "copy to clipboard";
    label.setTextFormat(format);
    label.textColor = 0x888888;
    label.selectable = false;
    label.x = 15;
    label.visible = false;
    
    flash.Lib.current.addChild(label);
    
    // button
    
    var button:SimpleButton = new SimpleButton();
    button.useHandCursor = true;
    button.upState = flash.Lib.attach("button_up");
    button.overState = flash.Lib.attach("button_over");
    button.downState = flash.Lib.attach("button_down");
    button.hitTestState = flash.Lib.attach("button_down");
    
    button.addEventListener(MouseEvent.MOUSE_UP, function(e:MouseEvent) {
      flash.system.System.setClipboard(text);
      label.text = "copied!";
      label.setTextFormat(format);
    });
    
    button.addEventListener(MouseEvent.MOUSE_OVER, function(e:MouseEvent) {
      label.visible = true;
    });
    
    button.addEventListener(MouseEvent.MOUSE_OUT, function(e:MouseEvent) {
      label.visible = false;
      label.text = "copy to clipboard";
      label.setTextFormat(format);
    });
    
    flash.Lib.current.addChild(button);
  }
}