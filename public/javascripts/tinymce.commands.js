define([
  "compiled/editor/stocktiny"
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
      var id = editorNode.attr("id");
      editorNode.data("rich_text", false);
      if(tinymce && tinymce.execCommand){
        tinymce.execCommand("mceRemoveEditor", false, id);
        editorList._removeEditorBox(id);
      }
    },

    isOnlyText: function(maybeHtml){
      return !(/</.test(maybeHtml) &&
              (!/^<a [^>]+>[^<]+<\/a>$/.test(maybeHtml) ||
              maybeHtml.indexOf('href=') == -1));
    },

    /**
     * Provide a means for inputting a link at the cursor point, after
     * re-establishing focus (important for IE11, which apparently hates
     * focus and will not remember your selection unless you explicitly
     * refocus).
     *
     * @param {String} id the id attribute of the tinymce node to add to
     * @param {String} content the text of the link inside the a tag,
     *   often passed in as the previously selected text prior to trying to
     *   create a link
     * @param {Hash} linkAttrs other attributes for the link (class, target, etc)
     */
    insertLink: function(id, content, linkAttrs){
      var editor = tinymce.get(id);
      editor.focus();
      if (EditorCommands.isOnlyText(content)) {
        var linkContent = editor.dom.encode(content);
        var linkHtml = editor.dom.createHTML("a", linkAttrs, linkContent);
        editor.insertContent(linkHtml);
      } else {
        editor.execCommand('mceInsertLink', false, linkAttrs);
      }
    }

  };

  return EditorCommands;
});
