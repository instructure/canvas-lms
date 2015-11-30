define([
  'compiled/views/tinymce/InsertUpdateImageView',
  'tinymce_plugins/instructure_equella/initializeEquella'
], function(InsertUpdateImageView, initializeEquella){

  return function (callbacks={}) {
    if(callbacks.imagePickerCB === undefined){
      callbacks.imagePickerCB = function(view){ /* no-op*/ }
    }

    if(callbacks.equellaCB === undefined){
      callbacks.equellaCB = function(view){ /* no-op*/ }
    }

    document.addEventListener('tinyRCE/initImagePicker', function(e){
      let view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode);
      // cb for testing
      callbacks.imagePickerCB(view)
    });

    document.addEventListener('tinyRCE/initEquella', function(e) {
      initializeEquella(e.detail.ed)
      // cb for testing
      callbacks.equellaCB()
    });
  }
});
