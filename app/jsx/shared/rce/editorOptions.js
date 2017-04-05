import _ from 'underscore'
import EditorConfig from 'tinymce.config'
import setupAndFocusTinyMCEConfig from 'setupAndFocusTinyMCEConfig'
import INST from 'INST'

  function editorOptions (width, id, tinyMCEInitOptions, enableBookmarkingOverride, tinymce){
    var editorConfig = new EditorConfig(tinymce, INST, width, id);

    // RichContentEditor takes care of the autofocus functionality at a higher level
    var autoFocus = undefined

    return _.extend({},
      editorConfig.defaultConfig(),
      setupAndFocusTinyMCEConfig(tinymce, autoFocus, enableBookmarkingOverride),
      (tinyMCEInitOptions.tinyOptions || {})
    );

  };

export default editorOptions
