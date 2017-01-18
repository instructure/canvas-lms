define([
  'underscore',
  'tinymce.config',
  'setupAndFocusTinyMCEConfig',
  'INST'
], function(_, EditorConfig, setupAndFocusTinyMCEConfig, INST){
  return function(width, id, tinyMCEInitOptions, enableBookmarkingOverride, tinymce){
    var editorConfig = new EditorConfig(tinymce, INST, width, id);

    // RichContentEditor takes care of the autofocus functionality at a higher level
    var autoFocus = undefined

    return _.extend({},
      editorConfig.defaultConfig(),
      setupAndFocusTinyMCEConfig(tinymce, autoFocus, enableBookmarkingOverride),
      (tinyMCEInitOptions.tinyOptions || {})
    );

  };
});
