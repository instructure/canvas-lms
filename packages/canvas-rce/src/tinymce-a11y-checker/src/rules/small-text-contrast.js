import formatMessage from "../format-message"
import contrast from "wcag-element-contrast"
import {
  onlyContainsLink,
  createStyleString,
  splitStyleAttribute,
  hasTextNode
} from "../utils/dom"
import rgbHex from "../utils/rgb-hex"

export default {
  test: (elem, config = {}) => {
    const disabled = config.disableContrastCheck == true
    const noText = !hasTextNode(elem)

    if (
      disabled ||
      noText ||
      onlyContainsLink(elem) ||
      contrast.isLargeText(elem)
    ) {
      return true
    }
    return contrast(elem)
  },

  data: elem => {
    const styles = window.getComputedStyle(elem)
    return {
      color: styles.color
    }
  },

  form: () => [
    {
      label: formatMessage("Change text color"),
      dataKey: "color",
      color: true
    }
  ],

  update: (elem, data) => {
    elem.style.color = data.color
    const styles = splitStyleAttribute(
      elem.getAttribute("data-mce-style") || ""
    )
    if (data && data.color && data.color.indexOf("#") < 0) {
      styles.color = `#${rgbHex(data.color)}`
    } else {
      styles.color = data.color
    }
    elem.setAttribute("data-mce-style", createStyleString(styles))
    return elem
  },

  message: () =>
    formatMessage(
      "Text smaller than 18pt (or bold 14pt) should display a minimum contrast ratio of 4.5:1."
    ),

  why: () =>
    formatMessage(
      "Text is difficult to read without sufficient contrast between the text and the background, especially for those with low vision."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/G17.html"
}
