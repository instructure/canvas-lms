const formatMessage = require("../format-message")

module.exports = {
  test: elem => {
    if (elem.tagName !== "IMG") {
      return true
    }
    const alt = elem.attributes.getNamedItem("alt")
    return alt && !!elem.attributes.getNamedItem("alt").value
  },

  data: elem => {
    const alt = elem.attributes.getNamedItem("alt")
    return {
      alt: alt ? alt.value : ""
    }
  },

  form: () => [
    {
      label: formatMessage("Add alt text for the image"),
      dataKey: "alt"
    }
  ],

  update: (elem, data) => {
    elem.setAttribute("alt", data.alt)
    return elem
  },

  message: () =>
    formatMessage(
      "Images should have an alt attribute describing its content."
    ),

  why: () =>
    formatMessage(`Paragraph about why alt text for images is important.`),

  link: "https://www.w3.org/TR/WCAG20-TECHS/G95.html"
}
