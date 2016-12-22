const exec = require('child_process').exec

module.exports = class WebpackHooks {
  apply (compiler) {
    const isEnabled = JSON.parse(process.env.ENABLE_CANVAS_WEBPACK_HOOKS || 'false')
    if (isEnabled) {
      const {
        CANVAS_WEBPACK_START_HOOK,
        CANVAS_WEBPACK_FAILED_HOOK,
        CANVAS_WEBPACK_DONE_HOOK
       } = process.env

      if (CANVAS_WEBPACK_START_HOOK) {
        compiler.plugin('compile', () => exec(CANVAS_WEBPACK_START_HOOK))
      }

      if (CANVAS_WEBPACK_FAILED_HOOK) {
        compiler.plugin('failed', () => exec(CANVAS_WEBPACK_FAILED_HOOK))
      }

      if (CANVAS_WEBPACK_DONE_HOOK) {
        compiler.plugin('done', () => exec(CANVAS_WEBPACK_DONE_HOOK))
      }
    }
  }
}
