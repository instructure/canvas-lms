define([
  'jsx/shared/rce/serviceRCELoader'
], function(serviceRCELoader){
  function loadRCEViaService (target, tinyMCEInitOptions) {
    serviceRCELoader.loadOnTarget(
      target,
      tinyMCEInitOptions,
      window.ENV.RICH_CONTENT_CDN_HOST || window.ENV.RICH_CONTENT_APP_HOST
    )
  }

  function loadRCEViaEditorBox(target, tinyMCEInitOptions){
    return tinyMCEInitOptions.defaultContent ?
      target.editorBox(tinyMCEInitOptions).editorBox('set_code', tinyMCEInitOptions.defaultContent) :
      target.editorBox(tinyMCEInitOptions)
  }

  function loadNewRCE (target, tinyMCEInitOptions={}) {
    return window.ENV.RICH_CONTENT_SERVICE_ENABLED ?
      loadRCEViaService(target, tinyMCEInitOptions) :
      loadRCEViaEditorBox(target, tinyMCEInitOptions)
  }

  return loadNewRCE;
});
