define([
  'underscore',
  'tinymce.config',
  'setupAndFocusTinyMCEConfig',
  'INST'
], function(_, EditorConfig, setupAndFocusTinyMCEConfig, INST){
  return function(width, id, tinyMCEInitOptions, enableBookmarkingOverride, tinymce){
    var editorConfig = new EditorConfig(tinymce, INST, width, id);
    var autoFocus = tinyMCEInitOptions.focus ? id : null

    return _.extend({},
      editorConfig.defaultConfig(),
      setupAndFocusTinyMCEConfig(tinymce, autoFocus, enableBookmarkingOverride),
      (tinyMCEInitOptions.tinyOptions || {})
    );

  };
});
