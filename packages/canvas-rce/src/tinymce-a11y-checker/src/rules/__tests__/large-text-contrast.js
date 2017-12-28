import rule from "../large-text-contrast"

let el

beforeEach(() => {
  el = document.createElement("div")
})

describe("test", () => {
  test("returns true if element does not contain any  text", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "30px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#fff"
    elem.textContent = "  "
    expect(rule.test(elem)).toBe(true)
  })

  test("returns true if disabled by the config", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "30px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#fff"
    elem.textContent = "disabled"
    expect(rule.test(elem, { disableContrastCheck: true })).toBe(true)
  })

  test("returns true if the only content of a text node is a link", () => {
    const elem = document.createElement("div")
    const link = document.createElement("a")
    elem.style.fontSize = "30px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#eee"
    link.setAttribute("href", "http://example.com")
    link.textContent = "Example Site"
    elem.appendChild(link)
    expect(rule.test(elem)).toBe(true)
  })

  test("returns false if large text does not have high enough contrast", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "30px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#eee"
    elem.textContent = "hello"
    expect(rule.test(elem)).toBe(false)
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })
})

describe("message", () => {
  test("returns the proper message", () => {
    expect(rule.message()).toMatchSnapshot()
  })
})

describe("why", () => {
  test("returns the proper why message", () => {
    expect(rule.why()).toMatchSnapshot()
  })
})
