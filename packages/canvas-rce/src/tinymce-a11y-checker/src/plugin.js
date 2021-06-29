import React from "react"
import ReactDOM from "react-dom"
import Checker from "./components/checker"
import formatMessage from "./format-message"
import checkNode from "./node-checker"

let instance
const pendingInstanceCallbacks = []
const container = document.createElement("div")
container.className = "tinymce-a11y-checker-container"
document.body.appendChild(container)

tinymce.create("tinymce.plugins.AccessibilityChecker", {
  init: function(ed) {
    ed.addCommand("openAccessibilityChecker", (...args) => {
      ReactDOM.render(
        <Checker getBody={ed.getBody.bind(ed)} editor={ed} />,
        container,
        function() {
          // this is a workaround for react 16 since ReactDOM.render is not
          // guaranteed to return the instance synchronously (especially if called
          // within another component's lifecycle method eg: componentDidMount). see:
          // https://github.com/facebook/react/issues/10309#issuecomment-318434635
          instance = this
          pendingInstanceCallbacks.forEach(cb => cb(instance))
          instance.check(...args)
        }
      )
    })

    ed.addCommand("checkAccessibility", function(
      ui,
      { done, config, additional_rules }
    ) {
      checkNode(ed.getBody(), done, config, additional_rules)
    })

    if (tinymce.majorVersion === "4") {
      // remove this branch when everything is on tinymce 5
      ed.addButton("check_a11y", {
        title: formatMessage("Check Accessibility"),
        cmd: "openAccessibilityChecker",
        icon: "a11y"
      })
    } else {
      ed.ui.registry.addButton("check_a11y", {
        title: formatMessage("Check Accessibility"),
        onAction: _ => ed.execCommand("openAccessibilityChecker"),
        icon: "a11y"
      })
    }
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
