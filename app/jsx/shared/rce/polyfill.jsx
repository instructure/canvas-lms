define(['underscore'], function(_) {

  const editorExtensions = {
    call(methodName, ...args) {
      // since exists? has a ? and cant be a regular function (yet we want
      // the same signature as editorbox) just return true rather than
      // calling as a fn on the editor
      if (methodName === "exists?") { return true }
      return this[methodName](...args)
    }
  }

  const polyfill = {
    wrapEditor(editor) {
      let extensions = _.extend({}, editorExtensions, editor)
      return _.extend(editor, extensions)
    }
  }

  return polyfill
})
