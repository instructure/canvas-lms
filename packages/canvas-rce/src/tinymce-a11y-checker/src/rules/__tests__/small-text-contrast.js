import rule from "../small-text-contrast"

let el

beforeEach(() => {
  el = document.createElement("div")
})

describe("test", () => {
  test("returns true if element does not contain any  text", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "10px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#fff"
    elem.textContent = "  "
    expect(rule.test(elem)).toBe(true)
  })

  test("returns false if large text does not have high enough contrast", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "10px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#eee"
    elem.textContent = "hello"
    expect(rule.test(elem)).toBe(false)
  })
})

describe("data", () => {})

describe("form", () => {})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })
})
