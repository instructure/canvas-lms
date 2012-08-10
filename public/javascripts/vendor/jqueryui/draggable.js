define(['jquery', 'jqueryui/draggable-unpatched', 'vendor/jquery.ui.touch-punch'], function ($, returnValueOfUnpatchedDraggable) {

  var _mouseMove = $.ui.draggable.prototype._mouseMove;
  $.ui.draggable.prototype._mouseMove = function() {
    var ret = _mouseMove.apply(this, arguments);
    // Workaround-Instructure: this is a custom behavior added to jqueryUI draggable to make it work for resizing tiny.
    // look for instructureHackToNotAutoSizeTop in tinymce.editor_box.js to see where it is used.
    if (this.options.instructureHackToNotAutoSizeTop) this.helper[0].style.top = '';
    return ret;
  };

  return returnValueOfUnpatchedDraggable;
});
