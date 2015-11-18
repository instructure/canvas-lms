define([
  'jquery',
  'jsx/shared/rce/editorOptions',
  'jsx/shared/rce/rceStore',
  'jsx/shared/rce/loadEventListeners'
], function($, editorOptions, RCEStore, loadEventListeners){
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

    createRCEProps(textarea, defaultContent){
      let textareaClassName = textarea.classList + " " + RCEStore.classKeyword
      let width = textarea.offsetWidth

      return {
        editorOptions: editorOptions.bind(null, width, textarea.id),
        defaultContent: textarea.value || defaultContent,
        textareaId: textarea.id,
        textareaClassName: textareaClassName
      }
    },

    loadOnTarget(target, defaultContent, host){
      const textarea = this.getTargetTextarea(target)
      const renderingTarget = this.getRenderingTarget(textarea)
      const propsForRCE = this.createRCEProps(textarea, defaultContent)

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
