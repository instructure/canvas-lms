define([
  'jsx/shared/rce/serviceRCELoader',
], function(serviceRCELoader){
  return function(){
    if (window.ENV.RICH_CONTENT_SERVICE_ENABLED) {
      serviceRCELoader.preload(window.ENV.RICH_CONTENT_APP_HOST)
    }
  }
});
