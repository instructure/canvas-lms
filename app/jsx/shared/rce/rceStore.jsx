define([
  'jquery',
  'underscore'
], function($, _){

  let RCEStore = {
    addToStore: function (targetId, RCEInstance) {
      window.tinyrce.editorsListing[targetId] = RCEInstance;
    },

    callOnEditor: function(textareaId, methodName, ...args) {
      let editor = window.tinyrce.editorsListing[textareaId]
      if (!editor) { return null }

      // since exists? has a ? and cant be a regular function (yet we want the
      // same signature as editorbox) just return true rather than calling as a
      // fn on the editor
      if (methodName === "exists?") {return true}
      return editor[methodName](...args)
    },

    callOnTarget: function ($target, methodName, ...args) {
      // freshen node; see comment in RichContentEditor.freshNode
      $target = $("#" + $target.attr("id"))
      if (methodName == 'get_code' && !$target.data("rich_text")) {
        // editor failed to get applied (data attribute missing);
        // user has been typing into this field as a bare text area,
        // and now is trying to get the contents ('get_code').
        // The best partial failure case for trying to get its contents
        // is to just use the data they've input.
        return $target.val()
      }
      return this.callOnEditor($target.id, methodName, ...args)
    }
  };

  return RCEStore;
});
