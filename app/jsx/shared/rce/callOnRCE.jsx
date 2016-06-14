define(['jsx/shared/rce/rceStore'], function(RCEStore) {
  return function (target, methodName, ...args) {
    return window.ENV.RICH_CONTENT_SERVICE_ENABLED ?
      RCEStore.callOnRCE(target, methodName, ...args) :
      target.editorBox(methodName, ...args) ;
  };
});
