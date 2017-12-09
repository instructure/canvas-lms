import formatMessage from "../format-message"

const MAX_ALT_LENGTH = 120

export default {
  "max-alt-length": MAX_ALT_LENGTH,

  test: elem => {
    if (elem.tagName !== "IMG") {
      return true
    }
    const alt = elem.getAttribute("alt")
    return alt == null || alt.length <= MAX_ALT_LENGTH
  },

  data: elem => {
    const alt = elem.getAttribute("alt")
    return { alt: alt || "" }
  },

  form: () => [
    {
      label: formatMessage("Change alt text"),
      dataKey: "alt",
      textarea: true
    }
  ],

  update: (elem, data) => {
    elem.setAttribute("alt", data.alt)
    return elem
  },

  message: () =>
    formatMessage(
      "Alt attribute text should not contain more than 120 characters."
    ),

  why: () =>
    formatMessage(
      "Screen readers cannot determine what is displayed in an image without alternative text, which describes the content and meaning of the image. Alternative text should be simple and concise."
    ),

  link: ""
}
