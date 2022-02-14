import formatMessage from "../format-message"
import { changeTag } from "../utils/dom"

const MAX_HEADING_LENGTH = 120
const IS_HEADING = {
  H1: true,
  H2: true,
  H3: true,
  H4: true,
  H5: true,
  H6: true,
}

export default {
  "max-heading-length": MAX_HEADING_LENGTH,

  id: "paragraphs-for-headings",
  test: (elem) => {
    if (!IS_HEADING[elem.tagName]) {
      return true
    }
    return elem.textContent.length <= MAX_HEADING_LENGTH
  },

  data: (elem) => {
    return {
      change: false,
    }
  },

  form: () => [
    {
      label: formatMessage("Change heading tag to paragraph"),
      checkbox: true,
      dataKey: "change",
    },
  ],

  update: (elem, data) => {
    let ret = elem
    if (data.change) {
      ret = changeTag(elem, "p")
    }
    return ret
  },

  message: () =>
    formatMessage("Headings should not contain more than 120 characters."),

  why: () =>
    formatMessage(
      "Sighted users browse web pages quickly, looking for large or bolded headings. Screen reader users rely on headers for contextual understanding. Headers should be concise within the proper structure."
    ),

  link: "",
}
