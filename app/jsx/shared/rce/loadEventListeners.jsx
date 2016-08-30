define([
  'compiled/views/tinymce/InsertUpdateImageView',
  'tinymce_plugins/instructure_equella/initializeEquella',
  'tinymce_plugins/instructure_external_tools/initializeExternalTools',
  'tinymce_plugins/instructure_record/mediaEditorLoader',
  'INST'
], function(InsertUpdateImageView, initializeEquella, initializeExternalTools, mediaEditorLoader, INST){

  return function (callbacks={}) {
    const validCallbacks = [
      "imagePickerCB",
      "equellaCB",
      "externalToolCB",
      "recordCB"
    ]

    validCallbacks.forEach( (cbName) => {
      if (callbacks[cbName] === undefined) {
        callbacks[cbName] = function(){ /* no-op*/ }
      }
    })

    document.addEventListener('tinyRCE/initImagePicker', function(e){
      let view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode);
      callbacks.imagePickerCB(view)
    });

    document.addEventListener('tinyRCE/initEquella', function(e) {
      initializeEquella(e.detail.ed)
      callbacks.equellaCB()
    });

    document.addEventListener('tinyRCE/initExternalTools', function(e) {
      initializeExternalTools.init(e.detail.ed, e.detail.url, INST)
      callbacks.externalToolCB()
    });

    document.addEventListener('tinyRCE/initRecord', function(e) {
      mediaEditorLoader.insertEditor(e.detail.ed)
      callbacks.recordCB()
    });
  }
});
