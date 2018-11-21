import formatMessage from "../format-message"
import { changeTag } from "../utils/dom"

const _forEach = Array.prototype.forEach

export default {
  id: "table-header",
  test: elem => {
    if (elem.tagName !== "TABLE") {
      return true
    }
    return elem.querySelector("th")
  },

  data: elem => {
    return {
      header: "none"
    }
  },

  form: () => [
    {
      label: formatMessage("Set table header"),
      dataKey: "header",
      options: [
        ["none", formatMessage("No headers")],
        ["row", formatMessage("Header row")],
        ["col", formatMessage("Header column")],
        ["both", formatMessage("Header row and column")]
      ]
    }
  ],

  update: (elem, data) => {
    _forEach.call(elem.querySelectorAll("th"), th => {
      changeTag(th, "td")
    })
    if (data.header === "none") {
      return elem
    }
    const row = data.header === "row" || data.header === "both"
    const col = data.header === "col" || data.header === "both"
    const tableRows = elem.querySelectorAll("tr")
    for (let i = 0; i < tableRows.length; ++i) {
      if (i === 0 && row) {
        _forEach.call(tableRows[i].querySelectorAll("td"), td => {
          const th = changeTag(td, "th")
          th.setAttribute("scope", "col")
        })
        continue
      }
      if (!col) {
        break
      }
      const td = tableRows[i].querySelector("td")
      if (td) {
        const th = changeTag(td, "th")
        th.setAttribute("scope", "row")
      }
    }
    return elem
  },

  message: () => formatMessage("Tables should include at least one header."),

  why: () =>
    formatMessage(
      "Screen readers cannot interpret tables without the proper structure. Table headers provide direction and overview of the content."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H43.html",
  linkText: () => formatMessage("Learn more about table headers")
}
