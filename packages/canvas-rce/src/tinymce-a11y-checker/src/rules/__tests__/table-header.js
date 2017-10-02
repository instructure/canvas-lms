const rule = require("../table-header")

let el

beforeEach(() => {
  el = document.createElement("table")
})

describe("test", () => {})

describe("data", () => {})

describe("form", () => {})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })
})
