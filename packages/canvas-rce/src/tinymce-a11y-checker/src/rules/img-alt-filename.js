import formatMessage from "../format-message"

import axios from "axios"

const FILENAMELIKE = /^\S+\.\S+$/

export default {
  id: "img-alt-filename",

  test: elem => !FILENAMELIKE.test(elem.getAttribute("alt")),

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

  link: "https://www.w3.org/TR/WCAG20-TECHS/F30.html",
  linkText: () => formatMessage("Learn more about using filenames as alt text")
}
