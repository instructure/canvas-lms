define([
  'compiled/views/tinymce/InsertUpdateImageView',
  'tinymce_plugins/instructure_equella/initializeEquella',
  'tinymce_plugins/instructure_external_tools/initializeExternalTools',
  'INST'
], function(InsertUpdateImageView, initializeEquella, initializeExternalTools, INST){

  return function (callbacks={}) {
    const validCallbacks = [
      "imagePickerCB",
      "equellaCB",
      "externalToolCB"
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
      initializeExternalTools(e.detail.ed, e.detail.url, INST)
      callbacks.externalToolCB()
    });
  }
});
