define([], function(){

  /**
   * A collection of functions that extract business logic
   * from the sphaghetti that is tinymce.editor_box.js
   *
   * They're all exported as self contained functions that hang off this
   * namespace with no global state
   * in this module because that's what has been really hurting debugging
   * efforts around tinymce issues in the past.
   *
   * functions in this module SHOULD NOT have side effects,
   * but should be focused around providing necessary data
   * or dom transformations with no state in this file.
   * @exports
   */
  var editorboxUtils = {

    /**
     * transforms an input url to make a link out of
     * into a correctly formed url.  If it's clearly a mailing link,
     * adds mailto: to the front, and if it has no protocol but isn't an
     * absolute path, it prepends "http://".
     *
     * @param {string} input the raw url representative input by a user
     *
     * @returns {string} a well formed url
     */
    cleanUrl: function(input){
      var url = input;
      if(input.match(/@/) && !input.match(/\//) && !input.match(/^mailto:/)) {
        url = "mailto:" + input;
      } else if(!input.match(/^\w+:\/\//) && !input.match(/^mailto:/) && !input.match(/^\//)) {
        url = "http://" + input;
      }

      if(url.indexOf("@") != -1 && url.indexOf("mailto:") != 0 && !url.match(/^http/)) {
        url = "mailto:" + url;
      }
      return url;
    }
  };

  return editorboxUtils;
});
