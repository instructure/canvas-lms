import formatMessage from "format-message"
import * as strings from "./strings"

const WORD_COUNT = 4

export default function describe(elem) {
  switch (elem.tagName) {
    case "IMG":
      return formatMessage("Image with filename {file}", {
        file: strings.filename(elem.src)
      })
    case "TABLE":
      return formatMessage("Table starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
    case "A":
      return formatMessage("Link with text starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
    case "P":
      return formatMessage("Paragraph starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
    case "TH":
      return formatMessage("Table header starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
    case "H1":
    case "H2":
    case "H3":
    case "H4":
    case "H5":
      return formatMessage("Heading starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
    default:
      return formatMessage("Element starting with {start}", {
        start: strings.firstWords(elem.textContent, WORD_COUNT)
      })
  }
}
