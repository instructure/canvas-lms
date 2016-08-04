define([
  'jquery',
  'underscore',
  'jsx/shared/rce/editorOptions',
  'jsx/shared/rce/loadEventListeners',
  'jsx/shared/rce/polyfill',
  'compiled/str/splitAssetString'
], function($, _, editorOptions, loadEventListeners, polyfill, splitAssetString) {

  let refreshToken = function(callback){
    return $.post("/api/v1/jwts").done((response)=>{
      callback(response.token)
    })
  }

  let RCELoader = {
    preload() {
      this.loadRCE(function(){})
    },

    loadOnTarget(target, tinyMCEInitOptions, callback) {
      const textarea = this.getTargetTextarea(target)
      const renderingTarget = this.getRenderingTarget(textarea, tinyMCEInitOptions.getRenderingTarget)
      const propsForRCE = this.createRCEProps(textarea, tinyMCEInitOptions)

      this.loadRCE(function(RCE) {
        RCE.renderIntoDiv(renderingTarget, propsForRCE, function(remoteEditor) {
          callback(textarea, polyfill.wrapEditor(remoteEditor))
        })
      })
    },

    loadSidebarOnTarget(target, callback) {
      let context = splitAssetString(ENV.context_asset_string)
      let props = {
        jwt: ENV.JWT,
        refreshToken: refreshToken,
        host: ENV.RICH_CONTENT_APP_HOST,
        canUploadFiles: ENV.RICH_CONTENT_CAN_UPLOAD_FILES,
        contextType: context[0],
        contextId: context[1],
        themeUrl: ENV.active_brand_config_json_url
      }
      this.loadRCE(function (RCE) {
        RCE.renderSidebarIntoDiv(target, props, function(remoteSidebar) {
          callback(polyfill.wrapSidebar(remoteSidebar))
        })
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
    loadRCE(cb) {
      if(this.cachedModule !== null){
        cb(this.cachedModule)
      } else {
        this.loadingCallbacks.push(cb)
        if(!this.loadingFlag){
          // we need to make sure we don't make this kinda expensive request
          // multiple times, so anybody who wants the module can queue up
          // a callback, but first one to this point performs the load
          this.loadingFlag = true
          let moduleUrl = this.buildModuleUrl()
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
    getRenderingTarget(textarea, getTargetFn = undefined) {
      let renderingTarget

      if (typeof getTargetFn === 'undefined') {
        renderingTarget = $(textarea).parent().get(0)
      } else {
        renderingTarget = getTargetFn(textarea)
      }
      $(renderingTarget).addClass('ic-RichContentEditor')

      return renderingTarget
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
        mirroredAttrs: this._attrsToMirror(textarea),
        onFocus: tinyMCEInitOptions.onFocus
      }
    },

    /**
     * helps with url construction which is different when using a CDN
     * than when loading directly from an RCE server
     *
     * @private
     * @return {String} ready-to-use URL for loading RCE remotely
     */
    buildModuleUrl() {
      let host, path
      if (window.ENV.RICH_CONTENT_CDN_HOST) {
        host = window.ENV.RICH_CONTENT_CDN_HOST
        path = '/latest'
      } else {
        host = window.ENV.RICH_CONTENT_APP_HOST
        path = '/get_module'
      }
      // trim trailing slash if there is one, as we're going to add one below
      host = host.replace(/\/$/, "")
      return '//' + host + path
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
