import formatMessage from "../format-message"

const FILENAMELIKE = /^\S+\.\S+$/

export default {
  id: "img-alt-filename",

  test: elem => {
    if (elem.tagName !== "IMG") {
      return true
    }
    const alt = elem.hasAttribute("alt") ? elem.getAttribute("alt") : null
    const isDecorative = alt !== null && alt.replace(/\s/g, "") === ""
    return !FILENAMELIKE.test(alt) || isDecorative
  },

  data: elem => {
    const alt = elem.hasAttribute("alt") ? elem.getAttribute("alt") : null
    const decorative = alt !== null && alt.replace(/\s/g, "") === ""
    return {
      alt: alt || "",
      decorative: decorative
    }
  },

  form: () => [
    {
      label: formatMessage("Change alt text"),
      dataKey: "alt",
      disabledIf: data => data.decorative
    },
    {
      label: formatMessage("Decorative image"),
      dataKey: "decorative",
      checkbox: true
    }
  ],

  update: (elem, data) => {
    if (data.decorative) {
      elem.setAttribute("alt", "")
      elem.setAttribute("role", "presentation")
    } else {
      elem.setAttribute("alt", data.alt)
      elem.removeAttribute("role")
    }
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

  link: "https://www.w3.org/TR/WCAG20-TECHS/F30.html",
  linkText: () => formatMessage("Learn more about using filenames as alt text")
}
