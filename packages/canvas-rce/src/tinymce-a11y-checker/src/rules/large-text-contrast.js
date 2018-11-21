import formatMessage from "../format-message"
import contrast from "wcag-element-contrast"
import smallTextContrast from "./small-text-contrast"
import { onlyContainsLink, hasTextNode } from "../utils/dom"

export default {
  id: "large-text-contrast",
  test: (elem, config = {}) => {
    const disabled = config.disableContrastCheck == true
    const noText = !hasTextNode(elem)
    if (
      disabled ||
      noText ||
      onlyContainsLink(elem) ||
      !contrast.isLargeText(elem)
    ) {
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
      "Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/G17.html",
  linkText: () => formatMessage("Learn more about color contrast")
}
