define([
  'jquery',
  'underscore',
  'jsx/shared/rce/editorOptions',
  'jsx/shared/rce/rceStore',
  'jsx/shared/rce/loadEventListeners'
], function($, _, editorOptions, RCEStore, loadEventListeners){
  let RCELoader = {
    cachedModule: null,

    setCache(val) {
      this.cachedModule = val;
    },

    preload(host) {
      this.loadRCE(host, function(){})
    },

    loadRCE(host, cb) {
      if(this.cachedModule !== null){
        cb(this.cachedModule)
      } else {
        $.getScript('http://'+ host +'/get_module', (res) => {
          loadEventListeners()
          if(!this.cachedModule){ this.setCache(RceModule) }
          cb(this.cachedModule);
        })
      }
    },

    getTargetTextarea(initialTarget) {
      return $(initialTarget).get(0).type == "textarea" ?
        $(initialTarget).get(0) :
        $(initialTarget).find("textarea").get(0)
    },

    getRenderingTarget(textarea) {
      return $(textarea).parent().get(0)
    },

    // anything that canvas needs to later find this
    // editor/textarea should be mirrored here so we
    // dont have to change too much canvas code
    _attrsToMirror(textarea) {
      let validAttrs = ["name"]
      let attrs = _.reduce(textarea.attributes, (memo, attr) => {
        memo[attr.name] = attr.value
        return memo
      }, {})

      return _.pick(attrs, validAttrs)
    },

    createRCEProps(textarea, tinyMCEInitOptions) {
      let textareaClassName = textarea.classList + " " + RCEStore.classKeyword
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
        textareaClassName: textareaClassName,
        language: ENV.LOCALE,
        mirroredAttrs: this._attrsToMirror(textarea)
      }
    },

    loadOnTarget(target, tinyMCEInitOptions, host) {
      const textarea = this.getTargetTextarea(target)
      const renderingTarget = this.getRenderingTarget(textarea)
      const propsForRCE = this.createRCEProps(textarea, tinyMCEInitOptions)

      const renderCallback = function(rceInstance){
        RCEStore.addToStore(textarea.id, rceInstance)
      }

      this.loadRCE(host, function (RCE) {
        RCE.renderIntoDiv(renderingTarget, propsForRCE, renderCallback)
      })
    }
  }

  return RCELoader;
});
