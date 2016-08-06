define(["jquery", 'jsx/shared/rce/RceCommandShim'], function($, RceCommandShim){

  /**
   * This is not yet a complete extraction, but the idea is to continue
   * moving direct interactions with the relevant tinymce editor
   * out of the link plugin itself and into this proxy object.
   *
   * The need first arose in response to an IE11 bug where some state
   * (specifically the currently selected content) needed to be extracted
   * and held onto at the time the link modal is generated, because IE11
   * loses the editor carat on a modal activation.  Rather than
   * use variables with very broad scope in the plugin itself to capture the
   * state at one point and use in another, this hides the temporary
   * persistance inside a kind of decorator.
   *
   * @param {tinymce.Editor} editor the tinymce instance we want
   *   to add links to
   * @param {jquery.Object} $editorEl an optional override for the editor target
   *   that can be found in normal circumstances by calling "getEditor"
   */
  var LinkableEditor = function(editor, $editorEl){

    this.id = editor.id;
    this.selectedContent = editor.selection.getContent();
    this.$editorEl = $editorEl;

    /**
     * Builds a jquery object wrapping the target text area for the
     * wrapped tinymce editor. Can be overridden in the constructor with
     * an optional second parameter.
     *
     * @returns {jquery.Object}
     */
    this.getEditor = function(){
      if(this.$editorEl !== undefined){
        return this.$editorEl;
      }
      return $("#" + this.id);
    };

    /**
     * proxies through a call to our jquery extension that puts new link
     * html into an existing tinymce editor.  Specifically useful
     * because of the "selectedContent" and "selectedRange" which are stored
     * at the time the link creation dialog is created (this is important
     * because in IE11 that information is lost as soon as the modal dialog
     * comes up)
     *
     * @param {String} text the interior content for the a tag
     * @param {String} classes any css classes to apply to the new link
     * @param {Object} [dataAttrs] key value pairs for link data attributes
     */
    this.createLink = function(text, classes, dataAttrs){
      RceCommandShim.send(this.getEditor(), "create_link",{
        url: text,
        classes: classes,
        selectedContent: this.selectedContent,
        dataAttributes: dataAttrs
      });
    };
  };

  return LinkableEditor;
});
