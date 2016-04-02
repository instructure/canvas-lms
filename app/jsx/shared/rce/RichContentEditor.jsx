define([
  'jsx/shared/rce/serviceRCELoader',
  'jsx/shared/rce/RceCommandShim',
  'jquery'
], function(serviceRCELoader, RceCommandShim, $){

  var flagMap = {
    'basic': "RICH_CONTENT_SERVICE_ENABLED",
    'sidebar': "RICH_CONTENT_SIDEBAR_ENABLED",
    'highrisk': "RICH_CONTENT_HIGH_RISK_ENABLED"
  }

  function serviceHost() {
    return window.ENV.RICH_CONTENT_CDN_HOST || window.ENV.RICH_CONTENT_APP_HOST
  }

  function loadRCEViaService (target, tinyMCEInitOptions) {
    serviceRCELoader.loadOnTarget(target, tinyMCEInitOptions, serviceHost())
  }

  function loadSidebarViaService (target, callback){
    serviceRCELoader.loadSidebarOnTarget(target, serviceHost(), callback)
  }

  function loadRCEViaEditorBox(target, tinyMCEInitOptions){
    return tinyMCEInitOptions.defaultContent ?
      target.editorBox(tinyMCEInitOptions).editorBox('set_code', tinyMCEInitOptions.defaultContent) :
      target.editorBox(tinyMCEInitOptions)
  }

  function flagToHeed(options){
    var riskLevel = options.riskLevel || 'highrisk'
    var flagToHeed = flagMap[riskLevel]
    return window.ENV[flagToHeed]
  }

  function sidebarContainer(){
    return document.getElementById("editor_tabs")
  }

  function establishParentNode(target){
    // some areas would wipe out the whole form
    // if we rendered a new editor into the textarea parent
    // element, so this is some helper functionality to create/reuse
    // a parent element if that's the case
    let targetId = target.attr("id")
    // xsslint safeString.identifier targetId parentId
    let parentId = "tinymce-parent-of-" + targetId
    if(target.parent().attr("id") == parentId){
      return // parent wrapper already exits
    }else{
      return target.wrap( "<div id='"+ parentId +"'></div>")
    }
  }

  var RichContentEditor = function(options){
    var options = options || {}
    this.featureFlag = flagToHeed(options)

    this.jQuery = options.jQuery || $ // useful for contextual overrides of global jquery
    this.commandShim = new RceCommandShim({jQuery: this.jQuery})

    // sort of crummy for now, but need to maintain an abstraction over old
    // and new sidebar usage, and this is similar to the way the old
    // wikiSidebar is basically a singleton.  Once we get rid of the
    // old wikiSidebar, we can hand the object/component itself back to use cases
    // and let them interact with it directly
    this.wikiSidebar = options.sidebar
    this.remoteSidebar = undefined
  }

  RichContentEditor.prototype.freshNode = function(target){
    // we need to make sure we have the latest node
    // in order to capture any changes, lots of views like to use
    // stale nodes
    let targetId = target.attr("id")
    return this.jQuery("#" + targetId)
  }

  RichContentEditor.prototype.loadNewEditor = function(target, tinyMCEInitOptions={}){
    // avoid modifying the original options object provided
    tinyMCEInitOptions = this.jQuery.extend({}, tinyMCEInitOptions)

    if (this.jQuery(target).length <= 0) {
      // no actual target, just short circuit out
      return
    }

    if(this.featureFlag){
      target = this.freshNode(target)

      if(tinyMCEInitOptions.manageParent){
        // if the direct parent of a textarea is the form itself,
        // we'd wipe the whole form out if we rendered into it's parent.
        //  This option lets users specify that they want RichContentEditor
        // to maintain a parent node for rendering
        delete tinyMCEInitOptions.manageParent
        establishParentNode(target)
      }

      loadRCEViaService(target, tinyMCEInitOptions)
    }else{
      loadRCEViaEditorBox(target, tinyMCEInitOptions)
    }
  }

  RichContentEditor.prototype.initSidebar = function(){
    if (this.featureFlag) {
      loadSidebarViaService(sidebarContainer(), (sidebarInstance)=>{
        this.remoteSidebar = sidebarInstance
      })
    } else {
      this.wikiSidebar && this.wikiSidebar.init()

    }
  }

  RichContentEditor.prototype.hideSidebar = function(){
    if (this.featureFlag) {
      //currentSidebar.hide()
      console.log("would have hidden sidebar; UNIMPLEMENTED")
    } else {
      if(this.wikiSidebar){
        this.wikiSidebar.hide()
      }
    }
  }

  RichContentEditor.prototype.attachSidebarTo = function(target, callback){
    var hasSidebar = this.wikiSidebar || this.remoteSidebar
    if (hasSidebar) {
      if (this.featureFlag) {
        //currentSidebar.attachToEditor(target)
        target = this.freshNode(target)
        console.log("would have attached sidebar to editor; UNIMPLEMENTED")
        sidebarContainer().style.display = ''
      } else {
        this.wikiSidebar.attachToEditor(target)
        this.wikiSidebar.show()
      }
      if(callback){
        callback()
      }
    }
  }

  RichContentEditor.prototype.preloadRemoteModule = function(){
    if (this.featureFlag) {
      serviceRCELoader.preload(serviceHost())
    }
  }

  RichContentEditor.prototype.callOnRCE = function(target, methodName, ...args){
    if(this.featureFlag){
      target = this.freshNode(target)
      return this.commandShim.send(target, methodName, ...args)
    } else {
      return target.editorBox(methodName, ...args)
    }
  }


  return RichContentEditor
});
