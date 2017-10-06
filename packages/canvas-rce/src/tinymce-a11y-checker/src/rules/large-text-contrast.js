const formatMessage = require("../format-message")
const contrast = require("wcag-element-contrast")
const smallTextContrast = require("./small-text-contrast")

module.exports = {
  test: elem => {
    if (!contrast.isLargeText(elem)) {
      return true
    }
    return contrast(elem)
  },

  data: smallTextContrast.data,

  form: smallTextContrast.form,

  update: smallTextContrast.update,

  message: () =>
    formatMessage(
      "Text larger than 18pt (or bold 14pt) should display a minimum contrast ratio of 3:1."
    ),

  why: () =>
    formatMessage(
      "Text is difficult to read without suffcient contrast between the text and the background, especially for those with low vision."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/G17.html"
}
