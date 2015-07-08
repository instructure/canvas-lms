define(["jquery"], function($){

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

    /**
     * Firefox has some special needs here because when we
     * ask tinymce for text content, in FF we get the alt text of any
     * img tag.  This helper function wraps that interaction, checks for
     * an img tag with alt attribute for "textContent", and replaces it with
     * a blank string if so.  This is important because our link injecting code
     * checks for blank string to decide whether to wrap a DOM node in an
     * a tag or just take the text and put an anchor around it.  We want it
     * to wrap the dom node in the case of an image so the image stays on the
     * page.
     *
     * @param {tinymce.Selection} selection the object representing the users
     *  currently selected content in the RCE, usually comes from "editor.selection"
     *
     * @returns {String}
     */
    this.extractTextContent = function(selection){
      var textContent = selection.getContent({format: "text"});
      var $content = $(selection.getContent());
      if($content.prop("tagName") == "IMG" && textContent == $content.attr("alt") && $content.html() == ""){
        textContent = "";
      }

      return textContent;
    };

    this.id = editor.id;
    this.selectedContent = this.extractTextContent(editor.selection);
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
     */
    this.createLink = function(text, classes){
      this.getEditor().editorBox("create_link", {
        url: text,
        classes: classes,
        selectedContent: this.selectedContent
      });
    };
  };

  return LinkableEditor;
});
