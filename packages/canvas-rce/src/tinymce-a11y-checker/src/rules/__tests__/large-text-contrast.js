const rule = require("../large-text-contrast")

let el

beforeEach(() => {
  el = document.createElement("div")
})

describe("test", () => {})

describe("data", () => {})

describe("form", () => {})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })
})
