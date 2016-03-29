define([
  'jsx/shared/rce/serviceRCELoader',
], function(serviceRCELoader){
  return function(){
    if (window.ENV.RICH_CONTENT_SERVICE_ENABLED) {
      serviceRCELoader.preload(window.ENV.RICH_CONTENT_CDN_HOST || window.ENV.RICH_CONTENT_APP_HOST)
    }
  }
});
