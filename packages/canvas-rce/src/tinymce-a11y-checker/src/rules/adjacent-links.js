const formatMessage = require("../format-message")
const dom = require("../utils/dom")

const shouldMergeAnchors = (elem1, elem2) => {
  if (!elem1 || !elem2 || elem1.tagName !== "A" || elem2.tagName !== "A") {
    return false
  }
  return elem1.getAttribute("href") === elem2.getAttribute("href")
}

module.exports = {
  test: function(elem) {
    if (elem.tagName != "A") {
      return true
    }
    return !shouldMergeAnchors(elem, elem.nextElementSibling)
  },

  data: elem => {
    return {
      combine: false
    }
  },

  form: () => [
    {
      label: formatMessage("Merge links"),
      checkbox: true,
      dataKey: "combine"
    }
  ],

  update: function(elem, data) {
    const rootElem = elem.parentNode
    if (data.combine) {
      const next = elem.nextElementSibling
      rootElem.removeChild(next)
      elem.innerHTML += next.innerHTML
    }
    return elem
  },

  rootNode: function(elem) {
    return elem.parentNode
  },

  message: () =>
    formatMessage("Adjacent links with the same URL should be a single link."),

  why: () =>
    formatMessage(
      "Keyboards navigate to links using the Tab key. Two adjacent links that direct to the same destination can be confusing to keyboard users."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H2.html"
}
