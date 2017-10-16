import rule from "../img-alt"

let el

beforeEach(() => {
  el = document.createElement("img")
})

describe("test", () => {
  test("returns true if alt text is not empty", () => {
    el.setAttribute("alt", "some text")
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns true if decorative", () => {
    el.setAttribute("data-decorative", "")
    expect(rule.test(el)).toBeTruthy()
  })

  test("returns false if no alt attribute", () => {
    expect(rule.test(el)).toBeFalsy()
  })

  test("returns false if alt is empty and not decorative", () => {
    el.setAttribute("alt", "")
    expect(rule.test(el)).toBeFalsy()
  })

  test("returns false for alt containing only white space", () => {
    el.setAttribute("alt", "   ")
    expect(rule.test(el)).toBeFalsy()
  })
})

describe("data", () => {
  test("returns alt text", () => {
    el.setAttribute("alt", "some text")
    expect(rule.data(el).alt).toBe("some text")
  })

  test("returns empty alt text if no alt attribute", () => {
    expect(rule.data(el).alt).toBe("")
  })

  test("returns decorative true if el has data-decorative", () => {
    el.setAttribute("data-decorative", "")
    expect(rule.data(el).decorative).toBeTruthy()
  })

  test("returns decorative false if el has alt text and data-decorative", () => {
    el.setAttribute("data-decorative", "")
    el.setAttribute("alt", "some text")
    expect(rule.data(el).decorative).toBeFalsy()
  })

  test("returns decorative false if el does not have data-decorative", () => {
    expect(rule.data(el).decorative).toBeFalsy()
  })
})

describe("form", () => {
  test("alt field is disabled if decorative", () => {
    const altField = rule.form().find(f => f.dataKey === "alt")
    expect(altField.disabledIf({ decorative: true })).toBeTruthy()
  })

  test("alt field is not disabled if not decorative", () => {
    const altField = rule.form().find(f => f.dataKey === "alt")
    expect(altField.disabledIf({ decorative: false })).toBeFalsy()
  })
})

describe("update", () => {
  test("returns same element", () => {
    expect(rule.update(el, {})).toBe(el)
  })

  test("sets alt text to empty and data-decorative if decorative", () => {
    rule.update(el, { decorative: true })
    expect(el.hasAttribute("data-decorative")).toBeTruthy()
    expect(el.getAttribute("alt")).toBe("")
  })

  test("sets alt text if not decorative", () => {
    rule.update(el, { decorative: false, alt: "some text" })
    expect(el.getAttribute("alt")).toBe("some text")
  })

  test("removes data-decorative if not decorative", () => {
    el.setAttribute("data-decorative", "")
    rule.update(el, { decorative: false })
    expect(el.hasAttribute("data-decorative")).toBeFalsy()
  })
})
