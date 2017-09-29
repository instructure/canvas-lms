const rule = require("../headings-sequence")

let h2
let body

beforeEach(() => {
  body = document.createElement("body")
  h2 = document.createElement("h2")
  body.appendChild(h2)
})

describe("test", () => {
  test("returns false if previous heading is not sequential", () => {
    const h4 = document.createElement("H4")
    body.appendChild(h4)
    expect(rule.test(h4)).toBeFalsy()
  })

  test("returns false if H2-H6 and top of document", () => {
    expect(rule.test(h2)).toBeFalsy()
  })

  test("return true if previous heading is sequential", () => {
    const h3 = document.createElement("H3")
    body.appendChild(h3)
    expect(rule.test(h3)).toBeTruthy()
  })

  test("return true if H1", () => {
    const h1 = document.createElement("h1")
    expect(rule.test(h1)).toBeTruthy()
  })

  test("return true on non-h tag", () => {
    const div = document.createElement("div")
    expect(rule.test(div)).toBeTruthy()
  })
})

describe("data", () => {
  test("default action is 'nothing'", () => {
    expect(rule.data().action).toBe("nothing")
  })
})

describe("form", () => {
  test("form has dataKey of 'action'", () => {
    expect(rule.form()[0].dataKey).toBe("action")
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(h2, {})).toBe(h2)
  })

  test("returns different h element on 'elem' action", () => {
    const h4 = document.createElement("h4")
    body.appendChild(h4)
    expect(rule.update(h4, { action: "elem" }).tagName).toBe("H3")
  })

  test("returns div element on 'modify' action", () => {
    expect(rule.update(h2, { action: "modify" }).tagName).toBe("DIV")
  })

  test("returns h1 element on 'modify' and prior elem unassigned", () => {
    expect(rule.update(h2, { action: "elem" }).tagName).toBe("H1")
  })
})
