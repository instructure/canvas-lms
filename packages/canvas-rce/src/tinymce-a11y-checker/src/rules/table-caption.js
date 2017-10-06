const formatMessage = require("../format-message")
const dom = require("../utils/dom")

module.exports = {
  test: elem => {
    if (elem.tagName !== "TABLE") {
      return true
    }
    const caption = elem.querySelector("caption")
    return !!caption && caption.textContent.replace("/s/g") !== ""
  },

  data: elem => {
    const alt = elem.attributes.getNamedItem("alt")
    return {
      caption: ""
    }
  },

  form: () => [
    {
      label: formatMessage("Add a caption"),
      dataKey: "caption"
    }
  ],

  update: (elem, data) => {
    let caption = elem.querySelector("caption")
    if (!caption) {
      caption = elem.ownerDocument.createElement("caption")
      dom.prepend(elem, caption)
    }
    caption.textContent = data.caption
    return elem
  },

  message: () =>
    formatMessage(
      "Tables should include a caption describing the contents of the table."
    ),

  why: () =>
    formatMessage(
      "Screen readers cannot interpret tables without the proper structure. Table captions describe the context and general understanding of the table."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H39.html"
}
