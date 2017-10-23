import formatMessage from "format-message"
import contrast from "wcag-element-contrast"

export default {
  test: elem => {
    const noText = elem.textContent.replace(/\s/g, "") === ""
    if (noText || contrast.isLargeText(elem)) {
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
    return elem
  },

  message: () =>
    formatMessage(
      "Text smaller than 18pt (or bold 14pt) should display a minimum contrast ratio of 4.5:1."
    ),

  why: () =>
    formatMessage(
      "Text is difficult to read without suffcient contrast between the text and the background, especially for those with low vision."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/G17.html"
}
