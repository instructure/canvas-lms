define([
  'underscore',
  'tinymce.config',
  'setupAndFocusTinyMCEConfig',
  'INST'
], function(_, EditorConfig, setupAndFocusTinyMCEConfig, INST){
  return function(width, id, tinymce){
    var config = new EditorConfig(tinymce, INST, width, id);
    return _.extend({}, config.defaultConfig(), setupAndFocusTinyMCEConfig(tinymce, id, !!INST.browser.ie));
  };
});
