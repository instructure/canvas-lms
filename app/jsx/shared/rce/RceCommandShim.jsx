define([
  'jquery',

  // for legacy pathways
  'wikiSidebar',
  'exports'
], ($, wikiSidebar, exports) => {
  // for each command, there are three possibilities:
  //
  //   .data('remoteEditor') is set:
  //     feature flag is on and succeeded, just use the remote editor call
  //
  //   .data('rich_text') is set:
  //     feature flag is off, use the legacy editorBox/wikiSidebar interface
  //
  //   neither is set:
  //     probably feature flag is on but failed, or maybe just a poorly set up
  //     spec (or worst case, poorly set up actual usage... booo). the action
  //     will do the best it can (see send for example), but often will be a
  //     no-op
  //
  Object.assign(exports, {

    send ($target, methodName, ...args) {
      const remoteEditor = $target.data('remoteEditor')
      if (remoteEditor) {
        if (methodName === 'get_code' && remoteEditor.isHidden()) {
          return $target.val()
        }
        return remoteEditor.call(methodName, ...args)
      } else if ($target.data('rich_text')) {
        return $target.editorBox(methodName, ...args)
      } else {
        // we're not set up, so tell the caller that `exists?` is false,
        // `get_code` is the textarea value, and ignore anything else.
        if (methodName === 'exists?') {
          return false
        } else if (methodName === 'get_code') {
          return $target.val()
        } else {
          console.warn(`called send('${methodName}') on an RCE instance that hasn't fully loaded, ignored`)
        }
      }
    },

    focus ($target) {
      const remoteEditor = $target.data('remoteEditor')
      if (remoteEditor) {
        remoteEditor.focus()
      } else if ($target.data('rich_text')) {
        wikiSidebar.attachToEditor($target)
      } else {
        console.warn("called focus() on an RCE instance that hasn't fully loaded, ignored")
      }
    },

    destroy ($target) {
      const remoteEditor = $target.data('remoteEditor')
      if (remoteEditor) {
        // detach the remote editor reference after destroying it
        remoteEditor.destroy()
        $target.data('remoteEditor', null)
      } else if ($target.data('rich_text')) {
        $target.editorBox('destroy')
      } else {
        console.warn("called destroy() on an RCE instance that hasn't fully loaded, ignored")
      }
    }
  })
})
