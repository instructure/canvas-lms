const formatMessage = require("../format-message")
const dom = require("../utils/dom")

const MAX_HEADING_LENGTH = 125
const IS_HEADING = {
  H1: true,
  H2: true,
  H3: true,
  H4: true,
  H5: true,
  H6: true
}

module.exports = {
  "max-heading-length": MAX_HEADING_LENGTH,

  test: elem => {
    if (!IS_HEADING[elem.tagName]) {
      return true
    }
    return elem.textContent.length <= MAX_HEADING_LENGTH
  },

  data: elem => {
    return {
      change: false
    }
  },

  form: () => [
    {
      label: formatMessage("Change Heading tag to P"),
      checkbox: true,
      dataKey: "change"
    }
  ],

  update: (elem, data) => {
    let ret = elem
    if (data.change) {
      ret = dom.changeTag(elem, "p")
    }
    return ret
  },

  message: () =>
    formatMessage("Heading tags should not be used for paragraphs"),

  why: () =>
    formatMessage(
      "paragraph on why headings tags should not be used for paragraphs"
    ),

  link: ""
}
