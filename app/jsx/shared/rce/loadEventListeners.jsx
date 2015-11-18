define([
  'compiled/views/tinymce/InsertUpdateImageView',
], function(InsertUpdateImageView){

  return function (callback) {
    if(callback === undefined){
      callback = function(view){ /* no-op*/ }
    }

    document.addEventListener('tinyRCE/initImagePicker', function(e){
      let view = new InsertUpdateImageView(e.detail.ed, e.detail.selectedNode);
      callback(view)
    });
  }

});
