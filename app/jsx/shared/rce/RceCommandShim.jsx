define(['jsx/shared/rce/rceStore', 'jquery'], function(RCEStore, $) {


  var RceCommandShim = function() {}

  RceCommandShim.prototype.send = function (target, methodName, ...args) {
    if(window.ENV.RICH_CONTENT_SERVICE_CONTEXTUALLY_ENABLED){
      return RCEStore.callOnTarget(target, methodName, ...args)
    } else {
      return target.editorBox(methodName, ...args)
    }
  }

  return RceCommandShim
});
