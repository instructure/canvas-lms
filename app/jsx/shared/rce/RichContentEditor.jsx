define([
  'jsx/shared/rce/serviceRCELoader',
  'jsx/shared/rce/RceCommandShim',
  'jsx/shared/rce/Sidebar',
  'jsx/shared/rce/featureFlag',
  'jquery',

  // for legacy pathways
  'tinymce.editor_box',
  'compiled/tinymce'
], function(serviceRCELoader, RceCommandShim, Sidebar, featureFlag, $) {

  function loadServiceRCE(target, tinyMCEInitOptions, callback) {
    serviceRCELoader.loadOnTarget(target, tinyMCEInitOptions, (textarea, remoteEditor) => {
      let $textarea = freshNode($(textarea))
      $textarea.data('remoteEditor', remoteEditor)
      if (callback) {
        callback()
      }
    })
  }

  function loadLegacyRCE(target, tinyMCEInitOptions, callback) {
    tinyMCEInitOptions.defaultContent ?
      target.editorBox(tinyMCEInitOptions).editorBox('set_code', tinyMCEInitOptions.defaultContent) :
      target.editorBox(tinyMCEInitOptions)
    if (callback) {
      callback()
    }
  }

  function establishParentNode(target) {
    // some areas would wipe out the whole form
    // if we rendered a new editor into the textarea parent
    // element, so this is some helper functionality to create/reuse
    // a parent element if that's the case
    let targetId = target.attr("id")
    // xsslint safeString.identifier targetId parentId
    let parentId = "tinymce-parent-of-" + targetId
    if (target.parent().attr("id") == parentId) {
      return // parent wrapper already exits
    } else {
      return target.wrap( "<div id='"+ parentId +"'></div>")
    }
  }

  function hideResizeHandleForScreenReaders() {
    $('.mce-resizehandle').attr('aria-hidden', true)
  }

  // Returns a unique id
  let _editorUid = 0;
  function nextID(){
    return "random_editor_id_" + _editorUid++;
  }

  /**
   * Make sure each the element has an id. If it
   * doesn't, give it a random one.
   * @private
   */
  function ensureID($el){
    const id = $el.attr('id')
    if(!id || id==''){
      $el.attr('id', nextID());
    }
  }

  /**
   * we need to make sure we have the latest node in order to capture any
   * changes, lots of views like to use stale nodes
   *
   * @private
   */
  function freshNode($target) {
    // Try to get the id
    let targetId = $target.attr("id")
    if(!targetId || targetId==''){
      return $target
    }
    // Try to get the element on the DOM
    let newTarget = $("#" + targetId)
    if(newTarget.length<=0){
      return $target
    }
    return newTarget
  }

  const RichContentEditor = {
    /**
     * start the remote module (if the feature flag is on) loading so that it's
     * hopefully done by the time initSidebar and loadNewEditor are called.
     * should typically be called at the top of any source file that calls one
     * of those.
     *
     * @public
     */
    preloadRemoteModule() {
      if (featureFlag()) {
        serviceRCELoader.preload()
      }
    },

    /**
     * load the sidebar. can pass callbacks to execute any time the sidebar is
     * shown (`show`) or hidden (`hide`).
     *
     * @public
     */
    initSidebar(subscriptions={}) {
      Sidebar.init(subscriptions)
    },

    /**
     * load an editor into the target element with the given options. most
     * options are passed on to tinymce, but locally:
     *
     *   focus (boolean)
     *     claim the new editor as active immediately after it's loaded
     *     (including showing the sidebar if any)
     *
     *   manageParent (boolean)
     *     ensure the target element has a containing div that doesn't contain
     *     the element's siblings, so when the RCE is rendered into the
     *     container it doesn't wipe out other parts of the DOM
     *
     * @public
     */
    loadNewEditor($target, tinyMCEInitOptions={}) {

      if ($target.length <= 0) {
        // no actual target, just short circuit out
        return
      }

      ensureID($target)

      // avoid modifying the original options object provided
      tinyMCEInitOptions = $.extend({}, tinyMCEInitOptions)

      let callback = undefined
      if (tinyMCEInitOptions.focus) {
        // call activateRCE once loaded
        callback = this.activateRCE.bind(this, $target)
      }

      if (featureFlag()) {
        $target = this.freshNode($target)

        if (tinyMCEInitOptions.manageParent) {
          delete tinyMCEInitOptions.manageParent
          establishParentNode($target)
        }

        const originalOnFocus = tinyMCEInitOptions.onFocus
        tinyMCEInitOptions.onFocus = (editor) => {
          this.activateRCE($target)
          if (typeof originalOnFocus === 'function') {
            originalOnFocus(editor)
          }
        }

        loadServiceRCE($target, tinyMCEInitOptions, callback)
      } else {
        loadLegacyRCE($target, tinyMCEInitOptions, callback)

        // listen for editor_box_focus events on our target, and trigger
        // activateRCE from them
        $target.on('editor_box_focus', () => this.activateRCE($target))
      }

      hideResizeHandleForScreenReaders()
    },

    /**
     * call a function on the target editor.
     *
     * @public
     */
    callOnRCE($target, methodName, ...args) {
      if (featureFlag()) {
        $target = this.freshNode($target)
      }
      return RceCommandShim.send($target, methodName, ...args)
    },

    /**
     * remove the target editor. if there's a sidebar, hide it
     *
     * @public
     */
    destroyRCE($target) {
      if (featureFlag()) {
        $target = this.freshNode($target)
      }
      RceCommandShim.destroy($target)
      Sidebar.hide()
    },

    /**
     * make the target the active editor, including to be recipient of sidebar
     * events. if there's a sidebar, make sure it's showing
     *
     * @private
     */
    activateRCE($target) {
      if (featureFlag()) {
        $target = this.freshNode($target)
      }
      RceCommandShim.focus($target)
      Sidebar.show()
    },

    freshNode: freshNode,

    ensureID: ensureID
  }

  return RichContentEditor
})
