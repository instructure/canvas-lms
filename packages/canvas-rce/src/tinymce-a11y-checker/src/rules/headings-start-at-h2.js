import { changeTag } from "../utils/dom"
import formatMessage from "../format-message"

export default {
  id: "headings-start-at-h2",

  test: (elem, config = {}) => {
    if (!!config.disableHeadingsStartAtH2) {
      return true
    }
    return elem.tagName !== "H1"
  },

  data: elem => {
    return {
      action: "nothing"
    }
  },

  form: () => [
    {
      label: formatMessage("Action to take:"),
      dataKey: "action",
      options: [
        ["nothing", formatMessage("Leave as is")],
        ["elem-only", formatMessage("Change only this heading's level")],
        ["modify", formatMessage("Remove heading style")]
      ]
    },
    {
      label: formatMessage("Additional considerations"),
      alert: true,
      dataKey: "alert",
      variant: "warning",
      message: formatMessage(
        "You may need to adjust additional headings to maintain page hierarchy."
      )
    }
  ],

  update: (elem, data) => {
    if (!data || !data.action) {
      return elem
    }

    switch (data.action) {
      case "nothing":
        return elem
      case "elem-only":
        return changeTag(elem, "h2")
      case "modify":
        return changeTag(elem, "p")
    }
  },

  message: () => formatMessage("The first heading on a page should be an H2."),

  why: () =>
    formatMessage(
      "Webpages should only have a single H1, which is automatically used by the page's Title. The first heading in your content should be an H2."
    ),

  link: "https://www.w3.org/TR/WCAG20-TECHS/H42.html",

  linkText: () =>
    formatMessage("Learn more about proper page heading structure")
}
