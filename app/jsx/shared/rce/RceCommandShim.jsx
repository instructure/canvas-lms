define(['jsx/shared/rce/rceStore', 'jquery'], function(RCEStore, $) {


  var RceCommandShim = function(options){
    var options = options || {}
    this.jQuery = options.jQuery || $ // useful for contextual overrides of global jquery
    this.store = options.store || RCEStore
  }

  RceCommandShim.prototype.send = function (target, methodName, ...args) {
    if(window.ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED){
      var liveNode = this.jQuery("#" + target.attr("id"))
      if(methodName == 'get_code' && !liveNode.data("rich_text")){
        // editor failed to get applied (data attribute missing);
        // user has been typing into this field as a bare text area,
        // and now is trying to get the contents ('get_code').
        // The best partial failure case for trying to get its contents
        // is to just use the data they've input.
        return target.val()
      }
      return this.store.callOnRCE(target, methodName, ...args)
    } else {
      return target.editorBox(methodName, ...args)
    }
  }

  return RceCommandShim
});
