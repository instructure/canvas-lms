define(['jquery'], function($) {


  var RceCommandShim = function() {}

  RceCommandShim.prototype.send = function ($target, methodName, ...args) {
    let remoteEditor = $target.data('remoteEditor')
    if (remoteEditor) {
      // just proxy to the remote editor
      return remoteEditor.call(methodName, ...args)
    } else if ($target.data('rich_text')) {
      // no remote editor, but does have tinymce: feature flag is off, use
      // editorBox
      return $target.editorBox(methodName, ...args)
    } else {
      // one of the two should have been set by a call to
      // RichContentEditor#loadOnTarget. but:
      //
      //  (1) maybe RichContentEditor#loadOnTarget failed; or
      //
      //  (2) some spec called it incidentally without having called
      //  loadOnTarget first
      //
      // in either case, just tell the caller that `exists?` is false,
      // `get_code` is the textarea value, and ignore anything else.
      //
      if (methodName == 'exists?') {
        return false
      } else if (methodName == 'get_code') {
        return $target.val()
      } else {
        console.warn("calling '" + methodName + "' on an RCE instance that hasn't fully loaded, ignored")
      }
    }
  }

  return RceCommandShim
});
