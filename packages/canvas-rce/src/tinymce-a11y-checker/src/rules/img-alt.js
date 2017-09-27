const formatMessage = require("../format-message")

module.exports = {
  test: elem => {
    if (elem.tagName !== "IMG") {
      return true
    }

    const alt = elem.getAttribute("alt")
    const isDecorative = elem.hasAttribute("data-decorative")
    return alt || isDecorative
  },

  data: elem => {
    const alt = elem.getAttribute("alt")
    const decorative = elem.hasAttribute("data-decorative")
    return {
      alt: alt || "",
      decorative: !alt && decorative
    }
  },

  form: () => [
    {
      label: formatMessage("Add alt text for the image"),
      dataKey: "alt",
      disabledIf: data => data.decorative
    },
    {
      label: formatMessage("Decorative Image"),
      dataKey: "decorative",
      checkbox: true
    }
  ],

  update: (elem, data) => {
    if (data.decorative) {
      elem.setAttribute("alt", "")
      elem.setAttribute("data-decorative", "true")
    } else {
      elem.setAttribute("alt", data.alt)
      elem.removeAttribute("data-decorative")
    }
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
