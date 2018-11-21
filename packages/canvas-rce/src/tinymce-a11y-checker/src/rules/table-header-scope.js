import formatMessage from "../format-message"

const VALID_SCOPES = ["row", "col", "rowgroup", "colgroup"]

export default {
  id: "table-header-scope",
  test: elem => {
    if (elem.tagName !== "TH") {
      return true
    }
    return VALID_SCOPES.indexOf(elem.getAttribute("scope")) !== -1
  },

  data: elem => {
    return {
      scope: elem.getAttribute("scope") || "none"
    }
  },

  form: () => [
    {
      label: formatMessage("Set header scope"),
      dataKey: "scope",
      options: [
        ["none", formatMessage("None")],
        ["row", formatMessage("Row")],
        ["col", formatMessage("Column")],
        ["rowgroup", formatMessage("Row group")],
        ["colgroup", formatMessage("Column group")]
      ]
    }
  ],

  update: (elem, data) => {
    if (data.header === "none") {
      elem.removeAttribute("scope")
    } else {
      elem.setAttribute("scope", data.scope)
    }
    return elem
  },

  message: () => formatMessage("Tables headers should specify scope."),

  why: () =>
    formatMessage(
      "Screen readers cannot interpret tables without the proper structure. Table headers provide direction and content scope."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H63.html",
  linkText: () =>
    formatMessage("Learn more about using scope attributes with tables")
}
