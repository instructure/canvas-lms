import * as dom from "./utils/dom"
import rules from "./rules"

export default function checkNode(
  node,
  done,
  config = {},
  additionalRules = []
) {
  if (!node) {
    return
  }
  const errors = []
  const childNodeCheck = child => {
    const composedRules = rules.concat(additionalRules)
    for (let rule of composedRules) {
      if (child.hasAttribute("data-ignore-a11y-check")) {
        continue
      }
      const promise = Promise.resolve(rule.test(child, config)).then(result => {
        if (!result) {
          errors.push({ node: child, rule })
        }
      })
    }
  }
  const checkDone = () => {
    if (typeof done === "function") {
      done(errors)
    }
  }
  dom.walk(node, childNodeCheck, checkDone)
}
