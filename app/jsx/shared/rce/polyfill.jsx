define(['underscore'], function(_) {

  const editorExtensions = {
    call(methodName, ...args) {
      // since exists? has a ? and cant be a regular function (yet we want
      // the same signature as editorbox) just return true rather than
      // calling as a fn on the editor
      if (methodName === "exists?") { return true }
      return this[methodName](...args)
    },

    focus() {
      // TODO implement this once in service
    }
  }

  const sidebarExtensions = {
    show() {
      // TODO generalize/adapt this once in service
      $("#editor_tabs").show()
    },

    hide() {
      // TODO generalize/adapt this once in service
      $("#editor_tabs").hide()
    }
  }

  const polyfill = {
    wrapEditor(editor) {
      let extensions = _.extend({}, editorExtensions, editor)
      return _.extend(editor, extensions)
    },

    wrapSidebar(sidebar) {
      let extensions = _.extend({}, sidebarExtensions, sidebar)
      return _.extend(sidebar, extensions)
    }
  }

  return polyfill
})
