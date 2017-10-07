import React from "react"
import ReactDOM from "react-dom"
import Checker from "./components/checker"
import formatMessage from "format-message"

tinymce.create("tinymce.plugins.AccessibilityChecker", {
  init: function(ed) {
    const container = document.createElement("div")
    container.className = "tinymce-a11y-checker-container"
    document.body.appendChild(container)
    const checker = ReactDOM.render(
      <Checker getBody={ed.getBody.bind(ed)} />,
      container
    )

    ed.addCommand("openAccessibilityChecker", checker.check.bind(checker))

    ed.addButton("check_a11y", {
      title: formatMessage("Check Accessibility"),
      cmd: "openAccessibilityChecker",
      icon: "a11y"
    })
  },

  getInfo: function() {
    return {
      longname: "Instructure Accessibility Checker",
      author: "Brent Burgoyne",
      authorurl: "https://github.com/instructure",
      infourl: "https://github.com/instructure/tinymce-a11y",
      version: "1.0"
    }
  }
})

// Register plugin
tinymce.PluginManager.add("a11y_checker", tinymce.plugins.AccessibilityChecker)
