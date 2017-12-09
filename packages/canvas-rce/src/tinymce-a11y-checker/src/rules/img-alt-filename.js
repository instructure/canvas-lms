import formatMessage from "../format-message"
import { filename } from "../utils/strings"

export default {
  test: elem => {
    if (elem.tagName !== "IMG") {
      return true
    }
    const alt = elem.getAttribute("alt")
    if (alt == null || alt === "") {
      return true
    }
    return filename(alt) !== filename(elem.src)
  },

  data: elem => {
    const alt = elem.getAttribute("alt")
    return { alt: alt || "" }
  },

  form: () => [
    {
      label: formatMessage("Change alt text"),
      dataKey: "alt"
    }
  ],

  update: (elem, data) => {
    elem.setAttribute("alt", data.alt)
    return elem
  },

  message: () =>
    formatMessage(
      "Image filenames should not be used as the alt attribute describing the image content."
    ),

  why: () =>
    formatMessage(
      "Screen readers cannot determine what is displayed in an image without alternative text, and filenames are often meaningless strings of numbers and letters that do not describe the context or meaning."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/F30.html"
}
