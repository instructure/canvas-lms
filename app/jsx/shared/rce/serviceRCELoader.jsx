define([
  'jquery',
  'underscore',
  'jsx/shared/rce/editorOptions',
  'jsx/shared/rce/rceStore',
  'jsx/shared/rce/loadEventListeners'
], function($, _, editorOptions, RCEStore, loadEventListeners){
  let RCELoader = {
    preload(host) {
      this.loadRCE(host, function(){})
    },

    loadOnTarget(target, tinyMCEInitOptions, host) {
      const textarea = this.getTargetTextarea(target)
      const getTargetFn = tinyMCEInitOptions.getRenderingTarget || this.getRenderingTarget
      const renderingTarget = getTargetFn(textarea)
      const propsForRCE = this.createRCEProps(textarea, tinyMCEInitOptions)

      const renderCallback = function(rceInstance){
        RCEStore.addToStore(textarea.id, rceInstance)
      }

      this.loadRCE(host, function (RCE) {
        RCE.renderIntoDiv(renderingTarget, propsForRCE, renderCallback)
      })
    },

    loadSidebarOnTarget(target, host, callback){
      let props = {}
      this.loadRCE(host, function (RCE) {
        RCE.renderSidebarIntoDiv(target, props, callback)
      })
    },

    /**
    * properties for managing several requests to load
    * the module from various pieces of canvas code.
    *
    * @private
    */
    cachedModule: null,
    loadingFlag: false,
    loadingCallbacks: [],

    /**
    * handle accepting new load requests depending on the current state
    * of the load/cache cycle
    *
    * @private
    */
    loadRCE(host, cb) {
      if(this.cachedModule !== null){
        cb(this.cachedModule)
      } else {
        this.loadingCallbacks.push(cb)
        if(!this.loadingFlag){
          // we need to make sure we don't make this kinda expensive request
          // multiple times, so anybody who wants the module can queue up
          // a callback, but first one to this point performs the load
          this.loadingFlag = true
          let moduleUrl = this.buildModuleUrl(host)
          $.getScript(moduleUrl, (res) => { this.onRemoteLoad() })
        }
      }
    },

    /**
    * sometimes we get passed a container that has the
    * textarea nested within it, we want to normalize to
    * just using whatever textarea is going to be bound to
    * the editor
    *
    * @private
    * @return {Element} the textarea
    */
    getTargetTextarea(initialTarget) {
      return $(initialTarget).get(0).type == "textarea" ?
        $(initialTarget).get(0) :
        $(initialTarget).find("textarea").get(0)
    },

    /**
    * the immediate parent of the textarea is the container
    * we want to render the remote react component inside, so it's
    * a sibiling with the actual form element being populated.
    *
    * @private
    * @return {Element} container element for rendering remote editor
    */
    getRenderingTarget(textarea) {
      return $(textarea).parent().get(0)
    },

    /**
    * anything that canvas needs to later find this
    * editor/textarea should be mirrored here so we
    * dont have to change too much canvas code
    *
    * @private
    * @return {Hash}
    */
    _attrsToMirror(textarea) {
      let validAttrs = ["name"]
      let attrs = _.reduce(textarea.attributes, (memo, attr) => {
        memo[attr.name] = attr.value
        return memo
      }, {})

      return _.pick(attrs, validAttrs)
    },

    /**
     * merges options provided by consuming code with some
     * intelligent defaults so that simple use cases can not
     * worry about providing repetitive options hashes.
     *
     * @private
     * @return {Hash} ready-to-use options hash to use as react props
     */
    createRCEProps(textarea, tinyMCEInitOptions) {
      let width = textarea.offsetWidth
      let height = textarea.offsetHeight

      if (height){
        tinyMCEInitOptions.tinyOptions = _.extend({},
          {height: height},
          (tinyMCEInitOptions.tinyOptions || {})
        )
      }

      return {
        editorOptions: editorOptions.bind(null, width, textarea.id, tinyMCEInitOptions, null),
        defaultContent: textarea.value || tinyMCEInitOptions.defaultContent,
        textareaId: textarea.id,
        textareaClassName: textarea.className,
        language: ENV.LOCALE,
        mirroredAttrs: this._attrsToMirror(textarea)
      }
    },

    /**
     * helps with url construction which is different when using a CDN
     * than when loading directly from an RCE server
     *
     * @private
     * @return {String} ready-to-use URL for loading RCE remotely
     */
    buildModuleUrl(host) {
      // trim trailing slash if there is one, as we're going to add one below
      host = host.replace(/\/$/, "")
      var moduleUrl = '//'+ host +'/get_module'
      if(host.indexOf("cloudfront") > -1){
        moduleUrl = '//' + host + '/latest'
      }
      return moduleUrl
    },

    /**
     * called when remote module has finished loading
     * so we can set the cache appropriately, un-set the loading
     * flag, and deal with any callbacks that have been queueing up that
     * need the module to execute.  Anything outside of this file using
     * this function could damage state and make the remote module loading fail.
     *
     * @private
     */
    onRemoteLoad() {
      loadEventListeners()
      if(!this.cachedModule){ this.cachedModule = RceModule }
      this.loadingFlag = false
      this.loadingCallbacks.forEach((loadingCallback)=>{
        loadingCallback(this.cachedModule)
      })
      this.loadingCallbacks = []
    }
  }

  return RCELoader;
});
