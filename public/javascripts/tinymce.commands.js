define([
  'compiled/editor/stocktiny'
], function(tinymce){

  /**
   * @exports
   * A series of functions that wrap conditionals
   * and context around sending imperative commands to tinymce.
   *
   * They're all exported as self contained functions that hang off this
   * namespace with no global state
   * in this module because that's what has been really hurting debugging
   * efforts around tinymce issues in the past.
   *
   * Each function in this module will have a side effect of dispatching
   * some command to either the global tinymce module or a fetched
   * editor instance, and often other side effects that modulate
   * a passed in jquery object or the global editor registry.
   * (They aren't pure!!)
   */
  var EditorCommands = {

    /**
     * Make sure an editor is removed from everywhere we know about it.
     * This includes unregistering it with tinmyce, and with Instructure's
     * editorBoxList.
     *
     * @param {jQueryObject} editorNode the DOM element that this operation
     *   applies to.
     * @param {EditorBoxList} editorList our instance of the editor registry
     *   that keeps track of all the editors we know about.
     */
    remove: function(editorNode, editorList){
      var id = editorNode.attr('id');
      editorNode.data('rich_text', false);
      if(tinymce && tinymce.execCommand){
        tinymce.execCommand('mceRemoveEditor', false, id);
        editorList._removeEditorBox(id);
      }
    }

  };

  return EditorCommands;
});
