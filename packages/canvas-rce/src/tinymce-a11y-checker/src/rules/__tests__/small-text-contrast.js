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

  test("returns true if disabled by the config", () => {
    const elem = document.createElement("div")
    elem.style.fontSize = "10px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#fff"
    elem.textContent = "disabled"
    expect(rule.test(elem, { disableContrastCheck: true })).toBe(true)
  })

  test("returns true if the only content of a text node is a link", () => {
    const elem = document.createElement("div")
    const link = document.createElement("a")
    elem.style.fontSize = "10px"
    elem.style.backgroundColor = "#fff"
    elem.style.color = "#eee"
    link.setAttribute("href", "http://example.com")
    link.textContent = "Example Site"
    elem.appendChild(link)
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

describe("data", () => {
  test("returns the color matching the elements existing color", () => {
    el.style.color = "blue"
    expect(rule.data(el)).toEqual({
      color: "blue"
    })
  })
})

describe("form", () => {
  test("returns the proper object", () => {
    expect(rule.form()).toMatchSnapshot()
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("sets the elements style color based on the color option", () => {
    rule.update(el, { color: "#fff" })
    expect(el.style.color).toBe("rgb(255, 255, 255)") // Seems like this always comes back as rgb
  })

  test("sets the mce-style data attribute with the updated color", () => {
    rule.update(el, { color: "#fff" })
    expect(el.getAttribute("data-mce-style")).toBe("color: #fff;")
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
