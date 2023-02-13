import React from "react"
import ReactDOM from "react-dom"
import Checker from "./components/checker"
import formatMessage from "./format-message"
import checkNode from "./node-checker"

let isCheckerOpen = false
let instance
const pendingInstanceCallbacks = []
const container = document.createElement("div")
container.className = "tinymce-a11y-checker-container"
document.body.appendChild(container)

tinymce.create("tinymce.plugins.AccessibilityChecker", {
  init: function (ed) {
    ed.addCommand("openAccessibilityChecker", function (
      ui,
      { done, config, additionalRules, mountNode }
    ) {
      if (!isCheckerOpen) {
        ReactDOM.render(
          <Checker
            getBody={ed.getBody.bind(ed)}
            editor={ed}
            additionalRules={additionalRules}
            mountNode={mountNode}
            onClose={() => isCheckerOpen = false}
          />,
          container,
          function () {
            // this is a workaround for react 16 since ReactDOM.render is not
            // guaranteed to return the instance synchronously (especially if called
            // within another component's lifecycle method eg: componentDidMount). see:
            // https://github.com/facebook/react/issues/10309#issuecomment-318434635
            instance = this
            if (config) getInstance(instance => instance.setConfig(config))
            pendingInstanceCallbacks.forEach(cb => cb(instance))
            instance.check(done)
          }
        )
        isCheckerOpen = true
      }
    })

    ed.addCommand("checkAccessibility", function (
      ui,
      { done, config, additionalRules }
    ) {
      checkNode(ed.getBody(), done, config, additionalRules)
    })

    ed.ui.registry.addButton("check_a11y", {
      title: formatMessage("Check Accessibility"),
      onAction: _ => ed.execCommand("openAccessibilityChecker"),
      icon: "a11y"
    })
  }
})

// Register plugin
tinymce.PluginManager.add("a11y_checker", tinymce.plugins.AccessibilityChecker)

export function getInstance(cb) {
  if (instance != null) {
    return cb(instance)
  }
  pendingInstanceCallbacks.push(cb)
}

export function setLocale(locale) {
  const options = formatMessage.setup()
  options.locale = locale
  formatMessage.setup(options)
}
